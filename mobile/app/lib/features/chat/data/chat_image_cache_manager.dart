import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'local_cache_entry_registry.dart';

/// Custom cache manager for chat network images.
/// Stores files under a known directory (`libCachedImageData/chat_image_cache/`)
/// using SHA-256 (truncated to 32 hex chars) of the URL as the file id, so
/// [LocalCacheEntryRegistry.readImageContextSyncForFileName] can map a cached
/// file back to its conversation.
class ChatImageCacheManager extends CacheManager {
  static const _kCacheKey = 'chat_image_cache';

  static final ChatImageCacheManager _instance = ChatImageCacheManager._();

  factory ChatImageCacheManager() => _instance;

  ChatImageCacheManager._()
      : super(
          Config(
            _kCacheKey,
            stalePeriod: const Duration(days: 90),
            maxNrOfCacheObjects: 4000,
            fileService: _ChatImageFileService(),
          ),
        );

  static String get cacheKey => _kCacheKey;
}

/// File service that emits stable file ids — the SHA-256 prefix of the URL —
/// so on-disk filenames are predictable.
class _ChatImageFileService extends HttpFileService {
  _ChatImageFileService() : super();

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final response = await super.get(url, headers: headers);
    return _ChatImageFileServiceResponse(response, url);
  }
}

class _ChatImageFileServiceResponse implements FileServiceResponse {
  _ChatImageFileServiceResponse(this._inner, this._url);

  final FileServiceResponse _inner;
  final String _url;

  @override
  Stream<List<int>> get content => _inner.content;

  @override
  int? get contentLength => _inner.contentLength;

  @override
  String get eTag => LocalCacheEntryRegistry.imageFileIdForUrl(_url);

  @override
  String get fileExtension {
    final ext = _inner.fileExtension;
    if (ext.isNotEmpty) return ext;
    final lowered = _url.toLowerCase();
    for (final candidate in const ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.heic']) {
      if (lowered.contains(candidate)) return candidate;
    }
    return '.jpg';
  }

  @override
  int get statusCode => _inner.statusCode;

  @override
  DateTime get validTill => _inner.validTill;
}
