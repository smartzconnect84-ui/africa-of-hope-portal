import { supabase } from "@/aoh/integrations/supabase/client";

/**
 * Central notification service. Every module sends notifications through
 * `notify()`; the server decides the provider (Knock primary, OneSignal backup),
 * checks who may notify whom, de-duplicates and logs every delivery. No provider
 * secret ever reaches the browser.
 */
const NOTIFY_URL = "https://ryqcuaiqnohwwdiapzjl.supabase.co/functions/v1/notify";

export type NotificationEvent =
  | "account-registered" | "account-password-changed" | "account-login-new"
  | "account-profile-updated" | "account-security-alert"
  | "system-announcement" | "system-maintenance" | "system-policy-update"
  | "message-new" | "message-reply" | "message-mention" | "message-request"
  | "admin-new-registration" | "admin-new-application" | "admin-pending-approval" | "admin-task"
  | "edu-course-announcement" | "edu-enrollment-confirmed" | "edu-instructor-update"
  | "edu-material-available" | "edu-assessment-assigned" | "edu-certificate-ready" | "edu-training-reminder";

export interface NotifyResult { ok: boolean; error?: string; sent?: number; duplicate?: boolean; provider?: string }

async function call<T = Record<string, unknown>>(body: Record<string, unknown>): Promise<T & { ok: boolean; error?: string }> {
  try {
    const { data } = await supabase.auth.getSession();
    const token = data.session?.access_token;
    if (!token) return { ok: false, error: "Sign in required" } as T & { ok: boolean; error?: string };
    const res = await fetch(NOTIFY_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
      body: JSON.stringify(body),
    });
    return (await res.json()) as T & { ok: boolean; error?: string };
  } catch (e) {
    return { ok: false, error: e instanceof Error ? e.message : "Network error" } as T & { ok: boolean; error?: string };
  }
}

/** Send a notification event. Pass `idempotencyKey` so a retry never sends twice. */
export function notify(input: {
  event: NotificationEvent;
  recipients: string[];
  data?: Record<string, string | number | boolean>;
  idempotencyKey?: string;
}): Promise<NotifyResult> {
  return call<NotifyResult>({ action: "notify", ...input });
}

/** Keep the signed-in user's Knock profile (name, email, role) in sync. */
export function syncKnockUser(): Promise<{ ok: boolean; error?: string }> {
  return call({ action: "identify" });
}

export interface NotificationStatus {
  ok: boolean; error?: string;
  provider: "knock" | "onesignal";
  knockConfigured: boolean; onesignalConfigured: boolean;
  stats: { sent?: number; failed?: number; duplicate?: number };
  failures: { event: string; recipient: string; provider: string; error: string | null; created_at: string }[];
  recent: { event: string; provider: string; status: string; created_at: string }[];
}
export const getNotificationStatus = () => call<NotificationStatus>({ action: "status" });
export const setNotificationProvider = (provider: "knock" | "onesignal", confirm = false) =>
  call<{ provider: string }>({ action: "set_provider", provider, confirm });
export const sendTestNotification = () => call<NotifyResult>({ action: "test" });
export const setupKnockWorkflow = (environment = "development") =>
  call<{ channel?: string; environment?: string }>({ action: "setup_knock", environment });

/** Signed Knock user token (needed when Knock enhanced security is on). */
export async function getKnockUserToken(): Promise<string | null> {
  const res = await call<{ token?: string }>({ action: "knock_token" });
  return res.ok && res.token ? res.token : null;
}
