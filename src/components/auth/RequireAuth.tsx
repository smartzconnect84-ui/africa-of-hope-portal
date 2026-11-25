import { useEffect, type ReactNode } from "react";
import { useRouter } from "@tanstack/react-router";
import { useAuth } from "@/hooks/useAuth";
import { AUTH_PATH, authUrl, currentPath } from "@/lib/auth-return";
import AuthPage from "@/components/auth/AuthPage";

/**
 * Show children only to signed-in visitors. It waits for the stored session
 * before deciding (no flash of the sign-in form for people who are signed in).
 * Signed-out visitors go to the app's one sign-in page, /auth (AuthPage mounted
 * by src/routes/auth.tsx), and come back here once they are signed in. An app
 * without that route shows the same sign-in page right here instead.
 *
 *   <RequireAuth><Dashboard /></RequireAuth>
 *     signed out -> /auth?returnTo=<this page>, and back here after sign-in
 *   <RequireAuth redirectTo="/members/sign-in"><Dashboard /></RequireAuth>
 *     the same, for a sign-in page mounted at another path
 */
export function RequireAuth({
  children,
  fallback,
  redirectTo,
}: {
  children: ReactNode;
  /** Shown while the session loads (and while redirecting). Default: a small spinner. */
  fallback?: ReactNode;
  /** The app's sign-in route. Default: /auth, when the app has that route. */
  redirectTo?: string;
}) {
  const { ready, user, recovering } = useAuth();
  const router = useRouter();
  const signInPath = redirectTo ?? (hasRoute(router, AUTH_PATH) ? AUTH_PATH : null);
  const leave = Boolean(signInPath) && ready && !user && !recovering;

  useEffect(() => {
    if (!leave || !signInPath) return;
    const to = authUrl(currentPath(), signInPath);
    if (router?.history) router.history.replace(to);
    else window.location.replace(to);
  }, [leave, signInPath, router]);

  const waiting = fallback ?? (
    <div className="flex min-h-[50vh] items-center justify-center" aria-busy="true">
      <svg viewBox="0 0 24 24" className="h-5 w-5 animate-spin text-muted-foreground" aria-hidden="true">
        <circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" strokeOpacity="0.25" strokeWidth="2.5" />
        <path d="M21 12a9 9 0 0 0-9-9" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" />
      </svg>
      <span className="sr-only">Loading…</span>
    </div>
  );

  if (!ready) return <>{waiting}</>;
  // A password-reset link lands here signed in, to choose a new password.
  if (recovering) return <AuthPage redirect={false} />;
  if (!user) return signInPath ? <>{waiting}</> : <AuthPage redirect={false} />;
  return <>{children}</>;
}

/** Whether the app has a route at this path (src/routes/auth.tsx or auth.index.tsx for /auth). */
function hasRoute(router: unknown, path: string): boolean {
  const routes = (router as { routesByPath?: Record<string, unknown> } | null)?.routesByPath;
  return Boolean(routes && path in routes);
}

/** Same component, alternative name. */
export const AuthGate = RequireAuth;

export default RequireAuth;
