import { displayRole } from "@/aoh/lib/roleDisplay";
import { MessageCircle } from "lucide-react";
import type { User } from "@/aoh/types";
import { accountId } from "@/aoh/lib/identifiers";
import { formatLastSeen, getLastSeen } from "@/aoh/lib/presence";
import { Button } from "@/aoh/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/aoh/components/ui/dialog";
import UserAvatar from "./UserAvatar";
import { cn } from "@/aoh/lib/utils";

export function PresenceDot({ online, className = "" }: { online: boolean; className?: string }) {
  return (
    <span
      title={online ? "Online now" : "Offline"}
      aria-label={online ? "Online now" : "Offline"}
      className={cn(
        "inline-block h-2.5 w-2.5 shrink-0 rounded-full ring-2 ring-white",
        online ? "bg-emerald-500" : "bg-slate-300",
        className,
      )}
    />
  );
}

function initials(name: string) {
  return name.split(" ").map((p) => p[0]).slice(0, 2).join("").toUpperCase();
}

export function UserProfileDialog({
  user,
  online,
  onClose,
  onMessage,
}: {
  user: User | null;
  online: boolean;
  onClose: () => void;
  onMessage: (u: User) => void;
}) {
  const lastSeen = user ? getLastSeen(user.id) : null;
  return (
    <Dialog open={!!user} onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="max-w-md">
        {user && (
          <>
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2">
                <MessageCircle className="h-4 w-4 text-emerald-700" />
                Member profile
              </DialogTitle>
              <DialogDescription>Account details and live availability.</DialogDescription>
            </DialogHeader>
            <div className="flex items-start gap-4">
              <div className="relative">
                {user.avatarUrl ? (
                  <UserAvatar user={user} className="h-16 w-16 text-lg" />
                ) : (
                  <span className="grid h-16 w-16 place-items-center rounded-full bg-gradient-to-br from-emerald-700 to-emerald-950 text-lg font-semibold text-amber-400">
                    {initials(user.name)}
                  </span>
                )}
                <span className="absolute -bottom-0.5 -right-0.5">
                  <PresenceDot online={online} />
                </span>
              </div>
              <div className="min-w-0 flex-1">
                <p className="truncate text-lg font-semibold text-slate-900">{user.name}</p>
                <p className="break-all font-mono text-[11px] text-emerald-800">ID: {accountId(user)}</p>
                <p className="mt-1 text-xs text-slate-500">
                  {online ? (
                    <span className="font-semibold text-emerald-700">● Active now</span>
                  ) : (
                    <span>Last active {formatLastSeen(lastSeen)}</span>
                  )}
                </p>
                <div className="mt-2 flex flex-wrap gap-1.5">
                  <span className="rounded-full bg-emerald-50 px-2.5 py-0.5 text-xs font-semibold text-emerald-800 ring-1 ring-emerald-700/15">
                    {displayRole(user.role)}
                  </span>
                  <span className="rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-medium text-slate-600">
                    {user.status}
                  </span>
                  {user.title && (
                    <span className="rounded-full bg-amber-50 px-2.5 py-0.5 text-xs font-medium text-amber-800">
                      {user.title}
                    </span>
                  )}
                </div>
              </div>
            </div>
            <div className="space-y-1 rounded-xl bg-slate-50 p-3 text-sm text-slate-600">
              <p className="break-all">{user.email}</p>
              {user.phone && <p>{user.phone}</p>}
              {user.bio && <p className="text-[13px]">{user.bio}</p>}
            </div>
            <div className="flex justify-end gap-2">
              <Button variant="outline" onClick={onClose}>
                Close
              </Button>
              <Button onClick={() => onMessage(user)} className="bg-emerald-700 hover:bg-emerald-800">
                <MessageCircle className="mr-1.5 h-4 w-4" /> Message
              </Button>
            </div>
          </>
        )}
      </DialogContent>
    </Dialog>
  );
}
