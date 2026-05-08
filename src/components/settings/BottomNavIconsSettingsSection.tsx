'use client';

import React, { useState, useMemo, useCallback, useRef, useEffect } from 'react';
import { useAuth } from '@/hooks/use-auth';
import { useSettings } from '@/hooks/use-settings';
import { useToast } from '@/hooks/use-toast';
import { NAV_LINKS } from '@/lib/constants';
import {
  DEFAULT_BOTTOM_NAV_LUCIDE_NAMES,
  resolveBottomNavLucideIconName,
} from '@/lib/bottom-nav-icons';
import { mergeBottomNavIconVisualStyles } from '@/lib/bottom-nav-icon-style-merge';
import { bottomNavIosTileClasses } from '@/lib/bottom-nav-ios-tiles';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Slider } from '@/components/ui/slider';
import { LucideIconPickerDialog } from '@/components/settings/LucideIconPickerDialog';
import { DynamicIcon, type IconName } from 'lucide-react/dynamic';
import { Pencil, Undo2, LayoutTemplate, Palette, Sparkles } from 'lucide-react';
import { cn } from '@/lib/utils';
import { tileBackgroundToColorInputValue } from '@/lib/bottom-nav-tile-color-input';
import { useI18n } from '@/hooks/use-i18n';
import type { BottomNavIconVisualStyle, UserRole } from '@/lib/types';

export function BottomNavIconsSettingsSection() {
  const { user } = useAuth();
  const { chatSettings, updateChatSettings } = useSettings();
  const { toast } = useToast();
  const { t } = useI18n();
  const role = user?.role as UserRole | undefined;

  const [pickerHref, setPickerHref] = useState<string | null>(null);
  const [stylePanelHref, setStylePanelHref] = useState<string | null>(null);
  /** Черновик толщины во время перетаскивания слайдера; фиксация в Firestore в `onValueCommit`. */
  const [strokeSliderDraft, setStrokeSliderDraft] = useState<number | null>(null);
  const [globalStrokeSliderDraft, setGlobalStrokeSliderDraft] = useState<number | null>(null);
  const [globalStylePanelOpen, setGlobalStylePanelOpen] = useState(false);

  useEffect(() => {
    setStrokeSliderDraft(null);
  }, [stylePanelHref, chatSettings.bottomNavIconStyles]);

  useEffect(() => {
    setGlobalStrokeSliderDraft(null);
  }, [globalStylePanelOpen, chatSettings.bottomNavIconGlobalStyle]);

  const links = useMemo(
    () => (role ? NAV_LINKS.filter((l) => (l.roles as string[]).includes(role)) : []),
    [role]
  );

  const iconNamesMap = chatSettings.bottomNavIconNames ?? {};
  const stylesMap = chatSettings.bottomNavIconStyles ?? {};
  const globalStyleMap = chatSettings.bottomNavIconGlobalStyle ?? {};
  const pickForHref = pickerHref ?? '';
  const currentResolved = pickForHref
    ? resolveBottomNavLucideIconName(pickForHref, iconNamesMap)
    : ('circle' as IconName);

  /** Актуальная копия стилей между round-trip Firestore — устраняет гонки слайдера и color input. */
  const stylesMergeRef = useRef<Record<string, BottomNavIconVisualStyle>>({});
  const persistChainRef = useRef(Promise.resolve());

  useEffect(() => {
    stylesMergeRef.current = { ...stylesMap };
  }, [stylesMap]);

  const globalStyleMergeRef = useRef<BottomNavIconVisualStyle>({});

  useEffect(() => {
    globalStyleMergeRef.current = { ...globalStyleMap };
  }, [globalStyleMap]);

  const persistGlobalStylePatch = useCallback(
    (patch: Partial<BottomNavIconVisualStyle & { strokeWidth?: number | null }>) => {
      persistChainRef.current = persistChainRef.current.then(async () => {
        const cur: BottomNavIconVisualStyle = { ...globalStyleMergeRef.current };
        if ('iconColor' in patch) {
          const v = patch.iconColor;
          if (v === null || v === undefined || (typeof v === 'string' && v.trim() === ''))
            delete cur.iconColor;
          else if (typeof v === 'string') cur.iconColor = v.trim();
        }
        if ('tileBackground' in patch) {
          const v = patch.tileBackground;
          if (v === null || v === undefined || (typeof v === 'string' && v.trim() === '')) {
            delete cur.tileBackground;
          } else if (typeof v === 'string') cur.tileBackground = v.trim();
        }
        if ('strokeWidth' in patch) {
          const v = patch.strokeWidth;
          if (v === null || v === undefined || (typeof v === 'number' && !Number.isFinite(v))) {
            delete cur.strokeWidth;
          } else if (typeof v === 'number') cur.strokeWidth = v;
        }
        globalStyleMergeRef.current = cur;
        const ok = await updateChatSettings({
          bottomNavIconGlobalStyle: Object.keys(cur).length ? cur : {},
        });
        if (!ok) {
          globalStyleMergeRef.current = { ...(chatSettings.bottomNavIconGlobalStyle ?? {}) };
          toast({ variant: 'destructive', title: t('settings.bottomNav.globalSaveError') });
        }
      });
      return persistChainRef.current;
    },
    [updateChatSettings, toast, chatSettings.bottomNavIconGlobalStyle]
  );

  const persistStylePatch = useCallback(
    (href: string, patch: Partial<BottomNavIconVisualStyle & { strokeWidth?: number | null }>) => {
      persistChainRef.current = persistChainRef.current.then(async () => {
        const prevAll = { ...stylesMergeRef.current };
        const cur: BottomNavIconVisualStyle = { ...(prevAll[href] ?? {}) };
        if ('iconColor' in patch) {
          const v = patch.iconColor;
          if (v === null || v === undefined || (typeof v === 'string' && v.trim() === ''))
            delete cur.iconColor;
          else if (typeof v === 'string') cur.iconColor = v.trim();
        }
        if ('tileBackground' in patch) {
          const v = patch.tileBackground;
          if (v === null || v === undefined || (typeof v === 'string' && v.trim() === '')) {
            delete cur.tileBackground;
          } else if (typeof v === 'string') cur.tileBackground = v.trim();
        }
        if ('strokeWidth' in patch) {
          const v = patch.strokeWidth;
          if (v === null || v === undefined || (typeof v === 'number' && !Number.isFinite(v))) {
            delete cur.strokeWidth;
          } else if (typeof v === 'number') cur.strokeWidth = v;
        }
        const nextAll = { ...prevAll };
        if (Object.keys(cur).length === 0) delete nextAll[href];
        else nextAll[href] = cur;

        stylesMergeRef.current = nextAll;
        const ok = await updateChatSettings({
          bottomNavIconStyles: Object.keys(nextAll).length ? nextAll : {},
        });
        if (!ok) {
          stylesMergeRef.current = { ...(chatSettings.bottomNavIconStyles ?? {}) };
          toast({ variant: 'destructive', title: t('settings.bottomNav.stylesSaveError') });
        }
      });
      return persistChainRef.current;
    },
    [updateChatSettings, toast, chatSettings.bottomNavIconStyles]
  );

  const handleIconChosen = async (name: string) => {
    if (!pickerHref) return;
    const next = { ...iconNamesMap, [pickerHref]: name };
    const ok = await updateChatSettings({ bottomNavIconNames: next });
    if (ok) {
      toast({ title: t('settings.bottomNav.iconSaved') });
    } else {
      toast({ variant: 'destructive', title: t('settings.bottomNav.saveError') });
    }
  };

  const handleResetHref = async (href: string) => {
    const next = { ...iconNamesMap };
    delete next[href];
    const nextStyles = { ...stylesMap };
    delete nextStyles[href];
    const ok = await updateChatSettings({
      bottomNavIconNames: Object.keys(next).length ? next : {},
      bottomNavIconStyles: Object.keys(nextStyles).length ? nextStyles : {},
    });
    if (ok) {
      stylesMergeRef.current = { ...nextStyles };
      toast({ title: t('settings.bottomNav.resetDone') });
    } else {
      toast({ variant: 'destructive', title: t('settings.bottomNav.saveError') });
    }
  };

  const hasOverride = (href: string) =>
    Object.prototype.hasOwnProperty.call(iconNamesMap, href) && iconNamesMap[href] !== undefined;

  const hasStyleOverride = (href: string) =>
    Object.prototype.hasOwnProperty.call(stylesMap, href) &&
    stylesMap[href] != null &&
    Object.keys(stylesMap[href] as object).length > 0;

  const hasGlobalStyleOverride =
    globalStyleMap != null && Object.keys(globalStyleMap as object).length > 0;

  const handleResetGlobal = async () => {
    const ok = await updateChatSettings({ bottomNavIconGlobalStyle: {} });
    if (ok) {
      globalStyleMergeRef.current = {};
      toast({ title: t('settings.bottomNav.globalResetDone') });
    } else {
      toast({ variant: 'destructive', title: t('settings.bottomNav.saveError') });
    }
  };

  if (!role || links.length === 0) return null;

  const appearance = chatSettings.bottomNavAppearance ?? 'colorful';

  const globalPreviewStrokeBase =
    typeof globalStyleMap.strokeWidth === 'number' && globalStyleMap.strokeWidth >= 0.75
      ? globalStyleMap.strokeWidth
      : 2;
  const globalPreviewStroke =
    globalStylePanelOpen && globalStrokeSliderDraft != null
      ? globalStrokeSliderDraft
      : globalPreviewStrokeBase;
  const globalPreviewIconColor =
    typeof globalStyleMap.iconColor === 'string' && globalStyleMap.iconColor.trim().length > 0
      ? globalStyleMap.iconColor.trim()
      : undefined;
  const globalHasCustomTileBg =
    typeof globalStyleMap.tileBackground === 'string' &&
    globalStyleMap.tileBackground.trim().length > 0;

  return (
    <>
      <section className="space-y-4">
        <h2 className="flex items-center gap-2 text-base font-semibold leading-none tracking-tight">
          <LayoutTemplate className="h-4 w-4 text-primary shrink-0" />
          {t('settings.bottomNav.title')}
        </h2>
        <div className="space-y-2">
          <div className="rounded-xl border border-primary/20 bg-primary/[0.06] dark:border-primary/25 dark:bg-primary/[0.08]">
            <div
              className={cn(
                'flex items-center gap-3 px-3 py-2.5',
                globalStylePanelOpen && 'rounded-t-xl border-b border-border/40'
              )}
            >
              <div
                className={cn(
                  'flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-background/80 ring-1 ring-black/5 dark:ring-white/10',
                  appearance === 'colorful' && !globalHasCustomTileBg && bottomNavIosTileClasses('/dashboard/chat'),
                  appearance === 'minimal' && !globalHasCustomTileBg && 'bg-background/90'
                )}
                style={
                  globalHasCustomTileBg
                    ? {
                        background: globalStyleMap.tileBackground!.trim(),
                        boxShadow: '0 4px 10px rgba(0,0,0,0.2), inset 0 1px 0 rgba(255,255,255,0.3)',
                      }
                    : undefined
                }
                aria-hidden
              >
                <Sparkles
                  className={cn(
                    'h-5 w-5',
                    appearance === 'colorful' &&
                      !globalPreviewIconColor &&
                      'text-white drop-shadow-[0_1px_2px_rgba(0,0,0,0.35)]',
                    appearance === 'minimal' &&
                      !globalPreviewIconColor &&
                      (globalHasCustomTileBg
                        ? 'text-white drop-shadow-[0_1px_2px_rgba(0,0,0,0.35)]'
                        : 'text-foreground')
                  )}
                  strokeWidth={globalPreviewStroke}
                  style={globalPreviewIconColor ? { color: globalPreviewIconColor } : undefined}
                />
              </div>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-medium">{t('settings.bottomNav.forAllIcons')}</p>
                <p className="text-[10px] text-muted-foreground">
                  {t('settings.bottomNav.forAllIconsDesc')}
                </p>
              </div>
              <div className="flex shrink-0 flex-wrap items-center justify-end gap-1">
                {hasGlobalStyleOverride && (
                  <Button
                    type="button"
                    variant="ghost"
                    size="icon"
                    className="h-9 w-9 rounded-lg"
                    title={t('settings.bottomNav.resetGlobal')}
                    onClick={() => void handleResetGlobal()}
                  >
                    <Undo2 className="h-4 w-4" />
                  </Button>
                )}
                <Button
                  type="button"
                  variant={globalStylePanelOpen ? 'secondary' : 'outline'}
                  size="sm"
                  className="h-9 rounded-lg gap-1.5 px-2.5"
                  onClick={() => setGlobalStylePanelOpen((o) => !o)}
                >
                  <Palette className="h-3.5 w-3.5" />
                  {t('settings.bottomNav.customize')}
                </Button>
              </div>
            </div>
            {globalStylePanelOpen && (
              <div className="space-y-4 bg-background/40 px-3 py-3 dark:bg-black/10">
                <div className="space-y-2">
                  <Label className="text-xs text-muted-foreground">{t('settings.bottomNav.iconColorAll')}</Label>
                  <div className="flex flex-wrap items-center gap-2">
                    <input
                      type="color"
                      aria-label={t('settings.bottomNav.colorResetGlobal')}
                      className="h-9 w-12 cursor-pointer rounded-md border border-border bg-background"
                      value={
                        globalPreviewIconColor ??
                        (appearance === 'colorful' ? '#ffffff' : '#64748b')
                      }
                      onChange={(e) => void persistGlobalStylePatch({ iconColor: e.target.value })}
                    />
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      className="h-8 rounded-lg text-xs"
                      onClick={() => void persistGlobalStylePatch({ iconColor: null })}
                    >
                      {t('settings.bottomNav.resetBtn')}
                    </Button>
                  </div>
                </div>
                <div className="space-y-2">
                  <div className="flex items-center justify-between gap-2">
                    <Label className="text-xs text-muted-foreground">{t('settings.bottomNav.strokeWidth')}</Label>
                    <span className="font-mono text-[11px] text-muted-foreground">
                      {globalPreviewStroke.toFixed(2)}
                    </span>
                  </div>
                  <Slider
                    min={1}
                    max={3}
                    step={0.25}
                    value={[globalPreviewStroke]}
                    onValueChange={(v) => {
                      const n = v[0];
                      if (typeof n === 'number') setGlobalStrokeSliderDraft(n);
                    }}
                    onValueCommit={(v) => {
                      const n = v[0];
                      if (typeof n !== 'number') return;
                      setGlobalStrokeSliderDraft(null);
                      void persistGlobalStylePatch({ strokeWidth: n });
                    }}
                  />
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    className="h-7 px-2 text-xs text-muted-foreground"
                    onClick={() => void persistGlobalStylePatch({ strokeWidth: null })}
                  >
                    {t('settings.bottomNav.resetStroke')}
                  </Button>
                </div>
                <div className="space-y-2">
                  <Label className="text-xs text-muted-foreground">{t('settings.bottomNav.tileBackground')}</Label>
                  <div className="flex flex-wrap items-center gap-2">
                    <input
                      type="color"
                      aria-label={t('settings.bottomNav.tileResetGlobal')}
                      className="h-9 w-12 cursor-pointer rounded-md border border-border bg-background"
                      value={tileBackgroundToColorInputValue(
                        globalStyleMap.tileBackground,
                        '#8b5cf6'
                      )}
                      onChange={(e) =>
                        void persistGlobalStylePatch({ tileBackground: e.target.value })
                      }
                    />
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      className="h-8 rounded-lg text-xs"
                      onClick={() => void persistGlobalStylePatch({ tileBackground: null })}
                    >
                      {t('settings.bottomNav.defaultGradient')}
                    </Button>
                  </div>
                </div>
              </div>
            )}
          </div>

          {links.map((link) => {
            const resolved = resolveBottomNavLucideIconName(link.href, iconNamesMap);
            const overridden = hasOverride(link.href);
            const visual = mergeBottomNavIconVisualStyles(globalStyleMap, stylesMap[link.href]);
            const hasCustomTileBg =
              typeof visual?.tileBackground === 'string' && visual.tileBackground.trim().length > 0;
            const previewStrokeBase =
              typeof visual?.strokeWidth === 'number' && visual.strokeWidth >= 0.75
                ? visual.strokeWidth
                : 2;
            const previewStroke =
              stylePanelHref === link.href && strokeSliderDraft != null
                ? strokeSliderDraft
                : previewStrokeBase;
            const previewIconColor =
              typeof visual?.iconColor === 'string' && visual.iconColor.trim().length > 0
                ? visual.iconColor.trim()
                : undefined;

            return (
              <div key={link.href} className="rounded-xl border border-border/50 dark:border-white/[0.08]">
                <div
                  className={cn(
                    'flex items-center gap-3 bg-muted/25 px-3 py-2.5 dark:bg-white/[0.04]',
                    stylePanelHref === link.href && 'rounded-t-xl border-b border-border/40'
                  )}
                >
                  <div
                    className={cn(
                      'flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-background/80 ring-1 ring-black/5 dark:ring-white/10',
                      appearance === 'colorful' && !hasCustomTileBg && bottomNavIosTileClasses(link.href),
                      appearance === 'minimal' && !hasCustomTileBg && 'bg-background/90'
                    )}
                    style={
                      hasCustomTileBg
                        ? {
                            background: visual!.tileBackground!.trim(),
                            boxShadow:
                              '0 4px 10px rgba(0,0,0,0.2), inset 0 1px 0 rgba(255,255,255,0.3)',
                          }
                        : undefined
                    }
                    aria-hidden
                  >
                    <DynamicIcon
                      name={resolved}
                      className={cn(
                        'h-5 w-5',
                        appearance === 'colorful' &&
                          !previewIconColor &&
                          'text-white drop-shadow-[0_1px_2px_rgba(0,0,0,0.35)]',
                        appearance === 'minimal' &&
                          !previewIconColor &&
                          (hasCustomTileBg
                            ? 'text-white drop-shadow-[0_1px_2px_rgba(0,0,0,0.35)]'
                            : 'text-foreground')
                      )}
                      strokeWidth={previewStroke}
                      style={previewIconColor ? { color: previewIconColor } : undefined}
                    />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-medium">{link.label}</p>
                    <p className="truncate font-mono text-[10px] text-muted-foreground">{resolved}</p>
                    <p className="truncate text-[10px] text-muted-foreground/80">
                      {t('settings.bottomNav.defaultValue')} {DEFAULT_BOTTOM_NAV_LUCIDE_NAMES[link.href] ?? '—'}
                    </p>
                  </div>
                  <div className="flex shrink-0 flex-wrap items-center justify-end gap-1">
                    {(overridden || hasStyleOverride(link.href)) && (
                      <Button
                        type="button"
                        variant="ghost"
                        size="icon"
                        className="h-9 w-9 rounded-lg"
                        title={t('settings.bottomNav.resetToDefault')}
                        onClick={() => void handleResetHref(link.href)}
                      >
                        <Undo2 className="h-4 w-4" />
                      </Button>
                    )}
                    <Button
                      type="button"
                      variant={stylePanelHref === link.href ? 'secondary' : 'ghost'}
                      size="icon"
                      className="h-9 w-9 rounded-lg"
                      title={t('settings.bottomNav.colorStrokeTitle')}
                      onClick={() =>
                        setStylePanelHref((h) => (h === link.href ? null : link.href))
                      }
                    >
                      <Palette className="h-4 w-4" />
                    </Button>
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      className="h-9 gap-1.5 rounded-lg px-2.5"
                      onClick={() => setPickerHref(link.href)}
                    >
                      <Pencil className="h-3.5 w-3.5" />
                      {t('settings.bottomNav.chooseBtn')}
                    </Button>
                  </div>
                </div>
                {stylePanelHref === link.href && (
                  <div className="space-y-4 bg-background/40 px-3 py-3 dark:bg-black/10">
                    <div className="space-y-2">
                      <Label className="text-xs text-muted-foreground">{t('settings.bottomNav.iconColor')}</Label>
                      <div className="flex flex-wrap items-center gap-2">
                        <input
                          type="color"
                          aria-label={t('settings.bottomNav.iconColor')}
                          className="h-9 w-12 cursor-pointer rounded-md border border-border bg-background"
                          value={
                            previewIconColor ??
                            (appearance === 'colorful' ? '#ffffff' : '#64748b')
                          }
                          onChange={(e) => void persistStylePatch(link.href, { iconColor: e.target.value })}
                        />
                        <Button
                          type="button"
                          variant="outline"
                          size="sm"
                          className="h-8 rounded-lg text-xs"
                          onClick={() => void persistStylePatch(link.href, { iconColor: null })}
                        >
                          {t('settings.bottomNav.defaultColor')}
                        </Button>
                      </div>
                    </div>
                    <div className="space-y-2">
                      <div className="flex items-center justify-between gap-2">
                        <Label className="text-xs text-muted-foreground">{t('settings.bottomNav.strokeWidth')}</Label>
                        <span className="font-mono text-[11px] text-muted-foreground">
                          {previewStroke.toFixed(2)}
                        </span>
                      </div>
                      <Slider
                        min={1}
                        max={3}
                        step={0.25}
                        value={[previewStroke]}
                        onValueChange={(v) => {
                          const n = v[0];
                          if (typeof n === 'number') setStrokeSliderDraft(n);
                        }}
                        onValueCommit={(v) => {
                          const n = v[0];
                          if (typeof n !== 'number') return;
                          setStrokeSliderDraft(null);
                          void persistStylePatch(link.href, { strokeWidth: n });
                        }}
                      />
                      <Button
                        type="button"
                        variant="ghost"
                        size="sm"
                        className="h-7 px-2 text-xs text-muted-foreground"
                        onClick={() => void persistStylePatch(link.href, { strokeWidth: null })}
                      >
                        {t('settings.bottomNav.resetStroke')}
                      </Button>
                    </div>
                    <div className="space-y-2">
                      <Label className="text-xs text-muted-foreground">
                        {t('settings.bottomNav.tileBackgroundItem')}
                      </Label>
                      <div className="flex flex-wrap items-center gap-2">
                        <input
                          type="color"
                          aria-label={t('settings.bottomNav.tileBackground')}
                          className="h-9 w-12 cursor-pointer rounded-md border border-border bg-background"
                          value={tileBackgroundToColorInputValue(
                            visual?.tileBackground,
                            '#8b5cf6'
                          )}
                          onChange={(e) =>
                            void persistStylePatch(link.href, { tileBackground: e.target.value })
                          }
                        />
                        <Button
                          type="button"
                          variant="outline"
                          size="sm"
                          className="h-8 rounded-lg text-xs"
                          onClick={() => void persistStylePatch(link.href, { tileBackground: null })}
                        >
                          {t('settings.bottomNav.defaultGradient')}
                        </Button>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </section>

      <LucideIconPickerDialog
        open={pickerHref !== null}
        onOpenChange={(o) => !o && setPickerHref(null)}
        title={
          pickForHref
            ? t('settings.bottomNav.iconPickerTitle', { label: links.find((l) => l.href === pickForHref)?.label ?? pickForHref })
            : t('settings.bottomNav.iconPickerFallbackTitle')
        }
        description={t('settings.bottomNav.iconPickerDesc')}
        currentName={String(currentResolved)}
        onSelect={handleIconChosen}
      />
    </>
  );
}
