-- Run this in Supabase SQL Editor.
-- Demo schema for Quasar/Vue phone loan application.

create extension if not exists pgcrypto;

create table if not exists public.phones (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  cash_price numeric(12,2) not null check (cash_price > 0),
  eligibility_monthly_price numeric(12,2) not null check (eligibility_monthly_price > 0),
  active boolean not null default true,
  image_url text,
  description text,
  created_at timestamptz not null default now()
);

create table if not exists public.risk_pricing (
  id uuid primary key default gen_random_uuid(),
  risk_group text not null unique check (risk_group in ('risk_1', 'risk_2', 'risk_3')),
  min_age int not null,
  max_age int not null,
  deposit_percent numeric(6,2) not null check (deposit_percent >= 0 and deposit_percent <= 100),
  annual_interest_rate numeric(6,2) not null check (annual_interest_rate >= 0),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.applications (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  id_number text not null,
  date_of_birth date not null,
  age_at_application int not null,
  risk_group text not null check (risk_group in ('risk_1', 'risk_2', 'risk_3')),
  monthly_income numeric(12,2),
  income_type text,
  income_document_path text,
  selected_phone_id uuid references public.phones(id),
  selected_pricing_snapshot jsonb,
  loan_principal numeric(12,2),
  loan_amount numeric(12,2),
  daily_repayment numeric(12,2),
  terms_accepted boolean not null default false,
  terms_accepted_at timestamptz,
  mock_payment_completed boolean not null default false,
  status text not null default 'identity_submitted' check (
    status in (
      'identity_submitted',
      'income_submitted',
      'phone_selected',
      'terms_accepted',
      'completed',
      'abandoned',
      'rejected_age'
    )
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz
);

create table if not exists public.application_events (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null references public.applications(id) on delete cascade,
  event_type text not null,
  event_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.applications
  add column if not exists loan_principal numeric(12,2),
  add column if not exists loan_amount numeric(12,2),
  add column if not exists daily_repayment numeric(12,2);

create unique index if not exists applications_one_completed_loan_per_id_number
on public.applications (id_number)
where status = 'completed';

create or replace function public.is_valid_luhn(input_value text)
returns boolean as $$
declare
  digits text := regexp_replace(coalesce(input_value, ''), '\D', '', 'g');
  total int := 0;
  digit int;
  should_double boolean := false;
  idx int;
begin
  if digits !~ '^\d{13}$' then
    return false;
  end if;

  for idx in reverse length(digits)..1 loop
    digit := substring(digits from idx for 1)::int;
    if should_double then
      digit := digit * 2;
      if digit > 9 then
        digit := digit - 9;
      end if;
    end if;
    total := total + digit;
    should_double := not should_double;
  end loop;

  return total % 10 = 0;
end;
$$ language plpgsql immutable;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'applications_full_name_not_blank') then
    alter table public.applications
      add constraint applications_full_name_not_blank
      check (length(trim(full_name)) > 1)
      not valid;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'applications_valid_sa_id') then
    alter table public.applications
      add constraint applications_valid_sa_id
      check (
        id_number ~ '^\d{13}$'
        and substring(id_number from 11 for 1) in ('0', '1')
        and public.is_valid_luhn(id_number)
        and substring(id_number from 1 for 6) = to_char(date_of_birth, 'YYMMDD')
      )
      not valid;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'applications_age_eligible') then
    alter table public.applications
      add constraint applications_age_eligible
      check (age_at_application between 18 and 65)
      not valid;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'applications_monthly_income_positive') then
    alter table public.applications
      add constraint applications_monthly_income_positive
      check (monthly_income is null or monthly_income > 0)
      not valid;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'applications_income_type_allowed') then
    alter table public.applications
      add constraint applications_income_type_allowed
      check (income_type is null or income_type in ('Salary', 'Self-employed', 'Other'))
      not valid;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'applications_income_step_complete') then
    alter table public.applications
      add constraint applications_income_step_complete
      check (
        status = 'identity_submitted'
        or (monthly_income is not null and income_type is not null and income_document_path is not null)
      )
      not valid;
  end if;

  if not exists (select 1 from pg_constraint where conname = 'applications_pricing_values_positive') then
    alter table public.applications
      add constraint applications_pricing_values_positive
      check (
        loan_principal is null or (
          loan_principal > 0
          and loan_amount > 0
          and daily_repayment > 0
        )
      )
      not valid;
  end if;
end $$;

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_applications_updated_at on public.applications;
create trigger trg_applications_updated_at
before update on public.applications
for each row execute function public.set_updated_at();

-- Prevent changing identity/pricing-group fields after initial submission.
create or replace function public.lock_application_identity_fields()
returns trigger as $$
begin
  if old.id_number is distinct from new.id_number
     or old.date_of_birth is distinct from new.date_of_birth
     or old.age_at_application is distinct from new.age_at_application
     or old.risk_group is distinct from new.risk_group then
    raise exception 'Identity fields are locked once submitted';
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_lock_application_identity_fields on public.applications;
create trigger trg_lock_application_identity_fields
before update on public.applications
for each row execute function public.lock_application_identity_fields();

-- Reference pricing. Replace these demo values with your real pricing.
insert into public.risk_pricing (risk_group, min_age, max_age, deposit_percent, annual_interest_rate, active)
values
  ('risk_1', 18, 30, 20.00, 35.00, true),
  ('risk_2', 31, 50, 15.00, 28.00, true),
  ('risk_3', 51, 65, 25.00, 40.00, true)
on conflict (risk_group) do update set
  min_age = excluded.min_age,
  max_age = excluded.max_age,
  deposit_percent = excluded.deposit_percent,
  annual_interest_rate = excluded.annual_interest_rate,
  active = excluded.active;

-- Demo phone catalogue. Change this in Supabase table editor.
insert into public.phones (name, cash_price, eligibility_monthly_price, active)
values
  ('Samsung Galaxy A05', 2499.00, 220.00, true),
  ('Samsung Galaxy A15', 3999.00, 350.00, true),
  ('Xiaomi Redmi 13C', 3299.00, 300.00, true),
  ('Honor X7b', 5999.00, 525.00, true),
  ('Samsung Galaxy A25', 6999.00, 625.00, true),
  ('iPhone 11 Pre-Owned', 8999.00, 800.00, true)
on conflict do nothing;

-- Storage bucket for income documents. Private bucket.
insert into storage.buckets (id, name, public)
values ('income-documents', 'income-documents', false)
on conflict (id) do nothing;

alter table public.phones enable row level security;
alter table public.risk_pricing enable row level security;
alter table public.applications enable row level security;
alter table public.application_events enable row level security;

grant usage on schema public to anon, authenticated;
grant select on public.phones to anon, authenticated;
grant select on public.risk_pricing to anon, authenticated;
grant select, insert, update on public.applications to anon, authenticated;
grant insert on public.application_events to anon, authenticated;

-- Public demo policies. These are intentionally simple for a live demo without login.
-- For production, replace anonymous policies with authenticated users or server-side API routes.

drop policy if exists "Anyone can read active phones" on public.phones;
create policy "Anyone can read active phones"
on public.phones for select
to anon, authenticated
using (active = true);

drop policy if exists "Anyone can read active risk pricing" on public.risk_pricing;
create policy "Anyone can read active risk pricing"
on public.risk_pricing for select
to anon, authenticated
using (active = true);

drop policy if exists "Anyone can read demo applications" on public.applications;
create policy "Anyone can read demo applications"
on public.applications for select
to public
using (true);

drop policy if exists "Anyone can create demo applications" on public.applications;
create policy "Anyone can create demo applications"
on public.applications for insert
to public
with check (true);

drop policy if exists "Anyone can update demo applications" on public.applications;
create policy "Anyone can update demo applications"
on public.applications for update
to public
using (true)
with check (true);

drop policy if exists "Anyone can create demo events" on public.application_events;
create policy "Anyone can create demo events"
on public.application_events for insert
to public
with check (true);

-- Storage policies for demo uploads.
grant insert on storage.objects to anon, authenticated;

drop policy if exists "Anyone can upload income documents" on storage.objects;
create policy "Anyone can upload income documents"
on storage.objects for insert
to public
with check (bucket_id = 'income-documents');

-- Keep reads private from the frontend by default. View documents from Supabase dashboard/admin tooling.
