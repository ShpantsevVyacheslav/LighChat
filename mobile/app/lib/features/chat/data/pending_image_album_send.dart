import 'package:image_picker/image_picker.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'outgoing_album_e2ee_context.dart';

/// Данные для исходящего альбома (пока грузится в ленте).
class PendingImageAlbumSend {
  PendingImageAlbumSend({
    required this.files,
    required this.text,
    this.replyTo,
    this.e2eeContext,
  });

  final List<XFile> files;
  final String text;
  final ReplyContext? replyTo;
  final OutgoingAlbumE2eeContext? e2eeContext;
}
