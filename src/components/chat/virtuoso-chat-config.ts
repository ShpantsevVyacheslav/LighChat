/**
 * Настройки виртуализации списка сообщений (ChatWindow / ThreadWindow).
 * Больший overscan = реже размонтируются уже отрисованные строки при прокрутке вверх и обратно.
 *
 * Раньше под Electron использовался более скромный viewport (память Chromium
 * embedded была заметно дороже, чем у браузера в системном Safari/Chrome).
 * После декомиссии Electron остался единый профиль.
 */
export const VIRTUOSO_CHAT_INCREASE_VIEWPORT: { top: number; bottom: number } = {
  top: 4800,
  bottom: 4800,
};

/** Минимум элементов за пределами viewport (дополнительно к пикселям, для высоких сообщений). */
export const VIRTUOSO_CHAT_MIN_OVERSCAN: { top: number; bottom: number } = {
  top: 10,
  bottom: 16,
};

export function getVirtuosoChatIncreaseViewport(): { top: number; bottom: number } {
  return VIRTUOSO_CHAT_INCREASE_VIEWPORT;
}
