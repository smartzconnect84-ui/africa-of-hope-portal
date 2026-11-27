-- AFRICA OF HOPE — VAPID live push (web) on top of the existing outbox.
--
-- Knock stays the in-app feed; this migration adds the device delivery path that
-- `push-send` uses: one row per browser push subscription, a SECURITY DEFINER
-- claim RPC (an endpoint belongs to a device, so a second member signing in on a
-- shared device must be able to reassign it — plain RLS cannot), the outbox
-- claim function, and the every-minute cron that drains the outbox.
--
-- Deploying the function itself needs the three secrets listed in
-- backend/functions/push-send/index.ts. They are never stored in the database.

create extension if not exists pg_cron;
create extension if not exists pg_net;

-- ---------------------------------------------------------------------------
-- Subscriptions: one row per browser/device endpoint.
-- ---------------------------------------------------------------------------
create table if not exists public.push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  endpoint text not null unique,
  p256dh text not null,
  auth text not null,
  user_agent text,
  enabled boolean not null default true,
  preferences jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists push_subscriptions_user_idx
  on public.push_subscriptions (user_id) where enabled;

alter table public.push_subscriptions enable row level security;

drop policy if exists push_subscriptions_own on public.push_subscriptions;
create policy push_subscriptions_own on public.push_subscriptions
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Dispatch token: shared secret between pg_cron / the insert trigger and the
-- Edge Function. No policies — only the service role and SECURITY DEFINER
-- functions read it.
-- ---------------------------------------------------------------------------
create table if not exists public.push_dispatch_token (
  id boolean primary key default true,
  token text not null default encode(extensions.gen_random_bytes(32), 'hex'),
  created_at timestamptz not null default now(),
  constraint push_dispatch_token_single_row check (id)
);

alter table public.push_dispatch_token enable row level security;
revoke all on public.push_dispatch_token from anon, authenticated;

insert into public.push_dispatch_token (id) values (true) on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- Claim a device for the signed-in member (client calls this after
-- pushManager.subscribe()).
-- ---------------------------------------------------------------------------
create or replace function public.register_push_subscription(
  p_endpoint text,
  p_p256dh text,
  p_auth text,
  p_user_agent text default null
) returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'Sign in to enable notifications' using errcode = '42501';
  end if;
  if coalesce(btrim(p_endpoint), '') = '' or coalesce(btrim(p_p256dh), '') = '' or coalesce(btrim(p_auth), '') = '' then
    raise exception 'Incomplete push subscription' using errcode = '22023';
  end if;

  insert into public.push_subscriptions (user_id, endpoint, p256dh, auth, user_agent, enabled, updated_at)
  values (v_user, p_endpoint, p_p256dh, p_auth, left(coalesce(p_user_agent, ''), 500), true, now())
  on conflict (endpoint) do update
    set user_id = v_user,
        p256dh = excluded.p256dh,
        auth = excluded.auth,
        user_agent = excluded.user_agent,
        enabled = true,
        updated_at = now();
end;
$function$;

revoke all on function public.register_push_subscription(text, text, text, text) from public, anon;
grant execute on function public.register_push_subscription(text, text, text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Outbox claim: hand the sender a batch and mark it `sending` so a second
-- worker (cron + instant trigger) cannot deliver the same row twice.
-- ---------------------------------------------------------------------------
create or replace function public._claim_push_rows(p_limit integer default 25)
returns table(id uuid, title text, body text, url text, recipient_id uuid, attempts integer)
language sql
security definer
set search_path to 'public'
as $function$
  with candidate as (
    select o.id
    from public.notification_outbox o
    where o.recipient_id is not null
      and (
        o.status = 'queued'
        or (o.status = 'failed' and o.attempts < 5
            and coalesce(o.next_attempt_at, o.created_at) <= now())
        or (o.status = 'sending'
            and coalesce(o.last_attempt_at, o.created_at) < now() - interval '10 minutes')
      )
    order by o.created_at
    limit greatest(1, least(coalesce(p_limit, 25), 50))
    for update skip locked
  )
  update public.notification_outbox o
     set status = 'sending',
         attempts = o.attempts + 1,
         last_attempt_at = now(),
         next_attempt_at = null
    from candidate c
   where o.id = c.id
  returning o.id, o.title, o.body, o.url, o.recipient_id, o.attempts;
$function$;

revoke all on function public._claim_push_rows(integer) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Cron drain: cheap no-op when nothing is queued, otherwise one HTTP call to
-- `push-send` with the dispatch token.
-- ---------------------------------------------------------------------------
create or replace function public._cron_dispatch_push()
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_url text := 'https://gatnzfjpuokopqyksqoy.supabase.co/functions/v1/push-send';
  v_token text;
begin
  if not exists (
    select 1 from public.notification_outbox o
    where o.recipient_id is not null
      and (
        o.status = 'queued'
        or (o.status = 'failed' and o.attempts < 5
            and coalesce(o.next_attempt_at, o.created_at) <= now())
        or (o.status = 'sending'
            and coalesce(o.last_attempt_at, o.created_at) < now() - interval '10 minutes')
      )
  ) then
    return;
  end if;

  select token into v_token from public.push_dispatch_token limit 1;
  if v_token is null then
    return;
  end if;

  perform net.http_post(
    url := v_url,
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-push-dispatch', v_token),
    body := jsonb_build_object('action', 'dispatch', 'limit', 25)
  );
end;
$function$;

revoke all on function public._cron_dispatch_push() from public, anon, authenticated;

-- Replace any earlier schedule that pointed at the OneSignal sender.
do $$
declare j record;
begin
  for j in select jobid from cron.job where command ilike '%_cron_dispatch_push%' loop
    perform cron.unschedule(j.jobid);
  end loop;
  perform cron.schedule('vapid-push-dispatch', '* * * * *', 'select public._cron_dispatch_push();');
end $$;
