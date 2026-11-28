// Cloudflare Workers entry for the Africa of Hope portal.
//
// The app is a Vite/TanStack Start build whose only route ("/") mounts the
// whole portal in the browser (src/routes/index.tsx → @/aoh/entry). `vite
// build` therefore emits a complete static site in dist/client: index.html,
// hashed JS/CSS chunks and public/ assets. This worker serves those files from
// the Sites asset binding, and answers any navigation request that has no file
// with index.html so in-app URLs and refreshes never 404.
//
// It also owns /api/blob/*, the only place that talks to Backblaze B2 for the
// portal's private school files (training materials, classwork submissions,
// profile documents, chat attachments, transparency reports). B2 credentials
// stay in Worker secrets; the browser only ever receives short-lived URLs for
// individual objects after the database has approved the caller.
const FILE_EXT = /\.[a-z0-9]{2,5}$/i;
const BLOB_PREFIX = "/api/blob/";
const MB = 1024 * 1024;

// Public marketing routes the SPA owns (mirrors src/aoh/lib/publicRoutes.ts).
// Anything else is a genuine 404 instead of a 200 that renders the home page.
const PUBLIC_ROUTE =
  /^\/(?:about(?:-us|-who-we-are)?|programmes?|programmes\/[a-z0-9-]+|programs|programs\/[a-z0-9-]+|admissions|apply|apply-online|impact|our-impact|term-dates|policies|transparency|cookies|donate|blog|blog\/.+|team|our-team|campus|campus-life|verify|portal|newsletter\/(?:confirm|unsubscribe))\/?$/i;

// Baseline hardening for every HTML/asset response. The site handles student
// accounts on this origin, so HSTS and a permissive-but-real CSP are better than
// none; img/connect allow any https origin because media and Supabase live off-site.
const SECURITY_HEADERS = {
  "strict-transport-security": "max-age=31536000; includeSubDomains",
  "x-content-type-options": "nosniff",
  "referrer-policy": "strict-origin-when-cross-origin",
  "permissions-policy": "geolocation=(), microphone=(), camera=()",
  "content-security-policy":
    "default-src 'self'; base-uri 'self'; object-src 'none'; " +
    "script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; " +
    "font-src 'self' data: https://fonts.gstatic.com; img-src 'self' data: blob: https:; " +
    "media-src 'self' blob: https:; connect-src 'self' https: wss:; frame-src 'self' https:; " +
    "worker-src 'self' blob:",
};

const NOT_FOUND_HTML = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>Page not found | AFRICA OF HOPE</title>
<style>
  body{margin:0;min-height:100dvh;display:grid;place-items:center;font-family:system-ui,-apple-system,"Segoe UI",sans-serif;background:#f6f8f7;color:#022c22}
  main{max-width:34rem;padding:2rem;text-align:center}
  p.eyebrow{margin:0;font-size:12px;font-weight:700;letter-spacing:.2em;text-transform:uppercase;color:#047857}
  h1{margin:.75rem 0 0;font-size:1.75rem;line-height:1.2}
  p.body{margin:.75rem 0 0;color:#475569;font-size:.95rem;line-height:1.6}
  a.cta{display:inline-flex;margin-top:1.5rem;padding:.75rem 1.25rem;border-radius:.75rem;background:#065f46;color:#fff;font-weight:600;text-decoration:none}
</style>
</head>
<body>
<main>
  <p class="eyebrow">404</p>
  <h1>This page could not be found.</h1>
  <p class="body">The link may be old or mistyped. The school’s programmes, admissions and certificate verification pages are all one click away.</p>
  <a class="cta" href="/">Back to the home page</a>
</main>
</body>
</html>`;

/** Adds the security headers (and immutable caching for hashed assets). */
function withHeaders(response, url) {
  const headers = new Headers(response.headers);
  for (const [name, value] of Object.entries(SECURITY_HEADERS)) headers.set(name, value);
  if (url.pathname.startsWith("/assets/")) {
    headers.set("cache-control", "public, max-age=31536000, immutable");
  }
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

const ALLOWED_TYPES = {
  "training-materials": [
    "application/pdf", "text/plain", "application/zip", "application/x-zip-compressed",
    "image/jpeg", "image/png", "image/webp", "image/gif", "image/heic",
    "video/mp4", "video/webm", "video/quicktime", "audio/mpeg", "audio/wav", "audio/ogg", "audio/mp4", "audio/x-m4a",
    "application/msword", "application/vnd.ms-powerpoint", "application/vnd.ms-excel",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  ],
  "classwork-submissions": [
    "application/pdf", "text/plain", "application/zip", "application/x-zip-compressed",
    "image/jpeg", "image/png", "image/webp", "image/gif", "image/heic",
    "video/mp4", "video/webm", "video/quicktime", "audio/mpeg", "audio/wav", "audio/ogg", "audio/mp4", "audio/x-m4a",
    "application/msword", "application/vnd.ms-powerpoint", "application/vnd.ms-excel",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  ],
  documents: [
    "application/pdf", "image/jpeg", "image/png", "image/webp",
    "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  ],
  "chat-attachments": [
    "application/pdf", "text/plain", "application/zip", "application/x-zip-compressed",
    "image/jpeg", "image/png", "image/webp", "image/gif", "image/heic",
    "video/mp4", "video/webm", "video/quicktime", "audio/mpeg", "audio/wav", "audio/ogg", "audio/mp4", "audio/x-m4a",
    "application/msword", "application/vnd.ms-powerpoint", "application/vnd.ms-excel",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  ],
  "transparency-reports": ["application/pdf"],
};

const BUCKET_LIMITS = {
  "training-materials": 25 * MB,
  "classwork-submissions": 25 * MB,
  documents: 10 * MB,
  "chat-attachments": 25 * MB,
  "transparency-reports": 10 * MB,
};

// Only these types render inline. Everything else is forced to download, so a
// stored HTML/SVG file can never execute on the portal origin.
const INLINE_TYPES = new Set([
  "application/pdf",
  "image/jpeg", "image/png", "image/webp", "image/gif", "image/heic",
  "video/mp4", "video/webm", "video/quicktime",
  "audio/mpeg", "audio/wav", "audio/ogg", "audio/mp4", "audio/x-m4a",
]);

const EMPTY_SHA256 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
const encoder = new TextEncoder();

// Project configuration is public, so it has safe defaults here instead of
// requiring a secret for each value. Secrets can still override any of them.
const DEFAULT_SUPABASE_URL = "https://gatnzfjpuokopqyksqoy.supabase.co";
const DEFAULT_B2_BUCKET = "aoh-school-materials";
const DEFAULT_B2_ENDPOINT = "s3.us-west-004.backblazeb2.com";

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" },
  });
}

function b2Config(env) {
  const keyId = String(env.B2_KEY_ID || "").replace(/\s+/g, "");
  const secret = String(env.B2_APPLICATION_KEY || "").replace(/\s+/g, "");
  const bucket = env.B2_BUCKET || DEFAULT_B2_BUCKET;
  const endpoint = String(env.B2_ENDPOINT || DEFAULT_B2_ENDPOINT).replace(/^https?:\/\//, "").replace(/\/+$/, "");
  if (!/^[A-Za-z0-9]{25}$/.test(keyId) || !secret || !bucket || !endpoint) return null;
  const region = endpoint.split(".")[1];
  if (!region) return null;
  return { keyId, secret, bucket, endpoint, region };
}

function supabaseConfig(env, request) {
  const url = String(env.SUPABASE_URL || DEFAULT_SUPABASE_URL).replace(/\/+$/, "");
  const anon = env.SUPABASE_ANON_KEY || (request && request.headers.get("x-supabase-anon-key")) || "";
  return url && anon ? { url, anon } : null;
}

// ── SigV4 ───────────────────────────────────────────────────────────────────

function hex(buffer) {
  return [...new Uint8Array(buffer)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

async function sha256Hex(data) {
  const bytes = typeof data === "string" ? encoder.encode(data) : data;
  return hex(await crypto.subtle.digest("SHA-256", bytes));
}

async function hmac(key, data) {
  const raw = typeof key === "string" ? encoder.encode(key) : key;
  const imported = await crypto.subtle.importKey("raw", raw, { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  return new Uint8Array(await crypto.subtle.sign("HMAC", imported, typeof data === "string" ? encoder.encode(data) : data));
}

function encodeKey(key) {
  return key.split("/").map(encodeURIComponent).join("/");
}

async function signB2(env, method, key, options = {}) {
  const config = b2Config(env);
  if (!config) throw new Error("Blob storage is not configured.");
  const payloadHash = options.payloadHash || EMPTY_SHA256;
  const now = new Date();
  const amzDate = now.toISOString().replace(/[-:]/g, "").replace(/\.\d{3}/, "");
  const dateStamp = amzDate.slice(0, 8);
  const canonicalUri = key ? `/${config.bucket}/${encodeKey(key)}` : `/${config.bucket}`;
  const query = options.query
    ? Object.keys(options.query).sort()
        .map((name) => `${encodeURIComponent(name)}=${encodeURIComponent(options.query[name])}`)
        .join("&")
    : "";
  const signed = {
    host: config.endpoint,
    "x-amz-content-sha256": payloadHash,
    "x-amz-date": amzDate,
  };
  if (options.copySource) signed["x-amz-copy-source"] = options.copySource;
  const names = Object.keys(signed).sort();
  const canonicalHeaders = names.map((name) => `${name}:${signed[name]}\n`).join("");
  const signedHeaders = names.join(";");
  const canonicalRequest = [method, canonicalUri, query, canonicalHeaders, signedHeaders, payloadHash].join("\n");
  const scope = `${dateStamp}/${config.region}/s3/aws4_request`;
  const stringToSign = ["AWS4-HMAC-SHA256", amzDate, scope, await sha256Hex(canonicalRequest)].join("\n");
  const kDate = await hmac(`AWS4${config.secret}`, dateStamp);
  const kRegion = await hmac(kDate, config.region);
  const kService = await hmac(kRegion, "s3");
  const kSigning = await hmac(kService, "aws4_request");
  const signature = hex(await hmac(kSigning, stringToSign));

  // Host is signed but not set: the runtime derives it from the URL. Copying a
  // signed header into fetch() would be silently ignored or rejected.
  const headers = {
    "x-amz-content-sha256": payloadHash,
    "x-amz-date": amzDate,
    authorization: `AWS4-HMAC-SHA256 Credential=${config.keyId}/${scope}, SignedHeaders=${signedHeaders}, Signature=${signature}`,
  };
  if (options.copySource) headers["x-amz-copy-source"] = options.copySource;
  if (options.contentType) headers["content-type"] = options.contentType;
  return { url: `https://${config.endpoint}${canonicalUri}${query ? `?${query}` : ""}`, headers };
}

// ── Portal auth ─────────────────────────────────────────────────────────────

async function verifyUser(request, env) {
  const config = supabaseConfig(env, request);
  if (!config) return null;
  const header = request.headers.get("authorization") || "";
  const token = header.startsWith("Bearer ") ? header.slice(7).trim() : "";
  if (!token) return null;
  const response = await fetch(`${config.url}/auth/v1/user`, {
    headers: { apikey: config.anon, authorization: `Bearer ${token}` },
  });
  if (!response.ok) return null;
  const user = await response.json().catch(() => null);
  return user && user.id ? { token, id: user.id, anon: config.anon } : null;
}

async function authorized(env, user, action, bucket, key) {
  const url = String(env.SUPABASE_URL || DEFAULT_SUPABASE_URL).replace(/\/+$/, "");
  const response = await fetch(`${url}/rest/v1/rpc/blob_authorize`, {
    method: "POST",
    headers: {
      apikey: user.anon,
      authorization: `Bearer ${user.token}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({ p_action: action, p_bucket: bucket, p_key: `aoh/${bucket}/${key}` }),
  });
  if (!response.ok) {
    console.error("blob_authorize", response.status, await response.text().catch(() => ""));
    return false;
  }
  return (await response.json().catch(() => false)) === true;
}

// ── Download tokens ─────────────────────────────────────────────────────────

function base64url(bytes) {
  let text = "";
  for (const byte of bytes) text += String.fromCharCode(byte);
  return btoa(text).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function downloadToken(env, bucket, key, expires) {
  const config = b2Config(env);
  if (!config) return "";
  // A dedicated signing secret can be rotated without invalidating B2 access.
  // Fall back to the B2 application key so existing deployments keep working.
  const secret = env.BLOB_SIGNING_SECRET || config.secret;
  return base64url(await hmac(secret, `${bucket}\n${key}\n${expires}`));
}

function sameSignature(a, b) {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i += 1) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

function safeKey(key) {
  if (!key || key.length > 512) return false;
  if (key.startsWith("/") || key.includes("\\")) return false;
  return key.split("/").every((part) => part && part !== "." && part !== "..");
}

function parseBlobPath(pathname) {
  if (!pathname.startsWith(BLOB_PREFIX)) return null;
  const rest = pathname.slice(BLOB_PREFIX.length);
  const slash = rest.indexOf("/");
  if (slash < 1) return null;
  try {
    const bucket = decodeURIComponent(rest.slice(0, slash));
    const key = rest.slice(slash + 1).split("/").map(decodeURIComponent).join("/");
    if (!ALLOWED_TYPES[bucket] && !BUCKET_LIMITS[bucket]) return null;
    if (!safeKey(key)) return null;
    return { bucket, key };
  } catch {
    return null;
  }
}

function xmlValue(block, tag) {
  const match = block.match(new RegExp(`<${tag}>([\\s\\S]*?)</${tag}>`));
  return match ? match[1] : "";
}

function decodeXml(value) {
  return value.replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, '"').replace(/&#39;/g, "'");
}

function disposition(name) {
  const fallback = String(name || "download").replace(/[^A-Za-z0-9._-]+/g, "-").slice(0, 120) || "download";
  return `attachment; filename="${fallback}"; filename*=UTF-8''${encodeURIComponent(name || fallback)}`;
}

// ── Routes ──────────────────────────────────────────────────────────────────

async function handleBlob(request, env, url) {
  if (url.pathname === `${BLOB_PREFIX}health`) {
    return json({ enabled: Boolean(b2Config(env)) });
  }

  const config = b2Config(env);
  if (!config) return json({ error: "Blob storage is not configured." }, 503);

  if (url.pathname === `${BLOB_PREFIX}sign` && request.method === "POST") {
    const user = await verifyUser(request, env);
    if (!user) return json({ error: "Sign in again to open this file." }, 401);
    const body = await request.json().catch(() => null);
    const bucket = body && body.bucket;
    const key = body && body.key;
    if (!bucket || !BUCKET_LIMITS[bucket] || !safeKey(key)) return json({ error: "Unknown file." }, 400);
    if (!(await authorized(env, user, "read", bucket, key))) return json({ error: "You do not have access to this file." }, 403);
    const seconds = Math.min(Math.max(Number(body.expires) || 600, 60), 3600);
    const expires = Math.floor(Date.now() / 1000) + seconds;
    const signature = await downloadToken(env, bucket, key, expires);
    const params = new URLSearchParams({ exp: String(expires), sig: signature });
    if (body.download) params.set("download", "1");
    if (body.name) params.set("name", String(body.name).slice(0, 160));
    return json({ url: `${BLOB_PREFIX}${encodeURIComponent(bucket)}/${key.split("/").map(encodeURIComponent).join("/")}?${params}` });
  }

  if (url.pathname === `${BLOB_PREFIX}move` && request.method === "POST") {
    const user = await verifyUser(request, env);
    if (!user) return json({ error: "Sign in again to move this file." }, 401);
    const body = await request.json().catch(() => null);
    const bucket = body && body.bucket;
    const from = body && body.from;
    const to = body && body.to;
    if (!bucket || !BUCKET_LIMITS[bucket] || !safeKey(from) || !safeKey(to)) return json({ error: "Unknown file." }, 400);
    if (!(await authorized(env, user, "move", bucket, from))) return json({ error: "You do not have access to this file." }, 403);
    if (!(await authorized(env, user, "move", bucket, to))) return json({ error: "You cannot move the file there." }, 403);
    const copySigned = await signB2(env, "PUT", to, { copySource: `/${config.bucket}/${encodeKey(from)}` });
    const copy = await fetch(copySigned.url, { method: "PUT", headers: copySigned.headers });
    if (!copy.ok) return json({ error: "The file could not be moved." }, 502);
    const removeSigned = await signB2(env, "DELETE", from);
    const removed = await fetch(removeSigned.url, { method: "DELETE", headers: removeSigned.headers });
    if (!removed.ok && removed.status !== 404) return json({ error: "The file was copied but the old copy could not be removed." }, 502);
    return json({ ok: true });
  }

  if (url.pathname === `${BLOB_PREFIX}list` && request.method === "GET") {
    const user = await verifyUser(request, env);
    if (!user) return json({ error: "Sign in again to list files." }, 401);
    const bucket = url.searchParams.get("bucket") || "";
    const prefix = url.searchParams.get("prefix") || "";
    if (!BUCKET_LIMITS[bucket] || !safeKey(prefix.replace(/\/$/, ""))) return json({ error: "Unknown folder." }, 400);
    const cleanPrefix = prefix.endsWith("/") ? prefix : `${prefix}/`;
    if (!(await authorized(env, user, "list", bucket, cleanPrefix))) return json({ error: "You do not have access to this folder." }, 403);
    const listSigned = await signB2(env, "GET", "", {
      query: { "list-type": "2", prefix: `aoh/${bucket}/${cleanPrefix}`, "max-keys": "1000" },
    });
    const response = await fetch(listSigned.url, { method: "GET", headers: listSigned.headers });
    if (!response.ok) return json({ error: "The folder could not be listed." }, 502);
    const xml = await response.text();
    const objects = [...xml.matchAll(/<Contents>([\s\S]*?)<\/Contents>/g)].map((match) => ({
      key: decodeXml(xmlValue(match[1], "Key")).replace(`aoh/${bucket}/`, ""),
      size: Number(xmlValue(match[1], "Size")) || 0,
      lastModified: xmlValue(match[1], "LastModified"),
    }));
    return json({ objects });
  }

  const route = parseBlobPath(url.pathname);
  if (!route) return json({ error: "Not found." }, 404);
  const { bucket, key } = route;

  if (request.method === "PUT") {
    const user = await verifyUser(request, env);
    if (!user) return json({ error: "Sign in again to upload this file." }, 401);
    if (!(await authorized(env, user, "upload", bucket, key))) return json({ error: "You cannot upload this file." }, 403);
    const limit = BUCKET_LIMITS[bucket];
    const contentType = (request.headers.get("content-type") || "application/octet-stream").split(";")[0].trim().toLowerCase();
    const types = ALLOWED_TYPES[bucket];
    if (types && !types.includes(contentType)) return json({ error: "This file format is not allowed here." }, 415);
    const announced = Number(request.headers.get("content-length") || 0);
    if (announced > limit) return json({ error: "This file is too large." }, 413);
    const body = await request.arrayBuffer();
    if (body.byteLength > limit) return json({ error: "This file is too large." }, 413);
    const signed = await signB2(env, "PUT", key, {
      payloadHash: await sha256Hex(body),
      contentType,
    });
    const response = await fetch(signed.url, { method: "PUT", headers: signed.headers, body });
    if (!response.ok) {
      console.error("b2 put", response.status, await response.text().catch(() => ""));
      return json({ error: "The file could not be saved." }, 502);
    }
    return json({ ok: true, path: `b2:${bucket}/${key}` });
  }

  if (request.method === "GET") {
    const expires = Number(url.searchParams.get("exp") || 0);
    const signature = url.searchParams.get("sig") || "";
    if (!expires || expires < Math.floor(Date.now() / 1000)) return json({ error: "This link has expired." }, 401);
    const expected = await downloadToken(env, bucket, key, expires);
    if (!signature || !sameSignature(signature, expected)) return json({ error: "This link is not valid." }, 401);
    const getSigned = await signB2(env, "GET", key);
    const response = await fetch(getSigned.url, { method: "GET", headers: getSigned.headers });
    if (!response.ok) return json({ error: "The file is unavailable." }, response.status === 404 ? 404 : 502);
    const headers = new Headers();
    const contentType = (response.headers.get("content-type") || "application/octet-stream")
      .split(";")[0].trim().toLowerCase();
    headers.set("content-type", contentType);
    const length = response.headers.get("content-length");
    if (length) headers.set("content-length", length);
    headers.set("cache-control", "private, max-age=300");
    headers.set("x-content-type-options", "nosniff");
    headers.set("cross-origin-resource-policy", "same-site");
    // Even if a user-controlled file is served inline, it cannot run script or
    // be embedded as a first-party document.
    headers.set("content-security-policy", "default-src 'none'; sandbox");
    const wantsDownload = url.searchParams.get("download") === "1";
    if (wantsDownload || !INLINE_TYPES.has(contentType)) {
      headers.set("content-disposition", disposition(url.searchParams.get("name") || key.split("/").pop()));
    }
    return new Response(response.body, { status: 200, headers });
  }

  if (request.method === "DELETE") {
    const user = await verifyUser(request, env);
    if (!user) return json({ error: "Sign in again to delete this file." }, 401);
    if (!(await authorized(env, user, "delete", bucket, key))) return json({ error: "You cannot delete this file." }, 403);
    const deleteSigned = await signB2(env, "DELETE", key);
    const response = await fetch(deleteSigned.url, { method: "DELETE", headers: deleteSigned.headers });
    if (!response.ok && response.status !== 404) return json({ error: "The file could not be deleted." }, 502);
    return json({ ok: true });
  }

  return json({ error: "Method not allowed." }, 405);
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname.startsWith(BLOB_PREFIX)) {
      try {
        return await handleBlob(request, env, url);
      } catch (error) {
        console.error("blob api", error);
        return json({ error: "File storage is temporarily unavailable." }, 500);
      }
    }

    // Assets and prerendered pages first — the platform binding is the static build.
    const asset = await env.ASSETS.fetch(request);
    if (asset.status !== 404 || FILE_EXT.test(url.pathname)) return withHeaders(asset, url);

    if (request.method !== "GET" && request.method !== "HEAD") return withHeaders(asset, url);

    // Unknown paths get a real 404 (no soft-404 home page), so crawlers never
    // index junk URLs as duplicates of the home page.
    const route = url.pathname === "/" ? "/" : url.pathname.replace(/\/+$/, "");
    if (route !== "/" && !PUBLIC_ROUTE.test(route)) {
      return withHeaders(
        new Response(NOT_FOUND_HTML, {
          status: 404,
          headers: {
            "content-type": "text/html; charset=utf-8",
            "cache-control": "no-store",
            "x-robots-tag": "noindex",
          },
        }),
        url,
      );
    }

    // App route without a prerendered file: serve the SPA entry. Deliberately no
    // Accept-header gate — Facebook, LinkedIn, WhatsApp and other preview
    // crawlers send `Accept: */*` and must still receive the page.
    const shell = await env.ASSETS.fetch(
      new Request(new URL("/index.html", url), {
        method: "GET",
        headers: request.headers,
      }),
    );
    return withHeaders(shell, url);
  },
};
