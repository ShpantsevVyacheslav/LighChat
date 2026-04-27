import 'e2ee_runtime.dart';

/// E2EE: runtime + epoch + зарезервированный `messageId` для альбома.
class OutgoingAlbumE2eeContext {
  const OutgoingAlbumE2eeContext({
    required this.runtime,
    required this.epoch,
    required this.messageId,
    required this.encryptText,
  });

  final MobileE2eeRuntime runtime;
  final int epoch;
  final String messageId;
  final bool encryptText;
}
