import 'package:flutter/cupertino.dart';

import '../../../l10n/app_localizations.dart';

/// Action-sheet «Поделиться геолокацией» в стиле Apple Messages:
/// native iOS `CupertinoActionSheet` с тремя duration-опциями
/// (Indefinitely / Until End of Day / For One Hour) + отдельной кнопкой
/// «Send Once» сверху.
///
/// Возвращает `id` выбранной длительности из
/// [liveLocationDurationOptions] (`once`, `h1`, `until_end_of_day`,
/// `forever`), или `null` если пользователь отменил.
///
/// На Android CupertinoActionSheet тоже рендерится корректно — это
/// чистый Flutter-виджет, нативные API не нужны.
Future<String?> showShareLocationSettingsSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showCupertinoModalPopup<String>(
    context: context,
    builder: (ctx) {
      return CupertinoActionSheet(
        title: Text(
          l10n.share_location_title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        message: Text(l10n.share_location_how),
        actions: [
          // «Send Once» — мгновенный pin без live-обновлений. В Apple
          // Messages это отдельный flow, у нас остаётся первой опцией
          // для совместимости с web/desktop.
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop('once'),
            child: Text(l10n.share_location_action_send_once),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop('h1'),
            child: Text(l10n.share_location_action_for_one_hour),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop('until_end_of_day'),
            child: Text(l10n.share_location_action_until_end_of_day),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop('forever'),
            child: Text(l10n.share_location_action_indefinitely),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.share_location_cancel),
        ),
      );
    },
  );
}
