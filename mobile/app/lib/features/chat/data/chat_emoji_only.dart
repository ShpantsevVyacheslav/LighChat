// ignore_for_file: valid_regexps — Dart runtime поддерживает \p{…}; линтер паттерн не парсит.

/// Паритет с web `isOnlyEmojis` (`src/lib/chat-utils.ts`).
final RegExp _onlyEmojiFullString = RegExp(
  r'^(\p{Extended_Pictographic}|\p{Emoji_Component}|\u200D|\uFE0F|\s)+$',
  unicode: true,
);

String stripTagsForEmojiCheck(String input) {
  return input
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('\n', ' ')
      .trim();
}

/// `true`, если после удаления HTML остались только эмодзи/пробелы/ZWJ/VS16.
bool isOnlyEmojisMessage(String? htmlOrPlain) {
  if (htmlOrPlain == null || htmlOrPlain.trim().isEmpty) return false;
  final cleaned = stripTagsForEmojiCheck(htmlOrPlain);
  if (cleaned.isEmpty) return false;
  return _onlyEmojiFullString.hasMatch(cleaned);
}

/// Размер шрифта для сообщения «только эмодзи» (веб `MessageText` ~5rem).
/// Общий для ленты и превью над контекст-меню.
double pureEmojiMessageFontSize(String fontSize) {
  return switch (fontSize) {
    'small' => 64.0,
    'large' => 86.0,
    _ => 76.0,
  };
}
