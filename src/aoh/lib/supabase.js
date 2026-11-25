// Single Supabase client for the whole portal (the school's own project).
// Re-exported so older imports keep working and never create a second client.
import { supabase as portalClient, SUPABASE_URL } from "@/aoh/integrations/supabase/client";

export const supabase = portalClient;
export const PROJECT_URL = SUPABASE_URL;

export function edgeUrl(slug) {
  return `${SUPABASE_URL}/functions/v1/${slug}`;
}
