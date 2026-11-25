import { createContext, useContext, useEffect, useState, useSyncExternalStore } from "react";
import type Knock from "@knocklabs/client";
import { useApp } from "@/aoh/context/AppContext";
import { getKnockClient, isKnockConfigured, KNOCK_FEED_CHANNEL_ID, resetKnockClient } from "@/aoh/lib/knock";
import { syncKnockUser } from "@/aoh/lib/notifications";
import KnockLiveSync from "@/aoh/components/notifications/KnockLiveSync";

type Feed = ReturnType<Knock["feeds"]["initialize"]>;
interface Ctx { knock: Knock; feed: Feed }
const KnockCtx = createContext<Ctx | null>(null);

export const useKnock = () => useContext(KnockCtx);

/** Feed state (items, unread count) from Knock's store. */
export function useKnockFeedState(feed: Feed | undefined) {
  return useSyncExternalStore(
    (cb) => (feed ? feed.store.subscribe(cb) : () => {}),
    () => (feed ? feed.store.getState() : null),
    () => null,
  );
}

/**
 * Connects the signed-in Supabase user (stable UUID) to their Knock in-app feed
 * and keeps their Knock profile (name, email, role) in sync through the server.
 */
export default function KnockProviderShell({ children }: { children: React.ReactNode }) {
  const { currentUser } = useApp();
  const id = currentUser?.id;
  const signature = `${id}|${currentUser?.name}|${currentUser?.email}|${currentUser?.role}|${currentUser?.status}`;

  const [value, setValue] = useState<Ctx | null>(null);

  // Create the feed inside the effect so every mount gets a fresh connection;
  // a torn-down feed is never reused, and a late network failure never crashes the page.
  useEffect(() => {
    if (!id || !isKnockConfigured()) { setValue(null); return; }
    const knock = getKnockClient(id);
    if (!knock) { setValue(null); return; }
    const feed = knock.feeds.initialize(KNOCK_FEED_CHANNEL_ID);
    try {
      feed.listenForUpdates();
      void Promise.resolve(feed.fetch()).catch(() => undefined);
    } catch { /* feed stays empty; the bell shows no items */ }
    setValue({ knock, feed });
    return () => {
      setValue(null);
      try { feed.teardown(); } catch { /* already closed */ }
    };
  }, [id]);

  useEffect(() => {
    if (!id) resetKnockClient();
    else if (isKnockConfigured()) void syncKnockUser();
  }, [id, signature]);

  return (
    <KnockCtx.Provider value={value}>
      {value && <KnockLiveSync />}
      {children}
    </KnockCtx.Provider>
  );
}
