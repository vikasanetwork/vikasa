# Appsmith admin – Datasource and Pages (MVP)

Connect datasource
- Type: PostgreSQL
- Host: <your-supabase-host>.supabase.co
- Port: 5432 (use direct connection if enabled; otherwise use pooled connection string)
- Database: postgres
- Username: postgres (or service role user – recommended to use a restricted admin role)
- Password: Use a secure secret (do not embed in pages)
- SSL: Required

Security note
- Prefer a dedicated DB user with read access on all tables and write on admin-controlled ones (withdrawals status, config, announcements). Alternatively use Supabase service key in a server proxy.
- Do NOT expose service role to end-users; Appsmith is admin-only.

Pages and queries
1) Dashboard
- KPIs: total users, daily claims, referrals, burned coins, total withdrawals
- SQL examples:
  - Total users: select count(*) from profiles;
  - Daily claims (past 7 days): select date_trunc('day', claimed_at) d, count(*) cnt from claims group by d order by d desc limit 7;
  - Total burned: select coalesce(sum(amount),0) from burns;

2) Users
- List: select p.*, v.available, v.total_unlocked, v.total_withdrawn_gross from v_user_balances v join profiles p on p.id=v.user_id order by p.created_at desc limit 100 offset {{Table.pageNo * Table.pageSize}};
- Search by email/username: add filters (ilike)
- Actions: view details, set kyc_status
  - update profiles set kyc_status={{SelectKyc.value}} where id={{Table.selectedRow.id}};

3) Claims
- Recent claims: select * from claims order by claimed_at desc limit 200;
- Force unlock (careful): update claims set status='unlocked' where id={{Table.selectedRow.id}};

4) Withdrawals
- Pending: select * from withdrawals where status='requested' order by requested_at asc;
- Approve (off-chain MVP): update withdrawals set status='complete', processed_at=now(), burn_amount=(gross_amount * (select (value->>'value')::numeric from config where key='burn_rate')), net_amount=(gross_amount - (gross_amount * (select (value->>'value')::numeric from config where key='burn_rate'))), tx_ref='ADMIN-'||id where id={{Table.selectedRow.id}};
- Reject: update withdrawals set status='rejected', notes={{TextAreaNotes.text}} where id={{Table.selectedRow.id}};

5) Config
- Query: select * from config order by key;
- Update JSON value: update config set value={{JSONEditor.text}}::jsonb where key={{Table.selectedRow.key}};

6) Announcements
- List: select * from announcements order by created_at desc;
- Insert: insert into announcements(title, body, image_url, priority, author_id) values ({{InputTitle.text}}, {{TextAreaBody.text}}, {{InputImage.text}}, {{SwitchPriority.isSwitched}}, {{appsmith.user.email /* resolve admin id via lookup if needed */}});

7) Burns (public ledger)
- Query: select * from v_burns_public;

8) Audit logs
- Query: select * from audit_logs order by created_at desc limit 200;
- Insert logs from admin actions in Appsmith via additional inserts.

Feature flags / notes
- Referral schedule and reward_base can be edited in config
- Saturday processing is automated by Edge Function cron; use page to monitor and, if needed, retry a specific withdrawal

Deployment
- Export the Appsmith app JSON and store under appsmith/exports/ later
- RBAC: restrict access to CEO/admin emails only
