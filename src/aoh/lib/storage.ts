import { supabase } from "@/aoh/integrations/supabase/client";
import { compressImage } from "./imagePerf";
import { newId, newUuid } from "./ids";
import { blobEnabled, blobPathFor, deleteBlob, isBlobPath, listBlobObjects, moveBlob, parseBlobPath, putBlob, signedBlobUrl } from "./blobStore";

const MB = 1024 * 1024;

const AVATAR_BUCKET = "avatars";
const PROGRAM_IMAGE_BUCKET = "program-images";
const BUSINESS_LOGO_BUCKET = "business-logos";
const DOCUMENT_BUCKET = "documents";
const SITE_ASSETS_BUCKET = "site-assets";

export const IMAGE_TYPES = ["image/jpeg", "image/png", "image/webp", "image/gif"];
export const DOCUMENT_TYPES = [
  "application/pdf",
  "image/jpeg",
  "image/png",
  "image/webp",
  "application/msword",
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
];
export const MAX_IMAGE_BYTES = 5 * MB;
export const MAX_IMAGE_INPUT_BYTES = 15 * MB;
export const MAX_VIDEO_BYTES = 100 * MB;
export const VIDEO_TYPES = ["video/mp4", "video/webm", "video/quicktime"];
export const MAX_DOCUMENT_BYTES = 10 * MB;

export const DOCUMENT_CATEGORIES = [
  "ID card",
  "Transcript",
  "Certificate",
  "CV / Resume",
  "Passport photo",
  "Other",
] as const;
export type DocumentCategory = (typeof DOCUMENT_CATEGORIES)[number];

export interface ProfileDocument {
  path: string;
  name: string;
  category: DocumentCategory;
  size: number;
  uploadedAt: string;
}

export function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < MB) return `${(bytes / 1024).toFixed(0)} KB`;
  return `${(bytes / MB).toFixed(1)} MB`;
}

/** Returns an error message, or null when the file is acceptable. */
export function validateFile(file: File, types: string[], maxBytes: number): string | null {
  if (!types.includes(file.type)) return `"${file.name}" is not a supported file type.`;
  if (file.size > maxBytes) return `"${file.name}" is larger than ${formatBytes(maxBytes)}.`;
  return null;
}

function extension(file: File): string {
  const fromName = file.name.includes(".") ? file.name.split(".").pop() : "";
  return (fromName || file.type.split("/")[1] || "bin").toLowerCase().replace(/[^a-z0-9]/g, "");
}

/** Random id that works on http://, older browsers and Safari (no crypto.randomUUID). */
const newStorageId = newUuid;

function safeName(name: string): string {
  return name.replace(/[^A-Za-z0-9._-]+/g, "-").replace(/-+/g, "-").slice(0, 80) || "file";
}

/**
 * A missing bucket ("Bucket not found") or missing upload policies
 * ("row-level security") both mean the storage migration has not run yet.
 */
function explain(message: string): string {
  return /bucket not found|row-level security/i.test(message)
    ? "File storage is not set up yet. Ask an administrator to apply the latest database migration."
    : message;
}

async function uploadPublicImage(bucket: string, folder: string, file: File): Promise<string> {
  const typeOk = validateFile(file, IMAGE_TYPES, MAX_IMAGE_INPUT_BYTES);
  // Type is always enforced; oversize phone photos get compressed before the final size check.
  if (typeOk && !typeOk.includes("larger than")) throw new Error(typeOk);
  // Every brand mark in site-assets (logos, favicons, PWA/splash, seals,
  // signatures) keeps its alpha channel: no white plate is ever baked in.
  const folderKey = folder.toLowerCase();
  const isBrandFolder = bucket === SITE_ASSETS_BUCKET && (/^(logo|favicon|pwa|splash|certificate|seal)/.test(folderKey) || folderKey.includes("logo") || folderKey.includes("favicon") || folderKey.includes("splash") || folderKey.includes("seal") || folderKey.includes("signature"));
  const preserve = isBrandFolder || /logo|icon|splash|seal|favicon/i.test(file.name);
  const optimized = await compressImage(file, preserve ? { preserveTransparency: true } : undefined);
  const invalid = validateFile(optimized, IMAGE_TYPES, MAX_IMAGE_BYTES);
  if (invalid) throw new Error(invalid);
  const path = `${folder}/${newStorageId()}.${extension(optimized)}`;
  const { error } = await supabase.storage
    .from(bucket)
    .upload(path, optimized, { cacheControl: "31536000", upsert: false, contentType: optimized.type });
  if (error) throw new Error(explain(error.message));
  return supabase.storage.from(bucket).getPublicUrl(path).data.publicUrl;
}

/** Removes every matching object in the folder except `keepUrl`. Best effort, never throws. */
async function pruneFolder(
  bucket: string,
  folder: string,
  keepUrl?: string,
  include: (name: string) => boolean = () => true,
) {
  try {
    const { data } = await supabase.storage.from(bucket).list(folder, { limit: 100 });
    const stale = (data ?? [])
      .filter((o) => include(o.name))
      .map((o) => `${folder}/${o.name}`)
      .filter((path) => !keepUrl || !keepUrl.endsWith(path));
    // Remove in small batches so a full folder never trips provider limits.
    for (let i = 0; i < stale.length; i += 50) {
      const batch = stale.slice(i, i + 50);
      if (batch.length) await supabase.storage.from(bucket).remove(batch);
    }
  } catch {
    /* stale files are harmless */
  }
}

/** Uploads a new profile photo and returns its public URL. */
export const uploadAvatar = (userId: string, file: File) =>
  uploadPublicImage(AVATAR_BUCKET, userId, file);

/**
 * Call after the profile row is saved so the previous photos can go.
 * Group photos share the avatars bucket under `<uid>/group-…`; only profile
 * photos may be pruned or changing an avatar would break every group chat.
 */
export const pruneAvatars = (userId: string, keepUrl?: string) =>
  pruneFolder(AVATAR_BUCKET, userId, keepUrl, (name) => !/^(group|chat)-/i.test(name));

export const uploadProgramImage = (programId: string, file: File) =>
  uploadPublicImage(PROGRAM_IMAGE_BUCKET, programId, file);

/**
 * Alumni-business logos submitted from the public Campus Life form. They cannot
 * use site-assets (staff-only writes), so they get their own public bucket that
 * anonymous submissions may insert into (see the business_logos_* policies).
 */
export const uploadBusinessLogo = (file: File) =>
  uploadPublicImage(BUSINESS_LOGO_BUCKET, "businesses", file);

export const pruneProgramImages = (programId: string, keepUrl?: string) =>
  pruneFolder(PROGRAM_IMAGE_BUCKET, programId, keepUrl);

/** Uploads a CMS image (logo, favicon, hero slide, section photo…) and returns its public URL. */
export const uploadSiteAsset = (folder: string, file: File) =>
  uploadPublicImage(SITE_ASSETS_BUCKET, folder, file);

/** Deletes superseded brand/site files in a folder, keeping only `keepUrl`. Best effort, never throws. */
export const pruneSiteAssets = (folder: string, keepUrl?: string) =>
  pruneFolder(SITE_ASSETS_BUCKET, folder, keepUrl);

export const uploadAuthBackground = (folder: string, file: File) =>
  uploadPublicImage(SITE_ASSETS_BUCKET, `auth-background/${safeName(folder)}`, file);

export const pruneAuthBackground = (folder: string, keepUrl?: string) =>
  pruneFolder(SITE_ASSETS_BUCKET, `auth-background/${safeName(folder)}`, keepUrl);

// ── Personal documents (private bucket, "profiles/<uid>/<ts>__<category>__<name>") ──

const docFolder = (userId: string) => `profiles/${userId}`;
const SEP = "__";

function parseDocument(path: string, name: string, size: number, createdAt: string): ProfileDocument {
  const [stamp, rawCategory, ...rest] = name.split(SEP);
  const category = DOCUMENT_CATEGORIES.find(
    (c) => safeName(c) === rawCategory,
  ) ?? "Other";
  const ts = Number(stamp);
  return {
    path,
    name: rest.length ? rest.join(SEP) : name,
    category,
    size,
    uploadedAt: Number.isFinite(ts) && ts > 0 ? new Date(ts).toISOString() : createdAt,
  };
}

export async function listDocuments(userId: string): Promise<ProfileDocument[]> {
  const folder = docFolder(userId);
  const result: ProfileDocument[] = [];
  for (let offset = 0; ; offset += 100) {
    const { data, error } = await supabase.storage.from(DOCUMENT_BUCKET)
      .list(folder, { limit: 100, offset, sortBy: { column: "name", order: "asc" } });
    if (error) throw new Error(explain(error.message));
    for (const item of data ?? []) {
      if (item.id && item.name !== ".emptyFolderPlaceholder") result.push(parseDocument(`${folder}/${item.name}`, item.name,
        Number((item.metadata as { size?: number } | null)?.size ?? 0), item.created_at ?? new Date().toISOString()));
    }
    if (!data || data.length < 100) break;
  }
  try {
    if (await blobEnabled()) {
      const objects = await listBlobObjects("documents", `${folder}/`);
      for (const object of objects) {
        const name = object.key.slice(folder.length + 1);
        if (!name || name.includes("/") || name === ".emptyFolderPlaceholder") continue;
        result.push(parseDocument(blobPathFor("documents", object.key), name,
          object.size, object.lastModified || new Date().toISOString()));
      }
    }
  } catch {
    /* legacy documents still list when B2 is unreachable */
  }
  const seen = new Set<string>();
  return result
    .filter((document) => (seen.has(document.path) ? false : (seen.add(document.path), true)))
    .sort((a, b) => b.uploadedAt.localeCompare(a.uploadedAt));
}

export async function uploadDocument(
  userId: string,
  file: File,
  category: DocumentCategory,
): Promise<string> {
  const invalid = validateFile(file, DOCUMENT_TYPES, MAX_DOCUMENT_BYTES);
  if (invalid) throw new Error(invalid);
  const path = `${docFolder(userId)}/${Date.now()}${SEP}${safeName(category)}${SEP}${newStorageId()}-${safeName(file.name)}`;
  if (await blobEnabled()) return putBlob("documents", path, file, file.type);
  const { error } = await supabase.storage
    .from(DOCUMENT_BUCKET)
    .upload(path, file, { contentType: file.type, upsert: false });
  if (error) throw new Error(explain(error.message));
  return path;
}

export async function documentUrl(path: string, download = false): Promise<string> {
  const name = path.split("/").pop()?.split(SEP).slice(2).join(SEP) || undefined;
  if (isBlobPath(path)) return signedBlobUrl(path, { download, name });
  const { data, error } = await supabase.storage
    .from(DOCUMENT_BUCKET)
    .createSignedUrl(path, 60 * 10, download ? { download: name ?? true } : undefined);
  if (error || !data) throw new Error(explain(error?.message ?? "Could not open the file"));
  return data.signedUrl;
}

export async function editDocument(userId: string, document: ProfileDocument, name: string, category: DocumentCategory): Promise<void> {
  const folder = docFolder(userId);
  const remote = parseBlobPath(document.path);
  const current = remote ? remote.key : document.path;
  if (!current.startsWith(`${folder}/`) || current.slice(folder.length + 1).includes("/")) throw new Error("Only your own documents may be edited.");
  if (!name.trim() || !DOCUMENT_CATEGORIES.includes(category)) throw new Error("Enter a document name and valid category.");
  const stamp = current.split("/").pop()!.split(SEP)[0];
  const path = `${folder}/${stamp}${SEP}${safeName(category)}${SEP}${safeName(name.trim())}`;
  if (path === current) return;
  if (remote) return moveBlob("documents", current, path);
  const { error } = await supabase.storage.from(DOCUMENT_BUCKET).move(document.path, path);
  if (error) throw new Error(explain(error.message));
}

export async function deleteDocument(path: string): Promise<void> {
  if (isBlobPath(path)) return deleteBlob(path);
  const { error } = await supabase.storage.from(DOCUMENT_BUCKET).remove([path]);
  if (error) throw new Error(explain(error.message));
}
