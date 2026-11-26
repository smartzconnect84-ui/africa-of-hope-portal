import { useCallback, useEffect, useState } from "react";
import { kvLoad, kvSave, type KvSaveResult } from "@/aoh/lib/portalKv";

export type BroadcastStyle = "info" | "success" | "urgent";

export interface Broadcast {
  id: string;
  title: string;
  message: string;
  /** Role names that see it. Empty = everyone signed in. */
  audience: string[];
  style: BroadcastStyle;
  active: boolean;
  /** ISO strings; empty means no limit. */
  startsAt: string;
  endsAt: string;
  /** Show again on every visit instead of once per person. */
  repeat: boolean;
  buttonLabel: string;
  buttonLink: string;
  createdAt: string;
}

const KEY = "broadcasts";
const CHANGE = "aoh:broadcasts-changed";

export function newBroadcast(): Broadcast {
  return {
    id: `bc-${Date.now().toString(36)}`,
    title: "",
    message: "",
    audience: [],
    style: "info",
    active: true,
    startsAt: "",
    endsAt: "",
    repeat: false,
    buttonLabel: "",
    buttonLink: "",
    createdAt: new Date().toISOString(),
  };
}

export function isBroadcastLive(b: Broadcast, role: string, now = Date.now()): boolean {
  if (!b.active) return false;
  if (b.audience.length > 0 && !b.audience.includes(role)) return false;
  if (b.startsAt && Date.parse(b.startsAt) > now) return false;
  if (b.endsAt && Date.parse(b.endsAt) < now) return false;
  return true;
}

export function useBroadcasts(pollMs = 30000) {
  const [items, setItems] = useState<Broadcast[]>([]);
  const [loading, setLoading] = useState(true);

  const reload = useCallback(async () => {
    const list = await kvLoad<Broadcast[]>(KEY, []);
    setItems(Array.isArray(list) ? list : []);
    setLoading(false);
  }, []);

  useEffect(() => {
    void reload();
    const timer = window.setInterval(() => void reload(), pollMs);
    const onChange = () => void reload();
    const onFocus = () => void reload();
    window.addEventListener(CHANGE, onChange);
    window.addEventListener("focus", onFocus);
    return () => {
      window.clearInterval(timer);
      window.removeEventListener(CHANGE, onChange);
      window.removeEventListener("focus", onFocus);
    };
  }, [reload, pollMs]);

  return { items, loading, reload };
}

export async function saveBroadcasts(list: Broadcast[]): Promise<KvSaveResult> {
  const result = await kvSave(KEY, list);
  window.dispatchEvent(new Event(CHANGE));
  return result;
}

const SEEN = "aoh-broadcast-seen:";
export function hasSeenBroadcast(userId: string, id: string): boolean {
  try {
    return localStorage.getItem(`${SEEN}${userId}:${id}`) === "1";
  } catch {
    return false;
  }
}
export function markBroadcastSeen(userId: string, id: string) {
  try {
    localStorage.setItem(`${SEEN}${userId}:${id}`, "1");
  } catch {
    /* ignore */
  }
}
