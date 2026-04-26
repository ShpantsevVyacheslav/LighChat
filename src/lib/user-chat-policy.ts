import type { User } from "@/lib/types";
import { isEitherBlockingFromUsers } from "@/lib/user-block-utils";

/** Можно ли начать личный чат (как в NewChatDialog). */
export function canStartDirectChat(currentUser: User, other: User): boolean {
  if (currentUser.id === other.id) return false;
  if (other.deletedAt) return false;
  if (isEitherBlockingFromUsers(currentUser, other)) return false;
  if (currentUser.role === "admin") return true;
  if (other.role === "admin") return true;
  if (currentUser.role === "worker") return other.role === "worker";
  return other.role !== "worker";
}
