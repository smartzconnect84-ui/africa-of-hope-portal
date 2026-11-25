import { useEffect, useRef } from "react";
import { toast } from "sonner";

/**
 * One central place that owns the browser / Android back button for the
 * state-driven parts of the app (public ⇄ portal and the portal module).
 * Public pages are URL based and stay with react-router; this module only
 * ever ADDS its own marker to history.state, so router entries keep working.
 *
 *  - every module change pushes a history entry, so Back returns to the
 *    previous module (not the start of the app);
 *  - an open dialog or the mobile menu is closed first, before anything else;
 *  - unsaved work (edited forms, a running exam) asks before it is left, and
 *    cancelling keeps the screen and its data exactly as it was;
 *  - at the very first screen Back shows "press back again to exit" instead
 *    of silently closing the app.
 */

type Snapshot = Record<string, string>;
type ApplyFn = (value: string) => void;

const slots = new Map<string, ApplyFn>();
const guards = new Set<() => string | null>();
let snap: Snapshot = {};
let started = false;
let ready = false;
let dirty = false;
let exitArmedUntil = 0;

const OVERLAY = '[role="dialog"][data-state="open"],[role="alertdialog"][data-state="open"],#portal-mobile-drawer';
const UNSAVED = "You have unsaved changes. Leave this page and lose them?";

function stateWith(extra: Record<string, unknown>) {
  const current = (window.history.state && typeof window.history.state === "object") ? window.history.state : {};
  return { ...current, ...extra };
}

function guardMessage(): string | null {
  for (const guard of guards) {
    const message = guard();
    if (message) return message;
  }
  return dirty ? UNSAVED : null;
}

function markDirty(event: Event) {
  const el = event.target as HTMLElement | null;
  if (!el?.closest) return;
  if (el.closest("[data-nav-ignore],[data-portal-search]")) return;
  if (el.closest("form,[role=dialog]")) dirty = true;
}

function restoreCurrent() {
  // Put the screen the user is on back as the newest entry (cancelled leave).
  window.history.pushState(stateWith({ aohRoot: false, aoh: { ...snap } }), "");
}

function onPop(event: PopStateEvent) {
  const state = event.state as { aohRoot?: boolean; aoh?: Snapshot } | null;

  if (state?.aohRoot) {
    const now = Date.now();
    if (now < exitArmedUntil) {
      exitArmedUntil = 0;
      window.history.back(); // genuine second press at the root: let the app close
      return;
    }
    if (guardMessage() && !window.confirm(guardMessage() ?? UNSAVED)) {
      restoreCurrent();
      return;
    }
    exitArmedUntil = now + 2500;
    restoreCurrent();
    toast("Press back again to exit", { duration: 2200 });
    return;
  }

  const target = state?.aoh;
  if (!target) return; // a react-router entry: the router handles it

  const overlay = document.querySelector(OVERLAY);
  if (overlay) {
    // Back closes the open dialog / menu first and keeps the page.
    restoreCurrent();
    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }));
    return;
  }

  const message = guardMessage();
  if (message && !window.confirm(message)) {
    restoreCurrent();
    return;
  }
  dirty = false;
  snap = { ...snap, ...target };
  // "site" first so the portal exists before its own view is applied.
  const order = ["site", ...Object.keys(target).filter((key) => key !== "site")];
  for (const key of order) {
    const value = target[key];
    if (value !== undefined) slots.get(key)?.(value);
  }
}

function start() {
  if (started || typeof window === "undefined") return;
  started = true;
  try {
    // Entry 0 is a quiet "root" marker; entry 1 is the real first screen.
    window.history.replaceState(stateWith({ aohRoot: true }), "");
    window.history.pushState(stateWith({ aohRoot: false, aoh: { ...snap } }), "");
  } catch { /* history unavailable: back button behaves natively */ }
  window.addEventListener("popstate", onPop);
  document.addEventListener("input", markDirty, true);
  document.addEventListener("submit", () => { dirty = false; }, true);
  window.addEventListener("beforeunload", (event) => {
    if (guardMessage()) { event.preventDefault(); event.returnValue = ""; }
  });
  window.setTimeout(() => { ready = true; }, 0);
}

/** The value a slot had in the entry the user came back to (used on remount). */
export function peekNavSlot(id: string): string | undefined {
  return snap[id];
}

/**
 * Registers a piece of navigation state. Changing `value` adds a history
 * entry; Back / Forward call `apply` with the earlier / later value.
 */
export function useNavSlot(id: string, value: string, apply: ApplyFn) {
  const applyRef = useRef(apply);
  applyRef.current = apply;
  const mounted = useRef(false);

  useEffect(() => {
    slots.set(id, (v) => applyRef.current(v));
    return () => { slots.delete(id); };
  }, [id]);

  useEffect(() => {
    if (typeof window === "undefined") return;
    start();
    const firstRun = !mounted.current;
    mounted.current = true;
    if (snap[id] === value) return;
    const unseen = snap[id] === undefined;
    snap = { ...snap, [id]: value };
    try {
      if (!ready || firstRun || unseen) window.history.replaceState(stateWith({ aoh: { ...snap } }), "");
      else window.history.pushState(stateWith({ aohRoot: false, aoh: { ...snap } }), "");
    } catch { /* ignore */ }
    dirty = false;
  }, [id, value]);
}

/** Ask before leaving while `active` (for example a running exam). */
export function useLeaveGuard(active: boolean, message: string) {
  useEffect(() => {
    if (!active) return;
    const guard = () => message;
    guards.add(guard);
    return () => { guards.delete(guard); };
  }, [active, message]);
}
