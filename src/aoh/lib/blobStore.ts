// Private school files can live in Backblaze B2 (new uploads) while older
// files remain in Supabase Storage. A stored path is either the legacy bucket
// path ("cohort/id/file.pdf") or a B2 path ("b2:training-materials/…").
//
// Every B2 request goes through /api/blob on this origin. The Worker verifies
// the Supabase session, asks the database (blob_authorize) whether this user
// may touch this object, and only then signs the B2 request. No B2 credential
// ever reaches the browser.
import { SUPABASE_ANON_KEY, supabase } from "@/aoh/integrations/supabase/client";

export type BlobBucket =
  | "training-materials"
  | "classwork-submissions"
  | "documents"
  | "chat-attachments"
  | "transparency-reports";

export const BLOB_BUCKETS: BlobBucket[] = [
  "training-materials",
  "classwork-submissions",
  "documents",
  "chat-attachments",
  "transparency-reports",
];

const B2_PREFIX = "b2:";

export function isBlobPath(path: string | null | undefined): path is string {
  return Boolean(path && path.startsWith(B2_PREFIX));
}

export function blobPathFor(bucket: BlobBucket, key: string): string {
  return `${B2_PREFIX}${bucket}/${key}`;
}

export function parseBlobPath(path: string): { bucket: BlobBucket; key: string } | null {
  if (!isBlobPath(path)) return null;
  const rest = path.slice(B2_PREFIX.length);
  const slash = rest.indexOf("/");
  if (slash < 1) return null;
  const bucket = rest.slice(0, slash) as BlobBucket;
  const key = rest.slice(slash + 1);
  if (!BLOB_BUCKETS.includes(bucket) || !key) return null;
  return { bucket, key };
}

async function authHeaders(): Promise<Record<string, string>> {
  const { data } = await supabase.auth.getSession();
  const token = data.session?.access_token;
  if (!token) throw new Error("Sign in again to use file storage.");
  // The anon key is public (it ships in the app bundle); the Worker needs it
  // for Supabase's API gateway and never gains extra privileges from it.
  return { authorization: `Bearer ${token}`, "x-supabase-anon-key": SUPABASE_ANON_KEY };
}

let mode: Promise<boolean> | null = null;

/** True when the Worker has B2 + Supabase configuration; cached for a minute. */
export function blobEnabled(): Promise<boolean> {
  if (!mode) {
    mode = (async () => {
      try {
        const response = await fetch("/api/blob/health", { headers: { accept: "application/json" } });
        if (!response.ok) return false;
        const body = (await response.json()) as { enabled?: boolean };
        return body?.enabled === true;
      } catch {
        return false;
      }
    })().then((enabled) => {
      if (!enabled) setTimeout(() => { mode = null; }, 60_000);
      return enabled;
    });
  }
  return mode;
}

function encodeKey(key: string): string {
  return key.split("/").map(encodeURIComponent).join("/");
}

async function messageFor(response: Response): Promise<string> {
  try {
    const body = (await response.json()) as { error?: string };
    if (body?.error) return body.error;
  } catch {
    /* not JSON */
  }
  if (response.status === 401) return "Sign in again to use file storage.";
  if (response.status === 403) return "You do not have permission to use this file.";
  if (response.status === 413) return "This file is too large.";
  return "File storage is temporarily unavailable. Please retry.";
}

/** Uploads bytes and returns the stored `b2:` path. */
export async function putBlob(
  bucket: BlobBucket,
  key: string,
  data: Blob,
  contentType?: string,
): Promise<string> {
  const response = await fetch(`/api/blob/${bucket}/${encodeKey(key)}`, {
    method: "PUT",
    headers: {
      ...(await authHeaders()),
      "content-type": contentType || (data instanceof File ? data.type : "") || "application/octet-stream",
    },
    body: data,
  });
  if (!response.ok) throw new Error(await messageFor(response));
  return blobPathFor(bucket, key);
}

/** Deletes a B2 object. */
export async function deleteBlob(path: string): Promise<void> {
  const parsed = parseBlobPath(path);
  if (!parsed) throw new Error("Unknown file.");
  const response = await fetch(`/api/blob/${parsed.bucket}/${encodeKey(parsed.key)}`, {
    method: "DELETE",
    headers: await authHeaders(),
  });
  if (!response.ok) throw new Error(await messageFor(response));
}

/** Short-lived same-origin URL for a private B2 object. */
export async function signedBlobUrl(
  path: string,
  options: { download?: boolean; name?: string; expires?: number } = {},
): Promise<string> {
  const parsed = parseBlobPath(path);
  if (!parsed) throw new Error("Unknown file.");
  const response = await fetch("/api/blob/sign", {
    method: "POST",
    headers: { ...(await authHeaders()), "content-type": "application/json" },
    body: JSON.stringify({
      bucket: parsed.bucket,
      key: parsed.key,
      download: Boolean(options.download),
      name: options.name,
      expires: options.expires ?? 600,
    }),
  });
  if (!response.ok) throw new Error(await messageFor(response));
  const body = (await response.json()) as { url?: string };
  if (!body.url) throw new Error("Could not open this file.");
  return body.url;
}

/** Lists objects under a folder, returning keys relative to the bucket. */
export async function listBlobObjects(
  bucket: BlobBucket,
  prefix: string,
): Promise<{ key: string; size: number; lastModified: string }[]> {
  const response = await fetch(
    `/api/blob/list?bucket=${encodeURIComponent(bucket)}&prefix=${encodeURIComponent(prefix)}`,
    { headers: { ...(await authHeaders()), accept: "application/json" } },
  );
  if (!response.ok) throw new Error(await messageFor(response));
  const body = (await response.json()) as { objects?: { key: string; size: number; lastModified: string }[] };
  return body.objects ?? [];
}

/** Renames/moves an object inside one bucket. */
export async function moveBlob(bucket: BlobBucket, from: string, to: string): Promise<void> {
  const response = await fetch("/api/blob/move", {
    method: "POST",
    headers: { ...(await authHeaders()), "content-type": "application/json" },
    body: JSON.stringify({ bucket, from, to }),
  });
  if (!response.ok) throw new Error(await messageFor(response));
}
