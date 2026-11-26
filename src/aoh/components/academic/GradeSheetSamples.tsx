import { useEffect, useMemo, useState } from "react";
import { Plus, Printer, RotateCcw, Save, Trash2, Users } from "lucide-react";
import { toast } from "sonner";
import { letterGrade, useApp } from "@/aoh/context/AppContext";
import { Button } from "@/aoh/components/ui/button";
import { kvLoad, kvSave } from "@/aoh/lib/portalKv";
import { cn } from "@/aoh/lib/utils";

interface ReportRow { id: string; subject: string; ca: number; exam: number }
interface Report {
  school: string;
  title: string;
  student: string;
  studentId: string;
  programme: string;
  term: string;
  attendance: string;
  rows: ReportRow[];
  teacherComment: string;
  principalComment: string;
  teacher: string;
  principal: string;
}
interface SheetRow { id: string; name: string; scores: number[] }
interface Sheet {
  school: string;
  title: string;
  cohort: string;
  term: string;
  cols: string[];
  max: number[];
  rows: SheetRow[];
}

const uid = () => Math.random().toString(36).slice(2, 9);

const sampleReport = (school: string): Report => ({
  school,
  title: "Student Report Card",
  student: "Amara Okafor",
  studentId: "AOH-0001",
  programme: "Professional Certificate in Digital Skills",
  term: "Term 1 · 2026/2027",
  attendance: "94%",
  rows: [
    { id: uid(), subject: "Digital Literacy", ca: 34, exam: 52 },
    { id: uid(), subject: "Communication Skills", ca: 30, exam: 48 },
    { id: uid(), subject: "Spreadsheets & Data", ca: 36, exam: 55 },
    { id: uid(), subject: "Professional Ethics", ca: 28, exam: 44 },
    { id: uid(), subject: "Project Work", ca: 38, exam: 54 },
  ],
  teacherComment: "Amara is attentive and consistent. Keep practising written reports to lift the exam score further.",
  principalComment: "A strong term. We are proud of your progress.",
  teacher: "Class Instructor",
  principal: "Director of Education",
});

const sampleSheet = (school: string): Sheet => ({
  school,
  title: "Class Grade Sheet",
  cohort: "Digital Skills · Cohort A",
  term: "Term 1 · 2026/2027",
  cols: ["Quiz 1", "Assignment", "Midterm", "Final"],
  max: [10, 20, 30, 40],
  rows: [
    { id: uid(), name: "Amara Okafor", scores: [9, 18, 26, 35] },
    { id: uid(), name: "Kwame Mensah", scores: [8, 15, 22, 31] },
    { id: uid(), name: "Fatima Bello", scores: [10, 19, 28, 37] },
    { id: uid(), name: "Daniel Tesfaye", scores: [7, 14, 20, 29] },
  ],
});

const plain = "w-full min-w-0 rounded border border-transparent bg-transparent px-1.5 py-1 outline-none hover:border-slate-300 focus:border-emerald-600 focus:bg-emerald-50/40 print:border-0";
const num = cn(plain, "text-center tabular-nums");

function Head({ school, title, onSchool, onTitle }: { school: string; title: string; onSchool: (v: string) => void; onTitle: (v: string) => void }) {
  return (
    <header className="border-b-2 border-emerald-800 pb-3 text-center">
      <input aria-label="School name" className={cn(plain, "text-center text-xl font-extrabold uppercase tracking-wide text-emerald-900")} value={school} onChange={(e) => onSchool(e.currentTarget.value)} />
      <input aria-label="Document title" className={cn(plain, "text-center text-sm font-bold uppercase tracking-[0.25em] text-amber-600")} value={title} onChange={(e) => onTitle(e.currentTarget.value)} />
    </header>
  );
}

function Field({ label, value, onChange }: { label: string; value: string; onChange: (v: string) => void }) {
  return (
    <label className="block min-w-0">
      <span className="text-[10px] font-bold uppercase tracking-wide text-slate-500">{label}</span>
      <input className={cn(plain, "font-medium text-slate-900")} value={value} onChange={(e) => onChange(e.currentTarget.value)} />
    </label>
  );
}

export default function GradeSheetSamples() {
  const { state, currentUser } = useApp();
  const school = state.settings.academyName || "Africa of Hope";
  const canEditShared = currentUser?.role !== "Student";
  const [mode, setMode] = useState<"report" | "sheet">("report");
  const [report, setReport] = useState<Report>(() => sampleReport(school));
  const [sheet, setSheet] = useState<Sheet>(() => sampleSheet(school));
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    void kvLoad<Report | null>("academic-report-sample", null).then((r) => r && setReport(r));
    void kvLoad<Sheet | null>("academic-sheet-sample", null).then((r) => r && setSheet(r));
  }, []);

  const reportTotals = useMemo(() => {
    const total = report.rows.reduce((t, r) => t + (Number(r.ca) || 0) + (Number(r.exam) || 0), 0);
    const avg = report.rows.length ? total / report.rows.length : 0;
    return { total, avg };
  }, [report.rows]);

  const save = async () => {
    setSaving(true);
    const res = mode === "report" ? await kvSave("academic-report-sample", report) : await kvSave("academic-sheet-sample", sheet);
    setSaving(false);
    if (res.shared) toast.success("Template saved for everyone");
    else toast.warning("Saved on this device only", { description: "Run the portal_kv database script so other staff see it." });
  };

  const reset = () => {
    if (!window.confirm("Reset this sample to the original?")) return;
    if (mode === "report") setReport(sampleReport(school));
    else setSheet(sampleSheet(school));
  };

  const fromCohort = (cohortId: string) => {
    const c = state.cohorts.find((x) => x.id === cohortId);
    if (!c) return;
    const assignments = state.assignments.filter((a) => a.cohortId === c.id).slice(0, 6);
    if (assignments.length === 0) {
      toast.info("This cohort has no assignments yet, so there are no marks to load.");
      return;
    }
    setSheet({
      school,
      title: "Class Grade Sheet",
      cohort: c.name,
      term: `${state.settings.academicYear} · ${state.settings.semester}`,
      cols: assignments.map((a) => a.title.slice(0, 18)),
      max: assignments.map((a) => a.maxMarks),
      rows: c.studentIds.map((sid) => ({
        id: sid,
        name: state.users.find((u) => u.id === sid)?.name ?? sid,
        scores: assignments.map((a) => state.submissions.find((s) => s.assignmentId === a.id && s.studentId === sid)?.marks ?? 0),
      })),
    });
    toast.success("Loaded real marks. You can still edit them.");
  };

  const setRow = (id: string, patch: Partial<ReportRow>) => setReport((r) => ({ ...r, rows: r.rows.map((x) => (x.id === id ? { ...x, ...patch } : x)) }));

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-3 print:hidden">
        <div>
          <h2 className="text-xl font-bold text-slate-900">Report card and grade sheet samples</h2>
          <p className="text-sm text-slate-600">Click any text or number to edit it. Totals and grades update by themselves.</p>
        </div>
        <div className="flex flex-wrap gap-2">
          <Button variant="outline" onClick={reset}><RotateCcw className="mr-1.5 h-4 w-4" /> Reset</Button>
          {canEditShared && (
            <Button variant="outline" disabled={saving} onClick={() => void save()}><Save className="mr-1.5 h-4 w-4" /> {saving ? "Saving…" : "Save template"}</Button>
          )}
          <Button onClick={() => window.print()} className="bg-amber-500 text-slate-950 hover:bg-amber-400"><Printer className="mr-1.5 h-4 w-4" /> Print / Save PDF</Button>
        </div>
      </div>

      <div className="flex flex-wrap items-end gap-2 print:hidden" role="tablist" aria-label="Sample type">
        {(["report", "sheet"] as const).map((m) => (
          <button key={m} type="button" role="tab" aria-selected={mode === m} onClick={() => setMode(m)} className={cn("h-10 rounded-xl px-4 text-sm font-semibold", mode === m ? "bg-emerald-800 text-white" : "bg-slate-100 text-slate-700 hover:bg-slate-200")}>
            {m === "report" ? "Report card" : "Grade sheet"}
          </button>
        ))}
        {mode === "sheet" && (
          <label className="ml-auto flex items-center gap-2 text-sm text-slate-600">
            <Users className="h-4 w-4" />
            <select className="h-10 rounded-md border border-slate-300 bg-white px-2 text-sm" defaultValue="" onChange={(e) => { if (e.currentTarget.value) fromCohort(e.currentTarget.value); e.currentTarget.value = ""; }}>
              <option value="">Fill from a real cohort…</option>
              {state.cohorts.map((c) => (<option key={c.id} value={c.id}>{c.name}</option>))}
            </select>
          </label>
        )}
      </div>

      {mode === "report" ? (
        <div className="print-area doc-portrait mx-auto w-full max-w-3xl rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-9 print:max-w-none print:rounded-none print:border-0 print:p-0 print:shadow-none">
          <Head school={report.school} title={report.title} onSchool={(v) => setReport({ ...report, school: v })} onTitle={(v) => setReport({ ...report, title: v })} />
          <div className="mt-4 grid gap-2 sm:grid-cols-2">
            <Field label="Student" value={report.student} onChange={(v) => setReport({ ...report, student: v })} />
            <Field label="Student ID" value={report.studentId} onChange={(v) => setReport({ ...report, studentId: v })} />
            <Field label="Programme" value={report.programme} onChange={(v) => setReport({ ...report, programme: v })} />
            <Field label="Term" value={report.term} onChange={(v) => setReport({ ...report, term: v })} />
          </div>
          <div className="mt-4 overflow-x-auto">
            <table className="w-full min-w-[520px] text-sm">
              <thead>
                <tr className="bg-emerald-900 text-xs uppercase tracking-wide text-white">
                  <th className="px-2 py-2 text-left">Subject</th>
                  <th className="px-2 py-2">CA /40</th>
                  <th className="px-2 py-2">Exam /60</th>
                  <th className="px-2 py-2">Total</th>
                  <th className="px-2 py-2">Grade</th>
                  <th className="w-8 print:hidden" />
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-200">
                {report.rows.map((r) => {
                  const total = (Number(r.ca) || 0) + (Number(r.exam) || 0);
                  return (
                    <tr key={r.id} data-lp-row>
                      <td><input aria-label="Subject" className={plain} value={r.subject} onChange={(e) => setRow(r.id, { subject: e.currentTarget.value })} /></td>
                      <td><input aria-label="CA mark" type="number" className={num} value={r.ca} onChange={(e) => setRow(r.id, { ca: Number(e.currentTarget.value) })} /></td>
                      <td><input aria-label="Exam mark" type="number" className={num} value={r.exam} onChange={(e) => setRow(r.id, { exam: Number(e.currentTarget.value) })} /></td>
                      <td className="text-center font-semibold tabular-nums">{total}</td>
                      <td className="text-center"><span className="rounded-full bg-amber-100 px-2 py-0.5 text-xs font-bold text-amber-800">{letterGrade(total)}</span></td>
                      <td className="print:hidden"><button type="button" aria-label={`Delete ${r.subject}`} onClick={() => setReport({ ...report, rows: report.rows.filter((x) => x.id !== r.id) })} className="p-1 text-rose-500"><Trash2 className="h-4 w-4" /></button></td>
                    </tr>
                  );
                })}
              </tbody>
              <tfoot>
                <tr className="border-t-2 border-emerald-800 font-bold">
                  <td className="px-2 py-2">Overall</td><td /><td />
                  <td className="text-center tabular-nums">{reportTotals.total}</td>
                  <td className="text-center">{letterGrade(Math.round(reportTotals.avg))}</td>
                  <td className="print:hidden" />
                </tr>
              </tfoot>
            </table>
          </div>
          <Button type="button" variant="outline" size="sm" className="mt-2 print:hidden" onClick={() => setReport({ ...report, rows: [...report.rows, { id: uid(), subject: "New subject", ca: 0, exam: 0 }] })}>
            <Plus className="mr-1 h-3.5 w-3.5" /> Add subject
          </Button>
          <div className="mt-4 grid gap-2 sm:grid-cols-3">
            <Field label="Average" value={`${reportTotals.avg.toFixed(1)} / 100`} onChange={() => undefined} />
            <Field label="Attendance" value={report.attendance} onChange={(v) => setReport({ ...report, attendance: v })} />
            <Field label="Pass mark" value={`${state.settings.passMark}%`} onChange={() => undefined} />
          </div>
          {([["Instructor's comment", "teacherComment"], ["Director's comment", "principalComment"]] as const).map(([l, k]) => (
            <label key={k} className="mt-3 block">
              <span className="text-[10px] font-bold uppercase tracking-wide text-slate-500">{l}</span>
              <textarea rows={2} className={cn(plain, "resize-none")} value={report[k]} onChange={(e) => setReport({ ...report, [k]: e.currentTarget.value })} />
            </label>
          ))}
          <div className="mt-10 grid grid-cols-2 gap-8 text-xs">
            <div className="border-t border-slate-400 pt-1"><input aria-label="Instructor label" className={plain} value={report.teacher} onChange={(e) => setReport({ ...report, teacher: e.currentTarget.value })} /></div>
            <div className="border-t border-slate-400 pt-1"><input aria-label="Director label" className={cn(plain, "text-right")} value={report.principal} onChange={(e) => setReport({ ...report, principal: e.currentTarget.value })} /></div>
          </div>
        </div>
      ) : (
        <div className="print-area doc-portrait mx-auto w-full max-w-4xl rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-8 print:max-w-none print:rounded-none print:border-0 print:p-0 print:shadow-none">
          <Head school={sheet.school} title={sheet.title} onSchool={(v) => setSheet({ ...sheet, school: v })} onTitle={(v) => setSheet({ ...sheet, title: v })} />
          <div className="mt-4 grid gap-2 sm:grid-cols-2">
            <Field label="Cohort" value={sheet.cohort} onChange={(v) => setSheet({ ...sheet, cohort: v })} />
            <Field label="Term" value={sheet.term} onChange={(v) => setSheet({ ...sheet, term: v })} />
          </div>
          <div className="mt-4 overflow-x-auto">
            <table className="w-full min-w-[560px] text-sm">
              <thead>
                <tr className="bg-emerald-900 text-xs uppercase tracking-wide text-white">
                  <th className="px-2 py-2 text-left">#</th>
                  <th className="px-2 py-2 text-left">Student</th>
                  {sheet.cols.map((c, i) => (
                    <th key={i} className="px-1 py-1">
                      <input aria-label="Column name" className={cn(num, "text-white placeholder:text-white/60 hover:border-white/40 focus:bg-emerald-800")} value={c} onChange={(e) => setSheet({ ...sheet, cols: sheet.cols.map((x, j) => (j === i ? e.currentTarget.value : x)) })} />
                      <input aria-label="Column maximum" type="number" className={cn(num, "text-[11px] font-normal text-emerald-100 hover:border-white/40 focus:bg-emerald-800")} value={sheet.max[i]} onChange={(e) => setSheet({ ...sheet, max: sheet.max.map((x, j) => (j === i ? Number(e.currentTarget.value) : x)) })} />
                    </th>
                  ))}
                  <th className="px-2 py-2">%</th>
                  <th className="px-2 py-2">Grade</th>
                  <th className="w-8 print:hidden" />
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-200">
                {sheet.rows.map((r, idx) => {
                  const got = r.scores.reduce((t, v) => t + (Number(v) || 0), 0);
                  const max = sheet.max.reduce((t, v) => t + (Number(v) || 0), 0);
                  const pct = max ? Math.round((got / max) * 100) : 0;
                  return (
                    <tr key={r.id} data-lp-row>
                      <td className="px-2 text-slate-500">{idx + 1}</td>
                      <td><input aria-label="Student name" className={plain} value={r.name} onChange={(e) => setSheet({ ...sheet, rows: sheet.rows.map((x) => (x.id === r.id ? { ...x, name: e.currentTarget.value } : x)) })} /></td>
                      {sheet.cols.map((_, i) => (
                        <td key={i}><input aria-label="Mark" type="number" className={num} value={r.scores[i] ?? 0} onChange={(e) => setSheet({ ...sheet, rows: sheet.rows.map((x) => (x.id === r.id ? { ...x, scores: sheet.cols.map((__, j) => (j === i ? Number(e.currentTarget.value) : x.scores[j] ?? 0)) } : x)) })} /></td>
                      ))}
                      <td className="text-center font-semibold tabular-nums">{pct}%</td>
                      <td className="text-center"><span className="rounded-full bg-amber-100 px-2 py-0.5 text-xs font-bold text-amber-800">{letterGrade(pct)}</span></td>
                      <td className="print:hidden"><button type="button" aria-label={`Delete ${r.name}`} onClick={() => setSheet({ ...sheet, rows: sheet.rows.filter((x) => x.id !== r.id) })} className="p-1 text-rose-500"><Trash2 className="h-4 w-4" /></button></td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
          <div className="mt-2 flex flex-wrap gap-2 print:hidden">
            <Button type="button" variant="outline" size="sm" onClick={() => setSheet({ ...sheet, rows: [...sheet.rows, { id: uid(), name: "New student", scores: sheet.cols.map(() => 0) }] })}><Plus className="mr-1 h-3.5 w-3.5" /> Add student</Button>
            <Button type="button" variant="outline" size="sm" onClick={() => setSheet({ ...sheet, cols: [...sheet.cols, "New"], max: [...sheet.max, 10], rows: sheet.rows.map((x) => ({ ...x, scores: [...x.scores, 0] })) })}><Plus className="mr-1 h-3.5 w-3.5" /> Add column</Button>
          </div>
        </div>
      )}
    </div>
  );
}
