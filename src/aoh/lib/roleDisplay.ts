/**
 * Single display mapping for the teaching role.
 * The stored Role value is exactly "Teacher-Instructor" (all permission checks,
 * filters and backend writes use it). Rows written before the rename still say
 * "Teacher", so both map to the same label here.
 */
export function displayRole(role: string | null | undefined): string {
  if (!role) return "";
  const trimmed = String(role).trim();
  // Placeholders stop the second pass from re-matching the "Instructor" that
  // the first pass just wrote.
  return trimmed
    .replace(/\b(?:teacher|instructor)s\b/gi, "\u0000P")
    .replace(/\b(?:teacher|instructor)\b/gi, "\u0000S")
    .replace(/\u0000P/g, "Teacher-Instructors")
    .replace(/\u0000S/g, "Teacher-Instructor");
}

/** Sidebar group heading for a signed-in role. */
export function displayGroupForRole(role: string | null | undefined): string {
  if (role === "Student") return "Student Desk";
  if (role === "Teacher-Instructor" || role === "Teacher") return "Teacher-Instructors";
  return "Administration";
}
