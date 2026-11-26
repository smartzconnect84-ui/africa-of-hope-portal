// Build the Freebuff Sites artifact for this app.
//
//   node scripts/build-sites.mjs
//
// 1. `vite build` → dist/client, the complete static site (index.html, hashed
//    JS/CSS, public/ files) plus dist/server (unused on Sites).
// 2. write deploy.json — the Sites manifest the Publish button and
//    sites_deploy both read. The Worker (sites/worker.js) serves
//    dist/client through env.ASSETS and falls back to index.html.
import { execFileSync } from "node:child_process";
import { cp, rm, stat, writeFile } from "node:fs/promises";
import path from "node:path";

const root = process.cwd();
const assetsDir = path.join(root, "sites/assets");

if (!process.argv.includes("--skip-vite")) {
  execFileSync("npx", ["vite", "build"], { stdio: "inherit", cwd: root });
}

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

const manifest = {
  entrypoint: "index.js",
  compatibilityDate: new Date().toISOString().slice(0, 10),
  modules: [{ name: "index.js", type: "esm", path: "./sites/worker.js" }],
  assetsDirectory: "./sites/assets",
};
await writeFile(path.join(root, "deploy.json"), JSON.stringify(manifest, null, 2) + "\n");

console.log(`[sites] index.html ${(size / 1024).toFixed(1)} kB`);
console.log(`[sites] manifest: ${path.join(root, "deploy.json")}`);
