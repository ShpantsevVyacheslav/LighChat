import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// «Catch me up» pill над композером. Показывается когда в чате накопились
/// непрочитанные сообщения и Apple Intelligence доступен. Тап — открывает
/// AI digest sheet с краткой выжимкой ([openAiChatDigestSheet]).
///
/// Виджет ничего сам не знает про подсчёт unread / форматирование сообщений —
/// все эти решения принимает родитель (`chat_screen`), а здесь только
/// презентационный слой. Если [unreadCount] < [minUnreadToShow] или
/// [aiAvailable] = false — pill схлопывается в [SizedBox.shrink].
class AiCatchMeUpPill extends StatelessWidget {
  const AiCatchMeUpPill({
    super.key,
    required this.aiAvailable,
    required this.unreadCount,
    required this.onTap,
    this.minUnreadToShow = 5,
  });

  final bool aiAvailable;
  final int unreadCount;
  final VoidCallback onTap;
  final int minUnreadToShow;

  @override
  Widget build(BuildContext context) {
    if (!aiAvailable || unreadCount < minUnreadToShow) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final accent = const Color(0xFF7C8DFF);
    final bg = isDark ? const Color(0xFF1E2127) : Colors.white;
    final fg = isDark ? const Color(0xFFE6E7EA) : const Color(0xFF1A1C22);
    final border = isDark ? const Color(0x14FFFFFF) : const Color(0x0F000000);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 13,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.ai_catch_me_up_label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: fg.withValues(alpha: 0.92),
                          height: 1.2,
                        ),
                      ),
                      Text(
                        l10n.ai_catch_me_up_unread_count(unreadCount),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: fg.withValues(alpha: 0.62),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: fg.withValues(alpha: 0.42),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
