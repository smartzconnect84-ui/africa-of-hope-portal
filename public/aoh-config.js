/* Africa of Hope portal — runtime backend configuration.
 *
 * This file is served next to index.html and runs before the app starts, so a
 * deployment can be pointed at its school database by editing this one file on
 * the server. No rebuild, no build-time secrets, no dashboard: it works on any
 * static host (Netlify, Vercel, Cloudflare Pages, GitHub Pages, cPanel, S3,
 * nginx, ...). Reload the page after editing.
 *
 * Fill in the public credentials of the Supabase project that holds the school
 * database (Supabase dashboard → Project Settings → API):
 *
 *   supabaseUrl      https://<project-ref>.supabase.co
 *   supabaseAnonKey  the anon / publishable key
 *
 * Both are public values: they ship to every browser. NEVER put the
 * service_role / secret key here — it bypasses every access policy.
 *
 * Leave both empty to use VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY when the
 * site is built with them instead. Values set here take priority over the build.
 */
window.AOH_CONFIG = {
  supabaseUrl: "",
  supabaseAnonKey: "",
};
