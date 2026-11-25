import { useEffect, useState } from "react";
import { BellRing } from "lucide-react";
import { toast } from "sonner";
import { useKnock } from "./KnockProviderShell";
import { isKnockConfigured } from "@/aoh/lib/knock";
import { Switch } from "@/aoh/components/ui/switch";
import { panelClass, SectionHeader } from "../Navigation";

const CHANNELS = [
  { key: "in_app_feed", label: "In-app notifications", hint: "The bell in the portal header." },
  { key: "email", label: "Email", hint: "Messages to your registered email address." },
  { key: "push", label: "Push notifications", hint: "Alerts on this phone or browser." },
  { key: "sms", label: "SMS", hint: "Text messages, where the school has switched them on." },
] as const;

const CATEGORIES = [
  { key: "system", label: "School announcements and maintenance" },
  { key: "messages", label: "Messages, replies and mentions" },
  { key: "learning", label: "Courses, materials, assessments and certificates" },
  { key: "reminders", label: "Training reminders" },
] as const;

type Prefs = { channel_types?: Record<string, boolean>; categories?: Record<string, boolean | { channel_types?: Record<string, boolean> }> };

function Body() {
  const ctx = useKnock();
  const knock = ctx!.knock;
  const [prefs, setPrefs] = useState<Prefs>({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let live = true;
    (async () => {
      try {
        const current = (await knock.user.getPreferences()) as unknown as Prefs;
        if (live) setPrefs(current ?? {});
      } catch { toast.error("Could not load your notification settings."); }
      finally { if (live) setLoading(false); }
    })();
    return () => { live = false; };
  }, [knock]);

  async function save(next: Prefs) {
    const before = prefs;
    setPrefs(next);
    try {
      await knock.user.setPreferences(next as never);
    } catch {
      setPrefs(before);
      toast.error("Your settings could not be saved. Please try again.");
    }
  }

  const channelOn = (k: string) => prefs.channel_types?.[k] !== false;
  const categoryOn = (k: string) => {
    const v = prefs.categories?.[k];
    return typeof v === "boolean" ? v : true;
  };

  return (
    <div className="space-y-4">
      <div className={`${panelClass} p-5`}>
        <h3 className="text-sm font-semibold text-slate-800">Where to reach you</h3>
        <ul className="mt-3 divide-y divide-slate-100">
          {CHANNELS.map((c) => (
            <li key={c.key} className="flex items-center justify-between gap-4 py-3">
              <div>
                <p className="text-sm font-medium text-slate-800">{c.label}</p>
                <p className="text-xs text-slate-500">{c.hint}</p>
              </div>
              <Switch
                aria-label={c.label}
                disabled={loading}
                checked={channelOn(c.key)}
                onCheckedChange={(on) => void save({ ...prefs, channel_types: { ...prefs.channel_types, [c.key]: on } })}
              />
            </li>
          ))}
        </ul>
      </div>
      <div className={`${panelClass} p-5`}>
        <h3 className="text-sm font-semibold text-slate-800">What to send</h3>
        <ul className="mt-3 divide-y divide-slate-100">
          {CATEGORIES.map((c) => (
            <li key={c.key} className="flex items-center justify-between gap-4 py-3">
              <p className="text-sm font-medium text-slate-800">{c.label}</p>
              <Switch
                aria-label={c.label}
                disabled={loading}
                checked={categoryOn(c.key)}
                onCheckedChange={(on) => void save({ ...prefs, categories: { ...prefs.categories, [c.key]: on } })}
              />
            </li>
          ))}
        </ul>
        <p className="mt-3 text-xs text-slate-500">
          Account and security notices, such as a password change or a new sign-in, are always delivered.
        </p>
      </div>
    </div>
  );
}

export default function NotificationPreferences() {
  const available = isKnockConfigured() && Boolean(useKnock());
  return (
    <div className="space-y-5">
      <SectionHeader title="Notification settings" subtitle="Choose how and when the school contacts you." />
      {available ? (
        <Body />
      ) : (
        <div className={`${panelClass} flex items-start gap-3 p-5 text-sm text-slate-600`}>
          <BellRing className="mt-0.5 h-5 w-5 shrink-0 text-emerald-700" />
          <p>Notification settings will appear here once the school connects its Knock notification account.</p>
        </div>
      )}
    </div>
  );
}
