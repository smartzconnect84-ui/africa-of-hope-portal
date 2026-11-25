import { StrictMode } from "react";
import { BrowserRouter } from "react-router";
import "./index.css";
import App from "./App";
import { restorePublicLaunch } from "./lib/publicBranding";
import { registerServiceWorker } from "./lib/pwa";

if (typeof window !== "undefined") {
  restorePublicLaunch();
  setupServiceWorker();
}

/**
 * The worker powers install, offline pages, update prompts and web push. It is
 * registered only on the real published site: in the editor preview (iframe,
 * dev server, preview host) it would serve stale pages, so any old one is removed.
 */
function setupServiceWorker() {
  if (!("serviceWorker" in navigator)) return;
  const inFrame = window.top !== window.self;
  const previewHost = /(^localhost$|^127\.|preview|\.swarmz\.cloud$)/i.test(location.hostname) && !/^aoh2\./i.test(location.hostname);
  if (import.meta.env.DEV || inFrame || previewHost) {
    navigator.serviceWorker.getRegistrations()
      .then((regs) => regs.forEach((r) => void r.unregister()))
      .catch(() => undefined);
    return;
  }
  registerServiceWorker();
}

export default function AohEntry() {
  return (
    <StrictMode>
      <BrowserRouter>
        <App />
      </BrowserRouter>
    </StrictMode>
  );
}
