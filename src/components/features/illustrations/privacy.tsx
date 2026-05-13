'use client';

import * as React from 'react';
import { Mail, Search, Shield, Smartphone, Users } from 'lucide-react';
import type { LucideIcon } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';
import { getFeaturesContent } from '../features-content';

function AnimatedSwitchRow({
  label,
  hint,
  on,
  animateToggle,
  delayMs,
  dense,
}: {
  label: string;
  hint?: string;
  on: boolean;
  animateToggle?: boolean;
  delayMs: number;
  dense?: boolean;
}) {
  return (
    <div
      className={cn(
        'flex items-center justify-between gap-3 rounded-xl bg-background/55 animate-feat-bubble-in',
        dense ? 'px-2.5 py-1.5' : 'px-3 py-2',
      )}
      style={{ animationDelay: `${delayMs}ms` }}
    >
      <div className="min-w-0 flex-1">
        <p className="truncate text-xs font-semibold text-foreground">{label}</p>
        {hint ? <p className="truncate text-[10px] text-muted-foreground">{hint}</p> : null}
      </div>
      <span
        className={cn(
          'relative inline-flex h-4 w-7 shrink-0 items-center rounded-full transition-colors',
          on ? 'bg-primary' : 'bg-muted-foreground/30'
        )}
        aria-hidden
      >
        <span
          className={cn(
            'absolute h-3 w-3 rounded-full bg-white shadow',
            animateToggle ? 'animate-feat-switch-toggle' : on ? 'translate-x-[14px]' : 'translate-x-[2px]'
          )}
        />
      </span>
    </div>
  );
}

/** Заголовок секции — повторяет CardHeader из реального `privacy/page.tsx`. */
function SectionTitle({ icon: Icon, label, hint }: { icon: LucideIcon; label: string; hint?: string }) {
  return (
    <div className="px-0.5 pt-1">
      <div className="flex items-center gap-1.5">
        <Icon className="h-3 w-3 text-muted-foreground" aria-hidden />
        <p className="text-[10px] font-bold uppercase tracking-wider text-foreground/85">{label}</p>
      </div>
      {hint ? <p className="px-0.5 text-[9px] text-muted-foreground">{hint}</p> : null}
    </div>
  );
}

/**
 * Реальный экран `dashboard/settings/privacy` — это 4 отдельные Card-секции,
 * каждая со своим заголовком + иконкой и набором настроек. Группа
 * «Group invites» — 3 взаимоисключающих Switch'a (как radio через
 * onCheckedChange).
 */
export function MockPrivacy({ className, compact }: { className?: string; compact?: boolean }) {
  const { locale } = useI18n();
  const t = React.useMemo(() => getFeaturesContent(locale).mockText, [locale]);

  if (compact) {
    // Компактный thumbnail — только Visibility-секция.
    return (
      <div className={cn('relative flex h-full w-full flex-col gap-1.5 p-3', className)}>
        <SectionTitle icon={Shield} label={t.privacyTitle} />
        <AnimatedSwitchRow label={t.privacyOnline} hint={t.privacyOnlineHint} on delayMs={0} dense />
        <AnimatedSwitchRow label={t.privacyLastSeen} hint={t.privacyLastSeenHint} on={false} animateToggle delayMs={120} dense />
        <AnimatedSwitchRow label={t.privacyReceipts} hint={t.privacyReceiptsHint} on delayMs={240} dense />
      </div>
    );
  }

  return (
    <div className={cn('relative flex h-full w-full flex-col gap-1.5 overflow-hidden p-3', className)}>
      {/* Section 1: Visibility */}
      <SectionTitle icon={Shield} label={t.privacyTitle} />
      <AnimatedSwitchRow label={t.privacyOnline} hint={t.privacyOnlineHint} on delayMs={0} dense />
      <AnimatedSwitchRow label={t.privacyLastSeen} hint={t.privacyLastSeenHint} on={false} animateToggle delayMs={120} dense />
      <AnimatedSwitchRow label={t.privacyReceipts} hint={t.privacyReceiptsHint} on delayMs={180} dense />

      {/* Section 2: Group invites — 3 взаимоисключающих Switch'a */}
      <SectionTitle icon={Users} label={t.privacyInvitesTitle} />
      <AnimatedSwitchRow label={t.privacyInviteEveryone} on={false} delayMs={240} dense />
      <AnimatedSwitchRow label={t.privacyInviteContacts} on delayMs={300} dense />
      <AnimatedSwitchRow label={t.privacyInviteNone} on={false} delayMs={360} dense />

      {/* Section 3: Finding you */}
      <SectionTitle icon={Search} label={t.privacySearchTitle} />
      <AnimatedSwitchRow label={t.privacyGlobalSearch} hint={t.privacyGlobalSearchHint} on={false} delayMs={420} dense />

      {/* Section 4: Profile for others */}
      <SectionTitle icon={Mail} label={t.privacyProfileTitle} />
      <div className="grid grid-cols-2 gap-1.5">
        <AnimatedSwitchRow label={t.privacyShowEmail} on delayMs={480} dense />
        <AnimatedSwitchRow label={t.privacyShowPhone} on={false} delayMs={540} dense />
      </div>
      {/* Чтобы было видно что есть еще 2 поля (DoB, Bio) — лёгкая подсказка */}
      <div className="flex items-center gap-1 px-0.5 text-[9px] text-muted-foreground">
        <Smartphone className="h-2.5 w-2.5" aria-hidden /> +{t.privacyMoreFields}
      </div>
    </div>
  );
}
