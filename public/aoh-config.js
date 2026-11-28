/**
 * Runtime backend configuration, loaded by index.html before the app bundle.
 *
 * These values are public: the URL and the Supabase anon/publishable key are
 * shipped to every browser. Never put a service_role or secret key here — it
 * bypasses every access policy. A build can still supply the values from
 * VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY; values set here take priority.
 */
window.AOH_CONFIG = {
  supabaseUrl: "https://gatnzfjpuokopqyksqoy.supabase.co",
  supabaseAnonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdhdG56ZmpwdW9rb3BxeWtzcW95Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIyNjAyMTcsImV4cCI6MjEwNzgzNjIxN30.g0tptBFvclxGhqePFrWz0nov3R_DRsOgnSQJpKjdDT8",
};
