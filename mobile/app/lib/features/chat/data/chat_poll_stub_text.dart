/// Текст-заглушка веба при отправке опроса (`<p>📊 Опрос</p>` → plain «📊 Опрос»).
/// Не показываем отдельным пузырьком в ленте.
bool isChatPollStubCaptionPlain(String plain) {
  final p = plain.trim().replaceAll(RegExp(r'\s+'), ' ');
  return p == '📊 Опрос' || p == 'Опрос';
}
