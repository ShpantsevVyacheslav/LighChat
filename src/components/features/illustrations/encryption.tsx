'use client';

import * as React from 'react';
import { Fingerprint, Lock, ShieldCheck } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';
import { getFeaturesContent } from '../features-content';

/** Точная копия реального `E2eeFingerprintBadge` (см. `src/components/chat/
 *  E2eeFingerprintBadge.tsx`): `Fingerprint`-иконка слева, sub-hint сверху и
 *  monospace-блок отпечатка снизу. Стилистика — `text-muted-foreground` для
 *  hint, обычный foreground для кода. */
function FingerprintBadge({ label }: { label: string }) {
  // Имитация реального отпечатка: 8 групп по 4 hex-символа через `·`.
  const fp = '5f2a · 8b91 · 4cc8 · 3dea · a1b4 · 0e77 · c9d5 · 6f12';
  return (
    <div className="flex items-start gap-2 rounded-lg border border-black/5 dark:border-white/10 bg-background/60 px-2.5 py-1.5">
      <Fingerprint className="mt-0.5 h-3.5 w-3.5 shrink-0 text-muted-foreground" aria-hidden />
      <div className="min-w-0 space-y-0.5">
        <div className="text-[9px] text-muted-foreground">
          E2EE · {label} <span className="opacity-60">(1 устр.)</span>
        </div>
        <code className="block break-all text-[10px] font-mono tracking-tight text-foreground/90">
          {fp}
        </code>
      </div>
    </div>
  );
}

const HEX_BLOCKS = [
  '9F2A', '8B71', '4CC8', '3DEA', '5F02', 'A1B4', '0E77', 'C9D5',
  '6F12', 'B83C', '7E0A', '21FE', 'D4A8', '5C19', 'E370', '08BD',
];

function CipherStream() {
  const cells = [...HEX_BLOCKS, ...HEX_BLOCKS];
  return (
    <div className="pointer-events-none relative flex h-full w-full items-center overflow-hidden">
      <div className="flex shrink-0 items-center gap-1.5 whitespace-nowrap pl-3 animate-feat-cipher-stream">
        {cells.map((c, i) => (
          <span
            key={i}
            className="font-mono text-[10px] font-semibold tracking-tight text-emerald-400/90 animate-feat-cipher-flicker"
            style={{ animationDelay: `${(i % 8) * 90}ms` }}
          >
            {c}
          </span>
        ))}
      </div>
    </div>
  );
}

/**
 * Анимация процесса E2EE для пользователя без технического бэкграунда:
 *  Алиса → поток зашифрованных hex-блоков → Боб (тот же текст у получателя).
 *  Сверху — закрытый замок и подпись «Сквозное шифрование».
 *  Снизу — одинаковые отпечатки ключей с обеих сторон.
 *  Все строки — мультиязычные через `mockText`.
 */
export function MockEncryption({ className }: { className?: string; compact?: boolean }) {
  const { locale } = useI18n();
  const t = React.useMemo(() => getFeaturesContent(locale).mockText, [locale]);

  return (
    <div className={cn('relative flex h-full w-full flex-col p-3', className)}>
      <div className="mx-auto flex items-center gap-1.5 rounded-full border border-emerald-500/30 bg-emerald-500/10 px-3 py-1 text-[10.5px] font-semibold text-emerald-600 dark:text-emerald-300">
        <Lock className="h-3 w-3 animate-feat-lock-cycle" aria-hidden />
        {t.e2eeBadge}
      </div>

      <div className="relative mt-3 flex min-h-0 flex-1 items-center gap-1 sm:gap-2">
        {/* Алиса */}
        <div className="z-10 flex w-[26%] shrink-0 flex-col items-center gap-1">
          <div className="flex h-10 w-10 items-center justify-center rounded-full bg-gradient-to-br from-rose-400 to-rose-600 text-sm font-bold text-white shadow">
            {t.peerAlice.charAt(0)}
          </div>
          <span className="text-[10px] font-semibold text-foreground">{t.peerAlice}</span>
          <div className="rounded-2xl rounded-tr-none bg-primary px-2.5 py-1.5 text-[11px] text-primary-foreground shadow-sm animate-feat-msg-fly-right">
            {t.peerHello}
          </div>
        </div>

        {/* Канал шифрования */}
        <div className="relative z-0 flex h-full flex-1 flex-col justify-center">
          <div className="pointer-events-none absolute -top-1 left-1/2 z-20 -translate-x-1/2">
            <div className="flex h-9 w-9 items-center justify-center rounded-full border border-emerald-500/40 bg-background/85 shadow-md backdrop-blur-md">
              <ShieldCheck className="h-4 w-4 text-emerald-500 dark:text-emerald-400 animate-feat-lock-cycle" aria-hidden />
            </div>
          </div>
          <div className="relative h-12 overflow-hidden rounded-2xl border border-emerald-500/20 bg-gradient-to-r from-emerald-500/15 via-emerald-400/5 to-emerald-500/15">
            <CipherStream />
            <div className="pointer-events-none absolute inset-y-0 left-0 w-6 bg-gradient-to-r from-background/90 to-transparent" />
            <div className="pointer-events-none absolute inset-y-0 right-0 w-6 bg-gradient-to-l from-background/90 to-transparent" />
          </div>
          <div className="mt-1 flex items-center justify-center gap-1.5">
            {[0, 1, 2, 3, 4].map((i) => (
              <span
                key={i}
                className="h-1 w-1 rounded-full bg-emerald-500/70 animate-feat-arrow-pulse"
                style={{ animationDelay: `${i * 200}ms` }}
              />
            ))}
          </div>
        </div>

        {/* Боб */}
        <div className="z-10 flex w-[26%] shrink-0 flex-col items-center gap-1">
          <div className="flex h-10 w-10 items-center justify-center rounded-full bg-gradient-to-br from-primary to-primary/70 text-sm font-bold text-primary-foreground shadow">
            {t.peerBob.charAt(0)}
          </div>
          <span className="text-[10px] font-semibold text-foreground">{t.peerBob}</span>
          <div className="rounded-2xl rounded-tl-none bg-muted px-2.5 py-1.5 text-[11px] text-foreground shadow-sm animate-feat-msg-fly-in">
            {t.peerHello}
          </div>
        </div>
      </div>

      {/* Реальный `E2eeFingerprintBadge`: ОДИН badge с Fingerprint-иконкой,
          uppercase-hint сверху и monospace-кодом снизу. Сравнение отпечатков
          в LighChat — это user-задача, поэтому в UI нет «match»-бейджа.
          Мы повторяем боевой компонент один-в-один. */}
      <div className="mt-2">
        <FingerprintBadge label={t.peerAlice} />
      </div>
    </div>
  );
}
