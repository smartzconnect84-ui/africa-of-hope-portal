import { useEffect, useState } from "react";
import { useApp } from "@/aoh/context/AppContext";
import UserProfileDialog from "@/aoh/components/chat/UserProfileDialog";

/** Mount once: opens a profile card whenever any avatar or name is clicked. */
export default function ProfileHost() {
  const { state, currentUser } = useApp();
  const [userId, setUserId] = useState<string | null>(null);

  useEffect(() => {
    const on = (e: Event) => setUserId((e as CustomEvent<{ userId?: string }>).detail?.userId ?? null);
    window.addEventListener("aoh:open-profile", on);
    return () => window.removeEventListener("aoh:open-profile", on);
  }, []);

  const user = userId ? (state.users.find((u) => u.id === userId) ?? (currentUser?.id === userId ? currentUser : null)) : null;
  return <UserProfileDialog user={user} online={!!user?.isOnline} onClose={() => setUserId(null)} />;
}
