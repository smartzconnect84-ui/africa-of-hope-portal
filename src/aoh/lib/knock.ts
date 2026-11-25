import Knock from "@knocklabs/client";

// Public identifiers only (safe in the browser). The secret key stays on the server.
export const KNOCK_PUBLIC_API_KEY = (import.meta.env.VITE_KNOCK_PUBLIC_API_KEY as string | undefined)?.trim() || "pk_fgs_fDXGlYlbFnTgKObJ1Xj9rALk6F8a3ZSxBOmDgx0";
export const KNOCK_FEED_CHANNEL_ID = (import.meta.env.VITE_KNOCK_FEED_CHANNEL_ID as string | undefined)?.trim() || "7fd6d7e6-bf65-4987-af01-b6035e4c033f";

export function isKnockConfigured(): boolean {
  return Boolean(KNOCK_PUBLIC_API_KEY && KNOCK_FEED_CHANNEL_ID);
}

let client: Knock | null = null;
let clientUser = "";

/** One Knock client per signed-in user; switching user tears the old one down. */
export function getKnockClient(
  userId: string,
  token?: string | null,
  refreshToken?: () => Promise<string | null>,
): Knock | null {
  if (!isKnockConfigured() || !userId || typeof window === "undefined") return null;
  if (client && clientUser === userId) return client;
  client?.teardown();
  client = new Knock(KNOCK_PUBLIC_API_KEY);
  client.authenticate(userId, token ?? undefined, refreshToken
    ? { onUserTokenExpiring: async () => (await refreshToken()) ?? token ?? undefined, timeBeforeExpirationInMs: 120000 }
    : undefined);
  clientUser = userId;
  return client;
}

export function resetKnockClient() {
  client?.teardown();
  client = null;
  clientUser = "";
}
