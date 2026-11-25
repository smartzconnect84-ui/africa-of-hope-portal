import { useCallback, useEffect, useState } from "react";
import { CheckCircle2, CircleAlert, Loader2, Send } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/aoh/components/ui/button";
import { panelClass, SectionHeader } from "../Navigation";
import {
  getNotificationStatus, sendTestNotification, setNotificationProvider, setupKnockWorkflow, type NotificationStatus,
} from "@/aoh/lib/notifications";

function Pill({ ok, children }: { ok: boolean; children: React.ReactNode }) {
  return (
    <span className={`inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-[11px] font-semibold ${ok ? "bg-emerald-100 text-emerald-800" : "bg-amber-100 text-amber-800"}`}>
      {ok ? <CheckCircle2 className="h-3.5 w-3.5" /> : <CircleAlert className="h-3.5 w-3.5" />} {children}
    </span>
  );
}

export default function NotificationAdmin() {
  const [status, setStatus] = useState<NotificationStatus | null>(null);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    const res = await getNotificationStatus();
    if (res.ok) { setStatus(res); setError(""); } else setError(res.error ?? "Could not load notification status.");
  }, []);
  useEffect(() => { void load(); }, [load]);

  async function switchTo(provider: "knock" | "onesignal") {
    if (provider === "onesignal" && !window.confirm("Switch ALL notifications to the OneSignal backup provider? Knock will stop sending.")) return;
    setBusy(true);
    const res = await setNotificationProvider(provider, provider === "onesignal");
    setBusy(false);
    if (res.ok) { toast.success(`Active provider is now ${provider === "knock" ? "Knock" : "OneSignal"}.`); void load(); }
    else toast.error(res.error ?? "Could not switch provider.");
  }

  async function setupWorkflow() {
    setBusy(true);
    const res = await setupKnockWorkflow("development");
    setBusy(false);
    if (res.ok) toast.success("Knock workflow created and committed. Now press Send test.");
    else toast.error(res.error ?? "Could not create the workflow.", { duration: 12000 });
  }

  async function test() {
    setBusy(true);
    const res = await sendTestNotification();
    setBusy(false);
    if (res.ok) toast.success(`Test sent through ${res.provider}. Check your bell or device.`);
    else toast.error(res.error ?? "The test notification failed.");
    void load();
  }

  if (error) return <div className={`${panelClass} p-5 text-sm text-rose-700`}>{error}</div>;
  if (!status) return <div className={`${panelClass} flex items-center gap-2 p-5 text-sm text-slate-500`}><Loader2 className="h-4 w-4 animate-spin" /> Loading…</div>;

  return (
    <div className="space-y-5">
      <SectionHeader title="Notification centre" subtitle="Provider status, delivery history and test tools." />
      <div className="grid gap-4 sm:grid-cols-2">
        {([
          { id: "knock", name: "Knock (primary)", configured: status.knockConfigured },
          { id: "onesignal", name: "OneSignal (backup)", configured: status.onesignalConfigured },
        ] as const).map((p) => (
          <div key={p.id} className={`${panelClass} p-4`}>
            <div className="flex items-center justify-between gap-2">
              <p className="text-sm font-semibold text-slate-800">{p.name}</p>
              {status.provider === p.id && <Pill ok>Active</Pill>}
            </div>
            <div className="mt-2"><Pill ok={p.configured}>{p.configured ? "Connected" : "Keys not added yet"}</Pill></div>
            {status.provider !== p.id && (
              <Button size="sm" variant="outline" className="mt-3" disabled={busy || !p.configured} onClick={() => void switchTo(p.id)}>
                Make active
              </Button>
            )}
          </div>
        ))}
      </div>

      <div className={`${panelClass} p-4`}>
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex gap-6 text-sm">
            <span><b className="text-emerald-700">{status.stats.sent ?? 0}</b> sent</span>
            <span><b className="text-rose-600">{status.stats.failed ?? 0}</b> failed</span>
            <span className="text-slate-500">last 7 days</span>
          </div>
          <Button size="sm" variant="outline" disabled={busy} onClick={() => void setupWorkflow()}>
            Create Knock workflow
          </Button>
          <Button size="sm" disabled={busy} onClick={() => void test()}>
            {busy ? <Loader2 className="mr-1.5 h-4 w-4 animate-spin" /> : <Send className="mr-1.5 h-4 w-4" />} Send test to me
          </Button>
        </div>
      </div>

      <div className={`${panelClass} p-4`}>
        <h3 className="text-sm font-semibold text-slate-800">Failed deliveries</h3>
        {status.failures.length === 0 ? (
          <p className="mt-2 text-sm text-slate-500">No failures recorded.</p>
        ) : (
          <ul className="mt-2 divide-y divide-slate-100 text-xs">
            {status.failures.map((f, i) => (
              <li key={i} className="py-2">
                <span className="font-semibold text-slate-700">{f.event}</span> via {f.provider}
                <span className="block text-rose-600">{f.error}</span>
                <span className="text-slate-400">{new Date(f.created_at).toLocaleString()}</span>
              </li>
            ))}
          </ul>
        )}
      </div>

      <div className={`${panelClass} p-4`}>
        <h3 className="text-sm font-semibold text-slate-800">Recent events</h3>
        <ul className="mt-2 divide-y divide-slate-100 text-xs">
          {status.recent.length === 0 && <li className="py-2 text-slate-500">Nothing sent yet.</li>}
          {status.recent.map((r, i) => (
            <li key={i} className="flex justify-between gap-3 py-2">
              <span>{r.event} <span className="text-slate-400">({r.provider})</span></span>
              <span className={r.status === "sent" ? "text-emerald-700" : "text-rose-600"}>{r.status}</span>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}
