-- 0004: RPCs and views for admin/edge functions

-- Eligible claim users: those who never claimed, or whose last claim is older than p_hours
-- NOTE: Intended to be called from an Edge Function using the service role.
create or replace function public.eligible_claim_users(p_hours integer)
returns table(user_id uuid)
language sql
security definer
set search_path = public
as $$
  select p.id as user_id
  from profiles p
  left join lateral (
    select c.claimed_at
    from claims c
    where c.user_id = p.id
    order by c.claimed_at desc
    limit 1
  ) lc on true
  where lc.claimed_at is null
     or lc.claimed_at <= (now() - make_interval(hours => p_hours));
$$;

comment on function public.eligible_claim_users is 'Returns users eligible to claim again based on interval hours. Call with service-role.';

-- User balances view (uses unlocked claims and requested/complete withdrawals)
create or replace view public.v_user_balances as
select
  p.id as user_id,
  coalesce((select sum(amount) from claims c where c.user_id = p.id and c.status in ('locked','unlocked')), 0::numeric(38,18)) as total_claimed,
  coalesce((select sum(amount) from claims c where c.user_id = p.id and c.status = 'unlocked'), 0::numeric(38,18)) as total_unlocked,
  coalesce((select sum(gross_amount) from withdrawals w where w.user_id = p.id and w.status in ('requested','complete')), 0::numeric(38,18)) as total_withdrawn_gross,
  coalesce((select sum(burn_amount) from withdrawals w where w.user_id = p.id and w.status = 'complete'), 0::numeric(38,18)) as total_burned,
  coalesce((select sum(net_amount) from withdrawals w where w.user_id = p.id and w.status = 'complete'), 0::numeric(38,18)) as total_withdrawn_net,
  (coalesce((select sum(amount) from claims c where c.user_id = p.id and c.status = 'unlocked'), 0::numeric(38,18))
   - coalesce((select sum(gross_amount) from withdrawals w where w.user_id = p.id and w.status in ('requested','complete')), 0::numeric(38,18))) as available
from profiles p;

-- Public burn ledger view
create or replace view public.v_burns_public as
select
  b.id,
  b.amount,
  b.created_at,
  w.user_id,
  w.tx_ref
from burns b
left join withdrawals w on w.id = b.withdrawal_id
order by b.created_at desc;
