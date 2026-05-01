import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'package:lighchat_mobile/app_providers.dart';
import '../../auth/ui/auth_glass.dart';
import '../../chat/data/local_storage_preferences.dart';
import '../../chat/ui/profile_subpage_header.dart';
import '../data/storage_cache_manager.dart';
import '../../../l10n/app_localizations.dart';

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

  String _formatDate(DateTime? value) {
    if (value == null) return '—';
    final d = value.toLocal();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd.$mm ${d.year} · $hh:$min';
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
    }
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
    }
  }

  Future<void> _toggleCategory({
    required String uid,
    required List<ConversationWithId> conversations,
    required LocalStorageCategory category,
    required bool enabled,
  }) async {
    final updated = _preferences.copyWith(
      e2eeMediaEnabled: category == LocalStorageCategory.e2eeMedia
          ? enabled
          : null,
      videoDownloadsEnabled: category == LocalStorageCategory.videoDownloads
          ? enabled
          : null,
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
    final updated = _preferences.copyWith(cacheBudgetGb: budgetGb);
    await _withBusy(() async {
      await LocalStoragePreferencesStore.save(updated);
      if (!mounted) return;
      setState(() => _preferences = updated);
      await _reload(uid: uid, conversations: conversations);
    });
  }

  Future<bool> _deleteEntryAndRefresh({
    required String uid,
    required List<ConversationWithId> conversations,
    required LocalStorageEntry entry,
  }) async {
    var ok = false;
    await _withBusy(() async {
      await _manager.clearEntry(entry);
      ok = true;
      await _reload(uid: uid, conversations: conversations);
    });
    return ok;
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    });
  }

  Future<void> _clearConversation({
    required String uid,
    required List<ConversationWithId> conversations,
    required LocalStorageConversationUsage usage,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.storage_settings_clear_chat_title(usage.conversationTitle),
        ),
        content: Text(l10n.storage_settings_clear_chat_body),
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
      await _manager.clearConversation(
        userId: uid,
        conversationId: usage.conversationId,
      );
      await _reload(uid: uid, conversations: conversations);
    });
  }

  Future<void> _openConversationEntries({
    required String uid,
    required List<ConversationWithId> conversations,
    required LocalStorageConversationUsage usage,
    required AppLocalizations l10n,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _StorageConversationEntriesScreen(
          title: usage.conversationTitle,
          subtitle: l10n.storage_settings_chat_subtitle(
            usage.entries.length,
            _formatBytes(usage.totalBytes),
          ),
          entries: usage.entries,
          categoryTitle: (c) => _categoryTitle(c, l10n),
          formatBytes: _formatBytes,
          formatDate: _formatDate,
          onDelete: (entry) => _deleteEntryAndRefresh(
            uid: uid,
            conversations: conversations,
            entry: entry,
          ),
        ),
      ),
    );
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
                        _SettingsCard(
                          title: l10n.storage_settings_total_label,
                          subtitle: l10n.storage_settings_subtitle,
                          leadingIcon: Icons.storage_rounded,
                          children: [
                            Text(
                              _formatBytes(snapshot.totalBytes),
                              style: TextStyle(
                                fontSize: 31,
                                fontWeight: FontWeight.w800,
                                color: dark ? Colors.white : scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.storage_settings_budget_label(
                                _preferences.cacheBudgetGb,
                              ),
                              style: TextStyle(
                                fontSize: _kMutedTextSize,
                                color: dark
                                    ? Colors.white.withValues(alpha: 0.68)
                                    : scheme.onSurface.withValues(alpha: 0.64),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _busy
                                        ? null
                                        : () => _trimToBudget(
                                            uid: user.uid,
                                            conversations: conversations,
                                          ),
                                    icon: const Icon(
                                      Icons.cleaning_services_rounded,
                                    ),
                                    label: Text(
                                      l10n.storage_settings_trim_button,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: _busy
                                        ? null
                                        : () => _confirmAndClearAll(
                                            uid: user.uid,
                                            conversations: conversations,
                                          ),
                                    icon: const Icon(
                                      Icons.delete_sweep_rounded,
                                    ),
                                    label: Text(
                                      l10n.storage_settings_clear_all_button,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _SettingsCard(
                          title: l10n.storage_settings_policy_title,
                          leadingIcon: Icons.tune_rounded,
                          children: [
                            for (final category in kUserToggleableCategories)
                              _SwitchRow(
                                title: _categoryTitle(category, l10n),
                                subtitle: _categorySubtitle(category, l10n),
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
                                    : scheme.onSurface.withValues(alpha: 0.92),
                              ),
                            ),
                            Slider(
                              value: _preferences.cacheBudgetGb.toDouble(),
                              min: LocalStoragePreferences.minCacheBudgetGb
                                  .toDouble(),
                              max: LocalStoragePreferences.maxCacheBudgetGb
                                  .toDouble(),
                              divisions:
                                  LocalStoragePreferences.maxCacheBudgetGb -
                                  LocalStoragePreferences.minCacheBudgetGb,
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
                          ],
                        ),
                        const SizedBox(height: 14),
                        _SettingsCard(
                          title: l10n.storage_settings_chats_title,
                          leadingIcon: Icons.forum_outlined,
                          children: [
                            if (snapshot.conversationUsages.isEmpty)
                              _MutedText(l10n.storage_settings_chats_empty)
                            else
                              for (final usage in snapshot.conversationUsages)
                                _ActionRow(
                                  title: usage.conversationTitle,
                                  subtitle: l10n.storage_settings_chat_subtitle(
                                    usage.entries.length,
                                    _formatBytes(usage.totalBytes),
                                  ),
                                  onTap: () => _openConversationEntries(
                                    uid: user.uid,
                                    conversations: conversations,
                                    usage: usage,
                                    l10n: l10n,
                                  ),
                                  trailing: IconButton(
                                    tooltip:
                                        l10n.storage_settings_clear_chat_action,
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                    ),
                                    onPressed: _busy
                                        ? null
                                        : () => _clearConversation(
                                            uid: user.uid,
                                            conversations: conversations,
                                            usage: usage,
                                          ),
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
          error: (e, _) => _ErrorState(message: e.toString(), onRetry: null),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(message: e.toString(), onRetry: null),
    );
  }
}

class _StorageConversationEntriesScreen extends StatefulWidget {
  const _StorageConversationEntriesScreen({
    required this.title,
    required this.subtitle,
    required this.entries,
    required this.categoryTitle,
    required this.formatBytes,
    required this.formatDate,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final List<LocalStorageEntry> entries;
  final String Function(LocalStorageCategory) categoryTitle;
  final String Function(int) formatBytes;
  final String Function(DateTime?) formatDate;
  final Future<bool> Function(LocalStorageEntry) onDelete;

  @override
  State<_StorageConversationEntriesScreen> createState() =>
      _StorageConversationEntriesScreenState();
}

class _StorageConversationEntriesScreenState
    extends State<_StorageConversationEntriesScreen> {
  late final List<LocalStorageEntry> _entries = [...widget.entries];
  bool _busy = false;

  IconData _iconFor(LocalStorageCategory category) {
    switch (category) {
      case LocalStorageCategory.e2eeMedia:
        return Icons.perm_media_rounded;
      case LocalStorageCategory.e2eeText:
        return Icons.text_snippet_rounded;
      case LocalStorageCategory.chatDrafts:
        return Icons.edit_note_rounded;
      case LocalStorageCategory.chatListSnapshot:
        return Icons.list_alt_rounded;
      case LocalStorageCategory.profileCards:
        return Icons.person_outline_rounded;
      case LocalStorageCategory.videoDownloads:
        return Icons.movie_creation_outlined;
      case LocalStorageCategory.videoThumbs:
        return Icons.image_outlined;
    }
  }

  Future<void> _delete(LocalStorageEntry entry) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ok = await widget.onDelete(entry);
      if (!mounted) return;
      if (ok) {
        setState(() {
          _entries.removeWhere((e) => e.id == entry.id);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuthBackground(
        child: SafeArea(
          child: Column(
            children: [
              ChatProfileSubpageHeader(title: widget.title),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: _kMutedTextSize,
                      color: scheme.onSurface.withValues(alpha: 0.68),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _entries.isEmpty
                    ? Center(
                        child: Text(
                          AppLocalizations.of(
                            context,
                          )!.storage_settings_chat_files_empty,
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          final entry = _entries[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _GlassCell(
                              child: ListTile(
                                leading: Icon(
                                  _iconFor(entry.category),
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.88,
                                  ),
                                ),
                                title: Text(
                                  entry.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: _kBodyTextSize,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.95,
                                    ),
                                  ),
                                ),
                                subtitle: Text(
                                  '${widget.categoryTitle(entry.category)} · ${widget.formatBytes(entry.bytes)} · ${widget.formatDate(entry.modifiedAt)}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: _kMutedTextSize,
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.66,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                  ),
                                  onPressed: _busy
                                      ? null
                                      : () => _delete(entry),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.children,
    this.subtitle,
    this.leadingIcon,
  });

  final String title;
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
                  title,
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
        crossAxisAlignment: CrossAxisAlignment.center,
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
          crossAxisAlignment: CrossAxisAlignment.center,
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

class _GlassCell extends StatelessWidget {
  const _GlassCell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: (dark ? const Color(0xFF0A1727) : Colors.white).withValues(
          alpha: dark ? 0.78 : 0.84,
        ),
        border: Border.all(
          color: (dark ? Colors.white : scheme.onSurface).withValues(
            alpha: dark ? 0.08 : 0.08,
          ),
        ),
      ),
      child: child,
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
