import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

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
    final width = (mq.size.width * 0.62).clamp(260.0, 320.0);
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
              child: const _PopoverCard(),
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
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: -0.1,
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
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

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
            ],
          ),
        ),
      ),
    );
  }
}
