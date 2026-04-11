'use client';

import type { ReactNode } from 'react';
import { ChevronRight } from 'lucide-react';
import { cn } from '@/lib/utils';
import { Switch } from '@/components/ui/switch';

/** Фон шторки профиля / утилит: `bg-background` подстраивается под тему, в т.ч. «Авто» от обоев. */
export const WA_PROFILE_BG = 'bg-background';
export const WA_PROFILE_MUTED = 'text-muted-foreground';
export const WA_PROFILE_BORDER = 'border-border';

/** Правая шторка утилит чата (медиа и т.п.): тот же фон, что и профиль участника. */
export const WA_CONVERSATION_UTILITY_SHEET_CONTENT_CLASS = cn(
  WA_PROFILE_BG,
  /** Без `touch-pan-y` на корне: иначе iOS отдаёт вертикальный жест шторке, а не внутреннему скроллу меню. */
  'flex h-full max-h-[100dvh] w-full min-h-0 flex-col overflow-hidden border-none p-0 text-foreground shadow-2xl sm:max-w-lg sm:rounded-l-[2.5rem]',
);

type WaQuickActionProps = {
  icon: ReactNode;
  label: string;
  onClick?: () => void;
  disabled?: boolean;
  /** Акцент иконки (как зелёный в WhatsApp). */
  accentClassName?: string;
};

export function WaQuickActionButton({
  icon,
  label,
  onClick,
  disabled,
  accentClassName = 'text-emerald-500',
}: WaQuickActionProps) {
  return (
    <button
      type="button"
      disabled={disabled}
      onClick={onClick}
      className={cn(
        'flex flex-1 flex-col items-center gap-1.5 rounded-2xl bg-muted py-3 px-1 transition-colors',
        'hover:bg-muted/80 active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-45',
      )}
    >
      <span className={cn('flex h-8 w-8 items-center justify-center', accentClassName)}>{icon}</span>
      <span className="text-center text-[11px] font-medium leading-tight text-foreground">{label}</span>
    </button>
  );
}

export function WaQuickActionRow({
  children,
  className,
}: {
  children: ReactNode;
  className?: string;
}) {
  return <div className={cn('flex w-full gap-2', className)}>{children}</div>;
}

/** Секция пунктов профиля: без «карточки», только вертикальный список. */
export function WaMenuSection({ children, className }: { children: ReactNode; className?: string }) {
  return <div className={cn('flex flex-col', className)}>{children}</div>;
}

type WaMenuRowProps = {
  icon: ReactNode;
  title: string;
  /** Подзаголовок под основной строкой (как у Lock chat / Encryption). */
  description?: string;
  right?: ReactNode;
  showChevron?: boolean;
  onClick?: () => void;
  disabled?: boolean;
};

export function WaMenuRow({
  icon,
  title,
  description,
  right,
  showChevron = true,
  onClick,
  disabled,
}: WaMenuRowProps) {
  const content = (
    <div
      className={cn(
        'flex w-full items-center gap-2 px-1 py-1.5 sm:px-1.5',
        onClick && !disabled && 'cursor-pointer active:bg-muted/70',
        disabled && 'opacity-50',
      )}
    >
      <div className="flex h-8 w-8 shrink-0 items-center justify-center text-muted-foreground [&_svg]:h-[18px] [&_svg]:w-[18px]">
        {icon}
      </div>
      <div className="min-w-0 flex-1 text-left">
        <div className="text-sm font-normal leading-snug text-foreground">{title}</div>
        {description ? (
          <p className="mt-0.5 text-xs leading-snug text-muted-foreground">{description}</p>
        ) : null}
      </div>
      <div className="flex shrink-0 items-center gap-0.5 text-muted-foreground">
        {right}
        {showChevron && !right ? <ChevronRight className="h-4 w-4 shrink-0 opacity-55" /> : null}
        {showChevron && right ? <ChevronRight className="h-4 w-4 shrink-0 opacity-40" /> : null}
      </div>
    </div>
  );

  if (onClick) {
    return (
      <button
        type="button"
        className="block w-full rounded-lg text-left [-webkit-tap-highlight-color:transparent]"
        onClick={onClick}
        disabled={disabled}
      >
        {content}
      </button>
    );
  }

  return <div className="w-full">{content}</div>;
}

export function WaMenuRowToggle({
  icon,
  title,
  description,
  checked,
  onCheckedChange,
  disabled,
}: Omit<WaMenuRowProps, 'right' | 'showChevron' | 'onClick'> & {
  checked: boolean;
  onCheckedChange?: (v: boolean) => void;
}) {
  return (
    <div
      className={cn(
        'flex w-full items-center gap-2 px-1 py-1.5 sm:px-1.5',
        disabled && 'opacity-50',
      )}
    >
      <div className="flex h-8 w-8 shrink-0 items-center justify-center text-muted-foreground [&_svg]:h-[18px] [&_svg]:w-[18px]">
        {icon}
      </div>
      <div className="min-w-0 flex-1 text-left">
        <div className="text-sm font-normal leading-snug text-foreground">{title}</div>
        {description ? (
          <p className="mt-0.5 text-xs leading-snug text-muted-foreground">{description}</p>
        ) : null}
      </div>
      <Switch
        checked={checked}
        onCheckedChange={onCheckedChange}
        disabled={disabled}
        className="shrink-0 data-[state=checked]:bg-emerald-600"
      />
    </div>
  );
}

export function WaFooterCaption({ children }: { children: ReactNode }) {
  return (
    <p className="px-1 pt-2 text-[10px] font-semibold uppercase tracking-wide text-muted-foreground">{children}</p>
  );
}
