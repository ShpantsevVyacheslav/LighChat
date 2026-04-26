/// Выбор обоев для экрана чата: переопределение из `chatConversationPrefs`
/// либо глобальное `users.chatSettings.chatWallpaper` (как на вебе в `ChatWindow`).
String? resolveEffectiveChatWallpaper({
  required String? globalChatWallpaper,
  required Map<String, dynamic> conversationPrefs,
}) {
  final convRaw = conversationPrefs['chatWallpaper'];
  if (convRaw is String && convRaw.trim().isNotEmpty) {
    return convRaw.trim();
  }
  final g = globalChatWallpaper?.trim();
  if (g != null && g.isNotEmpty) return g;
  return null;
}
