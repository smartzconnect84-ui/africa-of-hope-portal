/**
 * Single display mapping for the teaching role.
 * The stored Role value stays exactly "Teacher" (all permission checks,
 * filters and backend writes keep using it). Only human-readable labels
 * go through this helper so every surface reads "Teachers-Instructors".
 */
export function displayRole(role: string | null | undefined): string {
  if (!role) return "";
  const trimmed = String(role).trim();
  if (/^(teacher|instructor)(-instructor)?$/i.test(trimmed)) return "Teacher-Instructor";
  if (/^(teacher|instructor)s?(-instructors?)?$/i.test(trimmed)) return "Teachers-Instructors";
  return trimmed.replace(/\b(teacher|instructor)s\b/gi, "Teachers-Instructors").replace(/\b(teacher|instructor)\b/gi, "Teacher-Instructor");
}

/** Sidebar group heading for a signed-in role. */
export function displayGroupForRole(role: string | null | undefined): string {
  if (role === "Student") return "Student Desk";
  if (role === "Teacher") return "Teacher-Instructor";
  return "Administration";
}
