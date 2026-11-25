import { FileDown } from "lucide-react";
import { Button } from "@/aoh/components/ui/button";
import { useApp } from "@/aoh/context/AppContext";
import type { Program } from "@/aoh/types";
import { openProgramBrochure } from "@/aoh/lib/programBrochure";

/** f34/f38: one-click printable PDF brochure — black button with white text. */
export default function ProgramBrochureButton({
  program,
  variant = "outline",
  className,
}: {
  program: Program;
  variant?: "outline" | "ghost" | "secondary";
  className?: string;
}) {
  const { state } = useApp();
  return (
    <Button
      type="button"
      variant={variant}
      className={`bg-black text-white hover:bg-neutral-800 hover:text-white ${className ?? ""}`}
      aria-label={`Download ${program.title} brochure (PDF)`}
      onClick={() => openProgramBrochure(program, state.settings, state.websiteSettings)}
    >
      <FileDown data-icon="inline-start" /> Brochure
    </Button>
  );
}
