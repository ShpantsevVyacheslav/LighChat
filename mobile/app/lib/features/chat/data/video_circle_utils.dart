import 'package:lighchat_models/lighchat_models.dart';

/// Паритет веба: `att.name.startsWith('video-circle_')`.
///
/// Регистронезависимое сравнение; по URL — если в пути объекта Storage остался
/// сегмент `video-circle_` (старые клиенты без явного имени).
bool isVideoCircleAttachment(ChatAttachment a) {
  final n = a.name.toLowerCase();
  if (n.startsWith('video-circle_')) return true;
  try {
    final path = Uri.parse(a.url).path.toLowerCase();
    if (path.contains('video-circle_')) return true;
  } catch (_) {}
  return false;
}
