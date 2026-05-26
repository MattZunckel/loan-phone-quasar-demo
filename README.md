# Phone Loan Application Demo

Mobile-first Quasar + Vue + Supabase demo for a phone loan application flow.

## Features

- Step 1: Name, South African ID number, date of birth
- SA ID validation with DOB match and Luhn checksum
- Age eligibility: 18 to 65 inclusive
- Internal age-based pricing group; not shown to customer
- Step 2: Income and income-proof upload
- Step 3: Eligible phone dropdown based on income >= 10x calculated monthly repayment
- Step 4: Daily repayment only: total loan amount / 360
- Step 5: Terms acceptance and mock checkout
- Supabase Postgres storage for in-progress and completed applications
- Supabase Storage bucket for income proof documents
- One completed loan per South African ID number; abandoned or in-progress attempts can be restarted

## Prompt coverage

- Identity details are saved first and locked in the UI after submission.
- The database trigger in `supabase/schema.sql` prevents later updates to ID number, date of birth, age, and risk group.
- In-progress applications use statuses such as `identity_submitted`, `income_submitted`, `phone_selected`, and `terms_accepted`.
- Completed applications use status `completed` and store `completed_at`.
- A partial unique database index prevents the same ID number from having more than one `completed` application.
- Phone catalogue and risk pricing live in Supabase tables so they can be edited without changing the app code.
- Phone eligibility uses the applicant's risk pricing: `(loan_amount / 12) * 10 <= monthly_income`.
- The total loan formula is deliberately isolated in `src/utils/pricing.js` because the final formula is still pending.

