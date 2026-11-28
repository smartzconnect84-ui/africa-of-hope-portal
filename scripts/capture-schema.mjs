#!/usr/bin/env node
// Full schema capture for the Africa of Hope portal database.
//
// There is no pg_dump in the build image, so this script introspects
// pg_catalog with a handful of queries and emits the same information as a
// baseline DDL file: schemas, enums/domains, sequences, tables, columns,
// constraints, indexes, RLS flags, policies, functions, triggers, views,
// comments, grants, storage bucket configuration and the realtime publication.
//
// Usage (connection string is read from the environment, never from argv):
//   SUPABASE_DB_URL=postgresql://... node scripts/capture-schema.mjs
// or, with just the database password:
//   SUPABASE_DB_PASSWORD=... node scripts/capture-schema.mjs
//
// The output is a reference snapshot of production, not an incremental
// migration: see the header it writes for why it must not be replayed on a
// database that already has these objects.

import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { Client } from "pg";

// `.env` is gitignored, so the connection string can live in the workspace
// instead of a dashboard. Shell/dashboard values still win; this is only a
// fallback for credentials the deploy environment does not provide.
function hasDatabaseEnv() {
  return Boolean(
    process.env.SUPABASE_DB_URL ||
      process.env.SUPABASE_DB ||
      process.env.DATABASE_URL ||
      process.env.SUPABASE_DB_PASSWORD,
  );
}

if (!hasDatabaseEnv()) {
  try {
    process.loadEnvFile(path.resolve(import.meta.dirname, "..", ".env"));
  } catch {
    // no .env, or an unparsable one — the explicit error below covers it
  }
}

const PROJECT_REF = "gatnzfjpuokopqyksqoy";
const POOLER_HOST = "aws-0-us-east-1.pooler.supabase.com";
const OUT_FILE = path.resolve("backend/sql/20261128_schema_baseline.sql");

// Platform-managed schemas: captured only as a note, never recreated here.
const MANAGED_SCHEMAS = [
  "auth",
  "storage",
  "realtime",
  "_realtime",
  "_analytics",
  "_supavisor",
  "vault",
  "extensions",
  "graphql",
  "graphql_public",
  "pgbouncer",
  "supabase_migrations",
  "supabase_functions",
  "net",
  "cron",
  "pgsodium",
  "pgsodium_masks",
  "pg_catalog",
  "information_schema",
];

const GRANT_ROLES = new Set(["anon", "authenticated", "service_role", "public"]);

function connectionString() {
  // SUPABASE_DB_URL is canonical; the others are the names people actually use.
  const url = (
    process.env.SUPABASE_DB_URL ??
    process.env.SUPABASE_DB ??
    process.env.DATABASE_URL ??
    ""
  ).trim();
  if (url) return url;
  const password = (process.env.SUPABASE_DB_PASSWORD ?? "").trim();
  if (!password) {
    console.error(
      "Missing connection details: set SUPABASE_DB_URL (full postgres URI; " +
        "SUPABASE_DB and DATABASE_URL are accepted too) or SUPABASE_DB_PASSWORD.",
    );
    process.exit(2);
  }
  return `postgresql://postgres.${PROJECT_REF}:${encodeURIComponent(password)}@${POOLER_HOST}:5432/postgres`;
}

const qi = (name) => `"${String(name).replace(/"/g, '""')}"`;
const qn = (schema, name) => `${qi(schema)}.${qi(name)}`;
const ql = (value) => `'${String(value).replace(/'/g, "''")}'`;
const joinNames = (schema, name) => qn(schema, name);

// pg returns name[] as a JS array, but some clients hand back the literal
// `{anon,authenticated}` text; accept both.
function roleList(roles) {
  if (Array.isArray(roles)) return roles;
  if (typeof roles === "string") {
    return roles
      .replace(/^\{|\}$/g, "")
      .split(",")
      .map((r) => r.trim().replace(/^"|"$/g, ""))
      .filter(Boolean);
  }
  return [];
}

const out = [];
const stats = {};
let section = "";

function heading(title) {
  section = title;
  out.push("");
  out.push(
    "-- " +
      "-".repeat(75) +
      "\n-- " +
      title +
      "\n-- " +
      "-".repeat(75),
  );
}

function push(line = "") {
  out.push(line);
}

function count(key, n = 1) {
  stats[key] = (stats[key] ?? 0) + n;
}

async function main() {
  const client = new Client({
    connectionString: connectionString(),
    ssl: { rejectUnauthorized: false },
    application_name: "aoh-schema-capture",
    statement_timeout: 120_000,
  });
  await client.connect();
  const q = async (sql, params = []) => (await client.query(sql, params)).rows;

  try {
    const [version] = await q(
      "select version() as version, current_database() as db, current_user as usr, now() as at",
    );
    const dbVersion = String(version.version).split(" on ")[0];

    const schemaRows = await q(
      `select n.nspname as schema
         from pg_namespace n
        where n.nspname <> all($1::text[])
          and n.nspname not like 'pg\\_%'
          and not exists (
                select 1 from pg_depend d
                 where d.classid = 'pg_namespace'::regclass
                   and d.objid = n.oid
                   and d.deptype = 'e')
        order by 1`,
      [MANAGED_SCHEMAS],
    );
    const schemas = schemaRows.map((r) => r.schema);
    if (!schemas.length) throw new Error("No capturable schemas found");

    const managedPresent = await q(
      `select nspname from pg_namespace where nspname = any($1::text[]) order by 1`,
      [MANAGED_SCHEMAS],
    );

    out.push(
      `-- Africa of Hope portal — full database schema baseline`,
      `-- Captured from project ${PROJECT_REF} on ${new Date(
        version.at,
      ).toISOString()} by scripts/capture-schema.mjs`,
      `-- Server: ${dbVersion}`,
      `-- Capturable schemas: ${schemas.join(", ")}`,
      `--`,
      `-- This is a reference snapshot of production, generated from pg_catalog.`,
      `-- Do NOT replay it onto a database that already contains these objects:`,
      `-- it is a baseline to diff against, not an incremental migration.`,
      `-- Owner assignments, default privileges, extension internals and Supabase`,
      `-- platform schemas (${managedPresent.map((r) => r.nspname).join(", ")}) are out of scope.`,
      `-- Defaults or CHECK constraints that call a portal function expect that`,
      `-- function to exist already; replay such objects after the Functions section.`,
      `--`,
      `-- Regenerate with:`,
      `--   SUPABASE_DB_URL=... node scripts/capture-schema.mjs`,
    );

    heading("Schemas");
    for (const schema of schemas) {
      if (schema === "public") continue;
      push(`create schema if not exists ${qi(schema)};`);
      count("schemas");
    }
    if (schemas.length === 1) push("-- (public already exists in a Supabase database)");

    heading("Extensions");
    const extensions = await q(
      `select e.extname as name, n.nspname as schema, e.extversion as version
         from pg_extension e
         join pg_namespace n on n.oid = e.extnamespace
        order by 1`,
    );
    for (const ext of extensions) {
      if (ext.name === "plpgsql") continue;
      push(
        `create extension if not exists ${qi(ext.name)} with schema ${qi(
          ext.schema,
        )} version ${ql(ext.version)};`,
      );
      count("extensions");
    }

    heading("Enum and domain types");
    const enums = await q(
      `select n.nspname as schema, t.typname as name,
              string_agg(quote_literal(e.enumlabel), ', ' order by e.enumsortorder) as labels
         from pg_type t
         join pg_namespace n on n.oid = t.typnamespace
         join pg_enum e on e.enumtypid = t.oid
        where n.nspname = any($1::text[])
        group by 1, 2
        order by 1, 2`,
      [schemas],
    );
    for (const e of enums) {
      push(`create type ${joinNames(e.schema, e.name)} as enum (${e.labels});`);
      count("enums");
    }

    const domains = await q(
      `select n.nspname as schema, t.typname as name,
              format_type(t.typbasetype, t.typtypmod) as base_type,
              t.typnotnull as not_null,
              case when t.typdefault is null then null else t.typdefault end as default_expr
         from pg_type t
         join pg_namespace n on n.oid = t.typnamespace
        where n.nspname = any($1::text[]) and t.typtype = 'd'
        order by 1, 2`,
      [schemas],
    );
    for (const d of domains) {
      let line = `create domain ${joinNames(d.schema, d.name)} as ${d.base_type}`;
      if (d.default_expr) line += ` default ${d.default_expr}`;
      if (d.not_null) line += " not null";
      push(`${line};`);
      count("domains");
    }
    const domainChecks = await q(
      `select n.nspname as schema, t.typname as name, c.conname as constraint_name,
              pg_get_constraintdef(c.oid, true) as def
         from pg_constraint c
         join pg_type t on t.oid = c.contypid
         join pg_namespace n on n.oid = t.typnamespace
        where n.nspname = any($1::text[]) and c.contype = 'c'
        order by 1, 2, 3`,
      [schemas],
    );
    for (const c of domainChecks) {
      push(
        `alter domain ${joinNames(c.schema, c.name)} add constraint ${qi(
          c.constraint_name,
        )} ${c.def};`,
      );
      count("domain_checks");
    }

    const composites = await q(
      `select n.nspname as schema, t.typname as name,
              string_agg(
                format('%I %s', a.attname, format_type(a.atttypid, a.atttypmod)),
                ', ' order by a.attnum) as cols
         from pg_type t
         join pg_namespace n on n.oid = t.typnamespace
         join pg_class c on c.oid = t.typrelid
         join pg_attribute a on a.attrelid = c.oid and a.attnum > 0 and not a.attisdropped
        where n.nspname = any($1::text[]) and t.typtype = 'c' and c.relkind = 'c'
        group by 1, 2
        order by 1, 2`,
      [schemas],
    );
    for (const c of composites) {
      push(`create type ${joinNames(c.schema, c.name)} as (${c.cols});`);
      count("composites");
    }

    heading("Sequences");
    const sequences = await q(
      `select n.nspname as schema, c.relname as name, s.seqstart, s.seqincrement,
              s.seqmin, s.seqmax, s.seqcache, s.seqcycle,
              exists (
                select 1 from pg_depend d
                 where d.classid = 'pg_class'::regclass
                   and d.objid = c.oid
                   and d.deptype = 'i') as is_identity
         from pg_class c
         join pg_namespace n on n.oid = c.relnamespace
         join pg_sequence s on s.seqrelid = c.oid
        where n.nspname = any($1::text[]) and c.relkind = 'S'
        order by 1, 2`,
      [schemas],
    );
    const ownedSeqs = await q(
      `select sn.nspname as seq_schema, sc.relname as seq_name,
              tn.nspname as table_schema, t.relname as table_name, a.attname as column_name
         from pg_depend d
         join pg_class sc on sc.oid = d.objid
         join pg_namespace sn on sn.oid = sc.relnamespace
         join pg_class t on t.oid = d.refobjid
         join pg_namespace tn on tn.oid = t.relnamespace
         join pg_attribute a on a.attrelid = t.oid and a.attnum = d.refobjsubid
        where d.classid = 'pg_class'::regclass
          and d.refclassid = 'pg_class'::regclass
          and d.deptype in ('a', 'i')
          and sc.relkind = 'S'
          and sn.nspname = any($1::text[])`,
      [schemas],
    );
    const ownerBySeq = new Map(
      ownedSeqs.map((r) => [`${r.seq_schema}.${r.seq_name}`, r]),
    );
    for (const s of sequences) {
      if (s.is_identity) continue; // created implicitly by the identity column
      push(
        `create sequence if not exists ${joinNames(s.schema, s.name)}` +
          ` as bigint start with ${s.seqstart} increment by ${s.seqincrement}` +
          ` minvalue ${s.seqmin} maxvalue ${s.seqmax} cache ${s.seqcache}` +
          (s.seqcycle ? " cycle" : " no cycle") +
          `;`,
      );
      const owner = ownerBySeq.get(`${s.schema}.${s.name}`);
      if (owner) {
        push(
          `alter sequence ${joinNames(s.schema, s.name)} owned by ${joinNames(
            owner.table_schema,
            owner.table_name,
          )}.${qi(owner.column_name)};`,
        );
      }
      count("sequences");
    }

    heading("Tables and columns");
    const tables = await q(
      `select n.nspname as schema, c.relname as name,
              case c.relpersistence when 'u' then true else false end as unlogged,
              c.reloptions as options,
              obj_description(c.oid, 'pg_class') as comment
         from pg_class c
         join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = any($1::text[]) and c.relkind in ('r', 'p')
          and not exists (
                select 1 from pg_depend d
                 where d.classid = 'pg_class'::regclass
                   and d.objid = c.oid
                   and d.deptype = 'e')
        order by 1, 2`,
      [schemas],
    );
    const columns = await q(
      `select n.nspname as schema, c.relname as table_name, a.attnum,
              a.attname as name,
              format_type(a.atttypid, a.atttypmod) as type,
              a.attnotnull as not_null,
              a.attidentity as identity,
              a.attgenerated as generated,
              pg_get_expr(ad.adbin, ad.adrelid) as default_expr,
              col_description(c.oid, a.attnum) as comment
         from pg_attribute a
         join pg_class c on c.oid = a.attrelid
         join pg_namespace n on n.oid = c.relnamespace
         left join pg_attrdef ad on ad.adrelid = c.oid and ad.adnum = a.attnum
        where n.nspname = any($1::text[]) and c.relkind in ('r', 'p')
          and a.attnum > 0 and not a.attisdropped
        order by 1, 2, a.attnum`,
      [schemas],
    );
    const columnsByTable = new Map();
    for (const col of columns) {
      const key = `${col.schema}.${col.table_name}`;
      if (!columnsByTable.has(key)) columnsByTable.set(key, []);
      columnsByTable.get(key).push(col);
    }
    for (const table of tables) {
      const cols = columnsByTable.get(`${table.schema}.${table.name}`) ?? [];
      if (!cols.length) continue;
      const options = (table.options ?? [])
        .filter((o) => !o.startsWith("toast."))
        .map((o) => o.replace(/^fillfactor=/, "fillfactor = "));
      push(
        `create ${table.unlogged ? "unlogged " : ""}table if not exists ${joinNames(
          table.schema,
          table.name,
        )} (`,
      );
      const lines = cols.map((col) => {
        let line = `  ${qi(col.name)} ${col.type}`;
        if (col.generated === "s" && col.default_expr) {
          line += ` generated always as (${col.default_expr}) stored`;
        } else if (col.identity === "a") {
          line += " generated always as identity";
        } else if (col.identity === "d") {
          line += " generated by default as identity";
        } else if (col.default_expr) {
          line += ` default ${col.default_expr}`;
        }
        if (col.not_null) line += " not null";
        return line;
      });
      push(lines.join(",\n") + "\n)" + (options.length ? ` with (${options.join(", ")})` : "") + ";");
      count("tables");
      for (const col of cols) {
        if (col.comment) {
          push(
            `comment on column ${joinNames(col.schema, col.table_name)}.${qi(
              col.name,
            )} is ${ql(col.comment)};`,
          );
        }
      }
      if (table.comment) {
        push(`comment on table ${joinNames(table.schema, table.name)} is ${ql(table.comment)};`);
      }
    }

    heading("Constraints");
    const constraints = await q(
      `select n.nspname as schema, c.relname as table_name, con.conname as name,
              con.contype as type, con.convalidated as validated,
              pg_get_constraintdef(con.oid, true) as def
         from pg_constraint con
         join pg_class c on c.oid = con.conrelid
         join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = any($1::text[])
          and c.relkind in ('r', 'p')
          and con.contype in ('p', 'u', 'c', 'f', 'x')
        order by case con.contype
                   when 'p' then 1 when 'u' then 2 when 'c' then 3
                   when 'x' then 4 else 5 end,
                 1, 2, 3`,
      [schemas],
    );
    for (const c of constraints) {
      push(
        `alter table only ${joinNames(c.schema, c.table_name)} add constraint ${qi(
          c.name,
        )} ${c.def}${c.validated ? "" : " not valid"};`,
      );
      count("constraints");
    }

    heading("Indexes");
    const indexes = await q(
      `select n.nspname as schema, t.relname as table_name, i.relname as name,
              pg_get_indexdef(i.oid) as def
         from pg_index x
         join pg_class i on i.oid = x.indexrelid
         join pg_class t on t.oid = x.indrelid
         join pg_namespace n on n.oid = t.relnamespace
        where n.nspname = any($1::text[])
          and t.relkind in ('r', 'p')
          and not exists (
                select 1 from pg_constraint con where con.conindid = i.oid)
        order by 1, 2, 3`,
      [schemas],
    );
    for (const i of indexes) {
      push(`${i.def};`);
      count("indexes");
    }

    heading("Row level security");
    const rls = await q(
      `select n.nspname as schema, c.relname as name,
              c.relrowsecurity as enabled, c.relforcerowsecurity as forced
         from pg_class c
         join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = any($1::text[]) and c.relkind in ('r', 'p')
        order by 1, 2`,
      [schemas],
    );
    for (const t of rls) {
      if (!t.enabled) continue;
      push(`alter table ${joinNames(t.schema, t.name)} enable row level security;`);
      count("rls_enabled");
      if (t.forced) {
        push(`alter table ${joinNames(t.schema, t.name)} force row level security;`);
        count("rls_forced");
      }
    }

    heading("Functions");
    const functions = await q(
      `select n.nspname as schema, p.proname as name, p.oid,
              pg_get_functiondef(p.oid) as def
         from pg_proc p
         join pg_namespace n on n.oid = p.pronamespace
        where n.nspname = any($1::text[])
          and p.prokind in ('f', 'w')
          and not exists (
                select 1 from pg_depend d
                 where d.classid = 'pg_proc'::regclass
                   and d.objid = p.oid
                   and d.deptype = 'e')
        order by 1, 2, p.oid`,
      [schemas],
    );
    for (const f of functions) {
      push(f.def.trim().replace(/;$/, "") + ";");
      count("functions");
    }

    heading("Triggers");
    const triggers = await q(
      `select n.nspname as schema, c.relname as table_name, t.tgname as name,
              t.tgenabled as enabled, pg_get_triggerdef(t.oid, true) as def
         from pg_trigger t
         join pg_class c on c.oid = t.tgrelid
         join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = any($1::text[]) and not t.tgisinternal
        order by 1, 2, 3`,
      [schemas],
    );
    for (const t of triggers) {
      push(`${t.def};`);
      if (t.enabled === "D" || t.enabled === "R") {
        push(`alter table ${joinNames(t.schema, t.table_name)} disable trigger ${qi(t.name)};`);
      }
      count("triggers");
    }

    heading("Views");
    const views = await q(
      `select n.nspname as schema, c.relname as name, c.relkind as kind,
              c.reloptions as options, c.relispopulated as populated,
              pg_get_viewdef(c.oid, true) as def,
              obj_description(c.oid, 'pg_class') as comment
         from pg_class c
         join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = any($1::text[]) and c.relkind in ('v', 'm')
          and not exists (
                select 1 from pg_depend d
                 where d.classid = 'pg_class'::regclass
                   and d.objid = c.oid
                   and d.deptype = 'e')
        order by 1, 2`,
      [schemas],
    );
    for (const v of views) {
      const securityInvoker = (v.options ?? []).some(
        (o) => o === "security_invoker=true" || o === "security_invoker=on",
      );
      const body = String(v.def).trim().replace(/;$/, "");
      if (v.kind === "m") {
        push(`create materialized view ${joinNames(v.schema, v.name)} as\n${body}\n  with ${
          v.populated ? "data" : "no data"
        };`);
      } else {
        push(
          `create or replace view ${joinNames(v.schema, v.name)}${
            securityInvoker ? " with (security_invoker = true)" : ""
          } as\n${body};`,
        );
      }
      if (v.comment) {
        push(
          `comment on ${v.kind === "m" ? "materialized view" : "view"} ${joinNames(
            v.schema,
            v.name,
          )} is ${ql(v.comment)};`,
        );
      }
      count("views");
    }

    heading("Policies");
    const policies = await q(
      `select schemaname as schema, tablename as table_name, policyname as name,
              permissive, roles, cmd, qual, with_check
         from pg_policies
        where schemaname = any($1::text[])
        order by 1, 2, 3`,
      [schemas],
    );
    for (const p of policies) {
      const roles = roleList(p.roles);
      const targets = roles.length
        ? roles.map((r) => (r === "public" ? "public" : qi(r))).join(", ")
        : "public";
      let line = `create policy ${qi(p.name)} on ${joinNames(p.schema, p.table_name)}`;
      if (p.permissive === "RESTRICTIVE") line += " as restrictive";
      line += ` for ${String(p.cmd).toLowerCase()}`;
      line += ` to ${targets}`;
      if (p.qual) line += `\n  using (${p.qual})`;
      if (p.with_check) line += `\n  with check (${p.with_check})`;
      push(`${line};`);
      count("policies");
    }

    heading("Table, sequence and function grants");
    const aclRows = await q(
      `select n.nspname as schema, c.relname as name, c.relkind as kind,
              case when a.grantee = 0 then 'public' else r.rolname end as role,
              array_agg(distinct a.privilege_type order by a.privilege_type) as privileges
         from pg_class c
         join pg_namespace n on n.oid = c.relnamespace
         cross join lateral aclexplode(c.relacl) a
         left join pg_roles r on r.oid = a.grantee
        where n.nspname = any($1::text[]) and c.relkind in ('r', 'p', 'v', 'm', 'S')
        group by 1, 2, 3, 4
        order by 1, 2, 4`,
      [schemas],
    );
    for (const row of aclRows) {
      if (!row.role || !GRANT_ROLES.has(row.role)) continue;
      const target = row.kind === "S" ? "sequence" : "table";
      const privileges = row.privileges.map((p) => String(p).toLowerCase()).join(", ");
      push(`grant ${privileges} on ${target} ${joinNames(row.schema, row.name)} to ${row.role};`);
      count("grants");
    }
    const fnGrants = await q(
      `select n.nspname as schema, p.proname as name,
              pg_get_function_identity_arguments(p.oid) as args,
              case when a.grantee = 0 then 'public' else r.rolname end as role,
              array_agg(distinct a.privilege_type order by a.privilege_type) as privileges
         from pg_proc p
         join pg_namespace n on n.oid = p.pronamespace
         cross join lateral aclexplode(p.proacl) a
         left join pg_roles r on r.oid = a.grantee
        where n.nspname = any($1::text[]) and p.prokind in ('f', 'w')
        group by 1, 2, 3, 4
        order by 1, 2, 4`,
      [schemas],
    );
    for (const row of fnGrants) {
      if (!row.role || !GRANT_ROLES.has(row.role)) continue;
      const privileges = row.privileges.map((p) => String(p).toLowerCase()).join(", ");
      push(
        `grant ${privileges} on function ${joinNames(row.schema, row.name)}(${
          row.args
        }) to ${row.role};`,
      );
      count("function_grants");
    }

    heading("Storage buckets and policies");
    const buckets = await q(
      `select id, name, public, file_size_limit, allowed_mime_types
         from storage.buckets
        order by id`,
    );
    for (const b of buckets) {
      const mime = b.allowed_mime_types
        ? `array[${b.allowed_mime_types.map((m) => ql(m)).join(", ")}]`
        : "null";
      push(
        `insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)\n` +
          `values (${ql(b.id)}, ${ql(b.name)}, ${b.public}, ${
            b.file_size_limit ?? "null"
          }, ${mime})\n` +
          `on conflict (id) do update set public = excluded.public,\n` +
          `  file_size_limit = excluded.file_size_limit,\n` +
          `  allowed_mime_types = excluded.allowed_mime_types;`,
      );
      count("buckets");
    }
    const storagePolicies = await q(
      `select policyname as name, permissive, roles, cmd, qual, with_check
         from pg_policies
        where schemaname = 'storage' and tablename = 'objects'
        order by 1`,
    );
    for (const p of storagePolicies) {
      const roles = roleList(p.roles);
      const targets = roles.length
        ? roles.map((r) => (r === "public" ? "public" : qi(r))).join(", ")
        : "public";
      let line = `create policy ${qi(p.name)} on storage.objects`;
      if (p.permissive === "RESTRICTIVE") line += " as restrictive";
      line += ` for ${String(p.cmd).toLowerCase()} to ${targets}`;
      if (p.qual) line += `\n  using (${p.qual})`;
      if (p.with_check) line += `\n  with check (${p.with_check})`;
      push(`${line};`);
      count("storage_policies");
    }

    heading("Realtime publication");
    const realtime = await q(
      `select schemaname as schema, tablename as name
         from pg_publication_tables
        where pubname = 'supabase_realtime'
        order by 1, 2`,
    );
    for (const r of realtime) {
      push(
        `alter publication supabase_realtime add table ${joinNames(r.schema, r.name)};`,
      );
      count("realtime_tables");
    }
    if (!realtime.length) push("-- no tables published to supabase_realtime");

    heading("Applied migration history");
    let history = [];
    try {
      history = await q(
        `select version, name from supabase_migrations.schema_migrations order by version`,
      );
    } catch {
      push("-- supabase_migrations.schema_migrations not readable with this connection");
    }
    for (const m of history) push(`-- ${m.version}  ${m.name ?? ""}`);
    count("migrations", history.length);

    out.push(
      "",
      "-- ---------------------------------------------------------------------------",
      `-- Objects captured: ${Object.entries(stats)
        .map(([k, v]) => `${v} ${k}`)
        .join(", ")}`,
    );

    await mkdir(path.dirname(OUT_FILE), { recursive: true });
    const text = out.join("\n") + "\n";
    await writeFile(OUT_FILE, text, "utf8");

    console.log(`Wrote ${OUT_FILE}`);
    console.log(`${text.split("\n").length} lines, ${(text.length / 1024).toFixed(1)} KiB`);
    console.log(
      Object.entries(stats)
        .map(([k, v]) => `${k}=${v}`)
        .join(" "),
    );
  } finally {
    await client.end();
  }
}

main().catch((error) => {
  console.error("Schema capture failed:", error.message);
  process.exit(1);
});
