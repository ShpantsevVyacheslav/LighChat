import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

/**
 * Electron-wrapper удалён (декомиссирован в пользу Flutter desktop, см.
 * `mobile/app/lib/features/desktop_shell/`). Функция оставлена как
 * stub-noop для существующих call-sites — все ветки `isElectron()`
 * теперь dead-code и могут быть постепенно удалены.
 *
 * @deprecated Always returns `false`. Удалите call-sites при следующем
 * рефакторинге компонента.
 */
export function isElectron(): boolean {
  return false;
}

export function formatDuration(seconds?: number): string {
    if (seconds === undefined || seconds === null || seconds < 0) return '0м';
    if (seconds < 60) return `${Math.round(seconds)} с`;
    
    const days = Math.floor(seconds / 86400);
    const remainingAfterDays = seconds % 86400;
    const hours = Math.floor(remainingAfterDays / 3600);
    const minutes = Math.floor((remainingAfterDays % 3600) / 60);

    let result = '';
    if (days > 0) result += `${days}д `;
    if (hours > 0) result += `${hours}ч `;
    if (minutes > 0 || (days === 0 && hours === 0)) result += `${minutes}м`;

    return result.trim() || '0м';
}
