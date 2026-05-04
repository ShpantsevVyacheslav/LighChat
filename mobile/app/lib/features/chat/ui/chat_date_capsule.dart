import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// День в ленте чата: «Сегодня», «Вчера» или «20 апреля» (родительный падеж месяца).
String formatChatDayLabel(DateTime dt, AppLocalizations l10n, {DateTime? now}) {
  final local = dt.toLocal();
  final n = (now ?? DateTime.now()).toLocal();
  final day = DateTime(local.year, local.month, local.day);
  final today = DateTime(n.year, n.month, n.day);
  final yesterday = today.subtract(const Duration(days: 1));
  if (day == today) return l10n.date_today;
  if (day == yesterday) return l10n.date_yesterday;
  final months = <String>[
    l10n.date_month_1,
    l10n.date_month_2,
    l10n.date_month_3,
    l10n.date_month_4,
    l10n.date_month_5,
    l10n.date_month_6,
    l10n.date_month_7,
    l10n.date_month_8,
    l10n.date_month_9,
    l10n.date_month_10,
    l10n.date_month_11,
    l10n.date_month_12,
  ];
  final m = months[local.month - 1];
  if (local.year != n.year) {
    return '${local.day} $m ${local.year}';
  }
  return '${local.day} $m';
}

/// Капсула даты с размытием как у [ChatHeader] (белый текст).
class ChatBlurredDateCapsule extends StatelessWidget {
  const ChatBlurredDateCapsule({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final fg = Colors.white.withValues(alpha: 0.96);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
