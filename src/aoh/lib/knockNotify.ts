import { notify, type NotificationEvent } from "./notifications";

/** Back-compat wrapper: older callers go through the central notification service. */
export async function triggerKnockWorkflow(params: {
  workflow: string;
  recipients: string[];
  data?: Record<string, unknown>;
  category?: string;
}): Promise<{ ok: boolean; error?: string }> {
  const data: Record<string, string | number | boolean> = {};
  for (const [k, v] of Object.entries(params.data ?? {})) {
    if (typeof v === "string" || typeof v === "number" || typeof v === "boolean") data[k] = v;
  }
  return notify({ event: params.workflow as NotificationEvent, recipients: params.recipients, data });
}
