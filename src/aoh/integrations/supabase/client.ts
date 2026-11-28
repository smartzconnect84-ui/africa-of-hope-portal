// Single Supabase client for the whole portal (the school's own project).
//
// The backend is resolved at RUNTIME from /aoh-config.js, which any host can
// serve and edit without a rebuild — see src/aoh/lib/runtimeConfig.ts. Build-time
// VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY are used only when that file leaves
// the values empty, so the app is not tied to one hosting provider:
//   VITE_SUPABASE_URL      https://<project-ref>.supabase.co
//   VITE_SUPABASE_ANON_KEY the anon / publishable key (safe in the browser)
// The service_role key must never appear in this file or any other file that
// ships to the browser.
//
// RESILIENCE RULE: a missing backend must never crash the app. Without valid
// env vars the client points at an unroutable placeholder (RFC 2606 .invalid),
// so the app still boots and renders; data calls resolve to { error } and the
// auth UI reports the backend as not configured.
import { createClient } from "@supabase/supabase-js";
import { authStorage } from "@/aoh/lib/authStorage";
import { resolveBackendConfig } from "@/aoh/lib/runtimeConfig";

const env = (import.meta as { env?: Record<string, string | undefined> }).env;
const backend = resolveBackendConfig(
  env?.VITE_SUPABASE_URL ?? "",
  env?.VITE_SUPABASE_ANON_KEY ?? env?.VITE_SUPABASE_PUBLISHABLE_KEY ?? "",
);

/** True when the credentials were baked in from the environment at build time. */
export const SUPABASE_USING_ENV = backend.source === "build";

/** True when /aoh-config.js supplied the credentials at runtime. */
export const SUPABASE_USING_RUNTIME_CONFIG = backend.source === "runtime";

/** Where the credentials came from: the runtime config file, the build or nowhere. */
export const SUPABASE_CONFIG_SOURCE = backend.source;

/** Project base URL, without a trailing slash. */
export const SUPABASE_URL = backend.configured
  ? backend.url.replace(/\/+$/, "")
  : "https://supabase-not-connected.invalid";

/** Public anon (or publishable) key — this value is safe to ship to browsers. */
export const SUPABASE_ANON_KEY = backend.configured
  ? backend.anonKey
  : "supabase-not-connected";

/** Project ref, taken from the project URL hostname. */
export const SUPABASE_PROJECT_REF = (() => {
  if (!backend.configured) return "";
  try {
    return new URL(SUPABASE_URL).hostname.split(".")[0] ?? "";
  } catch {
    return "";
  }
})();

/** False when the backend is not connected — gate backend-dependent UI on this. */
export function isSupabaseConfigured(): boolean {
  return backend.configured;
}

// A recovery (password reset) link opens the auth page; the auth code reads this
// flag once, on load, to show the new-password form instead of the sign-in form.
// It must be computed before the client below consumes the URL fragment.
export const OPENED_FROM_RECOVERY_LINK = (() => {
  if (typeof window === "undefined") return false;
  try {
    const hash = new URLSearchParams(window.location.hash.replace(/^#/, ""));
    const query = new URLSearchParams(window.location.search);
    return hash.get("type") === "recovery" || query.get("mode") === "recover";
  } catch {
    return false;
  }
})();

if (!backend.configured && typeof window !== "undefined") {
  console.error(
    "[supabase] Not connected: add supabaseUrl and supabaseAnonKey to /aoh-config.js (works on any host, no rebuild), or set VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY at build time (see .env.example).",
  );
}

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    storage: authStorage,
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
});

// ── Pending registration ────────────────────────────────────────────────────
// The admission form's answers are kept on this device until the account's
// profile row exists, so the first sign-in can create the profile with the
// phone, programme choices and education level the applicant entered.
const PENDING_KEY = "aoh-pending-registration";
export type PendingRegistration = Record<string, unknown>;

function readPending(): Record<string, PendingRegistration> {
  try {
    const raw = localStorage.getItem(PENDING_KEY);
    if (!raw) return {};
    const parsed = JSON.parse(raw) as unknown;
    return parsed && typeof parsed === "object"
      ? (parsed as Record<string, PendingRegistration>)
      : {};
  } catch {
    return {};
  }
}

/** Store an applicant's details on this device until their profile is created. */
export function rememberPendingRegistration(
  email: string,
  payload: PendingRegistration,
): void {
  const key = email.trim().toLowerCase();
  if (!key) return;
  try {
    localStorage.setItem(
      PENDING_KEY,
      JSON.stringify({ ...readPending(), [key]: payload }),
    );
  } catch {
    /* storage is optional — the profile just keeps the sign-up metadata */
  }
}

/** Read and remove the stored details for this email (null when there are none). */
export function takePendingRegistration(
  email: string | null | undefined,
): PendingRegistration | null {
  const key = (email ?? "").trim().toLowerCase();
  if (!key) return null;
  try {
    const all = readPending();
    const found = all[key];
    if (!found) return null;
    delete all[key];
    if (Object.keys(all).length === 0) localStorage.removeItem(PENDING_KEY);
    else localStorage.setItem(PENDING_KEY, JSON.stringify(all));
    return found;
  } catch {
    return null;
  }
}
