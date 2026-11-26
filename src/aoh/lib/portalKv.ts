import { supabase } from "@/aoh/integrations/supabase/client";

/**
 * Small key/value store for editable portal content (document templates,
 * broadcast messages, guides). Reads and writes the `portal_kv` table when it
 * exists; always mirrors to this browser so editing never loses work.
 */
const PREFIX = "aoh-kv:";

function readLocal<T>(key: string, fallback: T): T {
  try {
    const raw = localStorage.getItem(PREFIX + key);
    return raw ? (JSON.parse(raw) as T) : fallback;
  } catch {
    return fallback;
  }
}

function writeLocal(key: string, value: unknown) {
  try {
    localStorage.setItem(PREFIX + key, JSON.stringify(value));
  } catch {
    /* storage full or blocked */
  }
}

export async function kvLoad<T>(key: string, fallback: T): Promise<T> {
  try {
    const { data, error } = await supabase.from("portal_kv").select("value").eq("key", key).maybeSingle();
    if (!error && data && data.value != null) {
      writeLocal(key, data.value);
      return data.value as T;
    }
  } catch {
    /* table missing or offline: use the local copy */
  }
  return readLocal(key, fallback);
}

export interface KvSaveResult {
  /** true when the shared database accepted the change */
  shared: boolean;
  error?: string;
}

export async function kvSave(key: string, value: unknown): Promise<KvSaveResult> {
  writeLocal(key, value);
  try {
    const { data: auth } = await supabase.auth.getUser();
    const { error } = await supabase
      .from("portal_kv")
      .upsert({ key, value, updated_by: auth.user?.id ?? null, updated_at: new Date().toISOString() }, { onConflict: "key" });
    if (error) return { shared: false, error: error.message };
    return { shared: true };
  } catch (err) {
    return { shared: false, error: err instanceof Error ? err.message : "Could not reach the database." };
  }
}
