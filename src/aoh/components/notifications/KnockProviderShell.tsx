import { useEffect } from "react";
import { KnockProvider, KnockFeedProvider } from "@knocklabs/react";
import { useApp } from "@/aoh/context/AppContext";
import { isKnockConfigured, KNOCK_PUBLIC_API_KEY, KNOCK_FEED_CHANNEL_ID } from "@/aoh/lib/knock";
import { syncKnockUser } from "@/aoh/lib/notifications";
import KnockLiveSync from "@/aoh/components/notifications/KnockLiveSync";

/**
 * Connects the signed-in Supabase user (stable UUID) to Knock's in-app feed and
 * keeps their Knock profile (name, email, role) in sync through the server.
 */
export default function KnockProviderShell({ children }: { children: React.ReactNode }) {
  const { currentUser } = useApp();
  const id = currentUser?.id;
  const signature = `${id}|${currentUser?.name}|${currentUser?.email}|${currentUser?.role}|${currentUser?.status}`;

  useEffect(() => {
    if (!isKnockConfigured() || !id) return;
    void syncKnockUser();
  }, [id, signature]);

  if (!isKnockConfigured() || !currentUser?.id) return <>{children}</>;

  return (
    <KnockProvider
      apiKey={KNOCK_PUBLIC_API_KEY}
      user={{ id: currentUser.id, name: currentUser.name, email: currentUser.email, avatar: currentUser.avatarUrl }}
      enabled
    >
      <KnockFeedProvider feedId={KNOCK_FEED_CHANNEL_ID}>
        <KnockLiveSync />
        {children}
      </KnockFeedProvider>
    </KnockProvider>
  );
}
