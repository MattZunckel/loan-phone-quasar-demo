# Phone Loan Application Demo

Mobile-first Quasar + Vue + Supabase demo for a phone loan application flow.

## Features

- Step 1: Name, South African ID number, date of birth
- SA ID validation with DOB match and Luhn checksum
- Age eligibility: 18 to 65 inclusive
- Internal age-based pricing group; not shown to customer
- Step 2: Income and income-proof upload
- Step 3: Eligible phone dropdown based on income >= 10x monthly eligibility price
- Step 4: Daily repayment only: total loan amount / 365
- Step 5: Terms acceptance and mock checkout
- Supabase Postgres storage for in-progress and completed applications
- Supabase Storage bucket for income proof documents

## Prompt coverage

- Identity details are saved first and locked in the UI after submission.
- The database trigger in `supabase/schema.sql` prevents later updates to ID number, date of birth, age, and risk group.
- In-progress applications use statuses such as `identity_submitted`, `income_submitted`, `phone_selected`, and `terms_accepted`.
- Completed applications use status `completed` and store `completed_at`.
- Phone catalogue and risk pricing live in Supabase tables so they can be edited without changing the app code.
- The total loan formula is deliberately isolated in `src/utils/pricing.js` because the final formula is still pending.

## Local setup

```bash
npm install
cp .env.example .env
npm run dev
```

Add your Supabase project URL and anon key to `.env`.

## Supabase setup

1. Create a Supabase project.
2. Go to SQL Editor.
3. Run `supabase/schema.sql`.
4. Create a private storage bucket called `income-documents` if the SQL does not create it automatically in your Supabase plan.

## Build

```bash
npm run build
```

The production bundle is generated in `dist/spa`.

## Live demo hosting

This is a static Quasar SPA backed by Supabase, so the simplest live demo route is Vercel or Netlify. The included `vercel.json` is ready for Vercel: set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` as environment variables, then deploy.

Fly.io can host it, but it is more work for this kind of frontend-only demo because you would need to serve the generated `dist/spa` folder from a small web server container. For this project, Vercel is the recommended hosting choice unless you later add a custom backend service.
