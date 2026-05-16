import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../data/live_location_duration_options.dart';

/// Компактный glass-popover для выбора длительности шаринга
/// геолокации. Узкий (~62% ширины экрана), парит над картой, с
/// hairline-разделителями между опциями.
///
/// 4 опции с иконками (∞ / 📅 / 🕐 / ⏱) + Cancel снизу (по требованию
/// пользователя — Apple их не показывает, у нас сохранили). Возвращает
/// id из [liveLocationDurationOptions] (`once`, `h1`, `until_end_of_day`,
/// `forever`) или `null` при отмене.
Future<String?> showShareLocationSettingsSheet(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  debugPrint('[location-share] showShareLocationSettingsSheet: opening');
  final result = await showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: l10n.share_location_cancel,
    barrierColor: Colors.black.withValues(alpha: 0.25),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, _) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, child) {
      final scale = Tween<double>(begin: 0.94, end: 1).animate(
        CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
      );
      final opacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
      );
      return FadeTransition(
        opacity: opacity,
        child: ScaleTransition(scale: scale, child: _PopoverShell(l10n: l10n)),
      );
    },
  );
  debugPrint(
    '[location-share] showShareLocationSettingsSheet: closed result=$result',
  );
  return result;
}

class _PopoverShell extends StatelessWidget {
  const _PopoverShell({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Компактная ширина: ~62% экрана, ограниченная min/max.
    // Bug 2: уже была компактная ширина, юзер просил ещё уже —
    // 52% экрана, 240..280pt.
    final width = (mq.size.width * 0.52).clamp(240.0, 280.0);
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          // Сдвигаем popover к правой нижней части (как у Apple
          // popover'а над картой) + safe-area bottom.
          padding: EdgeInsets.fromLTRB(
            0,
            0,
            12,
            mq.padding.bottom + 12,
          ),
          child: Align(
            alignment: Alignment.bottomRight,
            child: SizedBox(
              width: width,
              // Material нужен чтобы InkWell внутри строк рисовался без
              // ошибок ассертов; type=transparency не закрашивает
              // glass-фон. DefaultTextStyle с TextDecoration.none сносит
              // унаследованное «underline» с MaterialApp (та самая
              // жёлтая волнистая полоса под title — спорная default-
              // отрисовка для строк без Scaffold/Material parent'а).
              child: const Material(
                type: MaterialType.transparency,
                child: DefaultTextStyle(
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    color: Colors.white,
                  ),
                  child: _PopoverCard(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PopoverCard extends StatelessWidget {
  const _PopoverCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final cardColor = (dark ? Colors.white : Colors.white).withValues(
      alpha: dark ? 0.18 : 0.92,
    );
    final divider = (dark ? Colors.white : Colors.black).withValues(
      alpha: dark ? 0.16 : 0.10,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PopoverHeader(label: l10n.share_location_title),
              Container(height: 0.5, color: divider),
              _Row(
                icon: CupertinoIcons.infinite,
                label: l10n.share_location_action_indefinitely,
                onTap: () => Navigator.of(context).pop('forever'),
              ),
              Container(height: 0.5, color: divider),
              _Row(
                icon: CupertinoIcons.calendar,
                label: l10n.share_location_action_until_end_of_day,
                onTap: () => Navigator.of(context).pop('until_end_of_day'),
              ),
              Container(height: 0.5, color: divider),
              _Row(
                icon: CupertinoIcons.clock,
                label: l10n.share_location_action_for_one_hour,
                // T5: chevron-right теперь интерактивный (tap по
                // самой стрелке открывает granular sheet). Long-press
                // больше не используется — UX-handle стал явным.
                // Tap по основной части row — выбор «1 час».
                trailing: CupertinoIcons.chevron_right,
                onTrailingTap: () async {
                  final granular = await _showGranularDurationsSheet(context);
                  if (granular != null && context.mounted) {
                    Navigator.of(context).pop(granular);
                  }
                },
                onTap: () => Navigator.of(context).pop('h1'),
              ),
              Container(height: 0.5, color: divider),
              _Row(
                icon: CupertinoIcons.paperplane,
                label: l10n.share_location_action_send_once,
                onTap: () => Navigator.of(context).pop('once'),
              ),
              Container(height: 0.5, color: divider),
              _Row(
                icon: CupertinoIcons.xmark,
                label: l10n.share_location_cancel,
                destructive: true,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopoverHeader extends StatelessWidget {
  const _PopoverHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = (dark ? Colors.white : Colors.black).withValues(
      alpha: dark ? 0.55 : 0.50,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Text(
        label,
        // `decoration: TextDecoration.none` явно сбрасывает наследованный
        // underline (Flutter в showGeneralDialog по дефолту тянет
        // DefaultTextStyle с подчёркиванием для labels — отсюда жёлтая
        // волнистая полоса на скрине).
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: -0.1,
          decoration: TextDecoration.none,
          decorationColor: Colors.transparent,
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.trailing,
    this.onTrailingTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  final IconData? trailing;
  /// T5: тап непосредственно по trailing-иконке. Если null —
  /// trailing-иконка декоративная (не реагирует на тап,
  /// строка целиком ловит onTap).
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final base = dark ? Colors.white : Colors.black;
    final tint = destructive
        ? base.withValues(alpha: dark ? 0.75 : 0.65)
        : base.withValues(alpha: dark ? 0.96 : 0.92);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 18, color: tint),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: tint,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              // T5: trailing с onTrailingTap — обёрнут в собственный
              // InkWell, чтобы тап по нему НЕ триггерил основной
              // onTap (главная строка = выбор «1 час», стрелка =
              // расширенные варианты). Без callback — декоративная.
              if (trailing != null && onTrailingTap != null)
                InkWell(
                  onTap: onTrailingTap,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      trailing,
                      size: 16,
                      color: tint.withValues(alpha: 0.75),
                    ),
                  ),
                )
              else if (trailing != null)
                Icon(trailing, size: 14, color: tint.withValues(alpha: 0.55)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bug #8: расширенный выбор гранулярных длительностей. Открывается
/// long-press по строке «For One Hour» в основном popover'е.
/// Возвращает duration id (`m5`/`m15`/`m30`/`h1`/`h2`/`h6`/`d1`)
/// или null при отмене.
Future<String?> _showGranularDurationsSheet(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  debugPrint('[location-share] granular durations: opening');
  final result = await showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: l10n.share_location_cancel,
    barrierColor: Colors.black.withValues(alpha: 0.30),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, _) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, child) {
      final scale = Tween<double>(begin: 0.94, end: 1).animate(
        CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
      );
      final opacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
      );
      return FadeTransition(
        opacity: opacity,
        child: ScaleTransition(
          scale: scale,
          child: _GranularPopoverShell(l10n: l10n),
        ),
      );
    },
  );
  debugPrint('[location-share] granular durations: closed result=$result');
  return result;
}

class _GranularPopoverShell extends StatelessWidget {
  const _GranularPopoverShell({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = (mq.size.width * 0.55).clamp(260.0, 300.0);
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            0, 0, 12, mq.padding.bottom + 12,
          ),
          child: Align(
            alignment: Alignment.bottomRight,
            child: SizedBox(
              width: width,
              child: const Material(
                type: MaterialType.transparency,
                child: DefaultTextStyle(
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    color: Colors.white,
                  ),
                  child: _GranularPopoverCard(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GranularPopoverCard extends StatelessWidget {
  const _GranularPopoverCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final cardColor = Colors.white.withValues(alpha: dark ? 0.18 : 0.92);
    final divider = (dark ? Colors.white : Colors.black).withValues(
      alpha: dark ? 0.16 : 0.10,
    );
    // Гранулярный набор. Подмножество liveLocationDurationOptions
    // без `once` / `until_end_of_day` / `forever` — основные опции
    // уже представлены в главном popover'е.
    final granular = const ['m5', 'm15', 'm30', 'h1', 'h2', 'h6', 'd1'];
    final allOpts = {
      for (final o in liveLocationDurationOptions(l10n)) o.id: o,
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PopoverHeader(label: l10n.share_location_title),
              Container(height: 0.5, color: divider),
              for (var i = 0; i < granular.length; i++) ...[
                if (i > 0) Container(height: 0.5, color: divider),
                _Row(
                  icon: CupertinoIcons.clock,
                  label: allOpts[granular[i]]?.label ?? granular[i],
                  onTap: () => Navigator.of(context).pop(granular[i]),
                ),
              ],
              Container(height: 0.5, color: divider),
              _Row(
                icon: CupertinoIcons.xmark,
                label: l10n.share_location_cancel,
                destructive: true,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
