#!/usr/bin/env node
/**
 * RLS verification harness for the Africa of Hope portal.
 *
 * Impersonates real accounts at the database level (SET LOCAL ROLE plus the
 * request.jwt.claims GUC that auth.uid() reads) so the staff/student policies
 * can be exercised without anyone's password. Every check runs inside a
 * transaction that is always rolled back: this script writes nothing.
 *
 * Usage: node scripts/verify-rls.mjs
 * Needs SUPABASE_DB_URL or SUPABASE_DB (falls back to .env).
 */
import path from "node:path";
import { Client } from "pg";

for (const file of [".env", ".env.local"]) {
  try {
    process.loadEnvFile(path.resolve(import.meta.dirname, "..", file));
  } catch {
    /* optional */
  }
}

const connectionString = process.env.SUPABASE_DB_URL || process.env.SUPABASE_DB;
if (!connectionString) {
  console.error("Missing SUPABASE_DB_URL or SUPABASE_DB.");
  process.exit(2);
}

const client = new Client({ connectionString, ssl: { rejectUnauthorized: false } });
await client.connect();

const q = async (sql, params) => (await client.query(sql, params)).rows;

const pass = (detail) => ({ ok: true, detail });
const fail = (detail) => ({ ok: false, detail });
const skip = (detail) => ({ ok: true, detail, skipped: true });

const eq = (n) => (rows, err) => {
  if (err) return fail(`error ${err.code}: ${err.message}`);
  const got = Number(rows[0]?.n);
  return got === n ? pass(`n=${got}`) : fail(`expected ${n}, got ${got}`);
};
const atLeast = (n) => (rows, err) => {
  if (err) return fail(`error ${err.code}: ${err.message}`);
  const got = Number(rows[0]?.n);
  return got >= n ? pass(`n=${got}`) : fail(`expected >=${n}, got ${got}`);
};
const allowed = (rows, err) => (err ? fail(`${err.code}: ${err.message}`) : pass("allowed"));
// Zero rows or an outright grant denial both count: either way nothing is exposed.
const nothingVisible = (rows, err) => {
  if (err) return err.code === "42501" ? pass("denied at grant level") : fail(`unexpected error ${err.code}: ${err.message}`);
  const n = Number(rows[0]?.n);
  return n === 0 ? pass("n=0") : fail(`expected 0, got ${n}`);
};
const denied = (rows, err) => {
  if (!err) return fail(`allowed (${rows?.length ?? 0} rows) — expected refusal`);
  return err.code === "42501"
    ? pass("refused with insufficient_privilege")
    : fail(`unexpected error ${err.code}: ${err.message}`);
};
const isSet = (expected) => (rows, err) => {
  if (err) return fail(`error ${err.code}: ${err.message}`);
  const got = rows.map((r) => Object.values(r)[0]).sort();
  const want = [...expected].sort();
  return JSON.stringify(got) === JSON.stringify(want)
    ? pass(got.length ? got.join(", ") : "none")
    : fail(`expected [${want.join(", ")}], got [${got.join(", ")}]`);
};

// ---------------------------------------------------------------- personas
const pick = async (role, exclude) => {
  const rows = await q(
    `select id from public.profiles where role = $1 ${exclude ? "and id <> $2" : ""} order by created_at limit 1`,
    exclude ? [role, exclude] : [role],
  );
  return rows[0]?.id ?? null;
};

const personas = {
  studentA: await pick("Student"),
  studentB: null,
  teacher: await pick("Teacher-Instructor"),
};
personas.studentB = personas.studentA ? await pick("Student", personas.studentA) : null;
const teacherB = personas.teacher ? await pick("Teacher-Instructor", personas.teacher) : null;

for (const [key, id] of Object.entries({ ...personas, teacherB })) {
  if (!id) {
    console.error(`No account available for ${key}; cannot run the matrix.`);
    await client.end();
    process.exit(2);
  }
}

// Fixture availability, so "hidden rows" checks are not vacuously green.
const fixtures = Object.fromEntries(
  (
    await q(`
      select 'certificates' as name, count(*)::int as total from public.certificates
      union all select 'finance_kv', count(*)::int from public.portal_kv where key like 'finance-%' or key like 'cohort-plan:%'
      union all select 'notifications', count(*)::int from public.notifications
    `)
  ).map((r) => [r.name, r.total]),
);

// ------------------------------------------------------------------ checks
// Announcements are permission-driven, so the teacher-to-teacher expectation
// depends on whether this teacher actually holds it.
const teacherCanAnnounce = await asRole(
  "teacher",
  "select coalesce(public.has_permission('announcements.manage'), false) as ok",
).then((rows) => rows[0]?.ok === true);

const checks = [
  // Student: reads
  { as: "studentA", name: "reads own profile", sql: "select count(*)::int as n from public.profiles where id = auth.uid()", verdict: eq(1) },
  { as: "studentA", name: "cannot see other students' certificates", sql: "select count(*)::int as n from public.certificates where student_id <> auth.uid()", verdict: eq(0), needs: "certificates" },
  { as: "studentA", name: "cannot read finance/plan portal_kv", sql: "select count(*)::int as n from public.portal_kv where key like 'finance-%' or key like 'cohort-plan:%'", verdict: eq(0), needs: "finance_kv" },
  { as: "studentA", name: "cannot read other users' notifications", sql: "select count(*)::int as n from public.notifications where recipient_id <> auth.uid()", verdict: eq(0), needs: "notifications" },

  // Student: writes
  { as: "studentA", name: "cannot notify another user", sql: "insert into public.notifications (recipient_id, kind, title, body) values ($1, 'rls_verify', 'rls verify', '') returning 1 as ok", params: () => [personas.studentB], verdict: denied },
  { as: "studentA", name: "cannot insert system_settings", sql: "insert into public.system_settings (academy_name) values ('rls verify') returning 1 as ok", verdict: denied },
  { as: "studentA", name: "cannot insert certificates", sql: "insert into public.certificates (student_id, serial) values (auth.uid(), 'RLS-VERIFY') returning 1 as ok", verdict: denied },

  // Profile writes stay scoped to self or a managed student
  { as: "studentA", name: "can update own profile", sql: "with u as (update public.profiles set status = status where id = auth.uid() returning 1) select count(*)::int as n from u", verdict: eq(1) },
  { as: "studentA", name: "cannot update another student's profile", sql: "with u as (update public.profiles set status = status where id = $1 returning 1) select count(*)::int as n from u", params: () => [personas.studentB], verdict: eq(0) },
  { as: "teacher", name: "cannot update another teacher's profile", sql: "with u as (update public.profiles set status = status where id = $1 returning 1) select count(*)::int as n from u", params: () => [teacherB], verdict: eq(0) },

  // Teacher
  { as: "teacher", name: "can read student profiles", sql: "select count(*)::int as n from public.profiles where role = 'Student'", verdict: atLeast(1) },
  { as: "teacher", name: "can notify a student", sql: "insert into public.notifications (recipient_id, kind, title, body) values ($1, 'rls_verify', 'rls verify', '') returning 1 as ok", params: () => [personas.studentB], verdict: allowed },
  {
    as: "teacher",
    name: teacherCanAnnounce
      ? "can notify another teacher (holds announcements.manage)"
      : "cannot notify another teacher (no announcements.manage)",
    sql: "insert into public.notifications (recipient_id, kind, title, body) values ($1, 'rls_verify', 'rls verify', '') returning 1 as ok",
    params: () => [teacherB],
    verdict: teacherCanAnnounce ? allowed : denied,
  },
  { as: "teacher", name: "cannot insert system_settings", sql: "insert into public.system_settings (academy_name) values ('rls verify') returning 1 as ok", verdict: denied },

  // Anonymous visitor
  { as: "anon", name: "cannot read profiles", sql: "select count(*)::int as n from public.profiles", verdict: nothingVisible },
  { as: "anon", name: "cannot read certificates", sql: "select count(*)::int as n from public.certificates", verdict: nothingVisible },
  { as: "anon", name: "can submit a website enquiry", sql: "insert into public.website_enquiries (name, contact, message) values ('RLS verify', 'rls@verify.test', 'rollback only') returning 1 as ok", verdict: allowed },
  { as: "anon", name: "can submit a support pledge", sql: "insert into public.support_pledges (id, kind, name, email, phone) values (gen_random_uuid()::text, 'donation', 'RLS verify', 'rls@verify.test', '000') returning 1 as ok", verdict: allowed },
  { as: "anon", name: "cannot insert notifications", sql: "insert into public.notifications (recipient_id, kind, title, body) values ($1, 'rls_verify', 'rls verify', '') returning 1 as ok", params: () => [personas.teacher], verdict: denied },
  { as: "anon", name: "cannot insert system_settings", sql: "insert into public.system_settings (academy_name) values ('rls verify') returning 1 as ok", verdict: denied },

  // Catalogue invariants (run as the owner, no impersonation)
  {
    as: null,
    name: "portal_kv read policy still guards finance/plan keys",
    sql: "select count(*)::int as n from pg_policies where schemaname = 'public' and tablename = 'portal_kv' and cmd = 'SELECT' and qual like '%finance-%' and qual like '%cohort-plan:%'",
    verdict: atLeast(1),
  },
  { as: null, name: "RLS enabled on every public table", sql: "select count(*)::int as n from pg_class c join pg_namespace ns on ns.oid = c.relnamespace where ns.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity", verdict: eq(0) },
  {
    as: null,
    name: "anon can INSERT only the public intake tables",
    sql: "select c.relname from pg_class c join pg_namespace ns on ns.oid = c.relnamespace where ns.nspname = 'public' and c.relkind = 'r' and has_table_privilege('anon', c.oid, 'INSERT') order by 1",
    verdict: isSet(["study_plans", "support_pledges", "website_enquiries"]),
  },
  {
    as: null,
    name: "anon cannot EXECUTE the revoked RPCs",
    sql: "select p.proname from pg_proc p join pg_namespace ns on ns.oid = p.pronamespace where ns.nspname = 'public' and p.proname in ('lookup_certificate', 'next_admission_no', 'receive_enquiry', 'receive_pledge', 'receive_study_plan', 'record_support_intent') and has_function_privilege('anon', p.oid, 'EXECUTE') order by 1",
    verdict: isSet([]),
  },
];

// Run one statement as a persona inside a transaction that is always rolled back.
async function asRole(persona, sql, params = []) {
  await client.query("begin");
  try {
    if (persona) {
      await client.query(`set local role ${persona === "anon" ? "anon" : "authenticated"}`);
      const claims = persona === "anon" ? { role: "anon" } : { sub: personas[persona], role: "authenticated" };
      await client.query("select set_config('request.jwt.claims', $1, true)", [JSON.stringify(claims)]);
    }
    return (await client.query(sql, params)).rows;
  } finally {
    await client.query("rollback").catch(() => {});
  }
}

// ------------------------------------------------------------------- runner
async function run(check) {
  const role = check.as === "anon" ? "anon" : "authenticated";
  const claims = check.as === "anon" ? { role: "anon" } : { sub: personas[check.as], role: "authenticated" };
  await client.query("begin");
  try {
    await client.query(`set local role ${role}`);
    await client.query("select set_config('request.jwt.claims', $1, true)", [JSON.stringify(claims)]);
    try {
      const rows = (await client.query(check.sql, check.params ? check.params() : [])).rows;
      return check.verdict(rows, null);
    } catch (err) {
      return check.verdict(null, err);
    }
  } finally {
    await client.query("rollback").catch(() => {});
  }
}

let failures = 0;
let skipped = 0;
console.log(`personas: student ${personas.studentA} / ${personas.studentB}, teacher ${personas.teacher} / ${teacherB}`);
console.log(`fixtures: ${Object.entries(fixtures).map(([k, v]) => `${k}=${v}`).join(", ")}\n`);

for (const check of checks) {
  let result;
  try {
    // Impersonation needs role membership; fail loudly rather than silently pass.
    if (check.as) {
      await client.query("begin");
      try {
        await client.query(`set local role ${check.as === "anon" ? "anon" : "authenticated"}`);
      } finally {
        await client.query("rollback").catch(() => {});
      }
    }
    result = check.needs && fixtures[check.needs] === 0 ? skip(`no ${check.needs} rows to test against`) : await run(check);
  } catch (err) {
    result = fail(`${err.code ?? ""} ${err.message}`.trim());
  }
  if (result.skipped) skipped++;
  if (!result.ok) failures++;
  const label = `${(check.as ?? "catalog").padEnd(9)} ${check.name}`;
  console.log(`${result.ok ? (result.skipped ? "SKIP" : "PASS") : "FAIL"}  ${label.padEnd(58)} ${result.detail}`);
}

await client.end();
console.log(`\n${checks.length - failures - skipped} passed, ${failures} failed, ${skipped} skipped`);
process.exit(failures ? 1 : 0);
