import 'package:lighchat_models/lighchat_models.dart';

/// Паритет веба: `att.name.startsWith('video-circle_')`.
bool isVideoCircleAttachment(ChatAttachment a) {
  return a.name.startsWith('video-circle_');
}
