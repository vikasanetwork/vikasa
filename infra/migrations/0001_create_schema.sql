-- users: supabase auth handles auth.users; this profile table extends it.
create table profiles (
  id uuid primary key references auth.users(id),
  full_name text,
  username text unique not null,
  phone text,
  email_verified boolean default false,
  nc_wallet_email text,
  nc_wallet_email_verified boolean default false,
  referred_by uuid references profiles(id),
  referral_code text unique,
  device_fp_hash text,
  kyc_status text default 'none',
  created_at timestamptz default now()
);

create table config (
  key text primary key,
  value jsonb not null
);

create table claims (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id),
  amount numeric(38,18) not null,
  claimed_at timestamptz not null default now(),
  unlock_at timestamptz not null,
  ad_receipt_id text,
  status text default 'locked'  -- locked | unlocked | revoked
);

create table earnings_extra (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id),
  type text,  -- social|blog|ads
  amount numeric(38,18) not null,
  locked_until timestamptz,
  unique_key text, -- avoid duplicates (social post id, tx id)
  completed_at timestamptz
);

create table referrals (
  id uuid primary key default gen_random_uuid(),
  referrer_id uuid references profiles(id),
  referred_id uuid references profiles(id),
  bonus_amount numeric(38,18),
  device_fp_hash text,
  kyc_verified boolean default false,
  status text default 'pending',
  created_at timestamptz default now()
);

create table withdrawals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id),
  gross_amount numeric(38,18),
  burn_amount numeric(38,18),
  net_amount numeric(38,18),
  requested_at timestamptz default now(),
  processed_at timestamptz,
  status text default 'requested',
  tx_ref text,
  notes text
);

create table burns (
  id uuid primary key default gen_random_uuid(),
  withdrawal_id uuid references withdrawals(id),
  amount numeric(38,18),
  created_at timestamptz default now()
);

create table kycs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id),
  provider_status text,
  started_at timestamptz,
  verified_at timestamptz,
  cost numeric,
  promo_applied boolean default false
);

create table announcements (
  id uuid primary key default gen_random_uuid(),
  title text,
  body text,
  image_url text,
  priority boolean default false,
  created_at timestamptz default now(),
  author_id uuid references profiles(id)
);

create table audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references profiles(id),
  action text,
  target text,
  meta jsonb,
  created_at timestamptz default now()
);

-- config seeds (example)
insert into config(key, value) values
('claim_interval_hours', '{"value":3}'),
('min_withdrawal', '{"value":"5.00000000"}'),
('burn_rate', '{"value":"0.0001"}'), -- 0.01% -> 0.0001 fraction
('default_referral_code', '{"value":"VIKASA2025"}'),
('referral_thresholds', '{"value":[1000,5000,50000]}'),
('referral_rewards', '{"value":[ "1.00000000","0.50000000","0.10000000","0.01000000"]}');
