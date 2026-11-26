import { useEffect, useState } from "react";

export const TRANSLATE_LANGUAGES: { code: string; label: string }[] = [
  { code: "en", label: "English" },
  { code: "fr", label: "Français" },
  { code: "es", label: "Español" },
  { code: "pt", label: "Português" },
  { code: "ar", label: "العربية" },
  { code: "sw", label: "Kiswahili" },
  { code: "ha", label: "Hausa" },
  { code: "yo", label: "Yorùbá" },
  { code: "ig", label: "Igbo" },
  { code: "am", label: "አማርኛ" },
  { code: "zu", label: "isiZulu" },
  { code: "de", label: "Deutsch" },
  { code: "zh-CN", label: "中文" },
  { code: "hi", label: "हिन्दी" },
];

const PREF = "aoh-translate-pref";
const CHANGE = "aoh:translate-pref";
const cache = new Map<string, string>();

export interface TranslatePref {
  /** Language messages are translated into. */
  target: string;
  /** Translate incoming messages without tapping each one. */
  auto: boolean;
}

export function getTranslatePref(): TranslatePref {
  try {
    const raw = localStorage.getItem(PREF);
    if (raw) return { target: "en", auto: false, ...(JSON.parse(raw) as Partial<TranslatePref>) };
  } catch {
    /* ignore */
  }
  return { target: "en", auto: false };
}

export function setTranslatePref(next: Partial<TranslatePref>) {
  try {
    localStorage.setItem(PREF, JSON.stringify({ ...getTranslatePref(), ...next }));
  } catch {
    /* ignore */
  }
  window.dispatchEvent(new Event(CHANGE));
}

export function useTranslatePref(): TranslatePref {
  const [pref, setPref] = useState<TranslatePref>(getTranslatePref);
  useEffect(() => {
    const on = () => setPref(getTranslatePref());
    window.addEventListener(CHANGE, on);
    return () => window.removeEventListener(CHANGE, on);
  }, []);
  return pref;
}

/** Translate text into `target` (source language is detected). Throws on failure. */
export async function translateText(text: string, target: string): Promise<string> {
  const clean = text.trim().slice(0, 480);
  if (!clean) return "";
  const key = `${target}|${clean}`;
  const hit = cache.get(key);
  if (hit) return hit;
  const url = `https://api.mymemory.translated.net/get?q=${encodeURIComponent(clean)}&langpair=${encodeURIComponent(`autodetect|${target}`)}`;
  const res = await fetch(url);
  if (!res.ok) throw new Error("Translation service is unavailable. Try again shortly.");
  const json = (await res.json()) as { responseData?: { translatedText?: string }; responseStatus?: number };
  const out = json.responseData?.translatedText;
  if (!out || (json.responseStatus && json.responseStatus !== 200)) throw new Error("This message could not be translated.");
  cache.set(key, out);
  return out;
}
