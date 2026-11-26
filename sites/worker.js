// Cloudflare Workers entry for the Africa of Hope portal.
//
// The app is a Vite/TanStack Start build whose only route ("/") mounts the
// whole portal in the browser (src/routes/index.tsx → @/aoh/entry). `vite
// build` therefore emits a complete static site in dist/client: index.html,
// hashed JS/CSS chunks and public/ assets. This worker serves those files from
// the Sites asset binding, and answers any navigation request that has no file
// with index.html so in-app URLs and refreshes never 404.
const FILE_EXT = /\.[a-z0-9]{2,5}$/i;

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // Assets first — the platform binding is the static build.
    const asset = await env.ASSETS.fetch(request);
    if (asset.status !== 404 || FILE_EXT.test(url.pathname)) return asset;

    // Browser navigation to an unknown path: hand the SPA its entry document.
    if (request.method !== "GET" && request.method !== "HEAD") return asset;
    const acceptsHtml = (request.headers.get("accept") || "").includes("text/html");
    if (!acceptsHtml) return asset;

    return env.ASSETS.fetch(
      new Request(new URL("/index.html", url), {
        method: "GET",
        headers: request.headers,
      }),
    );
  },
};
