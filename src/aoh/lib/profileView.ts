/** Ask the app to open the profile card for a user id (handled by ProfileHost). */
export function openUserProfile(userId: string | undefined | null) {
  if (!userId || typeof window === "undefined") return;
  window.dispatchEvent(new CustomEvent("aoh:open-profile", { detail: { userId } }));
}
