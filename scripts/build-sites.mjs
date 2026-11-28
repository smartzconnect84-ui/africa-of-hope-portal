// Build the Freebuff Sites artifact for this app.
//
//   node scripts/build-sites.mjs
//
// 1. `vite build` → dist/client, the complete static site (index.html, hashed
//    JS/CSS, public/ files) plus dist/server (unused on Sites).
// 2. write dist/client/aoh-config.js from the deploy environment, so a host
//    that sets SUPABASE_URL + SUPABASE_ANON_KEY is connected automatically
//    without anyone pasting a config object into the deployment.
// 3. write deploy.json — the Sites manifest the Publish button and
//    sites_deploy both read. The Worker (sites/worker.js) serves
//    dist/client through env.ASSETS and falls back to index.html.
import { execFileSync } from "node:child_process";
import { cp, rm, stat, writeFile } from "node:fs/promises";
import path from "node:path";
import { resolveSupabaseConfig, writeRuntimeConfig } from "./aoh-config.mjs";
import { registerDeployOrigin } from "./register-auth-origin.mjs";

const root = process.cwd();
const assetsDir = path.join(root, "sites/assets");
const clientDir = path.join(root, "dist/client");

if (!process.argv.includes("--skip-vite")) {
  execFileSync("npx", ["vite", "build"], { stdio: "inherit", cwd: root });
}

// Point the build at this deployment's backend. Values from the environment
// win; without them the committed public/aoh-config.js is kept as-is. Vite
// reads .env itself but this script does not, so load it here — the same two
// variables then work locally, in CI and in any host's dashboard.
if (!process.env.SUPABASE_URL && !process.env.VITE_SUPABASE_URL) {
  try {
    process.loadEnvFile(path.join(root, ".env"));
  } catch {
    // no .env in this checkout — environment variables are enough
  }
}
const backend = await resolveSupabaseConfig(root);
if (backend.url) {
  await writeRuntimeConfig(clientDir, backend);
  console.log(`[config] backend ${new URL(backend.url).host} (from ${backend.origin})`);
  if (!backend.fromEnvironment) {
    console.warn(
      "[config] using the committed config; set SUPABASE_URL and SUPABASE_ANON_KEY to deploy against another project",
    );
  }
} else {
  console.warn(
    "[config] no Supabase settings found — set SUPABASE_URL and SUPABASE_ANON_KEY or keep public/aoh-config.js",
  );
}

// Sign-in links only work on origins GoTrue allows. Register the host this
// build is for, so a new domain needs no dashboard edit.
await registerDeployOrigin({ projectUrl: backend.url });

// Sites only accepts public build output: no hidden files/directories, source
// maps, keys or symlinks. Stage dist/client into sites/assets and leave out the
// entries it rejects (public/.well-known/assetlinks.json is the only one).
await rm(assetsDir, { recursive: true, force: true });
await cp(path.join(root, "dist/client"), assetsDir, {
  recursive: true,
  filter: (source) => {
    const name = path.basename(source);
    return !name.startsWith(".") && !name.endsWith(".map");
  },
});

const indexHtml = path.join(assetsDir, "index.html");
const { size } = await stat(indexHtml);

// A deployed app with no /aoh-config.js boots unconnected, so a build that
// cannot produce one is an error rather than a silent broken deploy.
const runtimeConfig = path.join(assetsDir, "aoh-config.js");
await stat(runtimeConfig).catch(() => {
  throw new Error(
    `[config] ${runtimeConfig} is missing: set SUPABASE_URL and SUPABASE_ANON_KEY, or add public/aoh-config.js`,
  );
});

const manifest = {
  entrypoint: "index.js",
  compatibilityDate: new Date().toISOString().slice(0, 10),
  modules: [{ name: "index.js", type: "esm", path: "./sites/worker.js" }],
  assetsDirectory: "./sites/assets",
};
await writeFile(path.join(root, "deploy.json"), JSON.stringify(manifest, null, 2) + "\n");

console.log(`[sites] index.html ${(size / 1024).toFixed(1)} kB`);
console.log(`[sites] manifest: ${path.join(root, "deploy.json")}`);
