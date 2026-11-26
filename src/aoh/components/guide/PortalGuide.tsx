import { useEffect, useMemo, useRef, useState } from "react";
import { Headphones, Pause, Play, Square, Volume2 } from "lucide-react";
import { useApp } from "@/aoh/context/AppContext";
import { Button } from "@/aoh/components/ui/button";
import { cn } from "@/aoh/lib/utils";

type Audience = "all" | "student" | "staff" | "teacher" | "admin";
interface Topic {
  id: string;
  title: string;
  audience: Audience[];
  steps: string[];
}

const TOPICS: Topic[] = [
  {
    id: "start",
    title: "Getting started",
    audience: ["all"],
    steps: [
      "Use the menu on the left, or the menu button on a phone, to move between sections.",
      "Tap your photo at the top to open your profile, change your picture and update your details.",
      "Tap any person's photo or name anywhere in the portal to see their profile card.",
      "Tap the AOH AI button to ask a question about the school or the portal.",
    ],
  },
  {
    id: "messages",
    title: "Messages and translation",
    audience: ["all"],
    steps: [
      "Open Messages and choose a person, or start a new chat.",
      "Use the globe button at the top of a chat to pick a language. Tap Translate on any message to read it in that language.",
      "Turn on automatic translation to read every incoming message in your language.",
      "To delete one of your own messages, press and hold it, or open its menu and choose Delete.",
    ],
  },
  {
    id: "learning",
    title: "Learning and assignments",
    audience: ["student"],
    steps: [
      "Open Assignments to see work due. Open one, write your answer and submit before the deadline.",
      "Open My Report Card to see your marks and grades for each term.",
      "Open Timetable and Study Calendar to see your classes and plan your week.",
      "Use Self-Paced Learning to study materials in your own time.",
    ],
  },
  {
    id: "fees",
    title: "Fees, invoices and receipts",
    audience: ["student"],
    steps: [
      "Open Pay Fees to send a payment and attach your proof.",
      "Open Invoices and Receipts to see your invoice, registration slip and every payment receipt.",
      "Press Print or Save PDF to keep a copy.",
    ],
  },
  {
    id: "teaching",
    title: "Teaching, marks and attendance",
    audience: ["teacher"],
    steps: [
      "Open Attendance to mark who came to class.",
      "Open Assignments to create work and enter marks.",
      "Open Report Card and Grade Sheet Samples to edit the layout, fill it from a real class and print it.",
    ],
  },
  {
    id: "finance",
    title: "Finance and records",
    audience: ["staff", "admin"],
    steps: [
      "Open Finance Ledger to record payments. Choose the student, category, amount and method.",
      "Open Invoices and Receipts, choose a student, then edit the school details, extra lines and discount before printing.",
      "Open Payment Confirmations to approve or reject payments students submitted.",
      "To delete a ledger entry, press and hold its row, then confirm.",
    ],
  },
  {
    id: "admin",
    title: "Broadcasts and administration",
    audience: ["admin"],
    steps: [
      "Open Live Broadcasts to write a popup message. Choose who sees it, a start and end time, and the style.",
      "Use Preview to see exactly what people will see, then save.",
      "Switch a broadcast off at any time. It disappears from screens within about thirty seconds.",
      "Open People to approve new applicants and manage accounts.",
    ],
  },
];

function matches(topic: Topic, role: string): boolean {
  const staff = role !== "Student";
  const admin = role === "Super Admin" || role === "School Admin";
  return topic.audience.some(
    (a) => a === "all" || (a === "student" && role === "Student") || (a === "teacher" && role === "Teacher") || (a === "staff" && staff) || (a === "admin" && admin),
  );
}

export default function PortalGuide() {
  const { currentUser } = useApp();
  const role = currentUser?.role ?? "Student";
  const topics = useMemo(() => TOPICS.filter((t) => matches(t, role)), [role]);
  const supported = typeof window !== "undefined" && "speechSynthesis" in window;
  const [playing, setPlaying] = useState<string | null>(null);
  const [paused, setPaused] = useState(false);
  const [rate, setRate] = useState(0.95);
  const queueToken = useRef(0);

  useEffect(() => () => { if (supported) window.speechSynthesis.cancel(); }, [supported]);

  const stop = () => {
    queueToken.current += 1;
    if (supported) window.speechSynthesis.cancel();
    setPlaying(null);
    setPaused(false);
  };

  const speak = (ids: string[]) => {
    if (!supported) return;
    stop();
    const token = queueToken.current;
    const chosen = topics.filter((t) => ids.includes(t.id));
    const parts = chosen.flatMap((t) => [{ id: t.id, text: `${t.title}.` }, ...t.steps.map((s, i) => ({ id: t.id, text: `Step ${i + 1}. ${s}` }))]);
    const next = (i: number) => {
      if (token !== queueToken.current) return;
      if (i >= parts.length) {
        setPlaying(null);
        return;
      }
      const u = new SpeechSynthesisUtterance(parts[i].text);
      u.rate = rate;
      u.lang = "en";
      u.onstart = () => setPlaying(parts[i].id);
      u.onend = () => next(i + 1);
      u.onerror = () => { if (token === queueToken.current) setPlaying(null); };
      window.speechSynthesis.speak(u);
    };
    next(0);
  };

  const togglePause = () => {
    if (!supported) return;
    if (paused) window.speechSynthesis.resume();
    else window.speechSynthesis.pause();
    setPaused(!paused);
  };

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h2 className="flex items-center gap-2 text-xl font-bold text-slate-900"><Headphones className="h-5 w-5 text-emerald-700" /> Portal guide</h2>
          <p className="mt-1 text-sm text-slate-600">Read the steps, or press Listen to hear them. Shown for your role: {role === "Teacher" ? "Teacher-Instructor" : role}.</p>
        </div>
        {supported && (
          <div className="flex flex-wrap items-center gap-2">
            <label className="flex items-center gap-1.5 text-xs text-slate-600">
              Speed
              <select className="h-9 rounded-md border border-slate-300 bg-white px-2 text-sm" value={rate} onChange={(e) => setRate(Number(e.currentTarget.value))}>
                <option value={0.8}>Slow</option>
                <option value={0.95}>Normal</option>
                <option value={1.2}>Fast</option>
              </select>
            </label>
            <Button onClick={() => speak(topics.map((t) => t.id))} className="bg-emerald-800 text-white hover:bg-emerald-900"><Volume2 className="mr-1.5 h-4 w-4" /> Listen to all</Button>
            {playing && (
              <>
                <Button variant="outline" onClick={togglePause} aria-label={paused ? "Resume" : "Pause"}>{paused ? <Play className="h-4 w-4" /> : <Pause className="h-4 w-4" />}</Button>
                <Button variant="outline" onClick={stop} aria-label="Stop"><Square className="h-4 w-4" /></Button>
              </>
            )}
          </div>
        )}
      </div>
      {!supported && <p className="rounded-lg bg-amber-50 p-3 text-sm text-amber-900">This browser cannot read aloud. The written steps below still work.</p>}
      <div className="grid gap-4 md:grid-cols-2">
        {topics.map((t) => (
          <section key={t.id} className={cn("rounded-2xl border bg-white p-5 shadow-sm", playing === t.id ? "border-emerald-500 ring-2 ring-emerald-500/20" : "border-slate-200")}>
            <div className="flex items-start justify-between gap-2">
              <h3 className="font-bold text-slate-900">{t.title}</h3>
              {supported && (
                <Button size="sm" variant="outline" onClick={() => speak([t.id])}><Volume2 className="mr-1 h-3.5 w-3.5" /> Listen</Button>
              )}
            </div>
            <ol className="mt-3 list-decimal space-y-2 pl-5 text-sm leading-6 text-slate-700">
              {t.steps.map((s) => (<li key={s}>{s}</li>))}
            </ol>
          </section>
        ))}
      </div>
    </div>
  );
}
