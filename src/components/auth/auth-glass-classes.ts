/**
 * Общие Tailwind-классы для стеклянного экрана входа и модалки регистрации.
 */

export const AUTH_LABEL_CLASS =
  "text-[9px] font-semibold uppercase tracking-wide opacity-80 ml-0.5";

/** Поля ввода: тот же вид, что у карточки входа */
export const AUTH_GLASS_INPUT_CLASS =
  "h-10 rounded-[14px] border border-white/35 bg-white/45 px-3.5 text-[15px] shadow-inner shadow-black/5 backdrop-blur-md placeholder:text-slate-500/80 focus-visible:border-primary/50 focus-visible:ring-primary/20 dark:border-white/12 dark:bg-white/[0.08] dark:text-white dark:placeholder:text-white/40";

/** Клиентская ошибка поля (дубликат email/телефон/логин и т.д.) */
export const AUTH_GLASS_INPUT_ERROR_CLASS =
  "border-destructive !border-destructive/90 focus-visible:border-destructive focus-visible:ring-2 focus-visible:ring-destructive/35 dark:border-destructive";

/** Внутренний блик карточки (накладывается absolute inset-0) */
export const AUTH_GLASS_CARD_HIGHLIGHT_CLASS =
  "pointer-events-none absolute inset-0 rounded-[28px] bg-gradient-to-b from-white/40 to-transparent opacity-50 dark:from-white/[0.08] dark:to-transparent dark:opacity-100";

/** Оболочка стеклянной карточки (вход и диалог регистрации) */
export const AUTH_GLASS_CARD_SHELL_CLASS =
  "relative overflow-hidden rounded-[28px] border border-white/55 bg-white/25 shadow-[0_12px_40px_-8px_rgba(0,0,0,0.15)] backdrop-blur-2xl backdrop-saturate-150 dark:border-white/[0.14] dark:bg-white/[0.07] dark:shadow-[0_16px_48px_-12px_rgba(0,0,0,0.55)]";

/** Затемнение под модалкой — в тон общему auth-фону */
export const AUTH_DIALOG_OVERLAY_CLASS = "bg-black/45 backdrop-blur-md";
