import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pending_image_album_send.dart';

class PendingImageAlbumNotifier extends Notifier<Map<String, PendingImageAlbumSend?>> {
  @override
  Map<String, PendingImageAlbumSend?> build() =>
      <String, PendingImageAlbumSend?>{};

  PendingImageAlbumSend? forConversation(String conversationId) =>
      state[conversationId];

  void setFor(String conversationId, PendingImageAlbumSend? value) {
    state = {...state, conversationId: value};
  }
}

final pendingImageAlbumNotifierProvider =
    NotifierProvider<PendingImageAlbumNotifier, Map<String, PendingImageAlbumSend?>>(
        PendingImageAlbumNotifier.new);
