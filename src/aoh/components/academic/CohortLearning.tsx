import { useCallback, useEffect, useMemo, useState } from "react";
import { toast } from "sonner";
import { CalendarDays, CheckCircle2, ChevronDown, Clock, Loader2, Pencil, Plus, Trash2, Users } from "lucide-react";
import { useApp } from "@/aoh/context/AppContext";
import { academicApi, type LearningUnit, type StudentProgressRow } from "@/aoh/lib/academics";
import { kvList, kvSave } from "@/aoh/lib/portalKv";
import type { Cohort } from "@/aoh/types";
import { Button } from "@/aoh/components/ui/button";
import { Input } from "@/aoh/components/ui/input";
import { Label } from "@/aoh/components/ui/label";
import { Textarea } from "@/aoh/components/ui/textarea";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/aoh/components/ui/dialog";
import { EmptyState, SectionHeader, panelClass } from "../Navigation";
import { cn } from "@/aoh/lib/utils";

type Category = "online" | "partial";
type Status = "draft" | "active" | "suspended" | "closed" | "archived";

interface Plan { id: string; name: string; arrangement: string; onsiteSchedule: string; assessment: string }
interface CohortConfig {
  category: Category;
  status: Status;
  capacity: number;
  registrationDeadline: string;
  weeklyRequirement: string;
  assessmentRequirements: string;
  completionCriteria: string;
  plans: Plan[];
}
interface PlanChoice { planId: string; approved: boolean; at: string }

const CONFIG_PREFIX = "academic-cohort-config:";
const CHOICE_PREFIX = "cohort-plan:";
const ARRANGEMENTS = [
  "Self-paced online learning + weekly physical onsite training",
  "Structured online learning + scheduled physical onsite training",
  "Instructor-guided independent online learning + physical practical training",
  "Other administrator-approved combination",
];
const STATUS_LABEL: Record<Status, string> = { draft: "Draft", active: "Active", suspended: "Suspended", closed: "Closed", archived: "Archived" };
const STATUS_STYLE: Record<Status, string> = {
  draft: "bg-slate-100 text-slate-700",
  active: "bg-emerald-100 text-emerald-800",
  suspended: "bg-amber-100 text-amber-800",
  closed: "bg-rose-100 text-rose-700",
  archived: "bg-slate-200 text-slate-600",
};
const defaultConfig: CohortConfig = {
  category: "online", status: "active", capacity: 30, registrationDeadline: "",
  weeklyRequirement: "", assessmentRequirements: "", completionCriteria: "", plans: [],
};
const selectClass = "h-10 w-full rounded-md border border-slate-200 bg-white px-3 text-sm";

const openView = (view: string) => window.dispatchEvent(new CustomEvent("aoh-open-view", { detail: view }));
const choiceKey = (cohortId: string, studentId: string) => `${CHOICE_PREFIX}${cohortId}:${studentId}`;
const uid = () => Math.random().toString(36).slice(2, 10);

/**
 * Cohort-Based Learning: one place for both cohort categories.
 * Reuses the existing cohorts, learning units (chapter = week, module, topic = lesson),
 * materials, progress, assignments, quizzes, timetable, attendance and certificates.
 * Extra cohort settings and plan choices live in the shared portal store.
 */
export default function CohortLearning({ canManage }: { canManage: boolean }) {
  const { state, currentUser } = useApp();
  const [configs, setConfigs] = useState<Record<string, CohortConfig>>({});
  const [choices, setChoices] = useState<Record<string, PlanChoice>>({});
  const [loading, setLoading] = useState(true);
  const [openId, setOpenId] = useState<string | null>(null);
  const [editing, setEditing] = useState<Cohort | null>(null);

  const load = useCallback(async () => {
    const [c, p] = await Promise.all([kvList<CohortConfig>(CONFIG_PREFIX), kvList<PlanChoice>(CHOICE_PREFIX)]);
    const cfg: Record<string, CohortConfig> = {};
    for (const [k, v] of Object.entries(c)) cfg[k.slice(CONFIG_PREFIX.length)] = { ...defaultConfig, ...v };
    setConfigs(cfg);
    setChoices(p);
    setLoading(false);
  }, []);
  useEffect(() => { void load(); }, [load]);

  const role = currentUser?.role;
  const cohorts = useMemo(() => {
    if (!currentUser) return [];
    if (canManage) return state.cohorts;
    if (role === "Student") return state.cohorts.filter((c) => c.studentIds.includes(currentUser.id));
    if (role === "Teacher") return state.cohorts.filter((c) => c.teacherId === currentUser.id);
    return state.cohorts;
  }, [state.cohorts, currentUser, canManage, role]);

  const cfgOf = (id: string): CohortConfig => configs[id] ?? defaultConfig;

  const saveConfig = async (cohortId: string, next: CohortConfig) => {
    setConfigs((m) => ({ ...m, [cohortId]: next }));
    const res = await kvSave(CONFIG_PREFIX + cohortId, next);
    if (res.shared) toast.success("Cohort settings saved");
    else toast.warning("Saved on this device only. Run the portal database script so everyone sees it.");
  };

  const saveChoice = async (cohortId: string, studentId: string, next: PlanChoice | null) => {
    const key = choiceKey(cohortId, studentId);
    setChoices((m) => { const copy = { ...m }; if (next) copy[key] = next; else delete copy[key]; return copy; });
    const res = await kvSave(key, next ?? { planId: "", approved: false, at: new Date().toISOString() });
    if (!res.shared) toast.warning(res.error ? `Could not save for everyone: ${res.error}` : "Saved on this device only.");
    return res.shared;
  };

  const title = role === "Student" ? "My Cohorts" : role === "Teacher" ? "My Assigned Cohorts" : "Cohort Learning";
  const subtitle = role === "Student"
    ? "Your cohorts, learning plan, weekly modules and progress."
    : canManage
      ? "Create the cohort structure: category, learning plans, capacity, deadlines and completion rules."
      : "Cohorts, enrolled students, weekly modules and progress.";

  return (
    <div className="space-y-5">
      <SectionHeader title={title} subtitle={subtitle} />
      {loading ? (
        <Loader2 className="mx-auto h-6 w-6 animate-spin text-emerald-700" aria-label="Loading cohorts" />
      ) : cohorts.length === 0 ? (
        <EmptyState
          icon={Users}
          title={role === "Student" ? "You are not in a cohort yet" : "No cohorts to show"}
          hint={role === "Student" ? "Once admissions places you in a cohort it will appear here." : canManage ? "Create a cohort in Cohort Coordinator first, then configure it here." : "Cohorts assigned to you will appear here."}
        />
      ) : (
        <div className="space-y-3">
          {cohorts.map((cohort) => {
            const cfg = cfgOf(cohort.id);
            const program = state.programs.find((p) => p.id === cohort.programId);
            const open = openId === cohort.id;
            return (
              <article key={cohort.id} className={cn(panelClass, "overflow-hidden")}>
                <button
                  type="button"
                  onClick={() => setOpenId(open ? null : cohort.id)}
                  aria-expanded={open}
                  className="flex w-full items-center gap-3 p-4 text-left sm:p-5"
                >
                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <h3 className="truncate font-semibold text-slate-900">{cohort.name}</h3>
                      <span className={cn("rounded-full px-2 py-0.5 text-[11px] font-semibold", STATUS_STYLE[cfg.status])}>{STATUS_LABEL[cfg.status]}</span>
                      <span className="rounded-full bg-sky-100 px-2 py-0.5 text-[11px] font-semibold text-sky-800">
                        {cfg.category === "online" ? "Fully online cohort" : "Partially based cohort"}
                      </span>
                    </div>
                    <p className="mt-1 text-xs text-slate-500">
                      {program?.title ?? "Course"} · {cohort.startDate} to {cohort.endDate} · {cohort.studentIds.length}/{cfg.capacity || "∞"} students
                    </p>
                  </div>
                  <ChevronDown className={cn("h-5 w-5 shrink-0 text-slate-400 transition-transform", open && "rotate-180")} />
                </button>
                {open && (
                  <CohortBody
                    cohort={cohort}
                    cfg={cfg}
                    choices={choices}
                    canManage={canManage}
                    onEdit={() => setEditing(cohort)}
                    onStatus={(status) => void saveConfig(cohort.id, { ...cfg, status })}
                    onChoice={saveChoice}
                  />
                )}
              </article>
            );
          })}
        </div>
      )}
      {editing && (
        <ConfigDialog
          cohort={editing}
          initial={cfgOf(editing.id)}
          onClose={() => setEditing(null)}
          onSave={async (next) => { await saveConfig(editing.id, next); setEditing(null); }}
        />
      )}
    </div>
  );
}

function CohortBody({
  cohort, cfg, choices, canManage, onEdit, onStatus, onChoice,
}: {
  cohort: Cohort;
  cfg: CohortConfig;
  choices: Record<string, PlanChoice>;
  canManage: boolean;
  onEdit: () => void;
  onStatus: (s: Status) => void;
  onChoice: (cohortId: string, studentId: string, next: PlanChoice | null) => Promise<boolean>;
}) {
  const { state, currentUser } = useApp();
  const isStudent = currentUser?.role === "Student";
  const partial = cfg.category === "partial";
  const myChoice = currentUser ? choices[choiceKey(cohort.id, currentUser.id)] : undefined;
  const myPlan = cfg.plans.find((p) => p.id === myChoice?.planId);
  const deadlinePassed = !!cfg.registrationDeadline && new Date(cfg.registrationDeadline).getTime() + 86400000 < Date.now();
  const canPick = cfg.status === "active" && !deadlinePassed && !(myChoice?.approved);

  return (
    <div className="space-y-5 border-t border-slate-100 p-4 sm:p-5">
      {canManage && (
        <div className="flex flex-wrap items-center gap-2">
          <Button size="sm" variant="outline" onClick={onEdit}><Pencil className="mr-1.5 h-4 w-4" />Configure cohort</Button>
          {(["active", "suspended", "closed", "archived"] as Status[]).filter((s) => s !== cfg.status).map((s) => (
            <Button key={s} size="sm" variant="ghost" onClick={() => onStatus(s)}>{s === "active" ? "Activate" : s === "suspended" ? "Suspend" : s === "closed" ? "Close" : "Archive"}</Button>
          ))}
        </div>
      )}

      <dl className="grid gap-3 text-sm sm:grid-cols-2">
        <Info label="Registration deadline" value={cfg.registrationDeadline || "Not set"} />
        <Info label="Weekly learning requirement" value={cfg.weeklyRequirement || "Not set"} />
        <Info label="Assessment requirements" value={cfg.assessmentRequirements || "Not set"} />
        <Info label="Completion criteria" value={cfg.completionCriteria || "Not set"} />
      </dl>

      {partial && (
        <section aria-label="Learning plans" className="space-y-3">
          <h4 className="text-sm font-semibold text-slate-900">Learning plans</h4>
          {cfg.plans.length === 0 ? (
            <p className="text-sm text-slate-500">No learning plans have been published for this cohort yet.</p>
          ) : isStudent ? (
            <div className="space-y-2">
              {myChoice && myPlan && (
                <p className={cn("rounded-lg px-3 py-2 text-sm font-medium", myChoice.approved ? "bg-emerald-50 text-emerald-800" : "bg-amber-50 text-amber-800")}>
                  {myChoice.approved ? "Approved plan: " : "Waiting for approval: "}{myPlan.name}
                </p>
              )}
              {cfg.plans.map((plan) => (
                <PlanCard key={plan.id} plan={plan} selected={myChoice?.planId === plan.id}
                  action={canPick && myChoice?.planId !== plan.id ? (
                    <Button size="sm" onClick={async () => {
                      if (!currentUser) return;
                      if (await onChoice(cohort.id, currentUser.id, { planId: plan.id, approved: false, at: new Date().toISOString() })) toast.success("Plan requested. An administrator will approve it.");
                    }}>Choose this plan</Button>
                  ) : null} />
              ))}
              {!canPick && !myChoice?.approved && <p className="text-xs text-slate-500">{cfg.status !== "active" ? "This cohort is not open for plan selection." : "The registration deadline has passed."}</p>}
            </div>
          ) : (
            <div className="grid gap-2 md:grid-cols-2">{cfg.plans.map((p) => <PlanCard key={p.id} plan={p} />)}</div>
          )}
        </section>
      )}

      {!isStudent && <Roster cohort={cohort} cfg={cfg} choices={choices} canManage={canManage} onChoice={onChoice} users={state.users} />}

      <Weeks cohort={cohort} isStudent={isStudent} userId={currentUser?.id} cohortIds={currentUser?.cohortIds} />

      <div className="flex flex-wrap gap-2">
        {isStudent ? (
          <>
            <Button size="sm" variant="outline" onClick={() => openView("course-player")}>Open lessons</Button>
            <Button size="sm" variant="outline" onClick={() => openView("study-materials")}>Study materials</Button>
            <Button size="sm" variant="outline" onClick={() => openView("assignments")}>Assignments</Button>
            <Button size="sm" variant="outline" onClick={() => openView("quizzes")}>Assessments</Button>
            <Button size="sm" variant="outline" onClick={() => openView("announcements")}>Announcements</Button>
            {partial && <Button size="sm" variant="outline" onClick={() => openView("timetable")}><CalendarDays className="mr-1.5 h-4 w-4" />Onsite schedule</Button>}
            {partial && <Button size="sm" variant="outline" onClick={() => openView("attendance")}>Attendance</Button>}
            <Button size="sm" variant="outline" onClick={() => openView("certificates")}>Certificate status</Button>
          </>
        ) : (
          <>
            <Button size="sm" variant="outline" onClick={() => openView("training-library")}>Learning materials</Button>
            <Button size="sm" variant="outline" onClick={() => openView("academic-planning")}>Weekly modules</Button>
            <Button size="sm" variant="outline" onClick={() => openView("assignments")}>Assignments & grading</Button>
            <Button size="sm" variant="outline" onClick={() => openView("quizzes")}>Quizzes & exams</Button>
            <Button size="sm" variant="outline" onClick={() => openView("attendance")}>Attendance</Button>
            <Button size="sm" variant="outline" onClick={() => openView("timetable")}>Timetable</Button>
            <Button size="sm" variant="outline" onClick={() => openView("announcements")}>Announcements</Button>
          </>
        )}
      </div>
    </div>
  );
}

function Info({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-lg bg-slate-50 p-3">
      <dt className="text-[11px] font-semibold uppercase tracking-wide text-slate-500">{label}</dt>
      <dd className="mt-1 whitespace-pre-line break-words text-slate-800">{value}</dd>
    </div>
  );
}

function PlanCard({ plan, selected, action }: { plan: Plan; selected?: boolean; action?: React.ReactNode }) {
  return (
    <div className={cn("rounded-xl border p-3 text-sm", selected ? "border-emerald-500 bg-emerald-50/50" : "border-slate-200")}>
      <p className="font-semibold text-slate-900">{plan.name}</p>
      <p className="mt-0.5 text-xs text-emerald-800">{plan.arrangement}</p>
      {plan.onsiteSchedule && <p className="mt-2 flex items-start gap-1.5 text-slate-600"><Clock className="mt-0.5 h-3.5 w-3.5 shrink-0" />Onsite: {plan.onsiteSchedule}</p>}
      {plan.assessment && <p className="mt-1 text-slate-600">Assessment: {plan.assessment}</p>}
      {action && <div className="mt-3">{action}</div>}
    </div>
  );
}

function Roster({
  cohort, cfg, choices, canManage, onChoice, users,
}: {
  cohort: Cohort;
  cfg: CohortConfig;
  choices: Record<string, PlanChoice>;
  canManage: boolean;
  onChoice: (cohortId: string, studentId: string, next: PlanChoice | null) => Promise<boolean>;
  users: { id: string; name: string }[];
}) {
  const names = new Map(users.map((u) => [u.id, u.name]));
  return (
    <section aria-label="Enrolled students">
      <h4 className="mb-2 text-sm font-semibold text-slate-900">Enrolled students ({cohort.studentIds.length})</h4>
      {cohort.studentIds.length === 0 ? (
        <p className="text-sm text-slate-500">No students enrolled yet.</p>
      ) : (
        <ul className="divide-y divide-slate-100 rounded-xl border border-slate-100">
          {cohort.studentIds.map((sid) => {
            const choice = choices[choiceKey(cohort.id, sid)];
            const plan = cfg.plans.find((p) => p.id === choice?.planId);
            return (
              <li key={sid} className="flex flex-wrap items-center gap-2 px-3 py-2 text-sm">
                <span className="min-w-0 flex-1 truncate font-medium text-slate-800">{names.get(sid) ?? "Student"}</span>
                {cfg.category === "partial" && (
                  plan ? (
                    <>
                      <span className="truncate text-xs text-slate-500">{plan.name}</span>
                      <span className={cn("rounded-full px-2 py-0.5 text-[11px] font-semibold", choice?.approved ? "bg-emerald-100 text-emerald-800" : "bg-amber-100 text-amber-800")}>
                        {choice?.approved ? "Approved" : "Pending"}
                      </span>
                      {canManage && (
                        <>
                          <Button size="sm" variant="outline" className="h-7" onClick={() => void onChoice(cohort.id, sid, { ...choice!, approved: !choice!.approved })}>
                            {choice?.approved ? "Revoke" : <><CheckCircle2 className="mr-1 h-3.5 w-3.5" />Approve</>}
                          </Button>
                          <Button size="sm" variant="ghost" className="h-7 text-rose-600" aria-label="Remove plan choice" onClick={() => void onChoice(cohort.id, sid, null)}><Trash2 className="h-3.5 w-3.5" /></Button>
                        </>
                      )}
                    </>
                  ) : <span className="text-xs text-slate-400">No plan chosen</span>
                )}
              </li>
            );
          })}
        </ul>
      )}
    </section>
  );
}

/** Course → Cohort → Week → Module → Lesson, read from the existing learning units. */
function Weeks({ cohort, isStudent, userId, cohortIds }: { cohort: Cohort; isStudent: boolean; userId?: string; cohortIds?: string[] }) {
  const [units, setUnits] = useState<LearningUnit[] | null>(null);
  const [progress, setProgress] = useState<StudentProgressRow[]>([]);
  const [error, setError] = useState("");

  useEffect(() => {
    let alive = true;
    (async () => {
      try {
        const rows = await academicApi.units([cohort.programId], [cohort.id]);
        const prog = isStudent && userId ? await academicApi.myProgress(cohortIds).catch(() => [] as StudentProgressRow[]) : [];
        if (!alive) return;
        setUnits(rows.filter((u) => u.cohort_id === cohort.id || (!u.cohort_id && u.program_id === cohort.programId)).sort((a, b) => a.position - b.position));
        setProgress(prog);
      } catch (err) {
        if (alive) setError(err instanceof Error ? err.message : "Could not load lessons.");
      }
    })();
    return () => { alive = false; };
  }, [cohort.id, cohort.programId, isStudent, userId, cohortIds]);

  const done = new Set(progress.filter((p) => p.status === "completed").map((p) => p.learning_unit_id));

  const weeks = useMemo(() => {
    const list: { title: string; items: LearningUnit[] }[] = [];
    for (const u of units ?? []) {
      if (u.unit_type === "chapter" || list.length === 0) list.push({ title: u.unit_type === "chapter" ? u.title : "Week 1", items: u.unit_type === "chapter" ? [] : [u] });
      else list[list.length - 1].items.push(u);
    }
    return list;
  }, [units]);

  if (error) return <p className="text-sm text-rose-700">{error}</p>;
  if (!units) return <Loader2 className="h-5 w-5 animate-spin text-emerald-700" aria-label="Loading weekly modules" />;
  const lessons = units.filter((u) => u.unit_type !== "chapter");
  const percent = lessons.length ? Math.round((lessons.filter((u) => done.has(u.id)).length / lessons.length) * 100) : 0;

  return (
    <section aria-label="Weekly learning modules" className="space-y-2">
      <div className="flex items-center justify-between gap-3">
        <h4 className="text-sm font-semibold text-slate-900">Weekly learning modules</h4>
        {isStudent && lessons.length > 0 && <span className="text-xs font-semibold text-emerald-800">{percent}% complete</span>}
      </div>
      {isStudent && lessons.length > 0 && (
        <div className="h-2 overflow-hidden rounded-full bg-slate-100"><div className="h-full bg-emerald-600" style={{ width: `${percent}%` }} /></div>
      )}
      {weeks.length === 0 ? (
        <p className="text-sm text-slate-500">No weekly modules have been added yet. Instructors add chapters (weeks), modules and lessons in Course Planning.</p>
      ) : (
        <ol className="space-y-2">
          {weeks.map((w, i) => (
            <li key={`${w.title}-${i}`} className="rounded-xl border border-slate-100 p-3">
              <p className="text-xs font-semibold uppercase tracking-wide text-emerald-700">Week {i + 1}</p>
              <p className="font-medium text-slate-900">{w.title}</p>
              {w.items.length > 0 && (
                <ul className="mt-2 space-y-1">
                  {w.items.map((u) => (
                    <li key={u.id} className="flex items-center gap-2 text-sm text-slate-700">
                      <CheckCircle2 className={cn("h-4 w-4 shrink-0", done.has(u.id) ? "text-emerald-600" : "text-slate-300")} />
                      <span className="min-w-0 flex-1 truncate">{u.unit_type === "module" ? "Module: " : "Lesson: "}{u.title}</span>
                    </li>
                  ))}
                </ul>
              )}
            </li>
          ))}
        </ol>
      )}
    </section>
  );
}

function ConfigDialog({ cohort, initial, onClose, onSave }: { cohort: Cohort; initial: CohortConfig; onClose: () => void; onSave: (c: CohortConfig) => Promise<void> }) {
  const [form, setForm] = useState<CohortConfig>(initial);
  const [busy, setBusy] = useState(false);
  const set = <K extends keyof CohortConfig>(k: K, v: CohortConfig[K]) => setForm((f) => ({ ...f, [k]: v }));
  const setPlan = (id: string, patch: Partial<Plan>) => set("plans", form.plans.map((p) => (p.id === id ? { ...p, ...patch } : p)));

  return (
    <Dialog open onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-2xl">
        <DialogHeader><DialogTitle>Configure {cohort.name}</DialogTitle></DialogHeader>
        <div className="grid gap-4 sm:grid-cols-2">
          <div>
            <Label htmlFor="cl-cat">Cohort category</Label>
            <select id="cl-cat" className={selectClass} value={form.category} onChange={(e) => set("category", e.target.value as Category)}>
              <option value="online">Category A: Fully online</option>
              <option value="partial">Category B: Partially based (selected plans)</option>
            </select>
          </div>
          <div>
            <Label htmlFor="cl-status">Status</Label>
            <select id="cl-status" className={selectClass} value={form.status} onChange={(e) => set("status", e.target.value as Status)}>
              {(Object.keys(STATUS_LABEL) as Status[]).map((s) => <option key={s} value={s}>{STATUS_LABEL[s]}</option>)}
            </select>
          </div>
          <div>
            <Label htmlFor="cl-cap">Capacity</Label>
            <Input id="cl-cap" type="number" min={0} value={form.capacity} onChange={(e) => set("capacity", Number(e.currentTarget.value) || 0)} />
          </div>
          <div>
            <Label htmlFor="cl-deadline">Registration deadline</Label>
            <Input id="cl-deadline" type="date" value={form.registrationDeadline} onChange={(e) => set("registrationDeadline", e.currentTarget.value)} />
          </div>
          <div className="sm:col-span-2">
            <Label htmlFor="cl-week">Weekly learning requirements</Label>
            <Textarea id="cl-week" rows={2} value={form.weeklyRequirement} onChange={(e) => set("weeklyRequirement", e.currentTarget.value)} placeholder="e.g. Complete one module and one quiz each week" />
          </div>
          <div className="sm:col-span-2">
            <Label htmlFor="cl-assess">Assessment requirements</Label>
            <Textarea id="cl-assess" rows={2} value={form.assessmentRequirements} onChange={(e) => set("assessmentRequirements", e.currentTarget.value)} />
          </div>
          <div className="sm:col-span-2">
            <Label htmlFor="cl-complete">Completion criteria</Label>
            <Textarea id="cl-complete" rows={2} value={form.completionCriteria} onChange={(e) => set("completionCriteria", e.currentTarget.value)} placeholder="e.g. 100% of lessons, 70% average, 80% onsite attendance" />
          </div>
        </div>

        {form.category === "partial" && (
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <h4 className="text-sm font-semibold text-slate-900">Approved learning plans</h4>
              <Button size="sm" variant="outline" onClick={() => set("plans", [...form.plans, { id: uid(), name: "", arrangement: ARRANGEMENTS[0], onsiteSchedule: "", assessment: "" }])}>
                <Plus className="mr-1 h-4 w-4" />Add plan
              </Button>
            </div>
            {form.plans.map((p) => (
              <div key={p.id} className="space-y-2 rounded-xl border border-slate-200 p-3">
                <div className="flex gap-2">
                  <Input aria-label="Plan name" placeholder="Plan name" value={p.name} onChange={(e) => setPlan(p.id, { name: e.currentTarget.value })} />
                  <Button size="icon" variant="ghost" aria-label="Remove plan" className="text-rose-600" onClick={() => set("plans", form.plans.filter((x) => x.id !== p.id))}><Trash2 className="h-4 w-4" /></Button>
                </div>
                <select aria-label="Arrangement" className={selectClass} value={p.arrangement} onChange={(e) => setPlan(p.id, { arrangement: e.target.value })}>
                  {ARRANGEMENTS.map((a) => <option key={a}>{a}</option>)}
                </select>
                <Input aria-label="Onsite schedule" placeholder="Physical training schedule (e.g. Saturdays 9:00 to 13:00, Lab 2)" value={p.onsiteSchedule} onChange={(e) => setPlan(p.id, { onsiteSchedule: e.currentTarget.value })} />
                <Input aria-label="Assessment arrangement" placeholder="Assessment arrangement" value={p.assessment} onChange={(e) => setPlan(p.id, { assessment: e.currentTarget.value })} />
              </div>
            ))}
          </div>
        )}

        <div className="flex justify-end gap-2">
          <Button variant="outline" onClick={onClose}>Cancel</Button>
          <Button
            disabled={busy || (form.category === "partial" && form.plans.some((p) => !p.name.trim()))}
            onClick={async () => { setBusy(true); await onSave(form); setBusy(false); }}
          >
            {busy ? "Saving…" : "Save changes"}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
