import { useEffect } from "react";
import { toast } from "sonner";

const HOLD_MS = 800;
const MOVE_LIMIT = 10;
const ROW = "tr, li, article, [data-lp-row], [data-row]";
const DELETE_TEXT = /^\s*(delete|remove|discard|clear)\b/i;
const SKIP = "input, textarea, select, [contenteditable='true'], [data-no-longpress], audio, video";

function findDeleteButton(row: Element): HTMLButtonElement | null {
  const buttons = Array.from(row.querySelectorAll<HTMLButtonElement>("button, [role='button']"));
  return (
    buttons.find((b) => {
      if ((b as HTMLButtonElement).disabled) return false;
      const text = `${b.getAttribute("aria-label") ?? ""} ${b.getAttribute("title") ?? ""}`.trim() || b.textContent || "";
      return DELETE_TEXT.test(text.trim());
    }) ?? null
  );
}

/**
 * Press and hold any row that has a Delete/Remove button for about a second
 * to delete it. We ask once ourselves and let the feature's own delete run, so
 * every screen keeps its normal safety checks and saving logic.
 */
export default function LongPressDeleteHost() {
  useEffect(() => {
    let timer: number | undefined;
    let row: Element | null = null;
    let sx = 0;
    let sy = 0;
    let fired = false;

    const clear = () => {
      if (timer) window.clearTimeout(timer);
      timer = undefined;
      row?.classList.remove("lp-arming");
      row = null;
    };

    const down = (e: PointerEvent) => {
      if (e.button !== 0 && e.pointerType === "mouse") return;
      const target = e.target as Element | null;
      if (!target || target.closest(SKIP)) return;
      // Pressing a control itself should never start a delete.
      if (target.closest("button, a, [role='button'], [role='tab'], [role='switch']")) return;
      const candidate = target.closest(ROW);
      if (!candidate || !findDeleteButton(candidate)) return;
      clear();
      row = candidate;
      fired = false;
      sx = e.clientX;
      sy = e.clientY;
      candidate.classList.add("lp-arming");
      timer = window.setTimeout(() => {
        const current = row;
        if (!current) return;
        fired = true;
        const button = findDeleteButton(current);
        current.classList.remove("lp-arming");
        row = null;
        if (!button) return;
        if (navigator.vibrate) navigator.vibrate(30);
        const name = (current.textContent ?? "").replace(/\s+/g, " ").trim().slice(0, 60);
        if (!window.confirm(`Delete this item?\n\n${name}${name.length >= 60 ? "…" : ""}`)) return;
        // The feature asks its own question too; we already got a yes.
        const original = window.confirm;
        window.confirm = () => true;
        try {
          button.click();
        } finally {
          window.setTimeout(() => {
            window.confirm = original;
          }, 0);
        }
        toast.message("Delete requested");
      }, HOLD_MS);
    };

    const move = (e: PointerEvent) => {
      if (!timer) return;
      if (Math.hypot(e.clientX - sx, e.clientY - sy) > MOVE_LIMIT) clear();
    };
    const swallowClick = (e: MouseEvent) => {
      if (fired) {
        e.stopPropagation();
        e.preventDefault();
        fired = false;
      }
    };
    const noMenu = (e: Event) => {
      if (timer) e.preventDefault();
    };

    document.addEventListener("pointerdown", down);
    document.addEventListener("pointermove", move);
    document.addEventListener("pointerup", clear);
    document.addEventListener("pointercancel", clear);
    document.addEventListener("click", swallowClick, true);
    document.addEventListener("contextmenu", noMenu);
    return () => {
      clear();
      document.removeEventListener("pointerdown", down);
      document.removeEventListener("pointermove", move);
      document.removeEventListener("pointerup", clear);
      document.removeEventListener("pointercancel", clear);
      document.removeEventListener("click", swallowClick, true);
      document.removeEventListener("contextmenu", noMenu);
    };
  }, []);
  return null;
}
