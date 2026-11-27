import { useEffect, useState } from "react";
import { BellRing, BellOff, Loader2, ShieldCheck, Smartphone } from "lucide-react";
import { Button } from "@/aoh/components/ui/button";
import { oneSignalHowLockScreenWorks } from "@/aoh/lib/onesignal";
import { disableWebPush, enableWebPush, webPushState, webPushSupported } from "@/aoh/lib/webPush";
import {
  initNativeOneSignal, nativeLogin, nativeLogout, nativeOptIn, nativeOptOut,
  nativeRequestPermission, nativeStatus, isNativeWrapper,
} from "@/aoh/lib/nativeOneSignal";
import { useApp } from "@/aoh/context/AppContext";
import { isIos, isStandalone } from "@/aoh/lib/pwa";

function safeMsg(e: unknown) { return e instanceof Error ? e.message : "Request failed"; }

/**
 * Live push subscription card. Renders inside portal dashboards for every role.
 * - Loads lazily, never blocks render, never auto-prompts.
 * - Web: VAPID subscription on the app's own service worker, stored in
 *   push_subscriptions and delivered by the `push-send` Edge Function.
 * - APK: the native OneSignal SDK owns permission and delivery.
 */
export default function OneSignalPanel({ compact = false }: { compact?: boolean }) {
  const { currentUser } = useApp();
  const [busy, setBusy] = useState(false);
  const [notice, setNotice] = useState("");
  const [status, setStatus] = useState<{ subscribed: boolean; permission: string } | null>(null);
  const native = isNativeWrapper();
  const supported = native || webPushSupported();

  const refresh = async () => {
    try {
      if (native) {
        const s = await nativeStatus();
        setStatus({ subscribed: s.subscribed, permission: s.permission });
        return;
      }
      const s = await webPushState(currentUser?.id);
      setStatus({ subscribed: s.subscribed, permission: s.permissionLabel });
    } catch { /* best-effort */ }
  };

  useEffect(() => {
    void initNativeOneSignal().then(() => void refresh()).catch(() => undefined);
    void refresh();
    if (!native) return;
    // Only the APK links a OneSignal identity; web delivery is VAPID and needs
    // no player id. Never call the OneSignal web SDK here — it would take over
    // the browser's single push subscription.
    if (currentUser?.id) {
      const tags: Record<string, string> = {};
      for (const pid of (currentUser.programIds ?? []).slice(0, 8)) tags[`course_${pid}`] = "enrolled";
      void nativeLogin(currentUser.id, tags).catch(() => undefined);
    } else {
      void nativeLogout().catch(() => undefined);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentUser?.id]);

  const enable = async () => {
    setBusy(true); setNotice("");
    try {
      if (native) {
        const p = await nativeRequestPermission();
        if (!p) { setNotice("Notifications are blocked for this app. Allow them in Android Settings → Apps → AFRICA OF HOPE → Notifications, then retry."); return; }
        const r = await nativeOptIn();
        setNotice(r.message);
      } else {
        if (!currentUser?.id) { setNotice("Sign in first, then enable notifications."); return; }
        const r = await enableWebPush(currentUser.id);
        setNotice(r.message);
      }
      await refresh();
    } catch (e) { setNotice(safeMsg(e)); }
    finally { setBusy(false); }
  };

  const disable = async () => {
    setBusy(true); setNotice("");
    try {
      if (native) {
        await nativeOptOut();
        setNotice("Push disabled in the APK. Portal messages and in-app history still work.");
      } else {
        await disableWebPush(currentUser?.id);
        setNotice("Push disabled on this device. Portal messages and in-app history still work.");
      }
      await refresh();
    } catch (e) { setNotice(safeMsg(e)); }
    finally { setBusy(false); }
  };

  if (!supported) {
    if (compact) return null;
    return (
      <section aria-label="Phone notifications" className="rounded-xl border border-dashed p-4 text-sm opacity-90">
        <p className="font-semibold flex items-center gap-2"><Smartphone size={16} /> Phone notifications (not supported here)</p>
        <p className="mt-1 text-muted-foreground">This browser cannot receive push notifications. Use Chrome, Edge, Firefox, or add this site to your Home Screen on iPhone/iPad. In-app messages and deadline reminders below still work.</p>
      </section>
    );
  }

  const on = !!status?.subscribed;
  return (
    <section aria-label="Phone notifications" className="rounded-xl border p-4 text-sm space-y-2">
      <div className="flex items-center justify-between gap-3 flex-wrap">
        <p className="font-semibold flex items-center gap-2">
          {on ? <BellRing size={16} className="text-green-700" /> : <BellOff size={16} />}
          Phone push {on ? "enabled" : "off"} <span className="font-normal text-muted-foreground">· {status?.permission ?? "…"}</span>
        </p>
        <div className="flex gap-2">
          {on
            ? <Button size="sm" variant="outline" onClick={disable} disabled={busy}>{busy ? <Loader2 className="animate-spin" size={14} /> : "Turn off"}</Button>
            : <Button size="sm" onClick={enable} disabled={busy}>{busy ? <Loader2 className="animate-spin" size={14} /> : "Enable notifications"}</Button>}
        </div>
      </div>
      <p className="text-muted-foreground flex gap-1.5 items-start"><ShieldCheck size={14} className="mt-0.5 shrink-0" />{oneSignalHowLockScreenWorks()}</p>
      {isIos() && !isStandalone() && (
        <p className="flex gap-1.5 items-start text-amber-700"><Smartphone size={14} className="mt-0.5 shrink-0" />On iPhone/iPad, enable this from the installed app: Safari → Share → Add to Home Screen, open it there, then press Enable (iOS 16.4+).</p>
      )}
      {!compact && <Button size="sm" variant="ghost" onClick={() => void refresh()}>Refresh status</Button>}
      {notice && <p role="status" className="rounded bg-muted px-2 py-1.5">{notice}</p>}
    </section>
  );
}
