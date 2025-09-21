# Edge Functions

This folder contains Deno TypeScript Edge Functions intended for Supabase Edge runtime.

Available functions (placeholders):
- claim_ad_validate_and_credit: Validate rewarded ad receipt (MVP: accept), ensure eligibility window, insert a claim with 90-day lock.
- notify_claim_ready: Cron-triggered to notify users when claim is ready (placeholder RPC and sending).
- release_locks: Cron-triggered to switch locked claims to unlocked when unlock_at <= now().
- process_weekly_withdrawals: Cron-triggered each Saturday UTC to process withdrawals, compute burn, mark complete (MVP: off-chain).

Shared:
- _shared/supabase_client.ts: creates a Supabase service client from env.

Environment variables required at runtime (set in project or function env):
- SUPABASE_URL
- SUPABASE_SERVICE_ROLE_KEY
- (Later) FIREBASE_SERVER_KEY for FCM sending

Deployment (manual via Supabase CLI):
- supabase functions deploy claim_ad_validate_and_credit
- supabase functions deploy notify_claim_ready
- supabase functions deploy release_locks
- supabase functions deploy process_weekly_withdrawals

Scheduling (example):
- Claim-ready notifications: every 15 minutes
- Release locks: hourly
- Weekly withdrawals: Saturday 00:05 UTC

IMPORTANT
- All monetary values must use fixed precision (strings or smallest units) and avoid floating point. Current placeholders use toFixed(8) for display; production must switch to integer smallest-units logic end-to-end.
- Never expose service role keys in client app.
