-- 0003: push_tokens table and policies

create table push_tokens (
  id bigserial primary key,
  user_id uuid references auth.users(id) on delete cascade,
  token text not null,
  platform text,
  updated_at timestamptz default now(),
  unique (user_id, token, platform)
);

alter table push_tokens enable row level security;

create policy push_tokens_select_self on push_tokens
  for select using (user_id = auth.uid());

create policy push_tokens_insert_self on push_tokens
  for insert with check (user_id = auth.uid());

create policy push_tokens_update_self on push_tokens
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());
