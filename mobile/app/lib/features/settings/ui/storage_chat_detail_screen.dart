import 'dart:io';

import 'package:flutter/material.dart';

import '../../auth/ui/auth_glass.dart';
import '../../chat/ui/profile_subpage_header.dart';
import '../data/storage_cache_manager.dart';
import '../../../l10n/app_localizations.dart';
import 'storage_donut_chart.dart';

const double _kMutedTextSize = 13;

enum _MediaTab { photos, videos, audios, files }

class StorageChatDetailScreen extends StatefulWidget {
  const StorageChatDetailScreen({
    super.key,
    required this.usage,
    required this.totalAppCacheBytes,
    required this.onDeleteEntries,
    required this.formatBytes,
  });

  final LocalStorageConversationUsage usage;
  final int totalAppCacheBytes;
  final Future<void> Function(List<LocalStorageEntry> entries) onDeleteEntries;
  final String Function(int) formatBytes;

  @override
  State<StorageChatDetailScreen> createState() =>
      _StorageChatDetailScreenState();
}

class _StorageChatDetailScreenState extends State<StorageChatDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<LocalStorageEntry> _allEntries;
  late List<LocalStorageEntry> _photoEntries;
  late List<LocalStorageEntry> _videoEntries;
  late List<LocalStorageEntry> _audioEntries;
  late List<LocalStorageEntry> _fileEntries;

  /// Selected entry IDs across all tabs.
  late Set<String> _selectedIds;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _allEntries = [...widget.usage.entries];
    _rebuildBuckets();
    _selectedIds = _allTrackedIds().toSet();
  }

  Iterable<String> _allTrackedIds() => [
    ..._photoEntries.map((e) => e.id),
    ..._videoEntries.map((e) => e.id),
    ..._audioEntries.map((e) => e.id),
    ..._fileEntries.map((e) => e.id),
  ];

  void _rebuildBuckets() {
    _photoEntries = [];
    _videoEntries = [];
    _audioEntries = [];
    _fileEntries = [];
    for (final e in _allEntries) {
      if (e.source != LocalStorageEntrySource.file) continue;
      if (e.filePath == null) continue;
      switch (classifyEntryMediaType(e)) {
        case StorageMediaType.photo:
          _photoEntries.add(e);
        case StorageMediaType.video:
          _videoEntries.add(e);
        case StorageMediaType.audio:
          _audioEntries.add(e);
        case StorageMediaType.file:
          _fileEntries.add(e);
        case StorageMediaType.other:
          // Skip thumbs / drafts / snapshots.
          break;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<LocalStorageEntry> _activeBucket(_MediaTab tab) => switch (tab) {
    _MediaTab.photos => _photoEntries,
    _MediaTab.videos => _videoEntries,
    _MediaTab.audios => _audioEntries,
    _MediaTab.files => _fileEntries,
  };

  int get _selectedBytes {
    final tracked = {..._allTrackedIds()};
    return _allEntries
        .where((e) => tracked.contains(e.id) && _selectedIds.contains(e.id))
        .fold<int>(0, (sum, e) => sum + e.bytes);
  }

  int get _trackedTotal =>
      _photoEntries.length +
      _videoEntries.length +
      _audioEntries.length +
      _fileEntries.length;

  List<DonutSegment> _buildSegments(AppLocalizations l10n) {
    final bd = widget.usage.mediaTypeBreakdown;
    final segments = <DonutSegment>[];
    if (bd.videoBytes > 0) {
      segments.add(DonutSegment(
        value: bd.videoBytes.toDouble(),
        color: kStorageVideoColor,
        label: l10n.storage_label_video,
      ));
    }
    if (bd.photoBytes > 0) {
      segments.add(DonutSegment(
        value: bd.photoBytes.toDouble(),
        color: kStoragePhotoColor,
        label: l10n.storage_label_photo,
      ));
    }
    if (bd.audioBytes > 0) {
      segments.add(DonutSegment(
        value: bd.audioBytes.toDouble(),
        color: kStorageAudioColor,
        label: l10n.storage_label_audio,
      ));
    }
    if (bd.fileBytes > 0) {
      segments.add(DonutSegment(
        value: bd.fileBytes.toDouble(),
        color: kStorageFileColor,
        label: l10n.storage_label_files,
      ));
    }
    if (bd.otherBytes > 0) {
      segments.add(DonutSegment(
        value: bd.otherBytes.toDouble(),
        color: kStorageOtherColor,
        label: l10n.storage_label_other,
      ));
    }
    return segments;
  }

  String _pct(int part, int total) {
    if (total <= 0) return '0%';
    final p = part / total * 100;
    if (p >= 10) return '${p.toStringAsFixed(0)}%';
    if (p >= 0.1) return '${p.toStringAsFixed(1)}%';
    return '<0.1%';
  }

  void _toggleAllInActiveTab() {
    final bucket = _activeBucket(_MediaTab.values[_tabController.index]);
    setState(() {
      final allSelected = bucket.every((e) => _selectedIds.contains(e.id));
      if (allSelected) {
        for (final e in bucket) {
          _selectedIds.remove(e.id);
        }
      } else {
        for (final e in bucket) {
          _selectedIds.add(e.id);
        }
      }
    });
  }

  bool _allSelectedInActiveTab() {
    final bucket = _activeBucket(_MediaTab.values[_tabController.index]);
    if (bucket.isEmpty) return false;
    return bucket.every((e) => _selectedIds.contains(e.id));
  }

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_busy || _selectedIds.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final tracked = {..._allTrackedIds()};
    final toDelete = _allEntries
        .where((e) => tracked.contains(e.id) && _selectedIds.contains(e.id))
        .toList();
    if (toDelete.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.storage_chat_detail_delete_title),
        content: Text(l10n.storage_chat_detail_delete_body(
          toDelete.length,
          widget.formatBytes(_selectedBytes),
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.onDeleteEntries(toDelete);
      if (!mounted) return;
      setState(() {
        for (final entry in toDelete) {
          _allEntries.removeWhere((e) => e.id == entry.id);
          _selectedIds.remove(entry.id);
        }
        _rebuildBuckets();
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _isImageEntry(LocalStorageEntry entry) {
    return classifyEntryMediaType(entry) == StorageMediaType.photo;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final bd = widget.usage.mediaTypeBreakdown;
    final chatPct = widget.totalAppCacheBytes > 0
        ? (widget.usage.totalBytes / widget.totalAppCacheBytes * 100)
            .toStringAsFixed(1)
        : '0';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuthBackground(
        child: SafeArea(
          child: Column(
            children: [
              ChatProfileSubpageHeader(title: widget.usage.conversationTitle),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: StorageDonutChart(
                        segments: _buildSegments(l10n),
                        centerText:
                            widget.formatBytes(widget.usage.totalBytes),
                        size: 180,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        l10n.storage_chat_detail_share(chatPct),
                        style: TextStyle(
                          fontSize: _kMutedTextSize,
                          color: dark
                              ? Colors.white.withValues(alpha: 0.60)
                              : scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _UsageBar(
                      fraction: widget.totalAppCacheBytes > 0
                          ? widget.usage.totalBytes /
                              widget.totalAppCacheBytes
                          : 0,
                    ),
                    const SizedBox(height: 16),
                    _GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Column(
                          children: [
                            if (bd.videoBytes > 0)
                              StorageCategoryRow(
                                color: kStorageVideoColor,
                                label: l10n.storage_media_type_video,
                                sizeText: widget.formatBytes(bd.videoBytes),
                                percent: _pct(bd.videoBytes, bd.totalBytes),
                              ),
                            if (bd.photoBytes > 0)
                              StorageCategoryRow(
                                color: kStoragePhotoColor,
                                label: l10n.storage_media_type_photo,
                                sizeText: widget.formatBytes(bd.photoBytes),
                                percent: _pct(bd.photoBytes, bd.totalBytes),
                              ),
                            if (bd.audioBytes > 0)
                              StorageCategoryRow(
                                color: kStorageAudioColor,
                                label: l10n.storage_media_type_audio,
                                sizeText: widget.formatBytes(bd.audioBytes),
                                percent: _pct(bd.audioBytes, bd.totalBytes),
                              ),
                            if (bd.fileBytes > 0)
                              StorageCategoryRow(
                                color: kStorageFileColor,
                                label: l10n.storage_media_type_files,
                                sizeText: widget.formatBytes(bd.fileBytes),
                                percent: _pct(bd.fileBytes, bd.totalBytes),
                              ),
                            if (bd.otherBytes > 0)
                              StorageCategoryRow(
                                color: kStorageOtherColor,
                                label: l10n.storage_media_type_other,
                                sizeText: widget.formatBytes(bd.otherBytes),
                                percent: _pct(bd.otherBytes, bd.totalBytes),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_trackedTotal > 0) ...[
                      const SizedBox(height: 16),
                      _MediaTabBar(
                        controller: _tabController,
                        photos: _photoEntries.length,
                        videos: _videoEntries.length,
                        audios: _audioEntries.length,
                        files: _fileEntries.length,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _toggleAllInActiveTab,
                            child: Text(
                              _allSelectedInActiveTab()
                                  ? l10n.storage_chat_detail_deselect_all
                                  : l10n.storage_chat_detail_select_all,
                            ),
                          ),
                        ],
                      ),
                      AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, _) {
                          final tab = _MediaTab.values[_tabController.index];
                          final bucket = _activeBucket(tab);
                          if (bucket.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  l10n.storage_chat_detail_tab_empty,
                                  style: TextStyle(
                                    fontSize: _kMutedTextSize,
                                    color: dark
                                        ? Colors.white.withValues(alpha: 0.55)
                                        : scheme.onSurface
                                            .withValues(alpha: 0.50),
                                  ),
                                ),
                              ),
                            );
                          }
                          if (tab == _MediaTab.files ||
                              tab == _MediaTab.audios) {
                            return _FilesList(
                              entries: bucket,
                              selectedIds: _selectedIds,
                              onToggle: _toggle,
                              formatBytes: widget.formatBytes,
                            );
                          }
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: bucket.length,
                            itemBuilder: (context, i) {
                              final entry = bucket[i];
                              final selected = _selectedIds.contains(entry.id);
                              return _MediaGridItem(
                                entry: entry,
                                selected: selected,
                                isImage: _isImageEntry(entry),
                                formatBytes: widget.formatBytes,
                                onToggle: () => _toggle(entry.id),
                              );
                            },
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              if (_trackedTotal > 0)
                _BottomDeleteBar(
                  busy: _busy,
                  selectedCount:
                      _selectedIds.where(_allTrackedIds().contains).length,
                  selectedBytes: _selectedBytes,
                  formatBytes: widget.formatBytes,
                  onDelete: _deleteSelected,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaTabBar extends StatelessWidget {
  const _MediaTabBar({
    required this.controller,
    required this.photos,
    required this.videos,
    required this.audios,
    required this.files,
  });

  final TabController controller;
  final int photos;
  final int videos;
  final int audios;
  final int files;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return TabBar(
      controller: controller,
      isScrollable: true,
      indicatorColor: const Color(0xFF2F86FF),
      indicatorWeight: 3,
      labelColor: dark ? Colors.white : scheme.onSurface,
      unselectedLabelColor: dark
          ? Colors.white.withValues(alpha: 0.50)
          : scheme.onSurface.withValues(alpha: 0.45),
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      unselectedLabelStyle:
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      tabs: [
        Tab(text: '${l10n.storage_media_type_photo} · $photos'),
        Tab(text: '${l10n.storage_media_type_video} · $videos'),
        Tab(text: '${l10n.storage_media_type_audio} · $audios'),
        Tab(text: '${l10n.storage_media_type_files} · $files'),
      ],
    );
  }
}

class _FilesList extends StatelessWidget {
  const _FilesList({
    required this.entries,
    required this.selectedIds,
    required this.onToggle,
    required this.formatBytes,
  });

  final List<LocalStorageEntry> entries;
  final Set<String> selectedIds;
  final void Function(String id) onToggle;
  final String Function(int) formatBytes;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Column(
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onToggle(entry.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: kStorageFileColor.withValues(alpha: 0.18),
                      ),
                      child: Icon(
                        Icons.insert_drive_file_rounded,
                        color: kStorageFileColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.92)
                                  : scheme.onSurface.withValues(alpha: 0.90),
                            ),
                          ),
                          Text(
                            formatBytes(entry.bytes),
                            style: TextStyle(
                              fontSize: 12,
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.55)
                                  : scheme.onSurface.withValues(alpha: 0.50),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Checkbox(
                      value: selectedIds.contains(entry.id),
                      onChanged: (_) => onToggle(entry.id),
                      shape: const CircleBorder(),
                      activeColor: const Color(0xFF2F86FF),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MediaGridItem extends StatelessWidget {
  const _MediaGridItem({
    required this.entry,
    required this.selected,
    required this.isImage,
    required this.formatBytes,
    required this.onToggle,
  });

  final LocalStorageEntry entry;
  final bool selected;
  final bool isImage;
  final String Function(int) formatBytes;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;

    Widget thumbnail;
    final path = entry.filePath;
    if (path != null && isImage) {
      thumbnail = Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, e, st) => _placeholder(dark),
      );
    } else {
      final isVideo = classifyEntryMediaType(entry) == StorageMediaType.video;
      thumbnail = Container(
        color: dark ? const Color(0xFF1A2A3A) : const Color(0xFFE0E0E0),
        child: Center(
          child: Icon(
            isVideo ? Icons.videocam_rounded : Icons.insert_drive_file_rounded,
            size: 32,
            color: dark
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.3),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onToggle,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            thumbnail,
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? const Color(0xFF2F86FF)
                      : Colors.black.withValues(alpha: 0.3),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.black.withValues(alpha: 0.55),
                ),
                child: Text(
                  formatBytes(entry.bytes),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(bool dark) {
    return Container(
      color: dark ? const Color(0xFF1A2A3A) : const Color(0xFFE0E0E0),
      child: Center(
        child: Icon(
          Icons.broken_image_rounded,
          size: 28,
          color: dark
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

class _BottomDeleteBar extends StatelessWidget {
  const _BottomDeleteBar({
    required this.busy,
    required this.selectedCount,
    required this.selectedBytes,
    required this.formatBytes,
    required this.onDelete,
  });

  final bool busy;
  final int selectedCount;
  final int selectedBytes;
  final String Function(int) formatBytes;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: (dark ? const Color(0xFF08111B) : Colors.white)
            .withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(
            color: (dark ? Colors.white : Colors.black)
                .withValues(alpha: dark ? 0.08 : 0.06),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: busy || selectedCount == 0 ? null : onDelete,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2F86FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.delete_sweep_rounded),
            label: Text(
              selectedCount > 0
                  ? l10n.storage_chat_detail_clear_button(
                      formatBytes(selectedBytes))
                  : l10n.storage_chat_detail_clear_button_empty,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  const _UsageBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: fraction.clamp(0.0, 1.0),
          minHeight: 6,
          backgroundColor: dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          valueColor: const AlwaysStoppedAnimation(Color(0xFF2F86FF)),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: (dark ? const Color(0xFF08111B) : Colors.white).withValues(
          alpha: dark ? 0.86 : 0.84,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: dark ? 0.12 : 0.44),
        ),
      ),
      child: child,
    );
  }
}
