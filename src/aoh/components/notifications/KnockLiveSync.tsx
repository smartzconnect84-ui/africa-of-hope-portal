import { useEffect } from "react";
import { useApp } from "@/aoh/context/AppContext";
import { supabase } from "@/aoh/integrations/supabase/client";
import { useKnock } from "./KnockProviderShell";

/** Refresh the feed when the portal's own notifications table gets a new row. */
export default function KnockLiveSync() {
  const { currentUser } = useApp();
  const knock = useKnock();

  useEffect(() => {
    if (!currentUser?.id || !knock) return;
    const channel = supabase
      .channel(`knock-live-${currentUser.id}`)
      .on("postgres_changes", { event: "INSERT", schema: "public", table: "notifications", filter: `recipient_id=eq.${currentUser.id}` },
        () => { void knock.feed.fetch(); })
      .subscribe();
    return () => { void supabase.removeChannel(channel); };
  }, [currentUser?.id, knock]);

  return null;
}
