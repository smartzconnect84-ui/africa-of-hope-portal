import { createFileRoute } from "@tanstack/react-router";

// The Africa of Hope portal is a client-side app mounted by the root route.
export const Route = createFileRoute("/")({
  component: () => null,
});
