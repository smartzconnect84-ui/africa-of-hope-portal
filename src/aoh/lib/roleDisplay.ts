/**
 * Single display mapping for the teaching role.
 * The stored Role value stays exactly "Teacher" (all permission checks,
 * filters and backend writes keep using it). Only human-readable labels
 * go through this helper so every surface reads "Instructor".
 */
export function displayRole(role: string | null | undefined): string {
  if (!role) return "";
  const trimmed = String(role).trim();
  if (/^(teacher|instructor)$/i.test(trimmed)) return "Instructor";
  if (/^(teacher|instructor)s$/i.test(trimmed)) return "Instructors";
  return trimmed.replace(/\b(teacher|instructor)s\b/gi, "Instructors").replace(/\b(teacher|instructor)\b/gi, "Instructor");
}

/** Sidebar group heading for a signed-in role. */
export function displayGroupForRole(role: string | null | undefined): string {
  if (role === "Student") return "Student Desk";
  if (role === "Teacher") return "Instructor";
  return "Administration";
}
