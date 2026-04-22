/// Вложение сообщения чата митинга — тот же wire, что [ChatAttachment] в web
/// (`src/lib/types.ts`): url, name, type (mime), size, опционально width/height.
class MeetingChatAttachment {
  const MeetingChatAttachment({
    required this.url,
    required this.name,
    required this.type,
    required this.size,
    this.width,
    this.height,
  });

  final String url;
  final String name;
  final String type;
  final int size;
  final int? width;
  final int? height;

  bool get isImage =>
      type.startsWith('image/') && !type.contains('svg');

  Map<String, dynamic> toFirestoreMap() => <String, dynamic>{
        'url': url,
        'name': name,
        'type': type,
        'size': size,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
      };

  static MeetingChatAttachment? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final url = map['url'];
    final name = map['name'];
    final type = map['type'];
    final size = map['size'];
    if (url is! String || url.isEmpty) return null;
    if (name is! String) return null;
    if (type is! String) return null;
    final sizeInt = size is int
        ? size
        : size is num
            ? size.toInt()
            : null;
    if (sizeInt == null) return null;
    final w = map['width'];
    final h = map['height'];
    return MeetingChatAttachment(
      url: url,
      name: name,
      type: type,
      size: sizeInt,
      width: w is int ? w : (w is num ? w.toInt() : null),
      height: h is int ? h : (h is num ? h.toInt() : null),
    );
  }
}
