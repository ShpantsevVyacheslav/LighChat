import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

/**
 * Checks if the application is running inside Electron.
 */
export function isElectron(): boolean {
  if (typeof window !== 'undefined' && typeof window.navigator !== 'undefined') {
    return window.navigator.userAgent.toLowerCase().indexOf(' electron/') > -1;
  }
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
