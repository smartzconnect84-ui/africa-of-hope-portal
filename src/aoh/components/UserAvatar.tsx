import { useEffect, useState } from "react";
import { openUserProfile } from "@/aoh/lib/profileView";
import type { User } from "@/aoh/types";
import { cn } from "@/aoh/lib/utils";

function initials(name: string) {
  return name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0]?.toUpperCase())
    .join("") || "?";
}

/** Round avatar that shows the profile photo and falls back to initials. */
export default function UserAvatar({ user, className, noProfile }: { user: Pick<User, "name" | "avatarUrl"> & { id?: string }; className?: string; noProfile?: boolean }) {
  const canOpen = !!user.id && !noProfile;
  const open = canOpen
    ? {
        role: "button" as const,
        tabIndex: 0,
        title: `View ${user.name}'s profile`,
        onClick: (e: { stopPropagation: () => void }) => { e.stopPropagation(); openUserProfile(user.id); },
        onKeyDown: (e: { key: string; stopPropagation: () => void; preventDefault: () => void }) => { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); e.stopPropagation(); openUserProfile(user.id); } },
      }
    : {};
  const [broken, setBroken] = useState(false);
  useEffect(() => setBroken(false), [user.avatarUrl]);
  return user.avatarUrl && !broken ? (
    <img
      src={user.avatarUrl}
      alt={user.name}
      onError={() => setBroken(true)}
      className={cn("shrink-0 rounded-full object-cover", canOpen && "cursor-pointer transition hover:ring-2 hover:ring-emerald-500/60", className)}
      {...open}
    />
  ) : (
    <span
      aria-hidden={canOpen ? undefined : true}
      className={cn(
        "grid shrink-0 place-items-center rounded-full bg-gradient-to-br from-emerald-600 to-emerald-900 font-semibold text-white",
        canOpen && "cursor-pointer transition hover:ring-2 hover:ring-emerald-500/60",
        className,
      )}
      {...open}
    >
      {initials(user.name)}
    </span>
  );
}
