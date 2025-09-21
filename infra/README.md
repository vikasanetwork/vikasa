# Infra

- migrations/: Supabase SQL migrations
- edge_functions/: Supabase Edge Functions (Deno) – add functions here and a deploy script

Apply migrations:
1) Create a Supabase project
2) Use Supabase SQL editor or CLI to apply migrations in order

Edge Functions:
- Keep one folder per function; include README for inputs/outputs
- Cron jobs (notify_claim_ready, release_locks, process_weekly_withdrawals) to be added later
