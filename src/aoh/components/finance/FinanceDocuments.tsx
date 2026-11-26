import { useEffect, useMemo, useState, type ReactNode } from "react";
import { FileText, ImagePlus, Pencil, Plus, Printer, ReceiptText, Save, Trash2, UserCheck } from "lucide-react";
import { imageToDataUrl } from "@/aoh/lib/imageResize";
import { toast } from "sonner";
import { formatCurrency, useApp } from "@/aoh/context/AppContext";
import { usePermission } from "@/aoh/hooks/usePermission";
import { Button } from "@/aoh/components/ui/button";
import { Input } from "@/aoh/components/ui/input";
import { Textarea } from "@/aoh/components/ui/textarea";
import UserAvatar from "@/aoh/components/UserAvatar";
import { kvLoad, kvSave } from "@/aoh/lib/portalKv";
import { cn } from "@/aoh/lib/utils";

type Tab = "invoice" | "slip" | "receipt";

interface Template {
  schoolName: string;
  tagline: string;
  address: string;
  contact: string;
  footerNote: string;
  terms: string;
  signatory: string;
  signatoryTitle: string;
  dueDays: number;
  signatureUrl: string;
}
interface StudentDoc {
  extra: { id: string; description: string; amount: number }[];
  discount: number;
  note: string;
}

const emptyDoc: StudentDoc = { extra: [], discount: 0, note: "" };
const fieldClass = "h-9 w-full rounded-md border border-slate-300 bg-white px-2.5 text-sm outline-none focus:border-emerald-600 focus:ring-2 focus:ring-emerald-600/20";

function Sheet({ children }: { children: ReactNode }) {
  return (
    <div className="print-area doc-portrait mx-auto w-full max-w-3xl rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-9 print:max-w-none print:rounded-none print:border-0 print:p-0 print:shadow-none">
      {children}
    </div>
  );
}

function Crest({ logoUrl, name }: { logoUrl: string; name: string }) {
  const [broken, setBroken] = useState(false);
  if (logoUrl && !broken)
    return <img src={logoUrl} alt={`${name} logo`} onError={() => setBroken(true)} className="aoh-logo h-16 w-16 shrink-0 object-contain sm:h-20 sm:w-20" />;
  return (
    <span aria-hidden className="grid h-16 w-16 shrink-0 place-items-center rounded-xl bg-emerald-900 text-xl font-black text-amber-400 sm:h-20 sm:w-20">
      {name.split(/\s+/).filter(Boolean).slice(0, 2).map((w) => w[0]?.toUpperCase()).join("") || "A"}
    </span>
  );
}

function Letterhead({ t, logoUrl, title, number, date }: { t: Template; logoUrl: string; title: string; number: string; date: string }) {
  const lines = t.address.split(/\n|,\s*/).map((l) => l.trim()).filter(Boolean);
  return (
    <header className="border-b-2 border-emerald-800 pb-4">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div className="flex min-w-0 items-center gap-3 sm:gap-4">
          <Crest logoUrl={logoUrl} name={t.schoolName} />
          <div className="min-w-0">
            <p className="break-words text-lg font-extrabold uppercase leading-tight tracking-wide text-emerald-900 sm:text-xl">{t.schoolName}</p>
            {t.tagline && <p className="text-xs italic text-slate-500">{t.tagline}</p>}
            <address className="mt-1 text-xs not-italic leading-5 text-slate-600">
              {lines.map((l) => (<span key={l} className="block break-words">{l}</span>))}
              {t.contact && <span className="block break-words">{t.contact}</span>}
            </address>
          </div>
        </div>
        <div className="shrink-0 rounded-lg bg-emerald-50 px-4 py-2 text-left sm:bg-transparent sm:p-0 sm:text-right">
          <p className="text-xl font-black tracking-[0.2em] text-amber-600 sm:text-2xl">{title}</p>
          <p className="mt-0.5 break-all font-mono text-xs text-slate-700">No. {number}</p>
          <p className="text-xs text-slate-500">Date: {date}</p>
        </div>
      </div>
    </header>
  );
}

function Signatures({ t }: { t: Template }) {
  return (
    <div className="mt-10 grid grid-cols-1 gap-8 text-xs text-slate-600 sm:grid-cols-2">
      <div className="border-t border-slate-400 pt-1">Received / acknowledged by</div>
      <div className="flex flex-col sm:items-end sm:text-right">
        {t.signatureUrl && <img src={t.signatureUrl} alt={`Signature of ${t.signatory}`} className="mb-1 h-14 w-auto max-w-[220px] object-contain object-left sm:object-right" />}
        <div className="w-full border-t border-slate-400 pt-1 sm:text-right">
          <span className="font-semibold text-slate-800">{t.signatory}</span>
          <br />
          {t.signatoryTitle}
        </div>
      </div>
    </div>
  );
}

export default function FinanceDocuments() {
  const { state, currentUser } = useApp();
  const canEdit = usePermission("fees.manage");
  const canView = usePermission("fees.view");
  const isStaff = canEdit || canView;
  const s = state.settings;

  const defaults: Template = useMemo(
    () => ({
      schoolName: s.academyName || "Africa of Hope",
      tagline: s.motto || "",
      address: s.address || "",
      contact: [s.contactEmail, s.contactPhone].filter(Boolean).join("  ·  "),
      footerNote: "Thank you for investing in your education.",
      terms: "Fees are non-transferable. Please quote the invoice or receipt number on every payment.",
      signatory: "Finance Office",
      signatoryTitle: s.academyName || "Africa of Hope",
      dueDays: 14,
      signatureUrl: "",
    }),
    [s.academyName, s.motto, s.address, s.contactEmail, s.contactPhone],
  );

  const logoUrl = state.websiteSettings.logos?.certificate || state.websiteSettings.logoUrl || "";
  const [tab, setTab] = useState<Tab>("invoice");
  const [template, setTemplate] = useState<Template>(defaults);
  const [editing, setEditing] = useState(false);
  const [studentId, setStudentId] = useState("");
  const [receiptId, setReceiptId] = useState("");
  const [doc, setDoc] = useState<StudentDoc>(emptyDoc);
  const [saving, setSaving] = useState(false);

  const students = useMemo(() => state.users.filter((u) => u.role === "Student"), [state.users]);

  useEffect(() => {
    void kvLoad<Template | null>("finance-template", null).then((saved) => setTemplate(saved ? { ...defaults, ...saved } : defaults));
  }, [defaults]);

  useEffect(() => {
    if (!isStaff && currentUser) setStudentId(currentUser.id);
    else if (!studentId && students[0]) setStudentId(students[0].id);
  }, [isStaff, currentUser, students, studentId]);

  const student = state.users.find((u) => u.id === studentId) ?? null;

  useEffect(() => {
    if (!studentId) return;
    void kvLoad<StudentDoc>(`finance-doc-${studentId}`, emptyDoc).then((d) => setDoc({ ...emptyDoc, ...d }));
  }, [studentId]);

  const myFees = useMemo(
    () => state.fees.filter((f) => f.studentId === studentId).sort((a, b) => b.date.localeCompare(a.date)),
    [state.fees, studentId],
  );
  useEffect(() => {
    if (!myFees.some((f) => f.id === receiptId)) setReceiptId(myFees[0]?.id ?? "");
  }, [myFees, receiptId]);

  const programs = useMemo(
    () => (student ? student.programIds.map((id) => state.programs.find((p) => p.id === id)).filter((p): p is NonNullable<typeof p> => !!p) : []),
    [student, state.programs],
  );
  const cohorts = student ? state.cohorts.filter((c) => student.cohortIds.includes(c.id) || c.studentIds.includes(student.id)) : [];

  const tuition = programs.reduce((t, p) => t + (p.tuition ?? 0), 0);
  const extraTotal = doc.extra.reduce((t, e) => t + (Number(e.amount) || 0), 0);
  const total = Math.max(tuition + extraTotal - (Number(doc.discount) || 0), 0);
  const paid = myFees.reduce((t, f) => t + f.amount, 0);
  const balance = Math.max(total - paid, 0);
  const today = new Date();
  const fmt = (d: Date | string) => new Date(d).toLocaleDateString(undefined, { day: "2-digit", month: "short", year: "numeric" });
  const idLabel = student?.accountNumber || student?.id.slice(0, 8).toUpperCase() || "—";
  const year = today.getFullYear();
  const due = new Date(today.getTime() + (Number(template.dueDays) || 0) * 86400000);
  const fee = myFees.find((f) => f.id === receiptId) ?? null;
  const paidUpTo = fee ? myFees.filter((f) => f.date <= fee.date).reduce((t, f) => t + f.amount, 0) : 0;

  const saveAll = async () => {
    setSaving(true);
    const a = await kvSave("finance-template", template);
    const b = studentId ? await kvSave(`finance-doc-${studentId}`, doc) : { shared: true };
    setSaving(false);
    setEditing(false);
    if (a.shared && b.shared) toast.success("Saved for everyone");
    else toast.warning("Saved on this device only", { description: "Run the portal_kv database script so other staff and students see your edits." });
  };

  const setT = <K extends keyof Template>(k: K, v: Template[K]) => setTemplate((t) => ({ ...t, [k]: v }));

  const tabs: { key: Tab; label: string; icon: typeof FileText }[] = [
    { key: "invoice", label: "Invoice", icon: FileText },
    { key: "slip", label: "Registration slip", icon: UserCheck },
    { key: "receipt", label: "Payment receipt", icon: ReceiptText },
  ];

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-3 print:hidden">
        <div>
          <h2 className="text-xl font-bold text-slate-900">Invoices, slips and receipts</h2>
          <p className="text-sm text-slate-600">Official documents ready to print or save as PDF.</p>
        </div>
        <div className="flex flex-wrap gap-2">
          {canEdit && !editing && (
            <Button variant="outline" onClick={() => setEditing(true)}>
              <Pencil className="mr-1.5 h-4 w-4" /> Edit
            </Button>
          )}
          {editing && (
            <Button disabled={saving} onClick={() => void saveAll()} className="bg-emerald-800 text-white hover:bg-emerald-900">
              <Save className="mr-1.5 h-4 w-4" /> {saving ? "Saving…" : "Save changes"}
            </Button>
          )}
          <Button onClick={() => window.print()} className="bg-amber-500 text-slate-950 hover:bg-amber-400">
            <Printer className="mr-1.5 h-4 w-4" /> Print / Save PDF
          </Button>
        </div>
      </div>

      <div className="flex flex-wrap items-end gap-3 print:hidden">
        <div className="flex flex-wrap gap-2" role="tablist" aria-label="Document type">
          {tabs.map((t) => (
            <button
              key={t.key}
              type="button"
              role="tab"
              aria-selected={tab === t.key}
              onClick={() => setTab(t.key)}
              className={cn("inline-flex h-10 items-center gap-1.5 rounded-xl px-4 text-sm font-semibold", tab === t.key ? "bg-emerald-800 text-white" : "bg-slate-100 text-slate-700 hover:bg-slate-200")}
            >
              <t.icon className="h-4 w-4" /> {t.label}
            </button>
          ))}
        </div>
        {isStaff && (
          <label className="min-w-0 flex-1 sm:max-w-xs">
            <span className="mb-1 block text-xs font-semibold text-slate-500">Student</span>
            <select className={fieldClass} value={studentId} onChange={(e) => setStudentId(e.currentTarget.value)}>
              {students.map((u) => (
                <option key={u.id} value={u.id}>
                  {u.name}
                </option>
              ))}
            </select>
          </label>
        )}
        {tab === "receipt" && myFees.length > 0 && (
          <label className="min-w-0 flex-1 sm:max-w-xs">
            <span className="mb-1 block text-xs font-semibold text-slate-500">Payment</span>
            <select className={fieldClass} value={receiptId} onChange={(e) => setReceiptId(e.currentTarget.value)}>
              {myFees.map((f) => (
                <option key={f.id} value={f.id}>
                  {fmt(f.date)} · {f.category} · {formatCurrency(f.amount)}
                </option>
              ))}
            </select>
          </label>
        )}
      </div>

      {editing && (
        <div className="grid gap-3 rounded-2xl border border-emerald-200 bg-emerald-50/50 p-4 print:hidden sm:grid-cols-2">
          {(
            [
              ["schoolName", "School name"],
              ["tagline", "Tagline"],
              ["contact", "Email and phone line"],
              ["signatory", "Signed by"],
              ["signatoryTitle", "Signer title"],
              ["footerNote", "Thank-you line"],
            ] as const
          ).map(([k, l]) => (
            <label key={k}>
              <span className="mb-1 block text-xs font-semibold text-slate-600">{l}</span>
              <Input value={template[k]} onChange={(e) => setT(k, e.currentTarget.value)} />
            </label>
          ))}
          <label>
            <span className="mb-1 block text-xs font-semibold text-slate-600">Payment due after (days)</span>
            <Input type="number" min={0} value={template.dueDays} onChange={(e) => setT("dueDays", Number(e.currentTarget.value))} />
          </label>
          <label>
            <span className="mb-1 block text-xs font-semibold text-slate-600">Discount for this student</span>
            <Input type="number" min={0} value={doc.discount} onChange={(e) => setDoc((d) => ({ ...d, discount: Number(e.currentTarget.value) }))} />
          </label>
          <div className="sm:col-span-2">
            <span className="mb-1 block text-xs font-semibold text-slate-600">Signature (PNG or JPG, shown above the signer line)</span>
            <div className="flex flex-wrap items-center gap-3">
              {template.signatureUrl ? (
                <img src={template.signatureUrl} alt="Current signature" className="h-14 w-auto rounded border border-slate-200 bg-white p-1" />
              ) : (
                <span className="text-xs text-slate-500">No signature uploaded yet.</span>
              )}
              <label className="inline-flex h-9 cursor-pointer items-center gap-1.5 rounded-md border border-slate-300 bg-white px-3 text-sm font-medium text-slate-700 hover:bg-slate-50">
                <ImagePlus className="h-4 w-4" /> Upload signature
                <input
                  type="file"
                  accept="image/*"
                  className="sr-only"
                  onChange={async (e) => {
                    const input = e.currentTarget;
                    const file = input.files?.[0];
                    input.value = "";
                    if (!file) return;
                    try {
                      setT("signatureUrl", await imageToDataUrl(file));
                      toast.success("Signature added. Press Save changes to keep it.");
                    } catch (err) {
                      toast.error(err instanceof Error ? err.message : "Could not use that image.");
                    }
                  }}
                />
              </label>
              {template.signatureUrl && (
                <Button type="button" variant="outline" size="sm" onClick={() => setT("signatureUrl", "")}>Remove</Button>
              )}
            </div>
          </div>
          <label className="sm:col-span-2">
            <span className="mb-1 block text-xs font-semibold text-slate-600">Address (one line per row, or separate with commas)</span>
            <Textarea rows={2} value={template.address} onChange={(e) => setT("address", e.currentTarget.value)} />
          </label>
          <label className="sm:col-span-2">
            <span className="mb-1 block text-xs font-semibold text-slate-600">Terms</span>
            <Textarea rows={2} value={template.terms} onChange={(e) => setT("terms", e.currentTarget.value)} />
          </label>
          <label className="sm:col-span-2">
            <span className="mb-1 block text-xs font-semibold text-slate-600">Note for this student</span>
            <Textarea rows={2} value={doc.note} onChange={(e) => setDoc((d) => ({ ...d, note: e.currentTarget.value }))} />
          </label>
          <div className="sm:col-span-2">
            <p className="mb-1 text-xs font-semibold text-slate-600">Extra invoice lines (books, exam fee…)</p>
            <div className="space-y-2">
              {doc.extra.map((l) => (
                <div key={l.id} className="flex gap-2">
                  <Input value={l.description} placeholder="Description" onChange={(e) => setDoc((d) => ({ ...d, extra: d.extra.map((x) => (x.id === l.id ? { ...x, description: e.currentTarget.value } : x)) }))} />
                  <Input className="w-28" type="number" value={l.amount} onChange={(e) => setDoc((d) => ({ ...d, extra: d.extra.map((x) => (x.id === l.id ? { ...x, amount: Number(e.currentTarget.value) } : x)) }))} />
                  <Button type="button" variant="outline" size="icon" aria-label="Remove line" onClick={() => setDoc((d) => ({ ...d, extra: d.extra.filter((x) => x.id !== l.id) }))}>
                    <Trash2 className="h-4 w-4 text-rose-600" />
                  </Button>
                </div>
              ))}
              <Button type="button" variant="outline" size="sm" onClick={() => setDoc((d) => ({ ...d, extra: [...d.extra, { id: `l${Date.now()}`, description: "", amount: 0 }] }))}>
                <Plus className="mr-1 h-3.5 w-3.5" /> Add line
              </Button>
            </div>
          </div>
        </div>
      )}

      {!student ? (
        <p className="rounded-xl border border-dashed border-slate-300 bg-white p-8 text-center text-sm text-slate-500">No student selected yet.</p>
      ) : tab === "invoice" ? (
        <Sheet>
          <Letterhead t={template} logoUrl={logoUrl} title="INVOICE" number={`INV-${idLabel}-${year}`} date={fmt(today)} />
          <section className="mt-5 flex flex-wrap items-center justify-between gap-3">
            <div className="flex items-center gap-3">
              <UserAvatar user={student} className="h-12 w-12 text-sm" />
              <div className="min-w-0">
                <p className="text-[11px] font-bold uppercase tracking-wide text-slate-500">Billed to</p>
                <p className="break-words font-semibold text-slate-900">{student.name}</p>
                <p className="break-all text-xs text-slate-600">Student ID {idLabel} · {student.email}</p>
              </div>
            </div>
            <div className="text-right text-xs text-slate-600">
              <p>Academic year: <b>{s.academicYear}</b></p>
              <p>Due by: <b>{fmt(due)}</b></p>
            </div>
          </section>
          <div className="mt-5 overflow-x-auto">
            <table className="w-full min-w-0 text-sm">
              <thead>
                <tr className="bg-emerald-900 text-left text-xs uppercase tracking-wide text-white">
                  <th className="px-3 py-2">Description</th>
                  <th className="px-3 py-2 text-right">Amount</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-200">
                {programs.map((p) => (
                  <tr key={p.id}>
                    <td className="px-3 py-2">{p.title} <span className="text-xs text-slate-500">tuition</span></td>
                    <td className="px-3 py-2 text-right">{formatCurrency(p.tuition ?? 0)}</td>
                  </tr>
                ))}
                {doc.extra.filter((e) => e.description || e.amount).map((e) => (
                  <tr key={e.id}>
                    <td className="px-3 py-2">{e.description || "Additional charge"}</td>
                    <td className="px-3 py-2 text-right">{formatCurrency(Number(e.amount) || 0)}</td>
                  </tr>
                ))}
                {programs.length === 0 && doc.extra.length === 0 && (
                  <tr><td colSpan={2} className="px-3 py-4 text-center text-slate-500">No programme charges yet.</td></tr>
                )}
              </tbody>
            </table>
          </div>
          <dl className="mt-4 w-full space-y-1 text-sm sm:ml-auto sm:max-w-xs">
            {doc.discount > 0 && (
              <div className="flex justify-between"><dt>Discount</dt><dd>− {formatCurrency(Number(doc.discount))}</dd></div>
            )}
            <div className="flex justify-between"><dt>Total</dt><dd className="font-semibold">{formatCurrency(total)}</dd></div>
            <div className="flex justify-between"><dt>Paid to date</dt><dd>{formatCurrency(paid)}</dd></div>
            <div className="flex justify-between border-t-2 border-emerald-800 pt-1 text-base font-extrabold text-emerald-900"><dt>Balance due</dt><dd>{formatCurrency(balance)}</dd></div>
          </dl>
          {doc.note && <p className="mt-4 whitespace-pre-line rounded-lg bg-amber-50 p-3 text-xs text-slate-700">{doc.note}</p>}
          <p className="mt-5 whitespace-pre-line text-xs text-slate-500">{template.terms}</p>
          <Signatures t={template} />
          <p className="mt-6 text-center text-xs italic text-slate-500">{template.footerNote}</p>
        </Sheet>
      ) : tab === "slip" ? (
        <Sheet>
          <Letterhead t={template} logoUrl={logoUrl} title="REGISTRATION SLIP" number={`REG-${idLabel}`} date={fmt(student.joinedDate || today)} />
          <section className="mt-6 flex flex-wrap items-center gap-4">
            <UserAvatar user={student} className="h-20 w-20 text-xl" />
            <div className="min-w-0">
              <p className="break-words text-xl font-bold text-slate-900">{student.name}</p>
              <p className="text-sm text-slate-600">Student ID <b className="font-mono">{idLabel}</b></p>
              <p className="text-sm text-slate-600">Status: <b>{student.status}</b></p>
            </div>
          </section>
          <dl className="mt-6 grid gap-x-8 gap-y-3 text-sm sm:grid-cols-2">
            {[
              ["Email", student.email],
              ["Phone", student.phone || "—"],
              ["Date of birth", student.dateOfBirth ? fmt(student.dateOfBirth) : "—"],
              ["Highest education", student.educationLevel || "—"],
              ["Academic year", `${s.academicYear} · ${s.semester}`],
              ["Registered on", fmt(student.joinedDate || today)],
            ].map(([k, v]) => (
              <div key={k} className="border-b border-slate-200 pb-1.5">
                <dt className="text-[11px] font-bold uppercase tracking-wide text-slate-500">{k}</dt>
                <dd className="break-words text-slate-900">{v}</dd>
              </div>
            ))}
          </dl>
          <h3 className="mt-6 text-sm font-bold uppercase tracking-wide text-emerald-900">Enrolled programmes</h3>
          <ul className="mt-2 space-y-1.5 text-sm">
            {programs.length === 0 && <li className="text-slate-500">No programme assigned yet.</li>}
            {programs.map((p) => (
              <li key={p.id} className="flex flex-wrap justify-between gap-2 rounded-lg bg-slate-50 px-3 py-2">
                <span className="font-medium">{p.title}</span>
                <span className="text-slate-500">{p.durationWeeks} weeks · {formatCurrency(p.tuition ?? 0)}</span>
              </li>
            ))}
            {cohorts.map((c) => (
              <li key={c.id} className="rounded-lg bg-emerald-50 px-3 py-2 text-emerald-900">Cohort: {c.name} · starts {fmt(c.startDate)}</li>
            ))}
          </ul>
          <p className="mt-4 text-sm">
            Registration fee: {myFees.some((f) => f.category === "Registration") ? <b className="text-emerald-700">Paid</b> : <b className="text-amber-700">Not yet recorded</b>}
          </p>
          {doc.note && <p className="mt-4 whitespace-pre-line rounded-lg bg-amber-50 p-3 text-xs text-slate-700">{doc.note}</p>}
          <p className="mt-5 whitespace-pre-line text-xs text-slate-500">Keep this slip. Present it with your student ID when asked.</p>
          <Signatures t={template} />
        </Sheet>
      ) : (
        <Sheet>
          {fee ? (
            <>
              <Letterhead t={template} logoUrl={logoUrl} title="RECEIPT" number={fee.reference || `RCT-${fee.id.slice(0, 8).toUpperCase()}`} date={fmt(fee.date)} />
              <section className="mt-6 rounded-xl bg-emerald-50 p-5 text-center">
                <p className="text-xs font-bold uppercase tracking-widest text-emerald-800">Amount received</p>
                <p className="mt-1 text-4xl font-black text-emerald-900">{formatCurrency(fee.amount)}</p>
              </section>
              <dl className="mt-6 grid gap-x-8 gap-y-3 text-sm sm:grid-cols-2">
                {[
                  ["Received from", student.name],
                  ["Student ID", idLabel],
                  ["Payment for", `${fee.category} fee`],
                  ["Method", fee.method],
                  ["Reference", fee.reference || "—"],
                  ["Date paid", fmt(fee.date)],
                  ["Total paid to date", formatCurrency(paidUpTo)],
                  ["Outstanding balance", formatCurrency(Math.max(total - paidUpTo, 0))],
                ].map(([k, v]) => (
                  <div key={k} className="border-b border-slate-200 pb-1.5">
                    <dt className="text-[11px] font-bold uppercase tracking-wide text-slate-500">{k}</dt>
                    <dd className="break-words text-slate-900">{v}</dd>
                  </div>
                ))}
              </dl>
              <p className="mt-5 text-xs text-slate-500">This receipt confirms the payment above was recorded by the finance office.</p>
              <Signatures t={template} />
              <p className="mt-6 text-center text-xs italic text-slate-500">{template.footerNote}</p>
            </>
          ) : (
            <p className="py-10 text-center text-sm text-slate-500">No payments recorded for this student yet, so there is no receipt to show.</p>
          )}
        </Sheet>
      )}
    </div>
  );
}
