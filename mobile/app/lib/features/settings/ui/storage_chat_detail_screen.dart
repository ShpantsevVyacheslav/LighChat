import 'dart:io';

import 'package:flutter/material.dart';

import '../../auth/ui/auth_glass.dart';
import '../../chat/ui/profile_subpage_header.dart';
import '../data/storage_cache_manager.dart';
import '../../../l10n/app_localizations.dart';
import 'storage_donut_chart.dart';

const double _kMutedTextSize = 13;

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

class _StorageChatDetailScreenState extends State<StorageChatDetailScreen> {
  late final List<LocalStorageEntry> _allEntries = [...widget.usage.entries];
  late final List<LocalStorageEntry> _mediaEntries = _allEntries
      .where((e) => e.source == LocalStorageEntrySource.file && e.filePath != null)
      .toList();
  late final Set<String> _selectedIds = {..._mediaEntries.map((e) => e.id)};
  bool _busy = false;

  int get _selectedBytes => _mediaEntries
      .where((e) => _selectedIds.contains(e.id))
      .fold<int>(0, (sum, e) => sum + e.bytes);

  List<DonutSegment> _buildSegments() {
    final bd = widget.usage.mediaTypeBreakdown;
    final segments = <DonutSegment>[];
    if (bd.videoBytes > 0) {
      segments.add(DonutSegment(
        value: bd.videoBytes.toDouble(),
        color: kStorageVideoColor,
        label: 'Video',
      ));
    }
    if (bd.photoBytes > 0) {
      segments.add(DonutSegment(
        value: bd.photoBytes.toDouble(),
        color: kStoragePhotoColor,
        label: 'Photo',
      ));
    }
    if (bd.fileBytes > 0) {
      segments.add(DonutSegment(
        value: bd.fileBytes.toDouble(),
        color: kStorageFileColor,
        label: 'Files',
      ));
    }
    if (bd.otherBytes > 0) {
      segments.add(DonutSegment(
        value: bd.otherBytes.toDouble(),
        color: kStorageOtherColor,
        label: 'Other',
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

  void _toggleAll() {
    setState(() {
      if (_selectedIds.length == _mediaEntries.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(_mediaEntries.map((e) => e.id));
      }
    });
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
    final toDelete = _mediaEntries
        .where((e) => _selectedIds.contains(e.id))
        .toList();
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
          _mediaEntries.removeWhere((e) => e.id == entry.id);
          _selectedIds.remove(entry.id);
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _isImageEntry(LocalStorageEntry entry) {
    final path = (entry.filePath ?? entry.label).toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp') ||
        path.endsWith('.heic') ||
        path.endsWith('.gif');
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
                        segments: _buildSegments(),
                        centerText: widget.formatBytes(
                          widget.usage.totalBytes,
                        ),
                        size: 180,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        l10n.storage_chat_detail_share(
                          chatPct,
                        ),
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
                          ? widget.usage.totalBytes / widget.totalAppCacheBytes
                          : 0,
                    ),
                    const SizedBox(height: 16),
                    _GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
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
                    if (_mediaEntries.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            l10n.storage_chat_detail_media_tab,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.92)
                                  : scheme.onSurface.withValues(alpha: 0.90),
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _toggleAll,
                            child: Text(
                              _selectedIds.length == _mediaEntries.length
                                  ? l10n.storage_chat_detail_deselect_all
                                  : l10n.storage_chat_detail_select_all,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _mediaEntries.length,
                        itemBuilder: (context, i) {
                          final entry = _mediaEntries[i];
                          final selected = _selectedIds.contains(entry.id);
                          return _MediaGridItem(
                            entry: entry,
                            selected: selected,
                            isImage: _isImageEntry(entry),
                            formatBytes: widget.formatBytes,
                            onToggle: () => _toggle(entry.id),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              if (_mediaEntries.isNotEmpty)
                _BottomDeleteBar(
                  busy: _busy,
                  selectedCount: _selectedIds.length,
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
