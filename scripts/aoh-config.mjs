// Resolve the Supabase backend settings for a deployment and write the runtime
// config file (`aoh-config.js`) that index.html loads before the app bundle.
//
// Why this exists: the portal must keep working when it is deployed to a new
// host without anyone copying a `window.AOH_CONFIG = { supabaseUrl, ... }`
// object into that host's dashboard. The build reads the project URL and the
// anon / publishable key from the deploy environment instead, so a fresh host
// needs two variables and nothing else:
//
//   SUPABASE_URL=https://<project-ref>.supabase.co
//   SUPABASE_ANON_KEY=<anon / publishable key>
//
// VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY are accepted as well, because
// Vite-based hosts usually expose those. When neither pair is set the build
// falls back to the values already in public/aoh-config.js, so the current
// zero-config deployment path keeps working exactly as before.
//
// The anon key is public by design (it ships to every browser and is limited
// by row-level security). A service_role key must never be written here, so it
// is detected and rejected before anything is emitted.

import { readFile, writeFile } from "node:fs/promises";
import path from "node:path";

const PUBLIC_CONFIG_FILE = path.join("public", "aoh-config.js");

function clean(value) {
  if (typeof value !== "string") return "";
  let text = value.trim();
  if (
    (text.startsWith('"') && text.endsWith('"')) ||
    (text.startsWith("'") && text.endsWith("'"))
  ) {
    text = text.slice(1, -1).trim();
  }
  return text;
}

function usableUrl(value) {
  try {
    const url = new URL(value);
    return url.protocol === "https:" || url.protocol === "http:";
  } catch {
    return false;
  }
}

/** The `role` claim of a Supabase JWT, or "" when the key is not a JWT. */
function jwtRole(key) {
  const parts = key.split(".");
  if (parts.length !== 3) return "";
  try {
    const payload = Buffer.from(
      parts[1].replace(/-/g, "+").replace(/_/g, "/"),
      "base64",
    ).toString("utf8");
    const claims = JSON.parse(payload);
    return typeof claims?.role === "string" ? claims.role : "";
  } catch {
    return "";
  }
}

/** Refuse anything that is not a browser-safe key. */
function assertPublicKey(key, source) {
  const role = jwtRole(key);
  if (role === "service_role") {
    throw new Error(
      `${source}: that is a service_role key — it bypasses every access policy and must never reach the browser. Use the anon / publishable key.`,
    );
  }
  if (/^(sb_secret_|sbp_)/.test(key)) {
    throw new Error(
      `${source}: that looks like a secret key, not the anon / publishable key.`,
    );
  }
  if (key.length < 20) {
    throw new Error(`${source}: the anon key looks truncated (${key.length} characters).`);
  }
}

/** Values already in public/aoh-config.js — the fallback for builds with no env. */
async function readCommittedConfig(root) {
  try {
    const text = await readFile(path.join(root, PUBLIC_CONFIG_FILE), "utf8");
    const read = (name) => {
      const match = text.match(new RegExp(`${name}\\s*:\\s*["']([^"']*)["']`));
      return match ? clean(match[1]) : "";
    };
    return {
      url: read("supabaseUrl"),
      key: read("supabaseAnonKey") || read("supabasePublishableKey"),
    };
  } catch {
    return { url: "", key: "" };
  }
}

/**
 * Resolve the backend settings.
 * Returns { url, key, origin, fromEnvironment }. `origin` is shown in build
 * logs; the key itself never is.
 */
export async function resolveSupabaseConfig(root = process.cwd(), env = process.env) {
  const pairs = [
    {
      source: "SUPABASE_URL / SUPABASE_ANON_KEY",
      origin: "deploy environment",
      url: clean(env.SUPABASE_URL),
      key: clean(env.SUPABASE_ANON_KEY || env.SUPABASE_PUBLISHABLE_KEY),
    },
    {
      source: "VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY",
      origin: "build environment",
      url: clean(env.VITE_SUPABASE_URL),
      key: clean(env.VITE_SUPABASE_ANON_KEY || env.VITE_SUPABASE_PUBLISHABLE_KEY),
    },
  ];

  for (const pair of pairs) {
    if (!pair.url && !pair.key) continue;
    if (!usableUrl(pair.url)) {
      throw new Error(`${pair.source}: the URL must be an absolute http(s) URL.`);
    }
    if (!pair.key) {
      throw new Error(`${pair.source}: the URL is set but the anon key is missing.`);
    }
    assertPublicKey(pair.key, pair.source);
    return {
      url: pair.url.replace(/\/+$/, ""),
      key: pair.key,
      origin: pair.origin,
      fromEnvironment: true,
    };
  }

  const committed = await readCommittedConfig(root);
  if (usableUrl(committed.url) && committed.key) {
    assertPublicKey(committed.key, PUBLIC_CONFIG_FILE);
    return {
      url: committed.url.replace(/\/+$/, ""),
      key: committed.key,
      origin: PUBLIC_CONFIG_FILE,
      fromEnvironment: false,
    };
  }

  return { url: "", key: "", origin: "", fromEnvironment: false };
}

/** The generated runtime config: a classic script that sets window.AOH_CONFIG. */
export function renderRuntimeConfig({ url, key }) {
  return [
    "/* Generated at build time by scripts/aoh-config.mjs — do not edit.",
    " * Configures which Supabase project the portal talks to.",
    " * Public by design (anon / publishable key); never a service_role key. */",
    `window.AOH_CONFIG = ${JSON.stringify(
      { supabaseUrl: url, supabaseAnonKey: key },
      null,
      2,
    )};`,
    "",
  ].join("\n");
}

/** Write aoh-config.js into a build output directory. */
export async function writeRuntimeConfig(outputDir, config) {
  const target = path.join(outputDir, "aoh-config.js");
  await writeFile(target, renderRuntimeConfig(config), "utf8");
  return target;
}

// `node scripts/aoh-config.mjs` prints what a build would use, without the key.
if (import.meta.url === `file://${process.argv[1]}`) {
  try {
    const config = await resolveSupabaseConfig(process.cwd());
    if (!config.url) {
      console.log("backend: not configured (no env pair and no public/aoh-config.js values)");
      process.exitCode = 1;
    } else {
      console.log(`backend: ${new URL(config.url).host} (from ${config.origin})`);
      console.log(`key: ${config.key.length} characters, role=${jwtRole(config.key) || "unknown"}`);
    }
  } catch (error) {
    console.error(`backend: ${error.message}`);
    process.exitCode = 1;
  }
}
