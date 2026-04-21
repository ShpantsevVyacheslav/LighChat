import 'package:lighchat_models/lighchat_models.dart';

class ThreadRoutePayload {
  const ThreadRoutePayload({this.parentMessage, this.focusMessageId});

  final ChatMessage? parentMessage;
  final String? focusMessageId;
}
