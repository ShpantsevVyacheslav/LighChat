
import type { UserRole } from "./types";
import {
  MessagesSquare,
  Video,
  Contact,
  PhoneCall,
} from "lucide-react";

export const APP_NAME = "LighChat";

export const ROLES: Record<UserRole, string> = {
  admin: "Администратор",
  worker: "Участник",
};

export const NAV_LINKS = [
  {
    href: "/dashboard/chat",
    label: "Чаты",
    icon: MessagesSquare,
    roles: ["admin", "worker"],
  },
  {
    href: "/dashboard/contacts",
    label: "Контакты",
    icon: Contact,
    roles: ["admin", "worker"],
  },
  {
    href: "/dashboard/meetings",
    label: "Конференции",
    icon: Video,
    roles: ["admin", "worker"],
  },
  {
    href: "/dashboard/calls",
    label: "Звонки",
    icon: PhoneCall,
    roles: ["admin", "worker"],
  },
];
