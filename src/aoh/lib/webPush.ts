/**
 * AFRICA OF HOPE — Live push over VAPID (Web Push).
 *
 * Knock stays the in-app feed; this channel puts the same notification on the
 * device's lock screen / notification shade even when the app is closed.
 *
 * - The public application-server key ships in the bundle (it is public by
 *   design). The matching private key lives only in the `push-send` Edge
 *   Function's secrets.
 * - The subscription is created on the app's own service worker (/sw.js), whose
 *   `push` handler is what draws the notification.
 * - One push subscription per service worker is all the browser allows, so
 *   nothing else (e.g. the OneSignal web SDK) may claim it.
 */

import { supabase } from "@/aoh/integrations/supabase/client";
import { isIos, isStandalone } from "@/aoh/lib/pwa";

const DEFAULT_VAPID_PUBLIC_KEY =
  "BMNlS3zp5r-MFg-GJFiOMfilQweibCy7KBq2IvOdsOkJK8TDATf5TqbCy_Ht8TDKmV1FoFEqIeKdYJdLbM9ENr8";

/** Public VAPID key. `VITE_VAPID_PUBLIC_KEY` overrides the bundled default. */
export function vapidPublicKey(): string {
  const fromEnv = ((import.meta as any)?.env?.VITE_VAPID_PUBLIC_KEY as string | undefined)?.trim() ?? "";
  return fromEnv || DEFAULT_VAPID_PUBLIC_KEY;
}

export function webPushSupported(): boolean {
  return (
    typeof window !== "undefined" &&
    window.isSecureContext &&
    "Notification" in window &&
    "serviceWorker" in navigator &&
    "PushManager" in window
  );
}

function keyBytes(base64: string): Uint8Array {
  const text = atob((base64 + "=".repeat((4 - (base64.length % 4)) % 4)).replace(/-/g, "+").replace(/_/g, "/"));
  return Uint8Array.from(text, (c) => c.charCodeAt(0));
}

async function registration(): Promise<ServiceWorkerRegistration> {
  let timer: ReturnType<typeof setTimeout> | undefined;
  try {
    return await Promise.race([
      navigator.serviceWorker.ready,
      new Promise<never>((_, reject) => {
        timer = setTimeout(() => reject(new Error("The app worker is not ready yet. Reload while online and try again.")), 10000);
      }),
    ]);
  } finally {
    clearTimeout(timer);
  }
}

function permissionLabel(permission: NotificationPermission): string {
  if (permission === "granted") return "allowed";
  if (permission === "denied") return "blocked";
  return "not asked yet";
}

export interface WebPushState {
  supported: boolean;
  permission: NotificationPermission;
  permissionLabel: string;
  subscribed: boolean;
}

/** Current device state: browser permission plus a stored, enabled subscription. */
export async function webPushState(userId?: string): Promise<WebPushState> {
  if (!webPushSupported()) {
    return { supported: false, permission: "denied", permissionLabel: "unsupported", subscribed: false };
  }
  const permission = Notification.permission;
  let subscribed = false;
  if (permission === "granted") {
    try {
      const reg = await registration();
      const sub = await reg.pushManager.getSubscription();
      if (sub) {
        const { data, error } = await supabase
          .from("push_subscriptions")
          .select("enabled")
          .eq("endpoint", sub.endpoint)
          .maybeSingle();
        subscribed = !error && Boolean(data?.enabled);
      }
    } catch { /* treat as not subscribed */ }
  }
  return { supported: true, permission, permissionLabel: permissionLabel(permission), subscribed };
}

/**
 * Subscribe this device and store it for the signed-in member.
 * Call from a click/tap handler: the OS permission prompt needs a gesture.
 */
export async function enableWebPush(userId: string): Promise<{ subscribed: boolean; message: string }> {
  if (!userId) return { subscribed: false, message: "Sign in first, then enable notifications." };
  if (!webPushSupported()) {
    return { subscribed: false, message: "This browser cannot receive push notifications. Use Chrome, Edge, Firefox or an installed Safari app." };
  }
  if (isIos() && !isStandalone()) {
    return { subscribed: false, message: "On iPhone/iPad: open Safari → Share → Add to Home Screen, then enable notifications from the installed app (iOS 16.4+)." };
  }

  let permission = Notification.permission;
  if (permission === "default") permission = await Notification.requestPermission();
  if (permission !== "granted") {
    return {
      subscribed: false,
      message: permission === "denied"
        ? "Notifications are blocked for this site. Allow them in your browser's Site settings → Notifications (and your device settings), then try again."
        : "Notifications were not allowed. Tap Enable again when you are ready.",
    };
  }

  const reg = await registration();
  if (!reg.pushManager) return { subscribed: false, message: "This browser cannot create a push subscription." };

  let sub = await reg.pushManager.getSubscription();
  if (!sub) {
    sub = await reg.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: keyBytes(vapidPublicKey()) as unknown as BufferSource,
    });
  }

  const json = sub.toJSON();
  const endpoint = sub.endpoint;
  const p256dh = json.keys?.p256dh ?? "";
  const auth = json.keys?.auth ?? "";

  // Claim the endpoint for this member. The RPC also reassigns a shared
  // device's previous subscription, which plain RLS would refuse to update.
  const claim = await supabase.rpc("register_push_subscription", {
    p_endpoint: endpoint,
    p_p256dh: p256dh,
    p_auth: auth,
    p_user_agent: navigator.userAgent.slice(0, 500),
  });
  if (claim.error) {
    // Fall back to a direct upsert for deployments where the helper is absent.
    const { error } = await supabase.from("push_subscriptions").upsert(
      {
        user_id: userId,
        endpoint,
        p256dh,
        auth,
        user_agent: navigator.userAgent.slice(0, 500),
        enabled: true,
        updated_at: new Date().toISOString(),
      },
      { onConflict: "endpoint" },
    );
    if (error) throw new Error(error.message);
  }

  return {
    subscribed: true,
    message: "Live push is on for this device. Messages, fees, grades and announcements now reach the lock screen even when the app is closed.",
  };
}

/** Stop delivering to this device: drop the stored row, then unsubscribe. */
export async function disableWebPush(userId?: string): Promise<void> {
  if (!webPushSupported()) return;
  const reg = await navigator.serviceWorker.getRegistration("/");
  const sub = await reg?.pushManager?.getSubscription();
  if (!sub) return;
  if (userId) {
    const { error } = await supabase.from("push_subscriptions").delete().eq("user_id", userId).eq("endpoint", sub.endpoint);
    if (error) throw new Error(error.message);
  }
  await sub.unsubscribe();
}
