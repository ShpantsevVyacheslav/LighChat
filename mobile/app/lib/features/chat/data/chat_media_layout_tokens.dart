class ChatMediaLayoutTokens {
  static const double mediaGridMaxWidth = 208;
  static const double gifAlbumGridMaxWidth = 416;
  static const double locationPreviewMaxWidth = 468;
  static const double messageBubbleMaxWidth = 320;

  /// Множитель ширины/высоты ячеек мозаики при 2+ изображениях (одиночные вложения без изменений).
  static const double mediaGridMosaicDisplayScale = 1.5;

  /// Множитель ширины для одного альбомного вложения (w ≥ h).
  static const double horizontalAttachmentDisplayScale = 1.3;

  /// Отступы между сообщениями и блоками медиа/подписи (×3 от базовых 2 px).
  static const double messageVerticalGap = 6;
  static const double mediaToMediaGap = 6;
  static const double mediaToCaptionGap = 6;
  static const double captionToStatusGap = 0;
  static const double mediaCardRadius = 18;

  /// Зазор над рамкой «ответ на сообщение» (и под строкой «Переслано», если она есть).
  /// Между рамкой и пузырём ответа отступа нет — визуально единый блок.
  static const double replyPreviewToBodyGap = 12;
}

double clampMediaWidth({required double available, required double maxWidth}) {
  if (available <= 0) return maxWidth;
  return available < maxWidth ? available : maxWidth;
}
