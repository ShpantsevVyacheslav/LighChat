import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Унифицированный confirm-dialog для destructive действий
/// (удалить сообщение, заблокировать пользователя, и т.п.).
///
/// Дизайн:
/// - тёмный rounded surface,
/// - крупный заголовок,
/// - body-текст,
/// - вертикальная пара кнопок: яркая красная (`destructive`) сверху,
///   нейтральная «Отмена» снизу.
///
/// Возвращает `true` если пользователь подтвердил, `false` / `null`
/// при отмене или закрытии dialog'а.
Future<bool?> showDestructiveConfirmDialog({
  required BuildContext context,
  required String title,
  required String confirmLabel,
  String? body,
  String? cancelLabel,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.38),
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx)!;
      return Dialog(
        backgroundColor: const Color(0xFF17191D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    height: 1.2,
                  ),
                ),
                if (body != null && body.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 13.5,
                      height: 1.24,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  height: 42,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      // iOS system destructive red — насыщенный,
                      // ярче прежнего #E24D59 (был слегка
                      // приглушённый).
                      backgroundColor: const Color(0xFFFF3B30),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(confirmLabel),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.11),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(cancelLabel ?? l10n.common_cancel),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
