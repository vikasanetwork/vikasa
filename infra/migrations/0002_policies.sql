-- 0002: RLS policies and additional config seeds

-- Enable RLS on all tables that hold user data
alter table profiles enable row level security;
alter table claims enable row level security;
alter table earnings_extra enable row level security;
alter table referrals enable row level security;
alter table withdrawals enable row level security;
alter table burns enable row level security;
alter table kycs enable row level security;
alter table announcements enable row level security;
alter table audit_logs enable row level security;

-- Profiles: a user can see/update only their own profile
create policy profiles_select_self on profiles
  for select using (id = auth.uid());
create policy profiles_update_self on profiles
  for update using (id = auth.uid()) with check (id = auth.uid());
create policy profiles_insert_self on profiles
  for insert with check (id = auth.uid());

-- Claims: users can read only their own; inserts blocked to clients (server inserts only)
create policy claims_select_self on claims
  for select using (user_id = auth.uid());
create policy claims_block_client_inserts on claims
  for insert with check (false);
create policy claims_block_client_updates on claims
  for update using (false);

-- Earnings extra: users can read their own; inserts by server only
create policy earnings_extra_select_self on earnings_extra
  for select using (user_id = auth.uid());
create policy earnings_extra_block_client_inserts on earnings_extra
  for insert with check (false);
create policy earnings_extra_block_client_updates on earnings_extra
  for update using (false);

-- Referrals: either party can read; insert by server only
create policy referrals_select_parties on referrals
  for select using (referrer_id = auth.uid() or referred_id = auth.uid());
create policy referrals_block_client_inserts on referrals
  for insert with check (false);
create policy referrals_block_client_updates on referrals
  for update using (false);

-- Withdrawals: user can read/insert own requests; updates only by server
create policy withdrawals_select_self on withdrawals
  for select using (user_id = auth.uid());
create policy withdrawals_insert_self on withdrawals
  for insert with check (user_id = auth.uid());
create policy withdrawals_block_client_updates on withdrawals
  for update using (false);

-- Burns: read allowed to all (public transparency); insert only by server
create policy burns_select_public on burns
  for select using (true);
create policy burns_block_client_inserts on burns
  for insert with check (false);
create policy burns_block_client_updates on burns
  for update using (false);

-- KYC: user can read own only; insert/update by server only
create policy kycs_select_self on kycs
  for select using (user_id = auth.uid());
create policy kycs_block_client_inserts on kycs
  for insert with check (false);
create policy kycs_block_client_updates on kycs
  for update using (false);

-- Announcements: readable by all; write by server only
create policy announcements_select_public on announcements
  for select using (true);
create policy announcements_block_client_inserts on announcements
  for insert with check (false);
create policy announcements_block_client_updates on announcements
  for update using (false);

-- Audit logs: not user-readable; server only
create policy audit_logs_block_select on audit_logs for select using (false);
create policy audit_logs_block_write on audit_logs for all using (false) with check (false);

-- Additional config seed for reward base amount (default 0.01000000 VIK)
insert into config(key, value) values
('reward_base', '{"value":"0.01000000"}')
on conflict (key) do nothing;
