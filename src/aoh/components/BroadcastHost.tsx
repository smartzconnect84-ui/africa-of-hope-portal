import { useEffect, useMemo, useState } from "react";
import { AlertTriangle, CheckCircle2, Megaphone } from "lucide-react";
import { useApp } from "@/aoh/context/AppContext";
import { Button } from "@/aoh/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogTitle } from "@/aoh/components/ui/dialog";
import { cn } from "@/aoh/lib/utils";
import {
  hasSeenBroadcast,
  isBroadcastLive,
  markBroadcastSeen,
  useBroadcasts,
  type Broadcast,
} from "@/aoh/lib/broadcasts";

const STYLES = {
  info: { icon: Megaphone, band: "from-emerald-700 to-emerald-900", chip: "bg-emerald-100 text-emerald-900" },
  success: { icon: CheckCircle2, band: "from-teal-600 to-emerald-800", chip: "bg-teal-100 text-teal-900" },
  urgent: { icon: AlertTriangle, band: "from-rose-600 to-red-800", chip: "bg-rose-100 text-rose-900" },
} as const;

export function BroadcastPopup({
  item,
  open,
  onClose,
}: {
  item: Pick<Broadcast, "title" | "message" | "style" | "buttonLabel" | "buttonLink">;
  open: boolean;
  onClose: () => void;
}) {
  const look = STYLES[item.style] ?? STYLES.info;
  const Icon = look.icon;
  const go = () => {
    const link = item.buttonLink.trim();
    if (link) {
      if (/^https?:\/\//i.test(link)) window.open(link, "_blank", "noopener,noreferrer");
      else window.location.assign(link);
    }
    onClose();
  };
  return (
    <Dialog open={open} onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="max-h-[90dvh] w-[calc(100vw-2rem)] max-w-md gap-0 overflow-hidden p-0">
        <div className={cn("bg-gradient-to-br px-6 py-5 text-white", look.band)}>
          <span className="grid h-11 w-11 place-items-center rounded-full bg-white/15">
            <Icon className="h-5 w-5" />
          </span>
          <DialogTitle className="mt-3 break-words text-xl font-bold leading-snug text-white">
            {item.title || "Message from the school"}
          </DialogTitle>
        </div>
        <div className="space-y-5 overflow-y-auto px-6 py-5">
          <DialogDescription asChild>
            <p className="whitespace-pre-wrap break-words text-[15px] leading-7 text-slate-700">{item.message}</p>
          </DialogDescription>
          <div className="flex flex-wrap justify-end gap-2">
            <Button variant="outline" onClick={onClose}>
              Close
            </Button>
            {item.buttonLabel.trim() && (
              <Button onClick={go} className="bg-emerald-800 text-white hover:bg-emerald-900">
                {item.buttonLabel}
              </Button>
            )}
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}

/** Mount once in the signed-in app: shows live admin broadcasts as a popup. */
export default function BroadcastHost() {
  const { currentUser } = useApp();
  const { items } = useBroadcasts();
  const [dismissed, setDismissed] = useState<Set<string>>(new Set());
  const me = currentUser?.id;
  const role = currentUser?.role ?? "";

  const next = useMemo(() => {
    if (!me) return null;
    const now = Date.now();
    return (
      items.find((b) => {
        if (dismissed.has(b.id) || !isBroadcastLive(b, role, now)) return false;
        if (b.repeat) {
          try {
            return sessionStorage.getItem(`aoh-bc-session:${me}:${b.id}`) !== "1";
          } catch {
            return true;
          }
        }
        return !hasSeenBroadcast(me, b.id);
      }) ?? null
    );
  }, [items, dismissed, me, role]);

  const [shownId, setShownId] = useState<string | null>(null);
  useEffect(() => {
    if (next && next.id !== shownId) setShownId(next.id);
  }, [next, shownId]);

  if (!me || !next) return null;
  const close = () => {
    if (next.repeat) {
      try {
        sessionStorage.setItem(`aoh-bc-session:${me}:${next.id}`, "1");
      } catch {
        /* ignore */
      }
    } else markBroadcastSeen(me, next.id);
    setDismissed((s) => new Set(s).add(next.id));
  };
  return <BroadcastPopup item={next} open onClose={close} />;
}
