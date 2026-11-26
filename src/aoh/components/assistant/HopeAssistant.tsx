import { useEffect, useRef, useState } from "react";
import ReactMarkdown from "react-markdown";
import { ArrowUp, Check, Copy, MessageSquare, Sparkles, SquarePen, Square, X } from "lucide-react";
import { useApp } from "../../context/AppContext";
import { useAssistantVisibility } from "../../context/AssistantVisibility";
import { streamAssistant, AssistantError, type AssistantMessage } from "../../lib/assistant";
import { answerLocally } from "../../lib/assistantOffline";
import { cn } from "@/aoh/lib/utils";
import { newId } from "@/aoh/lib/ids";

interface ChatBubble {
  id: string;
  role: "user" | "assistant" | "error";
  content: string;
  complete?: boolean;
}

function suggestionsFor(role: string | null): string[] {
  if (!role) {
    return [
      "What programmes do you offer?",
      "Help me write a professional letter",
      "Explain a topic for my studies",
    ];
  }
  if (role === "Student") {
    return ["How much do I still owe in fees?", "What quizzes do I have coming up?", "What programmes am I enrolled in?"];
  }
  if (role === "Teacher") {
    return ["How many students are in my cohorts?", "How do quiz attempts get graded?"];
  }
  return ["Give me a quick overview of the academy right now", "How many students are active?"];
}

export default function HopeAssistant() {
  const { state, currentUser } = useApp();
  const { hidden } = useAssistantVisibility();
  const [open, setOpen] = useState(false);
  const [bubbles, setBubbles] = useState<ChatBubble[]>([]);
  const [draft, setDraft] = useState("");
  const [sending, setSending] = useState(false);
  const [savedIds, setSavedIds] = useState<string[]>([]);
  const [copiedId, setCopiedId] = useState<string | null>(null);
  const [materialCohortId, setMaterialCohortId] = useState("");
  const scrollRef = useRef<HTMLDivElement>(null);
  const abortRef = useRef<AbortController | null>(null);

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight, behavior: "smooth" });
  }, [bubbles, sending]);

  useEffect(() => () => abortRef.current?.abort(), []);

  // Step aside whenever a dialog, drawer or popover is open (messaging, notifications,
  // forms...) so the launcher never covers the action the person is doing.
  const [covered, setCovered] = useState(false);
  useEffect(() => {
    const COVER = '[role="dialog"],[role="alertdialog"],[data-assistant-cover]';
    let frame = 0;
    const check = () => {
      frame = 0;
      setCovered(Boolean(document.querySelector(COVER)));
    };
    const schedule = () => { if (!frame) frame = window.requestAnimationFrame(check); };
    check();
    const observer = new MutationObserver(schedule);
    observer.observe(document.body, { childList: true, subtree: true });
    return () => { observer.disconnect(); if (frame) window.cancelAnimationFrame(frame); };
  }, []);

  // Do not carry another account's private conversation into a new session.
  useEffect(() => {
    abortRef.current?.abort();
    abortRef.current = null;
    setBubbles([]);
    setDraft("");
    setSending(false);
  }, [currentUser?.id]);

  if (!state.settings.assistantEnabled || hidden || covered) return null;

  const configuredLabel = state.websiteSettings.assistantLauncherLabel?.trim();
  const label = !configuredLabel || /luna|hope assistant|afrohope ai/i.test(configuredLabel)
    ? "AOH AI"
    : configuredLabel;
  const surface: "public" | "portal" = currentUser ? "portal" : "public";
  // Only Instructors, Staff and Admin accounts may save research into the Resource Center.
  // Explicit staff allowlist: every non-student staff role qualifies; Students never see the save control.
  const STAFF_SAVE_ROLES = ["Teacher", "Registrar", "Admission Officer", "Finance Officer", "School Admin", "Super Admin", "Director of Education", "Research Officer", "Executive Assistant", "Data Entry Officer", "Public Relations Officer", "Customer Care Officer"] as const;
  const canSaveMaterial = !!currentUser && (STAFF_SAVE_ROLES as readonly string[]).includes(currentUser.role);
  const materialCohorts = (state.cohorts ?? []).filter((c) => !currentUser || currentUser.role !== "Teacher" || c.teacherId === currentUser.id).slice(0, 50);

  function saveToMaterials(bubbleId: string, content: string) {
    const text = content.trim();
    if (!text) return;
    const cohort = (state.cohorts ?? []).find((c) => c.id === (materialCohortId || materialCohorts[0]?.id)) ?? null;
    const program = (state.programs ?? []).find((p) => p.id === cohort?.programId) ?? null;
    try {
      const key = "aoh-assistant-material-queue";
      const existing = JSON.parse(localStorage.getItem(key) ?? "[]");
      const queue = Array.isArray(existing) ? existing : [];
      queue.push({ id: newId(), title: text.split("\n")[0].slice(0, 80) || "AOH AI resource", body: text, savedAt: new Date().toISOString(), savedBy: currentUser?.id ?? null, programId: program?.id ?? null, cohortId: cohort?.id ?? null, programTitle: program?.title ?? null, cohortName: cohort?.name ?? null });
      localStorage.setItem(key, JSON.stringify(queue.slice(-20)));
      window.dispatchEvent(new CustomEvent("aoh:assistant-material", { detail: { count: queue.length, programId: program?.id ?? null, cohortId: cohort?.id ?? null } }));
      setSavedIds((prev) => (prev.includes(bubbleId) ? prev : [...prev, bubbleId]));
    } catch { /* storage unavailable — guidance below still shows */ }
  }

  async function send(text: string) {
    const content = text.trim();
    if (!content || content.length > 1500 || sending) return;
    const history: AssistantMessage[] = [
      ...bubbles.filter((b) => b.role === "user" || (b.role === "assistant" && b.complete)).map((b) => ({ role: b.role as "user" | "assistant", content: b.content })),
      { role: "user", content },
    ];
    setBubbles((prev) => [...prev, { id: newId(), role: "user", content }]);
    setDraft("");
    setSending(true);

    const assistantId = newId();
    setBubbles((prev) => [...prev, { id: assistantId, role: "assistant", content: "" }]);

    const controller = new AbortController();
    let receivedText = false;
    abortRef.current = controller;
    try {
      await streamAssistant({
        messages: history,
        surface,
        signal: controller.signal,
        onDelta: (delta) => {
          receivedText = receivedText || Boolean(delta.trim());
          if (!controller.signal.aborted) setBubbles((prev) => prev.map((b) => (b.id === assistantId ? { ...b, content: b.content + delta } : b)));
        },
      });
      if (!controller.signal.aborted) setBubbles((prev) => prev.map((b) => b.id === assistantId ? { ...b, complete: true } : b));
    } catch (e) {
      if (controller.signal.aborted || (e instanceof DOMException && e.name === "AbortError")) {
        setBubbles((prev) => prev.filter((b) => !(b.id === assistantId && b.content === "")));
        return;
      }
      const code = e instanceof AssistantError ? e.code : "unavailable";
      // The live assistant currently rejects signed-out visitors; say so plainly instead of asking them to use the portal.
      const publicBlocked = surface === "public" && ["unauthorized", "auth_required", "forbidden"].includes(code);
      const message = publicBlocked
        ? "The full AI chat is available after you sign in. Here is what I can answer from the school's public information."
        : e instanceof AssistantError ? e.message : "AOH AI is unavailable right now. Please try again shortly.";
      // Preserve the actual failure, even when a limited local answer is available.
      // Local/failed/partial replies must never become AI conversation context.
      const hasPartialReply = receivedText;
      if (!hasPartialReply && (["missing_key", "unavailable", "network", "timeout", "server_error", "empty"].includes(code) || publicBlocked)) {
        const local = answerLocally(content, {
          academyName: state.settings.academyName,
          programmes: state.programs.map((p) => ({ title: p.title, category: p.category, description: p.description })),
          contactEmail: state.settings.contactEmail,
          contactPhone: state.settings.contactPhone,
          address: state.settings.address,
          intakeStatus: state.settings.intakeStatus,
        });
        if (local) {
          setBubbles((prev) => [
            ...prev.map((b) => (b.id === assistantId ? { ...b, content: `**Limited local response — not an AI answer**\n\n${local}` } : b)),
            { id: newId(), role: "error", content: message },
          ]);
          return;
        }
      }
      setBubbles((prev) => {
        const withoutEmptyDraft = prev.filter((b) => !(b.id === assistantId && b.content === ""));
        return [...withoutEmptyDraft, { id: newId(), role: "error", content: message }];
      });
    } finally {
      if (abortRef.current === controller) {
        setSending(false);
        abortRef.current = null;
      }
    }
  }

  function newChat() {
    abortRef.current?.abort();
    abortRef.current = null;
    setBubbles([]);
    setDraft("");
    setSending(false);
  }

  function stop() {
    abortRef.current?.abort();
  }

  function copyReply(id: string, content: string) {
    void navigator.clipboard?.writeText(content).then(() => {
      setCopiedId(id);
      window.setTimeout(() => setCopiedId((cur) => (cur === id ? null : cur)), 1500);
    }).catch(() => undefined);
  }

  const firstName = currentUser?.name?.split(" ")[0];

  return (
    <>
      {!open && (
        <button
          type="button"
          onClick={() => setOpen(true)}
          aria-label={label}
          className={cn(
            "fixed z-40 flex items-center gap-2 rounded-full bg-[#171717] text-xs font-semibold text-white shadow-xl transition hover:bg-black",
            surface === "portal"
              ? "bottom-4 right-4 left-auto h-10 w-10 justify-center p-0 lg:w-auto lg:justify-start lg:px-3.5"
              : "bottom-5 right-5 px-3.5 py-2.5 max-sm:bottom-4 max-sm:right-3 max-sm:h-10 max-sm:w-10 max-sm:justify-center max-sm:p-0",
          )}
        >
          <MessageSquare className="h-4 w-4" />
          <span className={surface === "portal" ? "sr-only lg:not-sr-only" : "max-sm:sr-only"}>{label}</span>
        </button>
      )}

      {open && (
        <div
          role="region"
          aria-label={label}
          className="fixed inset-0 z-40 flex flex-col bg-white text-[#0d0d0d] sm:inset-auto sm:bottom-5 sm:right-5 sm:h-[min(680px,calc(100dvh-2.5rem))] sm:w-[440px] sm:overflow-hidden sm:rounded-3xl sm:border sm:border-black/10 sm:shadow-2xl"
        >
          <header className="flex items-center gap-1 border-b border-black/5 px-3 py-2.5 pt-[max(0.625rem,env(safe-area-inset-top))]">
            <button type="button" onClick={newChat} aria-label="New chat" title="New chat" className="grid h-9 w-9 place-items-center rounded-lg text-[#424242] hover:bg-[#f4f4f4]">
              <SquarePen className="h-[18px] w-[18px]" />
            </button>
            <p className="flex-1 truncate px-1 text-[15px] font-semibold">AOH AI</p>
            <button type="button" onClick={() => setOpen(false)} aria-label="Close assistant" className="grid h-9 w-9 place-items-center rounded-lg text-[#424242] hover:bg-[#f4f4f4]">
              <X className="h-[18px] w-[18px]" />
            </button>
          </header>

          <div ref={scrollRef} className="flex-1 overflow-y-auto px-4 py-5">
            {bubbles.length === 0 ? (
              <div className="mx-auto flex h-full max-w-md flex-col items-center justify-center text-center">
                <h2 className="text-[22px] font-semibold tracking-tight">
                  {firstName ? `What can I help with, ${firstName}?` : "What can I help with?"}
                </h2>
                <p className="mt-1.5 text-sm text-[#6b6b6b]">Ask about {state.settings.academyName || "AFRICA OF HOPE"}, your studies or anything else.</p>
                <div className="mt-6 grid w-full gap-2">
                  {suggestionsFor(currentUser?.role ?? null).map((s) => (
                    <button
                      key={s} type="button" onClick={() => send(s)}
                      className="rounded-2xl border border-black/10 px-4 py-3 text-left text-sm text-[#2f2f2f] transition hover:bg-[#f7f7f8]"
                    >
                      {s}
                    </button>
                  ))}
                </div>
              </div>
            ) : (
              <div className="mx-auto max-w-2xl space-y-6">
                {bubbles.map((b) => (
                  <div key={b.id} className={cn("flex", b.role === "user" ? "justify-end" : "justify-start")}>
                    {b.role === "error" ? (
                      <p className="max-w-full rounded-2xl bg-rose-50 px-4 py-2.5 text-sm text-rose-700">{b.content}</p>
                    ) : b.role === "user" ? (
                      <p className="max-w-[85%] whitespace-pre-wrap break-words rounded-3xl bg-[#f4f4f4] px-4 py-2.5 text-[15px] leading-relaxed">{b.content}</p>
                    ) : (
                      <div className="flex w-full gap-3">
                        <span className="mt-0.5 grid h-7 w-7 flex-none place-items-center rounded-full border border-black/10 bg-white text-[#0d0d0d]">
                          <Sparkles className="h-3.5 w-3.5" />
                        </span>
                        <div className="min-w-0 flex-1 text-[15px] leading-7">
                          {b.content ? (
                            <>
                              <div className="[&_a]:underline [&_ol]:my-2 [&_ol]:list-decimal [&_ol]:pl-5 [&_p]:my-2 [&_pre]:overflow-x-auto [&_pre]:rounded-xl [&_pre]:bg-[#f4f4f4] [&_pre]:p-3 [&_ul]:my-2 [&_ul]:list-disc [&_ul]:pl-5">
                                <ReactMarkdown>{b.content}</ReactMarkdown>
                              </div>
                              {b.complete && (
                                <div className="mt-1 flex items-center gap-1 text-[#6b6b6b]">
                                  <button type="button" onClick={() => copyReply(b.id, b.content)} aria-label="Copy reply" className="grid h-8 w-8 place-items-center rounded-lg hover:bg-[#f4f4f4]">
                                    {copiedId === b.id ? <Check className="h-4 w-4" /> : <Copy className="h-4 w-4" />}
                                  </button>
                                </div>
                              )}
                              {b.complete && canSaveMaterial && (
                                <div className="mt-2 space-y-1.5">
                                  {materialCohorts.length > 0 && (
                                    <label className="flex items-center gap-1.5 text-xs text-[#6b6b6b]">Course:
                                      <select value={materialCohortId || materialCohorts[0].id} onChange={(e) => setMaterialCohortId(e.target.value)} className="max-w-[200px] rounded-full border border-black/10 bg-white px-2 py-1 text-xs" aria-label="Course for training material">
                                        {materialCohorts.map((c) => (
                                          <option key={c.id} value={c.id}>{(state.programs ?? []).find((p) => p.id === c.programId)?.title ?? "Course"} · {c.name}</option>
                                        ))}
                                      </select>
                                    </label>
                                  )}
                                  <button type="button" disabled={savedIds.includes(b.id)} onClick={() => saveToMaterials(b.id, b.content)} className="inline-flex min-h-9 items-center gap-1 rounded-full border border-black/10 bg-white px-3 text-xs font-medium hover:bg-[#f7f7f8] disabled:opacity-60">
                                    {savedIds.includes(b.id) ? "Saved to training materials ✓" : "Save to training materials"}
                                  </button>
                                  {savedIds.includes(b.id) && (
                                    <p className="text-xs text-[#6b6b6b]">Open Academic Planning → Materials to review and submit it.</p>
                                  )}
                                </div>
                              )}
                            </>
                          ) : sending ? (
                            <span className="inline-flex items-center gap-1 py-2" aria-label="Waiting for a reply">
                              <i className="h-2 w-2 animate-pulse rounded-full bg-[#0d0d0d]" />
                            </span>
                          ) : (
                            <span className="text-[#6b6b6b]">No reply came back. Please try again.</span>
                          )}
                        </div>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>

          <form
            className="px-3 pb-[max(0.75rem,env(safe-area-inset-bottom))] pt-1"
            onSubmit={(e) => { e.preventDefault(); void send(draft); }}
          >
            <div className="mx-auto flex max-w-2xl items-end gap-2 rounded-[26px] border border-black/10 bg-[#f4f4f4] py-2 pl-4 pr-2">
              <textarea
                value={draft}
                rows={1}
                onChange={(e) => {
                  const el = e.currentTarget;
                  const value = el.value;
                  setDraft(value);
                  el.style.height = "auto";
                  el.style.height = `${Math.min(el.scrollHeight, 140)}px`;
                }}
                onKeyDown={(e) => {
                  if (e.key === "Enter" && !e.shiftKey && !e.nativeEvent.isComposing) {
                    e.preventDefault();
                    void send(draft);
                  }
                }}
                placeholder="Message AOH AI"
                aria-label="Message AOH AI"
                maxLength={1500}
                className="max-h-36 min-h-[28px] flex-1 resize-none bg-transparent py-1 text-[15px] leading-6 outline-none placeholder:text-[#8e8e8e]"
              />
              {sending ? (
                <button type="button" onClick={stop} aria-label="Stop generating" className="grid h-8 w-8 flex-none place-items-center rounded-full bg-[#0d0d0d] text-white">
                  <Square className="h-3 w-3 fill-current" />
                </button>
              ) : (
                <button type="submit" disabled={!draft.trim()} aria-label="Send message" className="grid h-8 w-8 flex-none place-items-center rounded-full bg-[#0d0d0d] text-white transition disabled:bg-[#d0d0d0]">
                  <ArrowUp className="h-4 w-4" />
                </button>
              )}
            </div>
            <p className="mt-2 text-center text-xs text-[#8e8e8e]">AOH AI can make mistakes. Check important information and school details.</p>
          </form>
        </div>
      )}
    </>
  );
}
