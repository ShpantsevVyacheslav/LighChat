import { isElectron } from '@/lib/utils';

/**
 * Настройки виртуализации списка сообщений (ChatWindow / ThreadWindow).
 * Больший overscan = реже размонтируются уже отрисованные строки при прокрутке вверх и обратно.
 */
export const VIRTUOSO_CHAT_INCREASE_VIEWPORT: { top: number; bottom: number } = {
  top: 4800,
  bottom: 4800,
};

export const VIRTUOSO_CHAT_INCREASE_VIEWPORT_ELECTRON: { top: number; bottom: number } = {
  top: 2200,
  bottom: 2200,
};

/** Минимум элементов за пределами viewport (дополнительно к пикселям, для высоких сообщений). */
export const VIRTUOSO_CHAT_MIN_OVERSCAN: { top: number; bottom: number } = {
  top: 10,
  bottom: 16,
};

export function getVirtuosoChatIncreaseViewport(): { top: number; bottom: number } {
  return isElectron() ? VIRTUOSO_CHAT_INCREASE_VIEWPORT_ELECTRON : VIRTUOSO_CHAT_INCREASE_VIEWPORT;
}
