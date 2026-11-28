/**
 * AFRICA OF HOPE — `push-send` Edge Function (VAPID / RFC 8291 web push).
 *
 * Replaces the OneSignal web sender as the live-push delivery path. Knock stays
 * the in-app feed (`knock-dispatch`); this function is what draws the lock-screen
 * notification.
 *
 * Two entry points, both POST:
 *  - Internal dispatch (pg_cron `_cron_dispatch_push()` and the outbox insert
 *    trigger): header `x-push-dispatch` must equal `push_dispatch_token.token`.
 *    `{action:"dispatch"}` claims queued outbox rows and encrypts a push per
 *    device; `{action:"health"}` reports key/device state without sending.
 *  - Staff broadcast: a member session JWT, checked against `profiles.role`,
 *    inserts `notifications` rows so the normal fan-out does the delivery.
 *
 * Secrets (Supabase dashboard → Edge Functions → Secrets), never in git:
 *  - VAPID_PUBLIC_KEY  — base64url, uncompressed P-256 point (65 bytes)
 *  - VAPID_PRIVATE_KEY — base64url, 32-byte P-256 scalar
 *  - VAPID_SUBJECT     — `mailto:` contact for the JWT `sub` claim
 *
 * Deploy: `supabase functions deploy push-send`
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import * as webpush from 'jsr:@negrel/webpush@0.5.0';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type, x-push-dispatch',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  });

function b64uToBytes(input: string): Uint8Array {
  const s = input.replace(/-/g, '+').replace(/_/g, '/');
  const padded = s + '='.repeat((4 - (s.length % 4)) % 4);
  const bin = atob(padded);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

function bytesToB64u(bytes: Uint8Array): string {
  let bin = '';
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

/** Accept `mailto:box@x`, `box@x` or `https://…`; reject anything else. */
function normalizeSubject(raw: string | undefined): string {
  const v = (raw ?? '').trim();
  const angle = v.match(/^mailto:\s*<([^>]+)>$/i) || v.match(/^<([^>]+)>$/);
  if (angle) return 'mailto:' + angle[1].trim();
  if (/^mailto:/i.test(v) || /^https?:\/\//i.test(v)) return v;
  return v.includes('@') ? 'mailto:' + v : '';
}

let cached: Promise<webpush.ApplicationServer> | null = null;

// VAPID application server, built once per isolate from the project secrets.
function appServer(): Promise<webpush.ApplicationServer> {
  if (!cached) {
    cached = (async () => {
      const pubRaw = (Deno.env.get('VAPID_PUBLIC_KEY') ?? '').trim();
      const privRaw = (Deno.env.get('VAPID_PRIVATE_KEY') ?? '').trim();
      const subject = normalizeSubject(Deno.env.get('VAPID_SUBJECT') ?? '');
      if (!pubRaw || !privRaw) throw new Error('VAPID_PRIVATE_KEY and VAPID_PUBLIC_KEY are not configured');

      const pub = b64uToBytes(pubRaw);
      const priv = b64uToBytes(privRaw);
      if (priv.length !== 32) throw new Error('VAPID_PRIVATE_KEY must be a 32-byte base64url key');

      // Uncompressed point (0x04 || X || Y) or bare X||Y.
      const x = pub.length === 65 ? pub.slice(1, 33) : pub.slice(0, 32);
      const y = pub.length === 65 ? pub.slice(33, 65) : pub.slice(32, 64);

      const publicKey = { kty: 'EC', crv: 'P-256', x: bytesToB64u(x), y: bytesToB64u(y), ext: true, key_ops: ['verify'] };
      const privateKey = { kty: 'EC', crv: 'P-256', x: bytesToB64u(x), y: bytesToB64u(y), d: bytesToB64u(priv), ext: true, key_ops: ['sign'] };

      const vapidKeys = await webpush.importVapidKeys({ publicKey, privateKey }, { extractable: false });
      return await webpush.ApplicationServer.new({
        contactInformation: subject || 'mailto:notifications@africaofhope.org',
        vapidKeys,
      });
    })();
  }
  return cached;
}

function statusOf(err: any): number {
  const raw = err?.statusCode ?? err?.status ?? err?.response?.status ?? err?.code;
  const n = Number(raw);
  return Number.isFinite(n) ? n : 0;
}

/** Encrypt and deliver one outbox row to every enabled device of its member. */
async function deliver(server: webpush.ApplicationServer, row: any) {
  const dead: string[] = [];
  const errors: string[] = [];
  let ok = 0;

  const payload = JSON.stringify({
    title: row.title,
    body: row.body,
    url: row.url || '/',
    tag: row.notification_id || row.id,
    notificationId: row.notification_id ?? null,
  });

  const subs: any[] = row.subscriptions;
  for (const s of subs) {
    try {
      const subscriber = server.subscribe({
        endpoint: s.endpoint,
        keys: { p256dh: s.p256dh, auth: s.auth },
      });
      await subscriber.pushTextMessage(payload, { ttl: 86400 });
      ok++;
    } catch (e: any) {
      const code = statusOf(e);
      // 404/410: the browser dropped the subscription — prune it.
      if (code === 404 || code === 410) dead.push(s.id);
      errors.push((code ? code + ' ' : '') + String(e?.message ?? e).slice(0, 200));
    }
  }

  return { ok, dead, errors };
}

async function dispatch(admin: any, limit: unknown) {
  const server = await appServer();
  const take = Math.min(Math.max(Number(limit) || 25, 1), 50);
  const { data: rows, error } = await admin.rpc('_claim_push_rows', { p_limit: take });
  if (error) throw new Error('claim failed: ' + error.message);

  let sent = 0, skipped = 0, failed = 0;

  for (const row of rows ?? []) {
    const { data: subs } = await admin
      .from('push_subscriptions')
      .select('id, endpoint, p256dh, auth')
      .eq('user_id', row.recipient_id)
      .eq('enabled', true);

    if (!subs || subs.length === 0) {
      await admin.from('notification_outbox').update({
        status: 'skipped',
        sent_at: new Date().toISOString(),
        last_error: 'No subscribed device for this member',
        provider_response: { channel: 'vapid', delivered: 0 },
      }).eq('id', row.id);
      skipped++;
      continue;
    }

    const result = await deliver(server, { ...row, subscriptions: subs });
    if (result.dead.length) {
      await admin.from('push_subscriptions').delete().in('id', result.dead);
    }

    if (result.ok > 0) {
      sent++;
      await admin.from('notification_outbox').update({
        status: 'sent',
        sent_at: new Date().toISOString(),
        last_error: result.errors[0] ?? null,
        provider_response: { channel: 'vapid', delivered: result.ok, devices: subs.length },
      }).eq('id', row.id);
    } else {
      failed++;
      const attempts = Number(row.attempts ?? 1);
      const retryInMinutes = Math.min(60, Math.pow(2, attempts));
      await admin.from('notification_outbox').update({
        status: 'failed',
        last_error: (result.errors[0] ?? 'Web push failed').slice(0, 500),
        next_attempt_at: attempts < 5 ? new Date(Date.now() + retryInMinutes * 60000).toISOString() : null,
        provider_response: { channel: 'vapid', delivered: 0, attempts },
      }).eq('id', row.id);
    }
  }

  return { claimed: (rows ?? []).length, sent, skipped, failed };
}

function isStaff(role: string) {
  return /admin|registrar|director|teacher|instructor|admission|support/i.test(role);
}

/** Only these roles may notify the whole institution. */
function canBroadcast(role: string) {
  return /^(super admin|school admin|registrar|director of education)$/i.test(role.trim());
}

/** Same-origin destination only; anything else becomes the notifications tab. */
function validUrl(value: unknown) {
  const raw = String(value ?? "#notifications").trim();
  if (!raw.startsWith("/") && !raw.startsWith("#")) return "#notifications";
  return raw.slice(0, 300);
}

/** Constant-time comparison for the shared dispatch token. */
function sameToken(a: string, b: string) {
  const left = new TextEncoder().encode(a);
  const right = new TextEncoder().encode(b);
  let diff = left.length ^ right.length;
  const len = Math.max(left.length, right.length);
  for (let i = 0; i < len; i++) diff |= (left[i] ?? 0) ^ (right[i] ?? 0);
  return diff === 0;
}

function audienceMatch(audience: string, role: string) {
  const r = role.toLowerCase();
  if (audience === 'students') return r.includes('student');
  if (audience === 'teachers') return /teacher|instructor|lecturer/.test(r);
  if (audience === 'admins') return /admin|registrar|director/.test(r);
  if (audience === 'staff') return !/student|teacher|instructor|lecturer|admin|registrar|director/.test(r);
  return true;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
  if (!supabaseUrl || !serviceKey) return json({ error: 'Server misconfigured' }, 500);

  const admin = createClient(supabaseUrl, serviceKey, { auth: { persistSession: false } });
  const body: any = req.method === 'POST' ? await req.json().catch(() => ({})) : {};

  // ---- Internal dispatch (cron / notification trigger) ----
  const dispatchToken = req.headers.get('x-push-dispatch') ?? '';
  if (dispatchToken) {
    const { data } = await admin.from('push_dispatch_token').select('token').limit(1).maybeSingle();
    if (!data || !sameToken(String(data.token), dispatchToken)) return json({ error: 'Unauthorized' }, 401);

    try {
      if (body.action === 'health') {
        const server = await appServer();
        const { count } = await admin
          .from('push_subscriptions')
          .select('id', { count: 'exact', head: true })
          .eq('enabled', true);
        return json({ ok: true, channel: 'vapid', keysLoaded: !!server, devices: count ?? 0 });
      }
      return json({ ok: true, channel: 'vapid', ...(await dispatch(admin, body.limit)) });
    } catch (e: any) {
      return json({ ok: false, error: String(e?.message ?? e) }, 500);
    }
  }

  // ---- Staff broadcast (member session required) ----
  const bearer = (req.headers.get('Authorization') ?? '').replace(/^Bearer\s+/i, '');
  if (!bearer) return json({ error: 'Missing session' }, 401);

  const { data: userData } = await admin.auth.getUser(bearer);
  const caller = userData?.user;
  if (!caller) return json({ error: 'Invalid session' }, 401);

  const { data: profile } = await admin.from('profiles').select('id, role').eq('id', caller.id).maybeSingle();
  if (!isStaff(String(profile?.role ?? ''))) return json({ error: 'Not allowed' }, 403);

  const title = String(body.title ?? '').trim().slice(0, 120);
  const message = String(body.body ?? body.message ?? '').trim().slice(0, 500);
  if (!title || !message) return json({ error: 'A title and message are required' }, 400);

  const audience = String(body.audience ?? 'all').toLowerCase().slice(0, 40);
  const direct = String(body.user_id ?? (audience.startsWith('user:') ? audience.slice(5) : '')).trim();

  // Teachers and other staff may target classes, but an institution-wide send is
  // an administrator decision — the same rule the older sender enforced.
  if ((audience === 'all' || audience === 'all_users') && !canBroadcast(String(profile?.role ?? ''))) {
    return json({ error: 'Institution-wide sends require an administrator or registrar.' }, 403);
  }

  const { data: people } = await admin.from('profiles').select('id, role').limit(2000);
  const recipients = direct
    ? [direct]
    : (people ?? []).filter((p: any) => audienceMatch(audience, String(p.role ?? ''))).map((p: any) => p.id).slice(0, 500);

  if (!recipients.length) {
    return json({ ok: true, queued: 0, channel: 'vapid', message: 'No recipients matched' });
  }

  const rows = recipients.map((id: string) => ({
    recipient_id: id,
    user_id: id,
    kind: 'announcement',
    title,
    body: message,
    url: validUrl(body.url),
  }));

  // Inserting into `notifications` is what fans out to the outbox and Knock,
  // so in-app and live push stay in lockstep for every recipient.
  let queued = 0;
  for (let i = 0; i < rows.length; i += 100) {
    const chunk = rows.slice(i, i + 100);
    const { error } = await admin.from('notifications').insert(chunk);
    if (error) return json({ ok: false, error: error.message, queued }, 500);
    queued += chunk.length;
  }

  return json({ ok: true, queued, channel: 'vapid' });
});
