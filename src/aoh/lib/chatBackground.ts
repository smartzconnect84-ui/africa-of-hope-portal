import { supabase } from "@/aoh/integrations/supabase/client";
import { kvLoad, kvSave } from "@/aoh/lib/portalKv";
import { uploadGroupBackground } from "@/aoh/lib/chat";
import { imageToJpegFile } from "@/aoh/lib/imageResize";

interface Target {
  kind: "dm" | "group";
  peerId?: string;
  groupId?: string;
}

/** Direct chats share one wallpaper between both people; groups keep it on the group. */
export const dmBackgroundKey = (a: string, b: string) => `chat-bg-dm:${[a, b].sort().join(":")}`;

export async function loadDmBackground(meId: string, peerId: string): Promise<string> {
  return kvLoad<string>(dmBackgroundKey(meId, peerId), "");
}

export async function setChatBackground(target: Target, meId: string, file: File): Promise<string> {
  const small = await imageToJpegFile(file);
  if (target.kind === "group" && target.groupId) return uploadGroupBackground(target.groupId, small);
  if (!target.peerId) throw new Error("Open a chat first.");
  const path = `${meId}/chat-bg-dm-${Date.now()}-${Math.random().toString(36).slice(2, 8)}.jpg`;
  const { error } = await supabase.storage.from("site-assets").upload(path, small, { contentType: "image/jpeg", cacheControl: "3600" });
  if (error) throw error;
  const url = supabase.storage.from("site-assets").getPublicUrl(path).data?.publicUrl;
  if (!url) throw new Error("Could not get the background link.");
  const saved = await kvSave(dmBackgroundKey(meId, target.peerId), url);
  if (!saved.shared) throw new Error(saved.error ?? "The shared background could not be saved. Run the portal_kv database script.");
  return url;
}

export async function clearChatBackground(target: Target, meId: string): Promise<void> {
  if (target.kind === "group" && target.groupId) {
    const { error } = await supabase.from("chat_groups").update({ background_url: null }).eq("id", target.groupId);
    if (error) throw error;
    return;
  }
  if (!target.peerId) return;
  const saved = await kvSave(dmBackgroundKey(meId, target.peerId), "");
  if (!saved.shared) throw new Error(saved.error ?? "Could not clear the background.");
}
