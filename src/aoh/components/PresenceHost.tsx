import { useApp } from "@/aoh/context/AppContext";
import { usePresence } from "@/aoh/lib/presence";

/** Mount once: keeps live online status flowing to every avatar. */
export default function PresenceHost() {
  const { currentUser } = useApp();
  usePresence(currentUser?.id ?? null);
  return null;
}
