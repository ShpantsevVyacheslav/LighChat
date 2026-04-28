typedef JsonMap = Map<String, Object?>;

/// Secret Chat hard-enforced media view limits (server-controlled docs).
///
/// Firestore subcollections under:
/// `conversations/{conversationId}/secretMedia*`
enum SecretMediaKind {
  image('image'),
  video('video'),
  voice('voice'),
  videoCircle('videoCircle'),
  file('file'),
  location('location');

  const SecretMediaKind(this.wire);
  final String wire;

  static SecretMediaKind? fromWire(Object? raw) {
    final s = raw is String ? raw : null;
    if (s == null || s.isEmpty) return null;
    for (final v in values) {
      if (v.wire == s) return v;
    }
    return null;
  }
}

class SecretMediaViewRequest {
  const SecretMediaViewRequest({
    required this.conversationId,
    required this.messageId,
    required this.fileId,
    required this.recipientUid,
    required this.recipientDeviceId,
    required this.kind,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
  });

  final String conversationId;
  final String messageId;
  final String fileId;
  final String recipientUid;
  final String recipientDeviceId;
  final SecretMediaKind kind;
  final String createdAt;
  final String expiresAt;
  final String status; // pending | fulfilled | expired

  static SecretMediaViewRequest? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = raw.map((k, v) => MapEntry(k.toString(), v));
    final conversationId = m['conversationId'];
    final messageId = m['messageId'];
    final fileId = m['fileId'];
    final recipientUid = m['recipientUid'];
    final recipientDeviceId = m['recipientDeviceId'];
    final kind = SecretMediaKind.fromWire(m['kind']);
    final createdAt = m['createdAt'];
    final expiresAt = m['expiresAt'];
    final status = m['status'];
    if (conversationId is! String || conversationId.isEmpty) return null;
    if (messageId is! String || messageId.isEmpty) return null;
    if (fileId is! String || fileId.isEmpty) return null;
    if (recipientUid is! String || recipientUid.isEmpty) return null;
    if (recipientDeviceId is! String || recipientDeviceId.isEmpty) return null;
    if (kind == null) return null;
    if (createdAt is! String || createdAt.isEmpty) return null;
    if (expiresAt is! String || expiresAt.isEmpty) return null;
    if (status is! String || status.isEmpty) return null;
    return SecretMediaViewRequest(
      conversationId: conversationId,
      messageId: messageId,
      fileId: fileId,
      recipientUid: recipientUid,
      recipientDeviceId: recipientDeviceId,
      kind: kind,
      createdAt: createdAt,
      expiresAt: expiresAt,
      status: status,
    );
  }
}

class SecretMediaKeyGrant {
  const SecretMediaKeyGrant({
    required this.conversationId,
    required this.messageId,
    required this.fileId,
    required this.recipientUid,
    required this.recipientDeviceId,
    required this.wrappedFileKeyForDevice,
    required this.issuedByUid,
  });

  final String conversationId;
  final String messageId;
  final String fileId;
  final String recipientUid;
  final String recipientDeviceId;
  final String wrappedFileKeyForDevice;
  final String issuedByUid;

  static SecretMediaKeyGrant? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = raw.map((k, v) => MapEntry(k.toString(), v));
    final conversationId = m['conversationId'];
    final messageId = m['messageId'];
    final fileId = m['fileId'];
    final recipientUid = m['recipientUid'];
    final recipientDeviceId = m['recipientDeviceId'];
    final wrappedFileKeyForDevice = m['wrappedFileKeyForDevice'];
    final issuedByUid = m['issuedByUid'];
    if (conversationId is! String || conversationId.isEmpty) return null;
    if (messageId is! String || messageId.isEmpty) return null;
    if (fileId is! String || fileId.isEmpty) return null;
    if (recipientUid is! String || recipientUid.isEmpty) return null;
    if (recipientDeviceId is! String || recipientDeviceId.isEmpty) return null;
    if (wrappedFileKeyForDevice is! String || wrappedFileKeyForDevice.isEmpty) {
      return null;
    }
    if (issuedByUid is! String || issuedByUid.isEmpty) return null;
    return SecretMediaKeyGrant(
      conversationId: conversationId,
      messageId: messageId,
      fileId: fileId,
      recipientUid: recipientUid,
      recipientDeviceId: recipientDeviceId,
      wrappedFileKeyForDevice: wrappedFileKeyForDevice,
      issuedByUid: issuedByUid,
    );
  }
}

