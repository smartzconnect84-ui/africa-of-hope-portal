import { useEffect, useRef, useState } from "react";
import { Bell, CheckCheck, Loader2 } from "lucide-react";
import { useKnock, useKnockFeedState } from "./KnockProviderShell";

function plain(html: string): string {
  return html.replace(/<[^>]+>/g, " ").replace(/&nbsp;/g, " ").replace(/\s+/g, " ").trim();
}

interface FeedItem {
  id: string;
  read_at: string | null;
  inserted_at: string;
  data?: Record<string, unknown> | null;
  blocks?: { name: string; rendered?: string }[];
  source?: { key?: string };
}

function itemText(item: FeedItem): { title: string; body: string } {
  const body = item.blocks?.find((b) => b.name === "body")?.rendered;
  const head = item.blocks?.find((b) => b.name === "title" || b.name === "headline")?.rendered;
  const data = item.data ?? {};
  return {
    title: plain(head ?? String(data.title ?? item.source?.key ?? "Notification")),
    body: plain(body ?? String(data.message ?? "")),
  };
}

export default function KnockNotificationBell() {
  const ctx = useKnock();
  const state = useKnockFeedState(ctx?.feed);
  const [open, setOpen] = useState(false);
  const box = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && setOpen(false);
    const onClick = (e: MouseEvent) => { if (box.current && !box.current.contains(e.target as Node)) setOpen(false); };
    window.addEventListener("keydown", onKey);
    window.addEventListener("mousedown", onClick);
    return () => { window.removeEventListener("keydown", onKey); window.removeEventListener("mousedown", onClick); };
  }, [open]);

  if (!ctx) return null;
  const items = (state?.items ?? []) as unknown as FeedItem[];
  const unread = state?.metadata?.unread_count ?? 0;
  const hasMore = Boolean(state?.pageInfo?.after);
  const loading = state?.networkStatus === "loading" || state?.networkStatus === "fetchMore";

  return (
    <div ref={box} className="relative">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        aria-label={unread > 0 ? `Notifications, ${unread} unread` : "Notifications"}
        aria-expanded={open}
        className="relative grid h-10 w-10 place-items-center rounded-xl text-white transition hover:bg-white/10"
      >
        <Bell className="h-5 w-5" />
        {unread > 0 && (
          <span className="absolute -right-0.5 -top-0.5 grid h-5 min-w-[20px] place-items-center rounded-full bg-amber-500 px-1 text-[11px] font-bold text-black ring-2 ring-white">
            {unread > 9 ? "9+" : unread}
          </span>
        )}
      </button>
      {open && (
        <div role="dialog" aria-label="Notifications" className="fixed inset-x-3 top-16 z-50 max-h-[70vh] overflow-hidden rounded-2xl border border-slate-200 bg-white text-slate-800 shadow-2xl sm:absolute sm:inset-x-auto sm:right-0 sm:top-12 sm:w-96">
          <div className="flex items-center justify-between border-b border-slate-100 px-4 py-3">
            <p className="text-sm font-semibold">Notifications</p>
            <button type="button" disabled={unread === 0} onClick={() => void ctx.feed.markAllAsRead()} className="inline-flex items-center gap-1 text-xs font-medium text-emerald-700 disabled:opacity-40">
              <CheckCheck className="h-3.5 w-3.5" /> Mark all read
            </button>
          </div>
          <ul className="max-h-[56vh] divide-y divide-slate-100 overflow-y-auto">
            {items.length === 0 && !loading && <li className="px-4 py-8 text-center text-sm text-slate-500">You are all caught up.</li>}
            {items.map((item) => {
              const { title, body } = itemText(item);
              return (
                <li key={item.id}>
                  <button type="button" onClick={() => !item.read_at && void ctx.feed.markAsRead(item as never)} className={`block w-full px-4 py-3 text-left hover:bg-emerald-50 ${item.read_at ? "" : "bg-emerald-50/50"}`}>
                    <span className="flex items-start gap-2">
                      {!item.read_at && <span className="mt-1.5 h-2 w-2 shrink-0 rounded-full bg-amber-500" aria-label="Unread" />}
                      <span className="min-w-0">
                        <span className="block text-sm font-medium">{title}</span>
                        {body && <span className="mt-0.5 line-clamp-2 block text-xs text-slate-600">{body}</span>}
                        <span className="mt-1 block text-[11px] text-slate-400">{new Date(item.inserted_at).toLocaleString()}</span>
                      </span>
                    </span>
                  </button>
                </li>
              );
            })}
            {loading && <li className="grid place-items-center py-4"><Loader2 className="h-4 w-4 animate-spin text-slate-400" /></li>}
          </ul>
          {hasMore && !loading && (
            <button type="button" onClick={() => void ctx.feed.fetchNextPage()} className="w-full border-t border-slate-100 py-2.5 text-xs font-medium text-emerald-700 hover:bg-emerald-50">
              Load older notifications
            </button>
          )}
        </div>
      )}
    </div>
  );
}
