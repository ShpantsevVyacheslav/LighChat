import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'package:lighchat_mobile/app_providers.dart';
import '../../auth/ui/auth_glass.dart';
import '../../chat/data/local_storage_preferences.dart';
import '../data/storage_cache_manager.dart';
import '../../../l10n/app_localizations.dart';
import 'storage_chat_detail_screen.dart';
import 'storage_donut_chart.dart';

const double _kHeaderTitleSize = 16;
const double _kCardTitleSize = 18;
const double _kBodyTextSize = 14;
const double _kMutedTextSize = 13;

class StorageSettingsScreen extends ConsumerStatefulWidget {
  const StorageSettingsScreen({super.key});

  @override
  ConsumerState<StorageSettingsScreen> createState() =>
      _StorageSettingsScreenState();
}

class _StorageSettingsScreenState extends ConsumerState<StorageSettingsScreen> {
  final _manager = StorageCacheManager();

  LocalStorageSnapshot? _snapshot;
  LocalStoragePreferences _preferences = LocalStoragePreferences.defaults();
  String? _error;
  bool _loading = true;
  bool _busy = false;
  String? _lastLoadFingerprint;

  @override
  void initState() {
    super.initState();
    LocalStoragePreferencesStore.load().then((value) {
      if (!mounted) return;
      setState(() => _preferences = value);
    });
  }

  Future<void> _reload({
    required String uid,
    required List<ConversationWithId> conversations,
  }) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await LocalStoragePreferencesStore.load();
      final snapshot = await _manager.inspect(
        userId: uid,
        conversations: conversations,
      );
      if (!mounted) return;
      setState(() {
        _preferences = prefs;
        _snapshot = snapshot;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _scheduleReloadIfNeeded({
    required String uid,
    required List<ConversationWithId> conversations,
  }) {
    final ids = conversations.map((c) => c.id).toList(growable: false)..sort();
    final fingerprint = '$uid::${ids.join("|")}';
    if (_lastLoadFingerprint == fingerprint && _snapshot != null) return;
    _lastLoadFingerprint = fingerprint;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reload(uid: uid, conversations: conversations);
    });
  }

  Future<void> _withBusy(Future<void> Function() run) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await run();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = <String>['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var idx = 0;
    while (value >= 1024 && idx < units.length - 1) {
      value /= 1024;
      idx++;
    }
    final digits = value >= 100
        ? 0
        : value >= 10
            ? 1
            : 2;
    return '${value.toStringAsFixed(digits)} ${units[idx]}';
  }

  String _pct(int part, int total) {
    if (total <= 0) return '0%';
    final p = part / total * 100;
    if (p >= 10) return '${p.toStringAsFixed(0)}%';
    if (p >= 0.1) return '${p.toStringAsFixed(1)}%';
    return '<0.1%';
  }

  String _categorySubtitle(
    LocalStorageCategory category,
    AppLocalizations l10n,
  ) {
    switch (category) {
      case LocalStorageCategory.e2eeMedia:
        return l10n.storage_category_e2ee_media_subtitle;
      case LocalStorageCategory.e2eeText:
        return l10n.storage_category_e2ee_text_subtitle;
      case LocalStorageCategory.chatDrafts:
        return l10n.storage_category_drafts_subtitle;
      case LocalStorageCategory.chatListSnapshot:
        return l10n.storage_category_chat_list_snapshot_subtitle;
      case LocalStorageCategory.profileCards:
        return l10n.storage_category_profile_cards_subtitle;
      case LocalStorageCategory.videoDownloads:
        return l10n.storage_category_video_downloads_subtitle;
      case LocalStorageCategory.videoThumbs:
        return l10n.storage_category_video_thumbs_subtitle;
      case LocalStorageCategory.chatImages:
        return l10n.storage_category_chat_images_subtitle;
    }
  }

  String _categoryTitle(LocalStorageCategory category, AppLocalizations l10n) {
    switch (category) {
      case LocalStorageCategory.e2eeMedia:
        return l10n.storage_category_e2ee_media;
      case LocalStorageCategory.e2eeText:
        return l10n.storage_category_e2ee_text;
      case LocalStorageCategory.chatDrafts:
        return l10n.storage_category_drafts;
      case LocalStorageCategory.chatListSnapshot:
        return l10n.storage_category_chat_list_snapshot;
      case LocalStorageCategory.profileCards:
        return l10n.storage_category_profile_cards;
      case LocalStorageCategory.videoDownloads:
        return l10n.storage_category_video_downloads;
      case LocalStorageCategory.videoThumbs:
        return l10n.storage_category_video_thumbs;
      case LocalStorageCategory.chatImages:
        return l10n.storage_category_chat_images;
    }
  }

  List<DonutSegment> _buildSegments(StorageMediaTypeBreakdown bd) {
    final segments = <DonutSegment>[];
    if (bd.videoBytes > 0) {
      segments.add(DonutSegment(
          value: bd.videoBytes.toDouble(),
          color: kStorageVideoColor,
          label: 'Video'));
    }
    if (bd.photoBytes > 0) {
      segments.add(DonutSegment(
          value: bd.photoBytes.toDouble(),
          color: kStoragePhotoColor,
          label: 'Photo'));
    }
    if (bd.fileBytes > 0) {
      segments.add(DonutSegment(
          value: bd.fileBytes.toDouble(),
          color: kStorageFileColor,
          label: 'Files'));
    }
    if (bd.otherBytes > 0) {
      segments.add(DonutSegment(
          value: bd.otherBytes.toDouble(),
          color: kStorageOtherColor,
          label: 'Other'));
    }
    return segments;
  }

  Future<void> _toggleCategory({
    required String uid,
    required List<ConversationWithId> conversations,
    required LocalStorageCategory category,
    required bool enabled,
  }) async {
    final updated = _preferences.copyWith(
      e2eeMediaEnabled:
          category == LocalStorageCategory.e2eeMedia ? enabled : null,
      videoDownloadsEnabled:
          category == LocalStorageCategory.videoDownloads ? enabled : null,
      chatImagesEnabled:
          category == LocalStorageCategory.chatImages ? enabled : null,
    );
    await _withBusy(() async {
      await LocalStoragePreferencesStore.save(updated);
      await _manager.applyPreferences(userId: uid, preferences: updated);
      if (!mounted) return;
      setState(() => _preferences = updated);
      await _reload(uid: uid, conversations: conversations);
    });
  }

  Future<void> _updateBudget({
    required String uid,
    required List<ConversationWithId> conversations,
    required int budgetGb,
  }) async {
    if (_preferences.cacheBudgetGb == budgetGb) return;
    final updated = _preferences.copyWith(cacheBudgetGb: budgetGb);
    setState(() => _preferences = updated);
    await LocalStoragePreferencesStore.save(updated);
  }

  Future<void> _updateAutoDelete({
    required String uid,
    required List<ConversationWithId> conversations,
    AutoDeletePeriod? personal,
    AutoDeletePeriod? groups,
  }) async {
    final updated = _preferences.copyWith(
      autoDeletePersonal: personal,
      autoDeleteGroups: groups,
    );
    setState(() => _preferences = updated);
    await LocalStoragePreferencesStore.save(updated);
    if (mounted) {
      await _manager.applyAutoDelete(
        userId: uid,
        conversations: conversations,
        preferences: updated,
      );
    }
  }

  Future<void> _confirmAndClearAll({
    required String uid,
    required List<ConversationWithId> conversations,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.storage_settings_clear_all_title),
        content: Text(l10n.storage_settings_clear_all_body),
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
    if (ok != true) return;
    await _withBusy(() async {
      await _manager.clearAllForUser(uid);
      await _reload(uid: uid, conversations: conversations);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.storage_settings_snackbar_cleared)),
      );
    });
  }

  Future<void> _trimToBudget({
    required String uid,
    required List<ConversationWithId> conversations,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    await _withBusy(() async {
      final freed = await _manager.trimToBudget(
        userId: uid,
        conversations: conversations,
        budgetBytes: _preferences.cacheBudgetGb * 1024 * 1024 * 1024,
      );
      await _reload(uid: uid, conversations: conversations);
      if (!mounted) return;
      final text = freed <= 0
          ? l10n.storage_settings_snackbar_budget_already_ok
          : l10n.storage_settings_snackbar_budget_trimmed(_formatBytes(freed));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(text)));
    });
  }

  Future<void> _openChatDetail({
    required String uid,
    required List<ConversationWithId> conversations,
    required LocalStorageConversationUsage usage,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StorageChatDetailScreen(
          usage: usage,
          totalAppCacheBytes: _snapshot?.totalBytes ?? 0,
          formatBytes: _formatBytes,
          onDeleteEntries: (entries) async {
            for (final entry in entries) {
              await _manager.clearEntry(entry);
            }
            await _reload(uid: uid, conversations: conversations);
          },
        ),
      ),
    );
    if (mounted) {
      _lastLoadFingerprint = null;
      _scheduleReloadIfNeeded(uid: uid, conversations: conversations);
    }
  }

  String _autoDeleteLabel(AutoDeletePeriod period, AppLocalizations l10n) {
    return switch (period) {
      AutoDeletePeriod.never => l10n.storage_auto_delete_never,
      AutoDeletePeriod.threeDays => l10n.storage_auto_delete_3_days,
      AutoDeletePeriod.oneWeek => l10n.storage_auto_delete_1_week,
      AutoDeletePeriod.oneMonth => l10n.storage_auto_delete_1_month,
      AutoDeletePeriod.threeMonths => l10n.storage_auto_delete_3_months,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authAsync = ref.watch(authUserProvider);
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: authAsync.when(
            data: (user) {
              if (user == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildForUser(context, user, l10n);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorState(message: e.toString(), onRetry: null),
          ),
        ),
      ),
    );
  }

  Widget _buildForUser(BuildContext context, User user, AppLocalizations l10n) {
    final indexAsync = ref.watch(userChatIndexProvider(user.uid));
    return indexAsync.when(
      data: (idx) {
        final ids = (idx?.conversationIds ?? const <String>[])
            .where((id) => id.trim().isNotEmpty)
            .toList(growable: false);
        final convAsync = ref.watch(
          conversationsProvider((key: conversationIdsCacheKey(ids))),
        );
        return convAsync.when(
          data: (conversations) {
            _scheduleReloadIfNeeded(
              uid: user.uid,
              conversations: conversations,
            );
            final snapshot = _snapshot;
            if (_loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_error != null) {
              return _ErrorState(
                message: _error!,
                onRetry: () =>
                    _reload(uid: user.uid, conversations: conversations),
              );
            }
            if (snapshot == null) {
              return _ErrorState(
                message: l10n.storage_settings_error_empty,
                onRetry: () =>
                    _reload(uid: user.uid, conversations: conversations),
              );
            }

            final scheme = Theme.of(context).colorScheme;
            final dark = scheme.brightness == Brightness.dark;
            final bd = snapshot.mediaTypeBreakdown;
            final budgetBytes =
                _preferences.cacheBudgetGb * 1024 * 1024 * 1024;
            final usageFraction =
                budgetBytes > 0 ? snapshot.totalBytes / budgetBytes : 0.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Material(
                        color: (dark ? Colors.white : scheme.surface)
                            .withValues(alpha: dark ? 0.08 : 0.74),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/account');
                            }
                          },
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(
                              Icons.chevron_left_rounded,
                              size: 30,
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.95)
                                  : scheme.onSurface.withValues(alpha: 0.94),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.storage_settings_title,
                        style: TextStyle(
                          fontSize: _kHeaderTitleSize,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          color: dark
                              ? Colors.white.withValues(alpha: 0.95)
                              : scheme.onSurface.withValues(alpha: 0.94),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () =>
                        _reload(uid: user.uid, conversations: conversations),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
                      children: [
                        // ── Donut chart ──
                        Center(
                          child: StorageDonutChart(
                            segments: _buildSegments(bd),
                            centerText: _formatBytes(snapshot.totalBytes),
                            centerSubtext: l10n.storage_settings_total_label,
                            size: 210,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            l10n.storage_settings_device_usage(
                              (usageFraction * 100).clamp(0, 100).toStringAsFixed(0),
                            ),
                            style: TextStyle(
                              fontSize: _kMutedTextSize,
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.60)
                                  : scheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: usageFraction.clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: dark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.06),
                              valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFF2F86FF)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Category breakdown ──
                        _SettingsCard(
                          children: [
                            if (bd.videoBytes > 0)
                              StorageCategoryRow(
                                color: kStorageVideoColor,
                                label: l10n.storage_media_type_video,
                                sizeText: _formatBytes(bd.videoBytes),
                                percent: _pct(bd.videoBytes, bd.totalBytes),
                              ),
                            if (bd.photoBytes > 0)
                              StorageCategoryRow(
                                color: kStoragePhotoColor,
                                label: l10n.storage_media_type_photo,
                                sizeText: _formatBytes(bd.photoBytes),
                                percent: _pct(bd.photoBytes, bd.totalBytes),
                              ),
                            if (bd.fileBytes > 0)
                              StorageCategoryRow(
                                color: kStorageFileColor,
                                label: l10n.storage_media_type_files,
                                sizeText: _formatBytes(bd.fileBytes),
                                percent: _pct(bd.fileBytes, bd.totalBytes),
                              ),
                            if (bd.otherBytes > 0)
                              StorageCategoryRow(
                                color: kStorageOtherColor,
                                label: l10n.storage_media_type_other,
                                sizeText: _formatBytes(bd.otherBytes),
                                percent: _pct(bd.otherBytes, bd.totalBytes),
                              ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () => _confirmAndClearAll(
                                          uid: user.uid,
                                          conversations: conversations,
                                        ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF2F86FF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                ),
                                icon: const Icon(Icons.delete_sweep_rounded),
                                label: Text(
                                  '${l10n.storage_settings_clear_all_button} ${_formatBytes(snapshot.totalBytes)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: Text(
                                l10n.storage_settings_clear_all_hint,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: dark
                                      ? Colors.white.withValues(alpha: 0.45)
                                      : scheme.onSurface
                                          .withValues(alpha: 0.40),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ── Auto-delete section ──
                        _SettingsCard(
                          title: l10n.storage_auto_delete_title,
                          leadingIcon: Icons.timer_outlined,
                          children: [
                            _DropdownRow<AutoDeletePeriod>(
                              icon: Icons.person_rounded,
                              title: l10n.storage_auto_delete_personal,
                              value: _preferences.autoDeletePersonal,
                              items: AutoDeletePeriod.values,
                              labelBuilder: (p) =>
                                  _autoDeleteLabel(p, l10n),
                              onChanged: _busy
                                  ? null
                                  : (v) => _updateAutoDelete(
                                        uid: user.uid,
                                        conversations: conversations,
                                        personal: v,
                                      ),
                            ),
                            _DropdownRow<AutoDeletePeriod>(
                              icon: Icons.group_rounded,
                              title: l10n.storage_auto_delete_groups,
                              value: _preferences.autoDeleteGroups,
                              items: AutoDeletePeriod.values,
                              labelBuilder: (p) =>
                                  _autoDeleteLabel(p, l10n),
                              onChanged: _busy
                                  ? null
                                  : (v) => _updateAutoDelete(
                                        uid: user.uid,
                                        conversations: conversations,
                                        groups: v,
                                      ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.storage_auto_delete_hint,
                              style: TextStyle(
                                fontSize: 12,
                                color: dark
                                    ? Colors.white.withValues(alpha: 0.50)
                                    : scheme.onSurface
                                        .withValues(alpha: 0.45),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ── Cache budget ──
                        _SettingsCard(
                          title: l10n.storage_settings_policy_title,
                          leadingIcon: Icons.tune_rounded,
                          children: [
                            for (final category in kUserToggleableCategories)
                              _SwitchRow(
                                title: _categoryTitle(category, l10n),
                                subtitle:
                                    _categorySubtitle(category, l10n),
                                value: _preferences.enabledFor(category),
                                onChanged: _busy
                                    ? null
                                    : (value) => _toggleCategory(
                                          uid: user.uid,
                                          conversations: conversations,
                                          category: category,
                                          enabled: value,
                                        ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.storage_settings_budget_slider_title,
                              style: TextStyle(
                                fontSize: _kBodyTextSize,
                                fontWeight: FontWeight.w700,
                                color: dark
                                    ? Colors.white.withValues(alpha: 0.94)
                                    : scheme.onSurface
                                        .withValues(alpha: 0.92),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: _preferences.cacheBudgetGb
                                        .toDouble(),
                                    min: LocalStoragePreferences
                                        .minCacheBudgetGb
                                        .toDouble(),
                                    max: LocalStoragePreferences
                                        .maxCacheBudgetGb
                                        .toDouble(),
                                    divisions: LocalStoragePreferences
                                            .maxCacheBudgetGb -
                                        LocalStoragePreferences
                                            .minCacheBudgetGb,
                                    label:
                                        '${_preferences.cacheBudgetGb} ${l10n.storage_unit_gb}',
                                    onChanged: _busy
                                        ? null
                                        : (value) => _updateBudget(
                                              uid: user.uid,
                                              conversations: conversations,
                                              budgetGb: value.round(),
                                            ),
                                  ),
                                ),
                                SizedBox(
                                  width: 56,
                                  child: Text(
                                    '${_preferences.cacheBudgetGb} ${l10n.storage_unit_gb}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: dark
                                          ? Colors.white
                                              .withValues(alpha: 0.80)
                                          : scheme.onSurface
                                              .withValues(alpha: 0.75),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            OutlinedButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () => _trimToBudget(
                                        uid: user.uid,
                                        conversations: conversations,
                                      ),
                              icon: const Icon(
                                  Icons.cleaning_services_rounded),
                              label:
                                  Text(l10n.storage_settings_trim_button),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ── By chats ──
                        _SettingsCard(
                          title: l10n.storage_settings_chats_title,
                          leadingIcon: Icons.forum_outlined,
                          children: [
                            if (snapshot.conversationUsages.isEmpty)
                              _MutedText(l10n.storage_settings_chats_empty)
                            else
                              for (final usage
                                  in snapshot.conversationUsages)
                                _ActionRow(
                                  title: usage.conversationTitle,
                                  subtitle:
                                      l10n.storage_settings_chat_subtitle(
                                    usage.entries.length,
                                    _formatBytes(usage.totalBytes),
                                  ),
                                  onTap: () => _openChatDetail(
                                    uid: user.uid,
                                    conversations: conversations,
                                    usage: usage,
                                  ),
                                ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              _ErrorState(message: e.toString(), onRetry: null),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(message: e.toString(), onRetry: null),
    );
  }
}

// ── Shared widgets ──

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.children,
    this.title,
    this.subtitle,
    this.leadingIcon,
  });

  final String? title;
  final String? subtitle;
  final List<Widget> children;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: (dark ? const Color(0xFF08111B) : Colors.white).withValues(
          alpha: dark ? 0.86 : 0.84,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: dark ? 0.12 : 0.44),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (leadingIcon != null) ...[
                  Icon(
                    leadingIcon,
                    size: 18,
                    color: dark
                        ? Colors.white.withValues(alpha: 0.72)
                        : scheme.onSurface.withValues(alpha: 0.62),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title!,
                    style: TextStyle(
                      fontSize: _kCardTitleSize,
                      fontWeight: FontWeight.w700,
                      color: dark ? Colors.white : scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: _kMutedTextSize,
                  color: dark
                      ? Colors.white.withValues(alpha: 0.70)
                      : scheme.onSurface.withValues(alpha: 0.68),
                ),
              ),
            ],
            const SizedBox(height: 10),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: _kBodyTextSize,
                    fontWeight: FontWeight.w600,
                    color: dark
                        ? Colors.white.withValues(alpha: 0.95)
                        : scheme.onSurface.withValues(alpha: 0.94),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: _kMutedTextSize,
                      color: dark
                          ? Colors.white.withValues(alpha: 0.68)
                          : scheme.onSurface.withValues(alpha: 0.64),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF2F86FF),
            inactiveThumbColor: (dark ? Colors.white : scheme.surface)
                .withValues(alpha: dark ? 0.9 : 1),
            inactiveTrackColor: (dark ? Colors.white : scheme.onSurface)
                .withValues(alpha: dark ? 0.2 : 0.2),
          ),
        ],
      ),
    );
  }
}

class _DropdownRow<T> extends StatelessWidget {
  const _DropdownRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22,
            color: dark
                ? Colors.white.withValues(alpha: 0.70)
                : scheme.onSurface.withValues(alpha: 0.60)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: _kBodyTextSize,
                fontWeight: FontWeight.w600,
                color: dark
                    ? Colors.white.withValues(alpha: 0.95)
                    : scheme.onSurface.withValues(alpha: 0.94),
              ),
            ),
          ),
          DropdownButton<T>(
            value: value,
            underline: const SizedBox.shrink(),
            isDense: true,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: dark
                  ? Colors.white.withValues(alpha: 0.70)
                  : scheme.onSurface.withValues(alpha: 0.60),
            ),
            dropdownColor: dark ? const Color(0xFF1A2A3A) : Colors.white,
            items: items
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(labelBuilder(e)),
                    ))
                .toList(),
            onChanged: onChanged == null
                ? null
                : (v) {
                    if (v != null) onChanged!(v);
                  },
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: _kBodyTextSize,
                      fontWeight: FontWeight.w600,
                      color: dark
                          ? Colors.white.withValues(alpha: 0.95)
                          : scheme.onSurface.withValues(alpha: 0.94),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: _kMutedTextSize,
                        color: dark
                            ? Colors.white.withValues(alpha: 0.68)
                            : scheme.onSurface.withValues(alpha: 0.64),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: dark
                        ? Colors.white.withValues(alpha: 0.30)
                        : scheme.onSurface.withValues(alpha: 0.34),
                  ),
          ],
        ),
      ),
    );
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        fontSize: _kMutedTextSize,
        color: scheme.onSurface.withValues(alpha: 0.66),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            if (onRetry != null)
              OutlinedButton(
                onPressed: onRetry,
                child: Text(AppLocalizations.of(context)!.common_retry),
              ),
          ],
        ),
      ),
    );
  }
}
