/// E2EE policy: what data types are encrypted.
///
/// Важно: этот модуль НЕ меняет криптографию и формат envelope'ов.
/// Он только решает, нужно ли вызывать шифрование для конкретного типа данных
/// и нужно ли писать plaintext-превью для reply.
library;

enum E2eeDataType { text, media, replyPreview }

class E2eeDataTypePolicy {
  const E2eeDataTypePolicy({
    required this.text,
    required this.media,
    required this.replyPreview,
  });

  /// Шифровать тело сообщения (`message.e2ee.ciphertext`).
  final bool text;

  /// Шифровать вложения (`message.e2ee.attachments` + Storage `chat-attachments-enc/...`).
  final bool media;

  /// Писать ли plaintext в `replyTo.text` / `replyTo.mediaPreviewUrl`.
  /// Если false — reply превью восстанавливается в UI из расшифрованного оригинала.
  final bool replyPreview;

  static const E2eeDataTypePolicy defaults = E2eeDataTypePolicy(
    text: true,
    media: true,
    replyPreview: true,
  );

  static E2eeDataTypePolicy fromFirestore(Object? raw) {
    if (raw is! Map) return defaults;
    final m = raw.map((k, v) => MapEntry(k.toString(), v));
    bool readBool(String key, bool fallback) {
      final v = m[key];
      if (v is bool) return v;
      return fallback;
    }

    final text = readBool('text', defaults.text);
    return E2eeDataTypePolicy(
      text: text,
      media: readBool('media', defaults.media),
      // Reply preview follows text encryption automatically.
      replyPreview: text,
    );
  }

  Map<String, Object?> toFirestoreMap() => <String, Object?>{
    'text': text,
    'media': media,
    // Keep field for backward compatibility, but enforce invariant.
    'replyPreview': text,
  };

  E2eeDataTypePolicy copyWith({
    bool? text,
    bool? media,
    bool? replyPreview,
  }) {
    final nextText = text ?? this.text;
    return E2eeDataTypePolicy(
      text: nextText,
      media: media ?? this.media,
      // Reply preview follows text encryption automatically.
      replyPreview: nextText,
    );
  }
}

/// Если override задан — используем его, иначе global.
E2eeDataTypePolicy resolveE2eeEffectivePolicy({
  required E2eeDataTypePolicy global,
  E2eeDataTypePolicy? override,
}) {
  return override ?? global;
}

