import { useMemo } from "react";
import { Megaphone } from "lucide-react";
import { useApp } from "@/aoh/context/AppContext";
import Marquee from "@/aoh/components/animata/container/marquee";
import type { Announcement } from "@/aoh/types";

function visibleTo(a: Announcement, role: string, now: number): boolean {
  if ((a.status ?? "published") !== "published") return false;
  if (a.scheduledAt && new Date(a.scheduledAt).getTime() > now) return false;
  if (a.expiresAt && new Date(a.expiresAt).getTime() < now) return false;
  const audience = a.audience ?? "all";
  if (audience === "students") return role === "Student" || role !== "Teacher";
  if (audience === "teachers") return role !== "Student";
  return true;
}

/** Scrolling strip of live announcements at the top of the portal. */
export default function PortalAnnouncementTicker({ onOpen }: { onOpen: () => void }) {
  const { state, currentUser } = useApp();
  const role = currentUser?.role ?? "Student";

  const items = useMemo(() => {
    const now = Date.now();
    const list = state.announcements
      .filter((a) => visibleTo(a, role, now))
      .map((a) => ({ id: a.id, urgent: a.category === "Urgent", text: a.title }));
    const site = state.websiteSettings;
    if (site.announcementEnabled && site.announcementText?.trim()) {
      list.push({ id: "site-banner", urgent: false, text: site.announcementText.trim() });
    }
    return list;
  }, [state.announcements, state.websiteSettings, role]);

  if (items.length === 0) return null;

  return (
    <button
      type="button"
      onClick={onOpen}
      aria-label="Open announcements"
      className="mb-4 flex w-full items-center gap-2 overflow-hidden rounded-xl bg-amber-400 px-3 py-2 text-left text-emerald-950 shadow-sm"
    >
      <Megaphone className="h-4 w-4 shrink-0" aria-hidden="true" />
      <span className="sr-only" aria-live="polite">{items.map((i) => i.text).join(". ")}</span>
      <Marquee
        repeat={2}
        pauseOnHover
        applyMask={false}
        className="min-w-0 flex-1 overflow-hidden p-0 text-xs font-semibold [--duration:40s] [--gap:3rem]"
      >
        {items.map((item) => (
          <span key={item.id} className="whitespace-nowrap" aria-hidden="true">
            {item.urgent ? "URGENT: " : ""}{item.text}
          </span>
        ))}
      </Marquee>
    </button>
  );
}
