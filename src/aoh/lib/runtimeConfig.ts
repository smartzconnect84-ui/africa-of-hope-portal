// Runtime backend configuration.
//
// The portal must not depend on one hosting provider or on secrets injected at
// build time. `/aoh-config.js` is served next to index.html and runs before the
// app bundle, so a deployment can be pointed at its school database by editing
// that one public file — no rebuild, no dashboard, any static host.
//
// Build-time VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY still work and are used
// only when the runtime file leaves the values empty. Runtime values win, so a
// build made for one project can be redeployed against another.
//
// Nothing here is secret: the anon / publishable key is designed to be public.

export interface AohRuntimeConfig {
  /** https://<project-ref>.supabase.co (or a self-hosted Supabase URL). */
  supabaseUrl?: string;
  /** The anon / publishable key — never the service_role key. */
  supabaseAnonKey?: string;
}

type RuntimeWindow = Window & {
  AOH_CONFIG?: Partial<Record<keyof AohRuntimeConfig, string>> & {
    /** Older/alternate name accepted for the same public key. */
    supabasePublishableKey?: string;
  };
};

export type BackendConfigSource = "runtime" | "build" | "none";

export interface BackendConfig {
  url: string;
  anonKey: string;
  source: BackendConfigSource;
  configured: boolean;
}

const text = (value: unknown): string => (typeof value === "string" ? value.trim() : "");

/** window.AOH_CONFIG as set by /aoh-config.js (empty outside the browser). */
export function readRuntimeConfig(): AohRuntimeConfig {
  if (typeof window === "undefined") return {};
  const config = (window as RuntimeWindow).AOH_CONFIG;
  if (!config || typeof config !== "object") return {};
  return {
    supabaseUrl: text(config.supabaseUrl),
    supabaseAnonKey: text(config.supabaseAnonKey) || text(config.supabasePublishableKey),
  };
}

function usableUrl(value: string): boolean {
  try {
    const url = new URL(value);
    return url.protocol === "https:" || url.protocol === "http:";
  } catch {
    return false;
  }
}

/**
 * Resolves the backend credentials: the runtime file wins when it sets either
 * value, otherwise the build-time env vars are used. A half-filled runtime file
 * counts as configured-at-runtime and reports "not configured" rather than
 * silently mixing a URL from one project with a key from another.
 */
export function resolveBackendConfig(envUrl: string, envKey: string): BackendConfig {
  const runtime = readRuntimeConfig();
  const runtimeUrl = runtime.supabaseUrl ?? "";
  const runtimeKey = runtime.supabaseAnonKey ?? "";
  const runtimeSet = Boolean(runtimeUrl || runtimeKey);

  const url = (runtimeSet ? runtimeUrl : envUrl).trim();
  const anonKey = (runtimeSet ? runtimeKey : envKey).trim();
  const configured = usableUrl(url) && anonKey.length > 0;

  return {
    url: configured ? url : "",
    anonKey: configured ? anonKey : "",
    source: runtimeSet ? "runtime" : configured ? "build" : "none",
    configured,
  };
}

/** Short human label for admin screens. */
export function backendConfigSourceLabel(source: BackendConfigSource): string {
  if (source === "runtime") return "aoh-config.js";
  if (source === "build") return "build env";
  return "not set";
}
