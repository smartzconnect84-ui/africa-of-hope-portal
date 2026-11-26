import { useEffect, useState } from "react";
import { Eye, Megaphone, Pencil, Plus, Trash2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/aoh/components/ui/button";
import { Input } from "@/aoh/components/ui/input";
import { Textarea } from "@/aoh/components/ui/textarea";
import { Switch } from "@/aoh/components/ui/switch";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/aoh/components/ui/dialog";
import { BroadcastPopup } from "@/aoh/components/BroadcastHost";
import { ROLES } from "@/aoh/lib/permissions";
import { displayRole } from "@/aoh/lib/roleDisplay";
import { cn } from "@/aoh/lib/utils";
import {
  newBroadcast,
  saveBroadcasts,
  useBroadcasts,
  type Broadcast,
  type BroadcastStyle,
} from "@/aoh/lib/broadcasts";

const label = "mb-1 block text-xs font-semibold uppercase tracking-wide text-slate-500";
const field = "h-10 w-full rounded-md border border-slate-200 bg-white px-3 text-sm outline-none focus:border-emerald-600 focus:ring-2 focus:ring-emerald-600/20";

function toLocalInput(iso: string) {
  if (!iso) return "";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "";
  const off = d.getTimezoneOffset() * 60000;
  return new Date(d.getTime() - off).toISOString().slice(0, 16);
}

export default function BroadcastAdmin() {
  const { items, loading, reload } = useBroadcasts(60000);
  const [list, setList] = useState<Broadcast[]>([]);
  const [editing, setEditing] = useState<Broadcast | null>(null);
  const [preview, setPreview] = useState<Broadcast | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => setList(items), [items]);

  const persist = async (next: Broadcast[], okMessage: string) => {
    setBusy(true);
    const res = await saveBroadcasts(next);
    setBusy(false);
    setList(next);
    void reload();
    if (res.shared) toast.success(okMessage);
    else
      toast.warning("Saved on this device only", {
        description: res.error
          ? `The shared database refused it: ${res.error}. Run the portal_kv database script, then save again.`
          : "Run the portal_kv database script so everyone sees it.",
      });
  };

  const submit = async () => {
    if (!editing) return;
    if (!editing.title.trim() || !editing.message.trim()) {
      toast.error("Add a title and a message first.");
      return;
    }
    const exists = list.some((b) => b.id === editing.id);
    const next = exists ? list.map((b) => (b.id === editing.id ? editing : b)) : [editing, ...list];
    setEditing(null);
    await persist(next, exists ? "Broadcast updated" : "Broadcast published");
  };

  const remove = async (b: Broadcast) => {
    if (!window.confirm(`Delete the broadcast "${b.title}"?`)) return;
    await persist(list.filter((x) => x.id !== b.id), "Broadcast deleted");
  };

  const toggle = (b: Broadcast) => persist(list.map((x) => (x.id === b.id ? { ...x, active: !x.active } : x)), b.active ? "Broadcast paused" : "Broadcast is live");

  const set = <K extends keyof Broadcast>(k: K, v: Broadcast[K]) => setEditing((e) => (e ? { ...e, [k]: v } : e));

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h2 className="flex items-center gap-2 text-xl font-bold text-slate-900">
            <Megaphone className="h-5 w-5 text-emerald-700" /> Live broadcasts
          </h2>
          <p className="mt-1 max-w-2xl text-sm text-slate-600">
            Write a message that pops up on every chosen member's screen the next time the portal refreshes, which is within about 30 seconds for people already signed in.
          </p>
        </div>
        <Button onClick={() => setEditing(newBroadcast())} className="bg-emerald-800 text-white hover:bg-emerald-900">
          <Plus className="mr-1.5 h-4 w-4" /> New broadcast
        </Button>
      </div>

      {loading ? (
        <p className="rounded-xl border border-slate-200 bg-white p-6 text-sm text-slate-500">Loading broadcasts…</p>
      ) : list.length === 0 ? (
        <div className="rounded-xl border border-dashed border-slate-300 bg-white p-8 text-center">
          <p className="font-semibold text-slate-800">No broadcasts yet</p>
          <p className="mt-1 text-sm text-slate-500">Create one to show a popup to students, instructors or staff.</p>
        </div>
      ) : (
        <ul className="space-y-3">
          {list.map((b) => {
            const liveNow = b.active && (!b.startsAt || Date.parse(b.startsAt) <= Date.now()) && (!b.endsAt || Date.parse(b.endsAt) >= Date.now());
            return (
              <li key={b.id} data-lp-row className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <p className="break-words font-semibold text-slate-900">{b.title}</p>
                      <span className={cn("rounded-full px-2 py-0.5 text-[11px] font-bold", liveNow ? "bg-emerald-100 text-emerald-800" : "bg-slate-100 text-slate-600")}>
                        {liveNow ? "Live" : b.active ? "Scheduled / ended" : "Paused"}
                      </span>
                      {b.style === "urgent" && <span className="rounded-full bg-rose-100 px-2 py-0.5 text-[11px] font-bold text-rose-800">Urgent</span>}
                      {b.repeat && <span className="rounded-full bg-amber-100 px-2 py-0.5 text-[11px] font-bold text-amber-800">Every visit</span>}
                    </div>
                    <p className="mt-1 line-clamp-2 whitespace-pre-wrap break-words text-sm text-slate-600">{b.message}</p>
                    <p className="mt-1 text-xs text-slate-500">
                      To: {b.audience.length ? b.audience.map(displayRole).join(", ") : "Everyone"}
                    </p>
                  </div>
                  <div className="flex flex-wrap items-center gap-2">
                    <Switch checked={b.active} onCheckedChange={() => void toggle(b)} aria-label={b.active ? "Pause broadcast" : "Turn broadcast on"} disabled={busy} />
                    <Button size="sm" variant="outline" onClick={() => setPreview(b)}>
                      <Eye className="mr-1 h-3.5 w-3.5" /> Preview
                    </Button>
                    <Button size="sm" variant="outline" onClick={() => setEditing(b)}>
                      <Pencil className="mr-1 h-3.5 w-3.5" /> Edit
                    </Button>
                    <Button size="sm" variant="outline" className="text-rose-600" onClick={() => void remove(b)} aria-label={`Delete broadcast ${b.title}`}>
                      <Trash2 className="mr-1 h-3.5 w-3.5" /> Delete
                    </Button>
                  </div>
                </div>
              </li>
            );
          })}
        </ul>
      )}

      <Dialog open={!!editing} onOpenChange={(o) => !o && setEditing(null)}>
        <DialogContent className="max-h-[92dvh] w-[calc(100vw-2rem)] max-w-xl overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{editing && list.some((b) => b.id === editing.id) ? "Edit broadcast" : "New broadcast"}</DialogTitle>
            <DialogDescription>Control who sees it, when, and how it looks.</DialogDescription>
          </DialogHeader>
          {editing && (
            <div className="space-y-4">
              <div>
                <label className={label} htmlFor="bc-title">Title</label>
                <Input id="bc-title" value={editing.title} maxLength={90} onChange={(e) => set("title", e.currentTarget.value)} />
              </div>
              <div>
                <label className={label} htmlFor="bc-msg">Message</label>
                <Textarea id="bc-msg" rows={5} value={editing.message} maxLength={1200} onChange={(e) => set("message", e.currentTarget.value)} />
              </div>
              <div>
                <p className={label}>Who sees it</p>
                <div className="flex flex-wrap gap-2">
                  <button type="button" onClick={() => set("audience", [])} className={cn("rounded-full border px-3 py-1 text-xs font-semibold", editing.audience.length === 0 ? "border-emerald-700 bg-emerald-700 text-white" : "border-slate-200 text-slate-600")}>
                    Everyone
                  </button>
                  {ROLES.map((r) => {
                    const on = editing.audience.includes(r);
                    return (
                      <button
                        key={r}
                        type="button"
                        onClick={() => set("audience", on ? editing.audience.filter((x) => x !== r) : [...editing.audience, r])}
                        className={cn("rounded-full border px-3 py-1 text-xs font-semibold", on ? "border-emerald-700 bg-emerald-700 text-white" : "border-slate-200 text-slate-600")}
                      >
                        {displayRole(r)}
                      </button>
                    );
                  })}
                </div>
              </div>
              <div className="grid gap-3 sm:grid-cols-2">
                <div>
                  <label className={label} htmlFor="bc-style">Look</label>
                  <select id="bc-style" className={field} value={editing.style} onChange={(e) => set("style", e.currentTarget.value as BroadcastStyle)}>
                    <option value="info">Notice (green)</option>
                    <option value="success">Good news (teal)</option>
                    <option value="urgent">Urgent (red)</option>
                  </select>
                </div>
                <div className="flex items-end gap-3">
                  <Switch id="bc-repeat" checked={editing.repeat} onCheckedChange={(v) => set("repeat", v)} />
                  <label htmlFor="bc-repeat" className="pb-2 text-sm text-slate-700">Show on every visit</label>
                </div>
                <div>
                  <label className={label} htmlFor="bc-start">Starts (optional)</label>
                  <input id="bc-start" type="datetime-local" className={field} value={toLocalInput(editing.startsAt)} onChange={(e) => set("startsAt", e.currentTarget.value ? new Date(e.currentTarget.value).toISOString() : "")} />
                </div>
                <div>
                  <label className={label} htmlFor="bc-end">Ends (optional)</label>
                  <input id="bc-end" type="datetime-local" className={field} value={toLocalInput(editing.endsAt)} onChange={(e) => set("endsAt", e.currentTarget.value ? new Date(e.currentTarget.value).toISOString() : "")} />
                </div>
                <div>
                  <label className={label} htmlFor="bc-btn">Button text (optional)</label>
                  <Input id="bc-btn" value={editing.buttonLabel} maxLength={30} onChange={(e) => set("buttonLabel", e.currentTarget.value)} />
                </div>
                <div>
                  <label className={label} htmlFor="bc-link">Button link</label>
                  <Input id="bc-link" value={editing.buttonLink} placeholder="https://…" onChange={(e) => set("buttonLink", e.currentTarget.value)} />
                </div>
              </div>
              <div className="flex flex-wrap justify-end gap-2 pt-1">
                <Button variant="outline" onClick={() => setPreview(editing)}>Preview</Button>
                <Button variant="outline" onClick={() => setEditing(null)}>Cancel</Button>
                <Button disabled={busy} onClick={() => void submit()} className="bg-emerald-800 text-white hover:bg-emerald-900">
                  {busy ? "Saving…" : "Save and publish"}
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>

      {preview && <BroadcastPopup item={preview} open onClose={() => setPreview(null)} />}
    </div>
  );
}
