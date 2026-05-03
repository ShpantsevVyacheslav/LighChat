import 'dart:convert';
import 'dart:io';

import 'package:lighchat_models/lighchat_models.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/app_localizations.dart';
import '../../chat/data/chat_list_offline_cache.dart';
import '../../chat/data/chat_message_draft_storage.dart';
import '../../chat/data/local_cache_entry_registry.dart';
import '../../chat/data/local_storage_preferences.dart';
import '../../chat/data/saved_messages_chat.dart';
import '../../chat/data/user_profiles_disk_cache.dart';

enum LocalStorageEntrySource { file, draftItem, chatListSnapshot, profileCard }

enum StorageMediaType { video, photo, file, other }

const _kVideoExtensions = {'.mp4', '.mov', '.avi', '.mkv', '.webm', '.m4v'};
const _kPhotoExtensions = {
  '.jpg', '.jpeg', '.png', '.webp', '.gif', '.heic', '.heif', '.bmp',
};

StorageMediaType classifyEntryMediaType(LocalStorageEntry entry) {
  switch (entry.category) {
    case LocalStorageCategory.videoDownloads:
      return StorageMediaType.video;
    case LocalStorageCategory.e2eeMedia:
      final ext = _fileExtension(entry.filePath ?? entry.label);
      if (_kVideoExtensions.contains(ext)) return StorageMediaType.video;
      if (_kPhotoExtensions.contains(ext)) return StorageMediaType.photo;
      return StorageMediaType.file;
    case LocalStorageCategory.chatImages:
      return StorageMediaType.photo;
    case LocalStorageCategory.videoThumbs:
    case LocalStorageCategory.e2eeText:
    case LocalStorageCategory.chatDrafts:
    case LocalStorageCategory.chatListSnapshot:
    case LocalStorageCategory.profileCards:
      return StorageMediaType.other;
  }
}

String _fileExtension(String path) {
  final dot = path.lastIndexOf('.');
  if (dot < 0 || dot == path.length - 1) return '';
  return path.substring(dot).toLowerCase();
}

class StorageMediaTypeBreakdown {
  const StorageMediaTypeBreakdown({
    required this.videoBytes,
    required this.photoBytes,
    required this.fileBytes,
    required this.otherBytes,
    required this.totalBytes,
  });

  final int videoBytes;
  final int photoBytes;
  final int fileBytes;
  final int otherBytes;
  final int totalBytes;

  factory StorageMediaTypeBreakdown.fromEntries(List<LocalStorageEntry> entries) {
    int video = 0, photo = 0, file = 0, other = 0;
    for (final e in entries) {
      switch (classifyEntryMediaType(e)) {
        case StorageMediaType.video:
          video += e.bytes;
        case StorageMediaType.photo:
          photo += e.bytes;
        case StorageMediaType.file:
          file += e.bytes;
        case StorageMediaType.other:
          other += e.bytes;
      }
    }
    return StorageMediaTypeBreakdown(
      videoBytes: video,
      photoBytes: photo,
      fileBytes: file,
      otherBytes: other,
      totalBytes: video + photo + file + other,
    );
  }
}

class LocalStorageEntry {
  const LocalStorageEntry({
    required this.id,
    required this.category,
    required this.source,
    required this.bytes,
    required this.label,
    this.conversationId,
    this.filePath,
    this.modifiedAt,
    this.sharedPrefsKey,
    this.sharedPrefsSubKey,
  });

  final String id;
  final LocalStorageCategory category;
  final LocalStorageEntrySource source;
  final int bytes;
  final String label;
  final String? conversationId;
  final String? filePath;
  final DateTime? modifiedAt;
  final String? sharedPrefsKey;
  final String? sharedPrefsSubKey;
}

class LocalStorageConversationUsage {
  const LocalStorageConversationUsage({
    required this.conversationId,
    required this.conversationTitle,
    required this.totalBytes,
    required this.entries,
    required this.mediaTypeBreakdown,
  });

  final String conversationId;
  final String conversationTitle;
  final int totalBytes;
  final List<LocalStorageEntry> entries;
  final StorageMediaTypeBreakdown mediaTypeBreakdown;
}

class LocalStorageSnapshot {
  const LocalStorageSnapshot({
    required this.totalBytes,
    required this.categoryBytes,
    required this.conversationUsages,
    required this.generalEntries,
    required this.allEntries,
    required this.mediaTypeBreakdown,
  });

  final int totalBytes;
  final Map<LocalStorageCategory, int> categoryBytes;
  final List<LocalStorageConversationUsage> conversationUsages;
  final List<LocalStorageEntry> generalEntries;
  final List<LocalStorageEntry> allEntries;
  final StorageMediaTypeBreakdown mediaTypeBreakdown;
}

class StorageCacheManager {
  Future<LocalStorageSnapshot> inspect({
    required String userId,
    required List<ConversationWithId> conversations,
    required AppLocalizations l10n,
  }) async {
    final entries = <LocalStorageEntry>[];
    final prefs = await SharedPreferences.getInstance();
    final supportDir = await getApplicationSupportDirectory();

    await _collectE2eeMedia(entries, supportDir);
    await _collectE2eeText(entries, supportDir);
    await _collectFlatDirectory(
      entries: entries,
      prefs: prefs,
      dir: Directory('${supportDir.path}/chat_video_cache'),
      category: LocalStorageCategory.videoDownloads,
      labelPrefix: 'Video cache',
    );
    await _collectFlatDirectory(
      entries: entries,
      prefs: prefs,
      dir: Directory('${supportDir.path}/video_first_frame_cache'),
      category: LocalStorageCategory.videoThumbs,
      labelPrefix: 'Thumb',
    );
    final tempDir = await getTemporaryDirectory();
    await _collectFlatDirectory(
      entries: entries,
      prefs: prefs,
      dir: Directory('${tempDir.path}/chat_image_cache'),
      category: LocalStorageCategory.chatImages,
      labelPrefix: 'Image',
    );
    _collectDraftEntries(entries, prefs, userId, l10n);
    _collectChatListSnapshot(entries, prefs, userId, l10n);
    _collectProfileEntries(entries, prefs, conversations, l10n);

    final categoryBytes = <LocalStorageCategory, int>{
      for (final c in LocalStorageCategory.values) c: 0,
    };
    for (final entry in entries) {
      categoryBytes[entry.category] =
          (categoryBytes[entry.category] ?? 0) + entry.bytes;
    }

    final conversationTitleById = _buildConversationTitleMap(
      currentUserId: userId,
      conversations: conversations,
    );
    final conversationEntries = <String, List<LocalStorageEntry>>{};
    final generalEntries = <LocalStorageEntry>[];
    for (final entry in entries) {
      final cid = entry.conversationId?.trim();
      if (cid == null || cid.isEmpty) {
        if (kAlwaysOnCategories.contains(entry.category)) continue;
        generalEntries.add(entry);
      } else {
        conversationEntries
            .putIfAbsent(cid, () => <LocalStorageEntry>[])
            .add(entry);
      }
    }

    final conversationUsages =
        conversationEntries.entries
            .map((e) {
              final sorted = [...e.value]
                ..sort((a, b) {
                  final am = a.modifiedAt?.millisecondsSinceEpoch ?? 0;
                  final bm = b.modifiedAt?.millisecondsSinceEpoch ?? 0;
                  if (am != bm) return bm.compareTo(am);
                  return b.bytes.compareTo(a.bytes);
                });
              final total = sorted.fold<int>(0, (sum, x) => sum + x.bytes);
              return LocalStorageConversationUsage(
                conversationId: e.key,
                conversationTitle:
                    conversationTitleById[e.key] ??
                    _fallbackConversationTitle(e.key),
                totalBytes: total,
                entries: sorted,
                mediaTypeBreakdown:
                    StorageMediaTypeBreakdown.fromEntries(sorted),
              );
            })
            .where((u) => u.totalBytes > 0)
            .toList(growable: false)
          ..sort((a, b) {
            if (a.totalBytes != b.totalBytes) {
              return b.totalBytes.compareTo(a.totalBytes);
            }
            return a.conversationTitle.toLowerCase().compareTo(
              b.conversationTitle.toLowerCase(),
            );
          });

    generalEntries.sort((a, b) => b.bytes.compareTo(a.bytes));
    final totalBytes = entries.fold<int>(0, (sum, x) => sum + x.bytes);
    return LocalStorageSnapshot(
      totalBytes: totalBytes,
      categoryBytes: categoryBytes,
      conversationUsages: conversationUsages,
      generalEntries: generalEntries,
      allEntries: entries,
      mediaTypeBreakdown: StorageMediaTypeBreakdown.fromEntries(entries),
    );
  }

  Future<void> clearAllForUser(String userId) async {
    for (final category in LocalStorageCategory.values) {
      await clearCategory(userId: userId, category: category);
    }
  }

  Future<void> clearConversation({
    required String userId,
    required String conversationId,
  }) async {
    final supportDir = await getApplicationSupportDirectory();
    final mediaDir = Directory(
      '${supportDir.path}/e2ee_cache/media/${conversationId.trim()}',
    );
    await _safeDeleteDir(mediaDir);

    final textFile = File(
      '${supportDir.path}/e2ee_cache/text/${conversationId.trim()}.json',
    );
    await _safeDeleteFile(textFile);

    final prefs = await SharedPreferences.getInstance();
    final key = chatDraftStorageKey(userId);
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final draftMap = decoded.map((k, v) => MapEntry(k.toString(), v));
      if (!draftMap.containsKey(conversationId)) return;
      draftMap.remove(conversationId);
      await prefs.setString(key, jsonEncode(draftMap));
    } catch (_) {}
  }

  Future<void> clearCategory({
    required String userId,
    required LocalStorageCategory category,
  }) async {
    final supportDir = await getApplicationSupportDirectory();
    final prefs = await SharedPreferences.getInstance();
    switch (category) {
      case LocalStorageCategory.e2eeMedia:
        await _safeDeleteDir(Directory('${supportDir.path}/e2ee_cache/media'));
        break;
      case LocalStorageCategory.e2eeText:
        await _safeDeleteDir(Directory('${supportDir.path}/e2ee_cache/text'));
        break;
      case LocalStorageCategory.chatDrafts:
        await prefs.remove(chatDraftStorageKey(userId));
        break;
      case LocalStorageCategory.chatListSnapshot:
        await prefs.remove(chatListOfflineSnapshotPrefsKey(userId));
        break;
      case LocalStorageCategory.profileCards:
        final keys = prefs
            .getKeys()
            .where((k) => k.startsWith(kUserProfileDiskCacheKeyPrefix))
            .toList(growable: false);
        for (final key in keys) {
          await prefs.remove(key);
        }
        break;
      case LocalStorageCategory.videoDownloads:
        await _safeDeleteDir(Directory('${supportDir.path}/chat_video_cache'));
        break;
      case LocalStorageCategory.videoThumbs:
        await _safeDeleteDir(
          Directory('${supportDir.path}/video_first_frame_cache'),
        );
        break;
      case LocalStorageCategory.chatImages:
        final tempDir = await getTemporaryDirectory();
        await _safeDeleteDir(
          Directory('${tempDir.path}/chat_image_cache'),
        );
        break;
    }
  }

  Future<void> clearEntry(LocalStorageEntry entry) async {
    switch (entry.source) {
      case LocalStorageEntrySource.file:
        final path = entry.filePath;
        if (path == null || path.trim().isEmpty) return;
        await _safeDeleteFile(File(path));
        break;
      case LocalStorageEntrySource.draftItem:
        final key = entry.sharedPrefsKey;
        final sub = entry.sharedPrefsSubKey;
        if (key == null || sub == null) return;
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(key);
        if (raw == null || raw.trim().isEmpty) return;
        try {
          final decoded = jsonDecode(raw);
          if (decoded is! Map) return;
          final map = decoded.map((k, v) => MapEntry(k.toString(), v));
          map.remove(sub);
          await prefs.setString(key, jsonEncode(map));
        } catch (_) {}
        break;
      case LocalStorageEntrySource.chatListSnapshot:
        final key = entry.sharedPrefsKey;
        if (key == null) return;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(key);
        break;
      case LocalStorageEntrySource.profileCard:
        final key = entry.sharedPrefsKey;
        if (key == null) return;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(key);
        break;
    }
  }

  Future<void> applyPreferences({
    required String userId,
    required LocalStoragePreferences preferences,
  }) async {
    for (final category in LocalStorageCategory.values) {
      if (!preferences.enabledFor(category)) {
        await clearCategory(userId: userId, category: category);
      }
    }
  }

  Future<int> trimToBudget({
    required String userId,
    required List<ConversationWithId> conversations,
    required int budgetBytes,
    required AppLocalizations l10n,
  }) async {
    final snapshot = await inspect(
      userId: userId,
      conversations: conversations,
      l10n: l10n,
    );
    if (snapshot.totalBytes <= budgetBytes) return 0;
    final candidates = [...snapshot.allEntries]
      ..sort((a, b) {
        final am = a.modifiedAt?.millisecondsSinceEpoch ?? 0;
        final bm = b.modifiedAt?.millisecondsSinceEpoch ?? 0;
        if (am != bm) return am.compareTo(bm);
        return a.bytes.compareTo(b.bytes);
      });

    var current = snapshot.totalBytes;
    var freed = 0;
    for (final entry in candidates) {
      if (current <= budgetBytes) break;
      await clearEntry(entry);
      current -= entry.bytes;
      freed += entry.bytes;
    }
    return freed;
  }

  Future<int> applyAutoDelete({
    required String userId,
    required List<ConversationWithId> conversations,
    required LocalStoragePreferences preferences,
    required AppLocalizations l10n,
  }) async {
    final now = DateTime.now();
    final snapshot = await inspect(
      userId: userId,
      conversations: conversations,
      l10n: l10n,
    );
    var freed = 0;
    for (final usage in snapshot.conversationUsages) {
      final conv = conversations
          .where((c) => c.id == usage.conversationId)
          .firstOrNull;
      if (conv == null) continue;
      final period = conv.data.isGroup
          ? preferences.autoDeleteGroups
          : preferences.autoDeletePersonal;
      final maxAge = period.toDuration();
      if (maxAge == null) continue;

      final cutoff = now.subtract(maxAge);
      for (final entry in usage.entries) {
        final modified = entry.modifiedAt;
        if (modified == null || modified.isAfter(cutoff)) continue;
        await clearEntry(entry);
        freed += entry.bytes;
      }
    }
    return freed;
  }

  Future<void> _collectE2eeMedia(
    List<LocalStorageEntry> out,
    Directory supportDir,
  ) async {
    final root = Directory('${supportDir.path}/e2ee_cache/media');
    if (!await root.exists()) return;
    final convDirs = await root.list(followLinks: false).toList();
    for (final entity in convDirs) {
      if (entity is! Directory) continue;
      final conversationId = _basename(entity.path).trim();
      final files = await entity
          .list(recursive: true, followLinks: false)
          .toList();
      for (final f in files) {
        if (f is! File) continue;
        final stat = await _safeStat(f);
        final bytes = stat?.size ?? 0;
        if (bytes <= 0) continue;
        out.add(
          LocalStorageEntry(
            id: 'file:${f.path}',
            category: LocalStorageCategory.e2eeMedia,
            source: LocalStorageEntrySource.file,
            bytes: bytes,
            label: _basename(f.path),
            conversationId: conversationId,
            filePath: f.path,
            modifiedAt: stat?.modified,
          ),
        );
      }
    }
  }

  Future<void> _collectE2eeText(
    List<LocalStorageEntry> out,
    Directory supportDir,
  ) async {
    final dir = Directory('${supportDir.path}/e2ee_cache/text');
    if (!await dir.exists()) return;
    final files = await dir.list(followLinks: false).toList();
    for (final entity in files) {
      if (entity is! File) continue;
      if (!entity.path.toLowerCase().endsWith('.json')) continue;
      final stat = await _safeStat(entity);
      final bytes = stat?.size ?? 0;
      if (bytes <= 0) continue;
      final name = _basename(entity.path);
      final conversationId = name.endsWith('.json')
          ? name.substring(0, name.length - 5)
          : name;
      out.add(
        LocalStorageEntry(
          id: 'file:${entity.path}',
          category: LocalStorageCategory.e2eeText,
          source: LocalStorageEntrySource.file,
          bytes: bytes,
          label: name,
          conversationId: conversationId,
          filePath: entity.path,
          modifiedAt: stat?.modified,
        ),
      );
    }
  }

  Future<void> _collectFlatDirectory({
    required List<LocalStorageEntry> entries,
    required SharedPreferences prefs,
    required Directory dir,
    required LocalStorageCategory category,
    required String labelPrefix,
  }) async {
    if (!await dir.exists()) return;
    final files = await dir.list(recursive: true, followLinks: false).toList();
    for (final entity in files) {
      if (entity is! File) continue;
      final stat = await _safeStat(entity);
      final bytes = stat?.size ?? 0;
      if (bytes <= 0) continue;
      final fileName = _basename(entity.path);
      final maybeCtx = switch (category) {
        LocalStorageCategory.videoDownloads =>
          LocalCacheEntryRegistry.readVideoContextSyncForFileName(
            prefs: prefs,
            fileName: fileName,
          ),
        LocalStorageCategory.videoThumbs =>
          LocalCacheEntryRegistry.readVideoThumbContextSyncForFileName(
            prefs: prefs,
            fileName: fileName,
          ),
        LocalStorageCategory.chatImages =>
          LocalCacheEntryRegistry.readImageContextSyncForFileName(
            prefs: prefs,
            fileName: fileName,
          ),
        _ => null,
      };
      final label = (maybeCtx?.attachmentName ?? '').trim().isNotEmpty
          ? '$labelPrefix · ${maybeCtx!.attachmentName!.trim()}'
          : '$labelPrefix · $fileName';
      entries.add(
        LocalStorageEntry(
          id: 'file:${entity.path}',
          category: category,
          source: LocalStorageEntrySource.file,
          bytes: bytes,
          label: label,
          conversationId: maybeCtx?.conversationId,
          filePath: entity.path,
          modifiedAt: stat?.modified,
        ),
      );
    }
  }

  void _collectDraftEntries(
    List<LocalStorageEntry> out,
    SharedPreferences prefs,
    String userId,
    AppLocalizations l10n,
  ) {
    final key = chatDraftStorageKey(userId);
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final map = decoded.map((k, v) => MapEntry(k.toString(), v));
      for (final e in map.entries) {
        final payload = jsonEncode(e.value);
        out.add(
          LocalStorageEntry(
            id: 'draft:${e.key}',
            category: LocalStorageCategory.chatDrafts,
            source: LocalStorageEntrySource.draftItem,
            bytes: utf8.encode(payload).length,
            label: l10n.storage_label_draft(e.key),
            conversationId: e.key,
            sharedPrefsKey: key,
            sharedPrefsSubKey: e.key,
          ),
        );
      }
    } catch (_) {}
  }

  void _collectChatListSnapshot(
    List<LocalStorageEntry> out,
    SharedPreferences prefs,
    String userId,
    AppLocalizations l10n,
  ) {
    final key = chatListOfflineSnapshotPrefsKey(userId);
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return;
    out.add(
      LocalStorageEntry(
        id: 'snapshot:$userId',
        category: LocalStorageCategory.chatListSnapshot,
        source: LocalStorageEntrySource.chatListSnapshot,
        bytes: utf8.encode(raw).length,
        label: l10n.storage_label_offline_snapshot,
        sharedPrefsKey: key,
      ),
    );
  }

  void _collectProfileEntries(
    List<LocalStorageEntry> out,
    SharedPreferences prefs,
    List<ConversationWithId> conversations,
    AppLocalizations l10n,
  ) {
    final namesByUserId = _participantNamesByUserId(conversations);
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (!key.startsWith(kUserProfileDiskCacheKeyPrefix)) continue;
      final raw = prefs.getString(key);
      if (raw == null || raw.trim().isEmpty) continue;
      final userId = key.substring(kUserProfileDiskCacheKeyPrefix.length);
      final displayName = (namesByUserId[userId] ?? userId).trim();
      out.add(
        LocalStorageEntry(
          id: 'profile:$userId',
          category: LocalStorageCategory.profileCards,
          source: LocalStorageEntrySource.profileCard,
          bytes: utf8.encode(raw).length,
          label: l10n.storage_label_profile_cache(displayName),
          sharedPrefsKey: key,
        ),
      );
    }
  }

  Map<String, String> _participantNamesByUserId(
    List<ConversationWithId> conversations,
  ) {
    final out = <String, String>{};
    for (final c in conversations) {
      final p = c.data.participantInfo;
      if (p == null || p.isEmpty) continue;
      for (final e in p.entries) {
        final uid = e.key.trim();
        if (uid.isEmpty) continue;
        final name = e.value.name.trim();
        if (name.isEmpty) continue;
        out.putIfAbsent(uid, () => name);
      }
    }
    return out;
  }

  Map<String, String> _buildConversationTitleMap({
    required String currentUserId,
    required List<ConversationWithId> conversations,
  }) {
    final out = <String, String>{};
    for (final c in conversations) {
      final data = c.data;
      if (isSavedMessagesConversation(data, currentUserId)) {
        out[c.id] = 'Saved messages';
        continue;
      }
      if (data.isGroup) {
        final groupName = (data.name ?? '').trim();
        out[c.id] = groupName.isNotEmpty ? groupName : 'Group chat';
        continue;
      }
      final otherUserId = data.participantIds.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );
      final otherName = (data.participantInfo?[otherUserId]?.name ?? '').trim();
      if (otherName.isNotEmpty) {
        out[c.id] = otherName;
      } else {
        final title = (data.name ?? '').trim();
        out[c.id] = title.isNotEmpty ? title : 'Direct chat';
      }
    }
    return out;
  }

  String _fallbackConversationTitle(String conversationId) {
    if (conversationId.isEmpty) return 'Chat';
    if (conversationId.length <= 16) return 'Chat $conversationId';
    return 'Chat ${conversationId.substring(0, 16)}…';
  }

  String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final idx = normalized.lastIndexOf('/');
    if (idx < 0) return normalized;
    return normalized.substring(idx + 1);
  }

  Future<FileStat?> _safeStat(File file) async {
    try {
      return await file.stat();
    } catch (_) {
      return null;
    }
  }

  Future<void> _safeDeleteFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<void> _safeDeleteDir(Directory dir) async {
    try {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }
}
