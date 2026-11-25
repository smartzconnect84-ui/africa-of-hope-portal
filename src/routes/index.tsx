import { createFileRoute } from "@tanstack/react-router";
import { site } from "@/data/content";

export const Route = createFileRoute("/")({
  component: HomePage,
  head: () => ({
    meta: [
      { title: site.title },
      { name: "description", content: site.description },
    ],
  }),
});

function HomePage() {
  return (
    <section className="min-h-screen flex items-center justify-center px-6">
      <h1 className="display text-5xl sm:text-7xl text-center">
        Your idea<br />
        is about to<br />
        come to life.
      </h1>
    </section>
  );
}
