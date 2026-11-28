// Register the deploying host in the Supabase Auth redirect allowlist.
//
// Without this, every new host needs a manual dashboard edit: GoTrue only
// honours an `emailRedirectTo` / `redirectTo` that matches `site_url` or the
// comma-separated `uri_allow_list`, so confirmation and password-reset links on
// an unregistered origin silently fall back to the old site.
//
// This runs during the build. It reads the origin the deployment is served
// from (SITE_URL, or a host-provided equivalent), appends it — and its `/**`
// pattern — to the existing allowlist, writes it back through the Supabase
// Management API, then re-reads the config to confirm.
//
// It never changes `site_url`: that value is the fallback for links with no
// redirect, so the production domain must stay in charge of it.
//
// Credentials: SUPABASE_ACCESS_TOKEN (Management API token). The project ref
// comes from SUPABASE_PROJECT_REF or the configured project URL. When either is
// missing the build says exactly what to set and carries on — a missing token
// must not block a deploy, but it must never be silent either.

const API_BASE = "https://api.supabase.com/v1";

/** Absolute http(s) origin from a URL, or "" when the value is not usable. */
export function normalizeOrigin(value) {
  if (typeof value !== "string" || !value.trim()) return "";
  try {
    const url = new URL(value.trim());
    if (url.protocol !== "https:" && url.protocol !== "http:") return "";
    return url.origin;
  } catch {
    return "";
  }
}

/**
 * The origin this deployment serves from. Explicit settings win; the
 * provider-specific names are the ones hosts inject by themselves.
 */
export function readDeployOrigin(env = process.env) {
  const candidates = [
    ["SITE_URL", env.SITE_URL],
    ["APP_ORIGIN", env.APP_ORIGIN],
    ["PUBLIC_SITE_URL", env.PUBLIC_SITE_URL],
    ["VITE_SITE_URL", env.VITE_SITE_URL],
    ["DEPLOY_PRIME_URL", env.DEPLOY_PRIME_URL],
    ["CF_PAGES_URL", env.CF_PAGES_URL],
    ["VERCEL_URL", env.VERCEL_URL ? `https://${env.VERCEL_URL}` : ""],
  ];
  for (const [name, value] of candidates) {
    const origin = normalizeOrigin(value);
    if (origin) return { origin, source: name };
  }
  return { origin: "", source: "" };
}

/** Add the origin and its path pattern to a comma-separated allowlist. */
export function addOriginToList(list, origin) {
  const entries = String(list ?? "")
    .split(",")
    .map((entry) => entry.trim())
    .filter(Boolean);
  const seen = new Set(entries.map((entry) => entry.toLowerCase()));
  const added = [];
  for (const candidate of [origin, `${origin}/**`]) {
    if (seen.has(candidate.toLowerCase())) continue;
    entries.push(candidate);
    seen.add(candidate.toLowerCase());
    added.push(candidate);
  }
  return { entries, added, list: entries.join(",") };
}

function projectRefFrom(projectUrl, explicit) {
  const fromEnv = String(explicit ?? "").trim();
  if (fromEnv) return fromEnv;
  const url = normalizeOrigin(projectUrl);
  if (!url) return "";
  try {
    return new URL(url).hostname.split(".")[0] ?? "";
  } catch {
    return "";
  }
}

async function managementApi(pathname, token, init = {}) {
  const response = await fetch(`${API_BASE}${pathname}`, {
    ...init,
    headers: {
      authorization: `Bearer ${token}`,
      "content-type": "application/json",
      ...(init.headers ?? {}),
    },
    signal: AbortSignal.timeout(20_000),
  });
  const text = await response.text();
  let body = null;
  try {
    body = text ? JSON.parse(text) : null;
  } catch {
    body = null;
  }
  if (!response.ok) {
    const detail =
      (body && (body.message || body.error || body.error_description)) ||
      `HTTP ${response.status}`;
    throw new Error(String(detail).slice(0, 300));
  }
  return body;
}

/**
 * Register the deploy origin. Returns
 * { status: "registered" | "present" | "skipped" | "failed", origin, reason }.
 * Never throws: the build reports the outcome instead of dying mid-deploy.
 */
export async function registerDeployOrigin(options = {}) {
  const env = options.env ?? process.env;
  const log = options.log ?? ((message) => console.warn(message));
  const { origin, source } = readDeployOrigin(env);
  const token = String(env.SUPABASE_ACCESS_TOKEN ?? env.SUPABASE_TOKEN ?? "").trim();
  const projectRef = projectRefFrom(options.projectUrl ?? env.SUPABASE_URL ?? "", env.SUPABASE_PROJECT_REF);
  const dryRun = Boolean(options.dryRun);

  if (!origin) {
    log(
      "[auth] no deploy origin to register — set SITE_URL=https://your-domain (or APP_ORIGIN); " +
        "sign-in links will only work on allowlisted hosts",
    );
    return { status: "skipped", origin: "", reason: "no SITE_URL" };
  }
  if (!token) {
    log(
      `[auth] ${origin} not registered: SUPABASE_ACCESS_TOKEN is missing, so the Supabase ` +
        "allowlist cannot be updated. Add it to the deploy environment (Project Settings → " +
        "API → access token) or add the origin in the dashboard.",
    );
    return { status: "skipped", origin, reason: "no SUPABASE_ACCESS_TOKEN" };
  }
  if (!projectRef) {
    log(
      `[auth] ${origin} not registered: no project ref. Set SUPABASE_PROJECT_REF or SUPABASE_URL.`,
    );
    return { status: "skipped", origin, reason: "no project ref" };
  }

  const path = `/projects/${projectRef}/config/auth`;
  try {
    const current = await managementApi(path, token);
    const before = String(current?.uri_allow_list ?? "");
    const merged = addOriginToList(before, origin);

    if (!merged.added.length) {
      log(`[auth] ${origin} (from ${source}) is already in the allowlist`);
      return { status: "present", origin, reason: "already allowlisted" };
    }
    if (dryRun) {
      log(`[auth] would add ${merged.added.join(", ")} to the allowlist (dry run)`);
      return { status: "registered", origin, reason: "dry run" };
    }

    await managementApi(path, token, {
      method: "PATCH",
      body: JSON.stringify({ uri_allow_list: merged.list }),
    });

    // Confirm the write actually took effect instead of trusting the response.
    const after = await managementApi(path, token);
    const saved = String(after?.uri_allow_list ?? "");
    const confirmed = addOriginToList(saved, origin).added.length === 0;
    if (!confirmed) {
      log(
        `[auth] wrote the allowlist but ${origin} is still missing on re-read — ` +
          "check the Supabase Auth settings before relying on sign-in here",
      );
      return { status: "failed", origin, reason: "not present after write" };
    }

    log(
      `[auth] registered ${origin} (from ${source}) in the Supabase redirect allowlist — ` +
        `${merged.entries.length} entries`,
    );
    return { status: "registered", origin, reason: `added ${merged.added.join(", ")}` };
  } catch (error) {
    log(
      `[auth] could not register ${origin}: ${error instanceof Error ? error.message : String(error)}. ` +
        "Sign-in links on this host will fall back to site_url until the origin is allowed.",
    );
    return { status: "failed", origin, reason: String(error?.message ?? error) };
  }
}

// Standalone use: `node scripts/register-auth-origin.mjs [--dry-run]`
if (import.meta.url === `file://${process.argv[1]}`) {
  const result = await registerDeployOrigin({ dryRun: process.argv.includes("--dry-run") });
  if (result.status === "failed") process.exitCode = 1;
}
