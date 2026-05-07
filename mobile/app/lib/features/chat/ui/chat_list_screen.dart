import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'package:lighchat_mobile/app_providers.dart';
import '../data/contact_display_name.dart';
import '../data/user_profile.dart';
import '../data/user_contacts_repository.dart';
import '../data/chat_list_offline_cache.dart';
import '../data/dm_display_title.dart';
import '../data/saved_messages_chat.dart';
import '../data/chat_message_draft_storage.dart';
import '../data/bottom_nav_icon_settings.dart';
import '../data/e2ee_plaintext_cache.dart';
import '../data/new_chat_user_search.dart' show ruEnSubstringMatch;
import '../../../l10n/app_localizations.dart';

import 'chat_folder_bar.dart';
import 'chat_list_item.dart';
import 'chat_bottom_nav.dart';
import 'chat_shell_backdrop.dart';
import '../../features_tour/data/features_welcome_pending.dart';
import '../../features_tour/ui/features_welcome_sheet.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    // Если auth-listener пометил «нужно показать модалку» (после
    // успешного логина) — показываем `FeaturesWelcomeSheet` поверх /chats
    // на следующем кадре. `consume()` атомарен, повторного показа не
    // будет, пока снова не залогинимся.
    if (FeaturesWelcomePending.consume()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(showFeaturesWelcomeSheet(context));
      });
    }
  }

  void _retryBoot({String? uid}) {
    ref.invalidate(authUserProvider);
    if (uid != null && uid.isNotEmpty) {
      ref.invalidate(registrationProfileCompleteProvider(uid));
      ref.invalidate(registrationProfileStatusProvider(uid));
      ref.invalidate(userChatIndexProvider(uid));
    }
  }

  Widget _bootLoading(String message, {String? uid}) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ChatShellBackdrop(),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(height: 14),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => _retryBoot(uid: uid),
                  child: Text(l10n.common_retry),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseReady = ref.watch(firebaseReadyProvider);
    final userAsync = ref.watch(authUserProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: !firebaseReady
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppLocalizations.of(context)!.chat_list_firebase_not_configured,
              ),
            )
          : userAsync.when(
              data: (user) {
                if (user == null) {
                  // Hard-redirect away from chats when signed out.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) context.go('/auth');
                  });
                  return _bootLoading(
                    AppLocalizations.of(context)!.chat_list_loading_sign_out,
                    uid: null,
                  );
                }

                final indexAsync = ref.watch(userChatIndexProvider(user.uid));
                return indexAsync.when(
                  data: (idx) {
                    final ids = (idx?.conversationIds ?? const <String>[])
                        .where((id) => !id.startsWith('sdm_'))
                        .toList(growable: false);
                    final convAsync = ref.watch(
                      conversationsProvider((
                        key: conversationIdsCacheKey(ids),
                      )),
                    );
                    return convAsync.when(
                      data: (convs) {
                        final visibleConversations = convs
                            .where(
                              (c) => _isVisibleConversationForUser(
                                user.uid,
                                c.data,
                              ),
                            )
                            .toList(growable: false);
                        final folders = _buildFolders(
                          currentUserId: user.uid,
                          idx: idx,
                          conversations: visibleConversations,
                        );
                        return _ChatListBody(
                          currentUserId: user.uid,
                          userChatIndex: idx,
                          folders: folders,
                          conversations: visibleConversations,
                        );
                      },
                      loading: () => _bootLoading(
                        AppLocalizations.of(
                          context,
                        )!.chat_list_loading_conversations,
                        uid: user.uid,
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          AppLocalizations.of(context)!.chat_list_error_generic(e),
                        ),
                      ),
                    );
                  },
                  loading: () => _bootLoading(
                    AppLocalizations.of(context)!.chat_list_loading_list,
                    uid: user.uid,
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      AppLocalizations.of(context)!.chat_list_error_generic(e),
                    ),
                  ),
                );
              },
              loading: () => _bootLoading(
                AppLocalizations.of(context)!.chat_list_loading_connecting,
                uid: null,
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context)!.chat_auth_error(e.toString()),
                ),
              ),
            ),
    );
  }

  List<ChatFolder> _buildFolders({
    required String currentUserId,
    required UserChatIndex? idx,
    required List<ConversationWithId> conversations,
  }) {
    final saved = ChatFolder(
      id: 'favorites',
      name: AppLocalizations.of(context)!.chat_list_folder_default_starred,
      conversationIds: const <String>[],
    );

    final all = ChatFolder(
      id: 'all',
      name: AppLocalizations.of(context)!.chat_list_folder_default_all,
      conversationIds: conversations.map((c) => c.id).toList(growable: false),
    );

    final unread = ChatFolder(
      id: 'unread',
      name: AppLocalizations.of(context)!.chat_list_folder_default_new,
      conversationIds: conversations
          .where((c) {
            final u =
                (c.data.unreadCounts?[currentUserId] ?? 0) +
                (c.data.unreadThreadCounts?[currentUserId] ?? 0);
            return u > 0;
          })
          .map((c) => c.id)
          .toList(growable: false),
    );

    final personal = ChatFolder(
      id: 'personal',
      name: AppLocalizations.of(context)!.chat_list_folder_default_direct,
      conversationIds: conversations
          .where((c) => !c.data.isGroup)
          .map((c) => c.id)
          .toList(growable: false),
    );

    final groups = ChatFolder(
      id: 'groups',
      name: AppLocalizations.of(context)!.chat_list_folder_default_groups,
      conversationIds: conversations
          .where((c) => c.data.isGroup)
          .map((c) => c.id)
          .toList(growable: false),
    );

    final custom = (idx?.folders ?? const <ChatFolder>[]);
    return <ChatFolder>[saved, all, unread, personal, groups, ...custom];
  }

  bool _isVisibleConversationForUser(String userId, Conversation conversation) {
    final participants = conversation.participantIds
        .where((id) => id.trim().isNotEmpty)
        .toList(growable: false);
    if (participants.isEmpty) return false;
    if (!participants.contains(userId)) return false;
    if (!conversation.isGroup && participants.length == 1) {
      return participants.first == userId;
    }
    return true;
  }
}

class _ChatListBody extends ConsumerStatefulWidget {
  const _ChatListBody({
    required this.currentUserId,
    required this.userChatIndex,
    required this.folders,
    required this.conversations,
  });

  final String currentUserId;
  final UserChatIndex? userChatIndex;
  final List<ChatFolder> folders;
  final List<ConversationWithId> conversations;

  @override
  ConsumerState<_ChatListBody> createState() => _ChatListBodyState();
}

class _ChatListBodyState extends ConsumerState<_ChatListBody> {
  String _activeFolderId = 'all';
  final _search = TextEditingController();
  final _listScrollController = ScrollController();
  Map<String, StoredChatMessageDraft> _draftByConv =
      <String, StoredChatMessageDraft>{};
  bool _showSecretChatsRow = false;

  String? _lastOfflinePersistFingerprint;

  late final VoidCallback _draftRevListener = _onChatDraftRevision;
  late final VoidCallback _previewRevListener = _onE2eePreviewRevision;

  void _onE2eePreviewRevision() {
    if (mounted) setState(() {});
  }

  void _persistOfflineSnapshot() {
    final idx = widget.userChatIndex;
    if (idx == null) return;
    final fp =
        '${idx.conversationIds.join('\u001e')}|${widget.conversations.map((c) => '${c.id}:${c.data.lastMessageTimestamp}').join('\u001f')}';
    if (fp == _lastOfflinePersistFingerprint) return;
    _lastOfflinePersistFingerprint = fp;
    unawaited(
      persistChatListOfflineSnapshot(
        userId: widget.currentUserId,
        index: idx,
        conversations: widget.conversations,
      ),
    );
  }

  void _onChatDraftRevision() {
    unawaited(_reloadChatDrafts());
  }

  void _onListScroll() {
    if (_listScrollController.hasClients && _listScrollController.offset > 4) {
      if (_showSecretChatsRow) {
        setState(() {
          _showSecretChatsRow = false;
        });
      }
    }
  }

  Future<void> _reloadChatDrafts() async {
    final m = await loadAllChatDraftsForUser(widget.currentUserId);
    if (!mounted) return;
    setState(() => _draftByConv = m);
  }

  @override
  void initState() {
    super.initState();
    _listScrollController.addListener(_onListScroll);
    chatDraftListRevision.addListener(_draftRevListener);
    // E2EE preview-кэш: прогреваем с диска, чтобы первая отрисовка списка
    // могла подставить настоящий текст вместо плейсхолдера «Зашифрованное
    // сообщение». Подписываемся на ревизию — каждое обновление preview
    // (после decrypt / send / edit) триггерит rebuild списка.
    E2eePlaintextCache.instance.previewRevision.addListener(
      _previewRevListener,
    );
    unawaited(E2eePlaintextCache.instance.warmUpPreviews());
    unawaited(_reloadChatDrafts());
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _persistOfflineSnapshot(),
    );
  }

  @override
  void didUpdateWidget(covariant _ChatListBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUserId != widget.currentUserId) {
      unawaited(_reloadChatDrafts());
    }
    if (oldWidget.conversations != widget.conversations ||
        oldWidget.userChatIndex != widget.userChatIndex) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _persistOfflineSnapshot(),
      );
    }
  }

  @override
  void dispose() {
    _listScrollController.removeListener(_onListScroll);
    _listScrollController.dispose();
    chatDraftListRevision.removeListener(_draftRevListener);
    E2eePlaintextCache.instance.previewRevision.removeListener(
      _previewRevListener,
    );
    _search.dispose();
    super.dispose();
  }

  Future<void> _openFavoritesChat({
    required String name,
    required String? avatar,
    required String? avatarThumb,
  }) async {
    final existing = widget.conversations
        .where((c) => isSavedMessagesConversation(c.data, widget.currentUserId))
        .toList(growable: false);
    if (existing.isNotEmpty) {
      existing.sort((a, b) {
        final ta =
            _parseIsoAsLocal(
              a.data.lastMessageTimestamp,
            )?.millisecondsSinceEpoch ??
            0;
        final tb =
            _parseIsoAsLocal(
              b.data.lastMessageTimestamp,
            )?.millisecondsSinceEpoch ??
            0;
        return tb.compareTo(ta);
      });
      if (!mounted) return;
      context.push('/chats/${existing.first.id}');
      return;
    }

    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
    try {
      final id = await repo.ensureSavedMessagesChat(
        currentUserId: widget.currentUserId,
        currentUserInfo: (name: name, avatar: avatar, avatarThumb: avatarThumb),
      );
      if (!mounted) return;
      context.push('/chats/$id');
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.chat_list_error_open_starred(e)),
        ),
      );
    }
  }

  String _formatTimeLabel(String? iso) {
    if (iso == null || iso.trim().isEmpty) return '';
    final dt = _parseIsoAsLocal(iso);
    if (dt == null) return '';
    final now = DateTime.now();
    final d0 = DateTime(now.year, now.month, now.day);
    final d1 = DateTime(dt.year, dt.month, dt.day);
    final diffDays = d0.difference(d1).inDays;
    if (diffDays == 0) {
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    if (diffDays == 1) {
      return AppLocalizations.of(context)!.chat_list_yesterday;
    }
    final dd = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final yy = (dt.year % 100).toString().padLeft(2, '0');
    return '$dd.$mo.$yy';
  }

  DateTime? _parseIsoAsLocal(String? raw) {
    final s = (raw ?? '').trim();
    if (s.isEmpty) return null;
    final dt = DateTime.tryParse(s);
    if (dt == null) return null;
    return dt.isUtc ? dt.toLocal() : dt;
  }

  bool _isDefaultFolderId(String id) {
    return id == 'favorites' ||
        id == 'all' ||
        id == 'unread' ||
        id == 'personal' ||
        id == 'groups';
  }

  Future<void> _handleFolderLongPress(
    BuildContext context,
    ChatFolder folder,
  ) async {
    if (_isDefaultFolderId(folder.id)) return;

    final deleteRequested = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        final scheme = Theme.of(ctx).colorScheme;
        final dark = scheme.brightness == Brightness.dark;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: const Color(
                  0xFF101216,
                ).withValues(alpha: dark ? 0.98 : 0.96),
                border: Border.all(
                  color: Colors.white.withValues(alpha: dark ? 0.10 : 0.20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.of(ctx).pop(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: Colors.red.withValues(alpha: 0.10),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFFF6B6B),
                            ),
                            SizedBox(width: 12),
                            Text(
                              l10n.chat_list_folder_delete_action,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFF6B6B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (deleteRequested != true || !context.mounted) return;
    final confirmed = await _confirmFolderDelete(context, folder);
    if (!confirmed || !context.mounted) return;

    final repo = ref.read(chatFoldersRepositoryProvider);
    if (repo == null) return;
    try {
      await repo.deleteFolder(
        userId: widget.currentUserId,
        folderId: folder.id,
      );
      if (!mounted) return;
      if (_activeFolderId == folder.id) {
        setState(() => _activeFolderId = 'all');
      }
    } catch (e) {
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(l10n.chat_list_error_delete_folder(e)),
        ),
      );
    }
  }

  Future<bool> _confirmFolderDelete(
    BuildContext context,
    ChatFolder folder,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        final scheme = Theme.of(ctx).colorScheme;
        final dark = scheme.brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: const Color(
                0xFF0C0D11,
              ).withValues(alpha: dark ? 0.98 : 0.96),
              border: Border.all(
                color: Colors.white.withValues(alpha: dark ? 0.10 : 0.20),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.chat_list_folder_delete_title,
                  style: const TextStyle(
                    fontSize: 22 / 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.chat_list_folder_delete_body(folder.name),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: scheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          side: BorderSide(
                            color: scheme.onSurface.withValues(alpha: 0.20),
                          ),
                        ),
                        child: Text(l10n.common_cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          backgroundColor: const Color(0xFFFF5A5F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          l10n.chat_list_folder_delete_action,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result == true;
  }

  bool _isPinnedInActiveFolder(String conversationId) {
    final pins =
        widget.userChatIndex?.folderPins?[_activeFolderId] ?? const <String>[];
    return pins.contains(conversationId);
  }

  bool _hasPinnedSupportInActiveFolder() {
    return _activeFolderId != 'favorites';
  }

  bool _isSavedConversation(ConversationWithId conversation) {
    return isSavedMessagesConversation(conversation.data, widget.currentUserId);
  }

  Future<void> _togglePinInActiveFolder(
    BuildContext context,
    ConversationWithId conversation,
  ) async {
    if (!_hasPinnedSupportInActiveFolder()) {
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.chat_list_pin_not_available),
        ),
      );
      return;
    }
    final repo = ref.read(chatFoldersRepositoryProvider);
    if (repo == null) return;
    try {
      final pinned = await repo.toggleFolderPin(
        userId: widget.currentUserId,
        folderId: _activeFolderId,
        conversationId: conversation.id,
      );
      if (!context.mounted) return;
      final folderName = widget.folders
          .firstWhere(
            (f) => f.id == _activeFolderId,
            orElse: () => widget.folders.first,
          )
          .name;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pinned
                ? AppLocalizations.of(
                    context,
                  )!.chat_list_pin_pinned_in_folder(folderName)
                : AppLocalizations.of(
                    context,
                  )!.chat_list_pin_unpinned_in_folder(folderName),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.chat_list_error_toggle_pin(e)),
        ),
      );
    }
  }

  Future<void> _openChatFoldersDialog(
    BuildContext context,
    ConversationWithId conversation,
  ) async {
    if (_isSavedConversation(conversation)) return;
    final repo = ref.read(chatFoldersRepositoryProvider);
    if (repo == null) return;
    final customFolders = widget.folders
        .where((f) => !_isDefaultFolderId(f.id))
        .toList(growable: false);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final dark = scheme.brightness == Brightness.dark;
        bool busy = false;
        final foldersL10n = AppLocalizations.of(ctx)!;
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> toggleFolder(ChatFolder folder) async {
              setModalState(() => busy = true);
              try {
                await repo.toggleConversationInFolder(
                  userId: widget.currentUserId,
                  folderId: folder.id,
                  conversationId: conversation.id,
                );
              } catch (e) {
                if (!ctx.mounted) return;
                final l10n = AppLocalizations.of(ctx)!;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(l10n.chat_list_error_update_folder(e)),
                  ),
                );
              } finally {
                if (ctx.mounted) setModalState(() => busy = false);
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: const Color(
                    0xFF0C0D11,
                  ).withValues(alpha: dark ? 0.98 : 0.96),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: dark ? 0.10 : 0.20),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      foldersL10n.chat_list_folders_title,
                      style: const TextStyle(
                        fontSize: 22 / 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      foldersL10n.chat_list_folders_subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurface.withValues(alpha: 0.62),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (customFolders.isEmpty)
                      Text(
                        foldersL10n.chat_list_folders_empty,
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.56),
                        ),
                      )
                    else
                      ...customFolders.map((folder) {
                        final selected = folder.conversationIds.contains(
                          conversation.id,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: busy ? null : () => toggleFolder(folder),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: selected
                                    ? const Color(
                                        0xFF2A79FF,
                                      ).withValues(alpha: 0.16)
                                    : Colors.white.withValues(alpha: 0.05),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF2A79FF)
                                      : Colors.white.withValues(alpha: 0.10),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      folder.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (busy)
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    Icon(
                                      selected
                                          ? Icons.check_circle_rounded
                                          : Icons.circle_outlined,
                                      color: selected
                                          ? const Color(0xFF2A79FF)
                                          : scheme.onSurface.withValues(
                                              alpha: 0.38,
                                            ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 6),
                    OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(foldersL10n.chat_list_action_close),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _clearChatHistory(
    BuildContext context,
    ConversationWithId conversation,
  ) async {
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirmChatAction(
      context: context,
      title: l10n.chat_list_clear_history_title,
      description: l10n.chat_list_clear_history_body,
      confirmLabel: l10n.chat_list_clear_history_confirm,
      destructive: false,
    );
    if (!confirmed) return;
    try {
      await repo.clearConversationForMe(
        conversationId: conversation.id,
        userId: widget.currentUserId,
      );
    } catch (e) {
      if (!context.mounted) return;
      final l10nErr = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10nErr.chat_list_error_clear_history(e)),
        ),
      );
    }
  }

  Future<void> _markConversationAsRead(
    BuildContext context,
    ConversationWithId conversation,
  ) async {
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
    try {
      await repo.markConversationAsRead(
        conversationId: conversation.id,
        userId: widget.currentUserId,
      );
    } catch (e) {
      if (!context.mounted) return;
      final l10nErr = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10nErr.chat_list_error_mark_read(e)),
        ),
      );
    }
  }

  Future<void> _deleteConversation(
    BuildContext context,
    ConversationWithId conversation,
  ) async {
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirmChatAction(
      context: context,
      title: l10n.chat_list_delete_chat_title,
      description: l10n.chat_list_delete_chat_body,
      confirmLabel: l10n.chat_list_delete_chat_confirm,
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await repo.deleteDirectConversationForAll(
        conversationId: conversation.id,
        currentUserId: widget.currentUserId,
      );
    } catch (e) {
      if (!context.mounted) return;
      final l10nErr = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(l10nErr.chat_list_error_delete_chat(e)),
        ),
      );
    }
  }

  Future<bool> _confirmChatAction({
    required BuildContext context,
    required String title,
    required String description,
    required String confirmLabel,
    required bool destructive,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final dark = scheme.brightness == Brightness.dark;
        final l10n = AppLocalizations.of(ctx)!;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: const Color(
                0xFF0C0D11,
              ).withValues(alpha: dark ? 0.98 : 0.96),
              border: Border.all(
                color: Colors.white.withValues(alpha: dark ? 0.10 : 0.20),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: scheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          side: BorderSide(
                            color: scheme.onSurface.withValues(alpha: 0.20),
                          ),
                        ),
                        child: Text(l10n.common_cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          backgroundColor: destructive
                              ? const Color(0xFFE2554D)
                              : const Color(0xFF2A79FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          confirmLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result == true;
  }

  Future<void> _openChatActionsMenu(
    BuildContext context,
    ConversationWithId conversation,
  ) async {
    final isSaved = _isSavedConversation(conversation);
    final canDelete = !conversation.data.isGroup && !isSaved;
    final canPin = _hasPinnedSupportInActiveFolder();
    final unreadCount =
        (conversation.data.unreadCounts?[widget.currentUserId] ?? 0) +
        (conversation.data.unreadThreadCounts?[widget.currentUserId] ?? 0);
    final canMarkAllRead = unreadCount > 0;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final dark = scheme.brightness == Brightness.dark;
        final l10n = AppLocalizations.of(ctx)!;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(color: Colors.black.withValues(alpha: 0.34)),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Container(
                  width: 336,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: const Color(
                      0xFF10161C,
                    ).withValues(alpha: dark ? 0.98 : 0.95),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: dark ? 0.10 : 0.18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 32,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (!isSaved)
                        _ChatMenuButton(
                          icon: Icons.folder_open_rounded,
                          iconColor: const Color(0xFF45C7D7),
                          label: l10n.chat_list_context_folders,
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _openChatFoldersDialog(context, conversation);
                          },
                        ),
                      _ChatMenuButton(
                        icon: _isPinnedInActiveFolder(conversation.id)
                            ? Icons.push_pin
                            : Icons.push_pin_outlined,
                        iconColor: canPin
                            ? const Color(0xFFF0AA3C)
                            : Colors.white.withValues(alpha: 0.32),
                        label: _isPinnedInActiveFolder(conversation.id)
                            ? l10n.chat_list_context_unpin
                            : l10n.chat_list_context_pin,
                        labelColor: canPin
                            ? null
                            : Colors.white.withValues(alpha: 0.38),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _togglePinInActiveFolder(context, conversation);
                        },
                      ),
                      _ChatMenuButton(
                        icon: Icons.mark_chat_read_rounded,
                        iconColor: canMarkAllRead
                            ? const Color(0xFF58C08A)
                            : Colors.white.withValues(alpha: 0.32),
                        label: l10n.chat_list_context_mark_all_read,
                        labelColor: canMarkAllRead
                            ? null
                            : Colors.white.withValues(alpha: 0.38),
                        onTap: () {
                          if (!canMarkAllRead) return;
                          Navigator.of(ctx).pop();
                          _markConversationAsRead(context, conversation);
                        },
                      ),
                      _ChatMenuButton(
                        icon: Icons.auto_fix_high_rounded,
                        iconColor: Colors.white.withValues(alpha: 0.78),
                        label: l10n.chat_list_context_clear_history,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _clearChatHistory(context, conversation);
                        },
                      ),
                      if (canDelete)
                        _ChatMenuButton(
                          icon: Icons.delete_outline_rounded,
                          iconColor: const Color(0xFFC53A34),
                          label: l10n.chat_list_context_delete_chat,
                          labelColor: const Color(0xFFC53A34),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _deleteConversation(context, conversation);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userDoc =
        ref
            .watch(userChatSettingsDocProvider(widget.currentUserId))
            .asData
            ?.value ??
        const <String, dynamic>{};
    final chatSettings = Map<String, dynamic>.from(
      userDoc['chatSettings'] as Map? ?? const <String, dynamic>{},
    );
    final bottomNavAppearance =
        (chatSettings['bottomNavAppearance'] as String?) ?? 'colorful';
    final bottomNavIconNames = parseBottomNavIconNames(
      chatSettings['bottomNavIconNames'],
    );
    final bottomNavGlobalStyle = BottomNavIconVisualStyle.fromJson(
      chatSettings['bottomNavIconGlobalStyle'],
    );
    final bottomNavIconStyles = parseBottomNavIconStyles(
      chatSettings['bottomNavIconStyles'],
    );
    final contactsAsync = ref.watch(
      userContactsIndexProvider(widget.currentUserId),
    );
    final contactProfiles = contactsAsync.value?.contactProfiles ?? const {};

    final folder = widget.folders.firstWhere(
      (f) => f.id == _activeFolderId,
      orElse: () => widget.folders.first,
    );
    final allowed = folder.conversationIds.toSet();
    final term = _search.text.trim().toLowerCase();
    final uniqueByKey = <String, ConversationWithId>{};
    int tsScore(ConversationWithId c) =>
        _parseIsoAsLocal(c.data.lastMessageTimestamp)?.millisecondsSinceEpoch ??
        0;
    String keyFor(ConversationWithId c) {
      if (c.data.isGroup) return 'conv:${c.id}';
      if (isSavedMessagesConversation(c.data, widget.currentUserId)) {
        return 'saved:${widget.currentUserId}';
      }
      final p = c.data.participantIds
          .where((id) => id.trim().isNotEmpty)
          .toList(growable: false);
      if (p.length != 2) return 'conv:${c.id}';
      final other = p.firstWhere(
        (id) => id != widget.currentUserId,
        orElse: () => '',
      );
      if (other.isEmpty) return 'conv:${c.id}';
      return 'dm:$other';
    }

    for (final c in widget.conversations.where((c) => allowed.contains(c.id))) {
      final key = keyFor(c);
      final prev = uniqueByKey[key];
      if (prev == null || tsScore(c) >= tsScore(prev)) {
        uniqueByKey[key] = c;
      }
    }
    final allUniqueByKey = <String, ConversationWithId>{};
    for (final c in widget.conversations) {
      final key = keyFor(c);
      final prev = allUniqueByKey[key];
      if (prev == null || tsScore(c) >= tsScore(prev)) {
        allUniqueByKey[key] = c;
      }
    }
    final folderConversations = uniqueByKey.values.toList(growable: false)
      ..sort((a, b) {
        final pins =
            widget.userChatIndex?.folderPins?[_activeFolderId] ??
            const <String>[];
        final aPinIndex = pins.indexOf(a.id);
        final bPinIndex = pins.indexOf(b.id);
        final aPinned = aPinIndex >= 0;
        final bPinned = bPinIndex >= 0;
        if (aPinned && bPinned) return aPinIndex.compareTo(bPinIndex);
        if (aPinned) return -1;
        if (bPinned) return 1;
        return tsScore(b).compareTo(tsScore(a));
      });

    final otherIds = <String>{};
    for (final c in widget.conversations) {
      if (c.data.isGroup) continue;
      final p = c.data.participantIds;
      if (p.length != 2) continue;
      final other = p.firstWhere(
        (id) => id != widget.currentUserId,
        orElse: () => '',
      );
      if (other.isNotEmpty) otherIds.add(other);
    }
    otherIds.add(widget.currentUserId);

    final unreadByFolder = <String, int>{};
    for (final f in widget.folders) {
      int sum = 0;
      final set = f.conversationIds.toSet();
      for (final c in widget.conversations) {
        if (!set.contains(c.id)) continue;
        sum +=
            (c.data.unreadCounts?[widget.currentUserId] ?? 0) +
            (c.data.unreadThreadCounts?[widget.currentUserId] ?? 0);
      }
      unreadByFolder[f.id] = sum;
    }

    // Fetch profiles for DM naming + avatars.
    final profilesRepoProvider = ref.watch(userProfilesRepositoryProvider);
    final profilesStream = profilesRepoProvider?.watchUsersByIds(
      otherIds.toList(growable: false),
    );

    return StreamBuilder<Map<String, UserProfile>>(
      stream: profilesStream,
      builder: (context, snapProfiles) {
        final profiles = snapProfiles.data ?? const <String, UserProfile>{};
        final l10nList = AppLocalizations.of(context)!;
        final selfProfile = profiles[widget.currentUserId];
        final rawSelfName = selfProfile?.name ?? '';
        final selfName = rawSelfName.trim().isNotEmpty
            ? rawSelfName.trim()
            : l10nList.account_menu_profile;
        final selfAvatar = selfProfile?.avatarThumb ?? selfProfile?.avatar;

        String conversationSearchText(ConversationWithId conversation) {
          final parts = <String>[];
          final data = conversation.data;
          final rawName = (data.name ?? '').trim();
          if (rawName.isNotEmpty) parts.add(rawName);

          if (isSavedMessagesConversation(data, widget.currentUserId)) {
            parts.add(l10nList.chat_list_folder_default_starred);
            final selfUsername = (selfProfile?.username ?? '').trim();
            if (selfUsername.isNotEmpty) {
              parts.add(selfUsername);
              parts.add('@$selfUsername');
            }
          } else if (data.isGroup) {
            for (final info
                in data.participantInfo?.values ??
                    const <ConversationParticipantInfo>[]) {
              final participantName = info.name.trim();
              if (participantName.isNotEmpty) parts.add(participantName);
            }
          } else {
            final otherId = data.participantIds.firstWhere(
              (id) => id != widget.currentUserId,
              orElse: () => '',
            );
            final profile = profiles[otherId];
            final cachedName = (data.participantInfo?[otherId]?.name ?? '')
                .trim();
            final profileName = resolveContactDisplayName(
              contactProfiles: contactProfiles,
              contactUserId: otherId,
              fallbackName: (profile?.name ?? '').trim().isNotEmpty
                  ? (profile?.name ?? '').trim()
                  : cachedName,
            ).trim();
            if (profileName.isNotEmpty) parts.add(profileName);
            final username = (profile?.username ?? '').trim();
            if (username.isNotEmpty) {
              parts.add(username);
              parts.add('@$username');
            }
            if (cachedName.isNotEmpty) parts.add(cachedName);
          }

          final lastMessage = (data.lastMessageText ?? '').trim();
          if (lastMessage.isNotEmpty) parts.add(lastMessage);

          final draft = _draftByConv[conversation.id];
          final draftPlain = draft == null
              ? ''
              : chatDraftPlainFromHtml(draft.html);
          if (draftPlain.trim().isNotEmpty) parts.add(draftPlain.trim());

          return parts.join('\n');
        }

        final convs = folderConversations
            .where((conversation) {
              if (term.isEmpty) return true;
              return ruEnSubstringMatch(
                conversationSearchText(conversation),
                term,
              );
            })
            .toList(growable: false);

        final hasAnyChats = allUniqueByKey.isNotEmpty;
        final isSearchActive = term.isNotEmpty;
        final isEmptyList = convs.isEmpty;
        // Если в активной папке есть conversationIds, но сами беседы ещё не пришли
        // (например, initial snapshot), показываем «загрузка». Если ids нет —
        // это просто пустая папка.
        final hasChatIdsButNotLoadedYet =
            !isSearchActive &&
            allowed.isNotEmpty &&
            folderConversations.isEmpty;
        final theme = Theme.of(context);
        final dark = theme.colorScheme.brightness == Brightness.dark;
        return Stack(
          fit: StackFit.expand,
          children: [
            const ChatShellBackdrop(),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.chat_list_title,
                            style: const TextStyle(
                              fontSize: 46 / 2,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        _headerIconButton(
                          context: context,
                          icon: Icons.create_new_folder_outlined,
                          tooltip: AppLocalizations.of(
                            context,
                          )!.chat_list_action_new_folder,
                          onPressed: () => _openCreateFolderModal(
                            context,
                            profiles: profiles,
                            selfProfile: selfProfile,
                            contactProfiles: contactProfiles,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _headerIconButton(
                          context: context,
                          icon: Icons.add_rounded,
                          tooltip: AppLocalizations.of(
                            context,
                          )!.chat_list_action_new_chat,
                          onPressed: () => context.go('/chats/new'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ChatFolderBar(
                    folders: widget.folders,
                    activeFolderId: _activeFolderId,
                    onSelectFolder: (id) async {
                      if (id == 'favorites') {
                        await _openFavoritesChat(
                          name: selfName,
                          avatar: selfProfile?.avatar,
                          avatarThumb: selfProfile?.avatarThumb,
                        );
                        return;
                      }
                      if (!mounted) return;
                      setState(() => _activeFolderId = id);
                    },
                    unreadByFolderId: unreadByFolder,
                    onLongPressFolder: (folder) =>
                        _handleFolderLongPress(context, folder),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white.withValues(
                          alpha: dark ? 0.07 : 0.14,
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: dark ? 0.14 : 0.22,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 23,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.45,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _search,
                              onChanged: (_) => setState(() {}),
                              textCapitalization: TextCapitalization.sentences,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlignVertical: TextAlignVertical.center,
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(
                                  context,
                                )!.chat_list_search_hint,
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          if (_search.text.trim().isNotEmpty)
                            IconButton(
                              constraints: const BoxConstraints(
                                minWidth: 30,
                                minHeight: 30,
                              ),
                              padding: EdgeInsets.zero,
                              splashRadius: 18,
                              icon: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 180),
                    crossFadeState: _showSecretChatsRow
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: Column(
                      children: [
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Material(
                            color: Colors.white.withValues(
                              alpha: dark ? 0.06 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => context.push('/chats/secret-inbox'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.lock_rounded,
                                      size: 22,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.secret_chats_title,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.45),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                    secondChild: const SizedBox.shrink(),
                  ),
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.metrics.axis != Axis.vertical) {
                          return false;
                        }
                        if (notification is OverscrollNotification &&
                            notification.overscroll < 0 &&
                            notification.metrics.pixels <= 0) {
                          if (!_showSecretChatsRow &&
                              notification.metrics.pixels < -10) {
                            setState(() => _showSecretChatsRow = true);
                          }
                        } else if (notification is ScrollUpdateNotification &&
                            notification.metrics.pixels < -10) {
                          if (!_showSecretChatsRow) {
                            setState(() => _showSecretChatsRow = true);
                          }
                        } else if (notification is ScrollStartNotification ||
                            notification is ScrollUpdateNotification ||
                            notification is ScrollEndNotification) {
                          if (notification.metrics.pixels > 0 &&
                              _showSecretChatsRow) {
                            setState(() => _showSecretChatsRow = false);
                          }
                        }
                        return false;
                      },
                      child: hasChatIdsButNotLoadedYet
                        ? Center(
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.chat_list_loading_list,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.65,
                                ),
                              ),
                            ),
                          )
                        : isEmptyList
                        ? _buildEmptyState(
                            context: context,
                            showCreateButton: !hasAnyChats && !isSearchActive,
                            title: isSearchActive
                                ? AppLocalizations.of(
                                    context,
                                  )!.chat_list_empty_search_title
                                : hasAnyChats
                                ? AppLocalizations.of(
                                    context,
                                  )!.chat_list_empty_folder_title
                                : AppLocalizations.of(
                                    context,
                                  )!.chat_list_empty_all_title,
                            description: isSearchActive
                                ? AppLocalizations.of(
                                    context,
                                  )!.chat_list_empty_search_body
                                : hasAnyChats
                                ? AppLocalizations.of(
                                    context,
                                  )!.chat_list_empty_folder_body
                                : AppLocalizations.of(
                                    context,
                                  )!.chat_list_empty_all_body,
                            onCreateTap: () => context.go('/chats/new'),
                          )
                        : ListView.separated(
                            controller: _listScrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 88),
                            itemCount: convs.length,
                            separatorBuilder: (_, _) => Divider(
                              height: 1,
                              indent: 84,
                              endIndent: 24,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                            itemBuilder: (context, index) {
                              final c = convs[index];
                              String title;
                              String? avatarUrl;
                              var isOnline = false;
                              if (isSavedMessagesConversation(
                                c.data,
                                widget.currentUserId,
                              )) {
                                title = AppLocalizations.of(
                                  context,
                                )!.chat_list_folder_default_starred;
                                avatarUrl =
                                    selfProfile?.avatarThumb ??
                                    selfProfile?.avatar ??
                                    c
                                        .data
                                        .participantInfo?[widget.currentUserId]
                                        ?.avatarThumb ??
                                    c
                                        .data
                                        .participantInfo?[widget.currentUserId]
                                        ?.avatar;
                              } else if (c.data.isGroup) {
                                title = groupConversationDisplayTitle(c, l10n: AppLocalizations.of(context)!);
                                avatarUrl = c.data.photoUrl;
                              } else {
                                final other = c.data.participantIds.firstWhere(
                                  (id) => id != widget.currentUserId,
                                  orElse: () => '',
                                );
                                final p = profiles[other];
                                isOnline =
                                    p?.online == true &&
                                    p?.privacySettings?.showOnlineStatus !=
                                        false;
                                avatarUrl =
                                    p?.avatarThumb ??
                                    p?.avatar ??
                                    c
                                        .data
                                        .participantInfo?[other]
                                        ?.avatarThumb ??
                                    c.data.participantInfo?[other]?.avatar;
                                title = dmConversationDisplayTitle(
                                  currentUserId: widget.currentUserId,
                                  conversation: c,
                                  otherUserId: other,
                                  profiles: profiles,
                                  contactProfiles: contactProfiles,
                                  l10n: AppLocalizations.of(context)!,
                                );
                              }
                              final rawLastFromFirestoreRaw =
                                  (c.data.lastMessageText ?? '').trim();
                              // Strip HTML tags that may leak from thread replies.
                              final rawLastFromFirestore = rawLastFromFirestoreRaw
                                  .replaceAll(RegExp(r'<[^>]*>'), '')
                                  .replaceAll('&nbsp;', ' ')
                                  .replaceAll('&amp;', '&')
                                  .replaceAll('&lt;', '<')
                                  .replaceAll('&gt;', '>')
                                  .replaceAll('&quot;', '"')
                                  .replaceAll("&#39;", "'")
                                  .replaceAll("&#x27;", "'")
                                  .trim();
                              // E2EE override: если в Firestore лежит
                              // плейсхолдер «Зашифрованное сообщение», ищем
                              // настоящий plaintext в локальном preview-кэше.
                              // Применяем только при совпадении момента
                              // (`cached.ts ≈ lastMessageTimestamp`), иначе
                              // мог бы вылезти stale-текст от предыдущего
                              // сообщения, ещё не успевшего декодироваться.
                              String rawLast;
                              if (rawLastFromFirestore ==
                                      l10nList
                                          .chat_e2ee_encrypted_message_placeholder &&
                                  c.data.lastMessageTimestamp != null) {
                                final cached = E2eePlaintextCache.instance
                                    .getPreviewSync(c.id);
                                final cachedDt = cached == null
                                    ? null
                                    : DateTime.tryParse(cached.ts);
                                final lastDt = DateTime.tryParse(
                                  c.data.lastMessageTimestamp!,
                                );
                                if (cached != null &&
                                    cachedDt != null &&
                                    lastDt != null &&
                                    cachedDt.toUtc().isAtSameMomentAs(
                                          lastDt.toUtc(),
                                        ) &&
                                    cached.text.isNotEmpty) {
                                  rawLast = cached.text;
                                } else {
                                  rawLast = rawLastFromFirestore;
                                }
                              } else {
                                rawLast = rawLastFromFirestore;
                              }
                              final clearedAtIso =
                                  c.data.clearedAt?[widget.currentUserId];
                              final clearedAt = _parseIsoAsLocal(clearedAtIso);
                              final lastAt = _parseIsoAsLocal(
                                c.data.lastMessageTimestamp,
                              );
                              final isClearedForCurrentUser =
                                  clearedAt != null &&
                                  (lastAt == null ||
                                      !lastAt.isAfter(clearedAt));
                              final draft = _draftByConv[c.id];
                              final draftLine = draft == null
                                  ? null
                                  : chatMainDraftPreviewLine(draft, l10nList);
                              final isEmptyConversation =
                                  rawLast.isEmpty;
                              final isNewlyCreatedAfterClear =
                                  isEmptyConversation && clearedAt != null;
                              // Translate preview markers stored in Firestore.
                              if (rawLast == '{{message}}') {
                                rawLast = l10nList.chat_preview_message;
                              } else if (rawLast == '{{sticker}}') {
                                rawLast = l10nList.chat_preview_sticker;
                              } else if (rawLast == '{{attachment}}') {
                                rawLast = l10nList.chat_preview_attachment;
                              } else if (rawLast == '{{encrypted}}') {
                                rawLast = l10nList.chat_e2ee_encrypted_message_placeholder;
                              }
                              // Also translate legacy hardcoded Russian markers.
                              else if (rawLast == 'Стикер') {
                                rawLast = l10nList.chat_preview_sticker;
                              } else if (rawLast == 'Вложение') {
                                rawLast = l10nList.chat_preview_attachment;
                              } else if (rawLast == 'Сообщение') {
                                rawLast = l10nList.chat_preview_message;
                              } else if (rawLast == 'Зашифрованное сообщение') {
                                rawLast = l10nList.chat_e2ee_encrypted_message_placeholder;
                              }
                              // Build rich subtitle with sender name + thread indicator.
                              String enrichedRawLast = rawLast;
                              if (rawLast.isNotEmpty) {
                                // Prefix with sender name for group chats.
                                if (c.data.isGroup && c.data.lastMessageSenderId != null) {
                                  final senderId = c.data.lastMessageSenderId!;
                                  String? senderName;
                                  if (senderId == widget.currentUserId) {
                                    senderName = l10nList.chat_list_item_sender_you;
                                  } else {
                                    final info = c.data.participantInfo?[senderId];
                                    senderName = info?.name;
                                    if (senderName == null || senderName.isEmpty) {
                                      final profile = profiles?[senderId];
                                      senderName = profile?.name.isNotEmpty == true
                                          ? profile?.name
                                          : profile?.username;
                                    }
                                  }
                                  if (senderName != null && senderName.isNotEmpty) {
                                    final firstName = senderName.split(' ').first;
                                    enrichedRawLast = '$firstName: $rawLast';
                                  }
                                }
                                // Add thread indicator prefix.
                                if (c.data.lastMessageIsThread) {
                                  enrichedRawLast = '↩ $enrichedRawLast';
                                }
                              }
                              final subtitle =
                                  (draftLine != null && draftLine.isNotEmpty)
                                  ? l10nList.chat_list_item_draft_line(
                                      draftLine,
                                    )
                                  : (isNewlyCreatedAfterClear
                                        ? l10nList.chat_list_item_chat_created
                                        : (isEmptyConversation
                                              ? l10nList
                                                    .chat_list_item_no_messages_yet
                                              : isClearedForCurrentUser
                                              ? l10nList
                                                    .chat_list_item_history_cleared
                                              : enrichedRawLast));
                              final unreadCount =
                                  (c.data.unreadCounts?[widget.currentUserId] ??
                                      0) +
                                  (c.data.unreadThreadCounts?[widget
                                          .currentUserId] ??
                                      0);
                              final timeLabel = _formatTimeLabel(
                                c.data.lastMessageTimestamp,
                              );
                              // Determine unread reaction emoji badge.
                              String? unreadReactionEmoji;
                              if (c.data.lastReactionEmoji != null &&
                                  c.data.lastReactionEmoji!.isNotEmpty &&
                                  c.data.lastReactionSenderId != widget.currentUserId) {
                                final seenAt = c.data.lastReactionSeenAt?[widget.currentUserId];
                                final reactionTs = c.data.lastReactionTimestamp;
                                final seenDt = seenAt != null ? DateTime.tryParse(seenAt) : null;
                                final reactDt = reactionTs != null ? DateTime.tryParse(reactionTs) : null;
                                if (reactDt != null && (seenDt == null || seenDt.isBefore(reactDt))) {
                                  unreadReactionEmoji = c.data.lastReactionEmoji;
                                }
                              }
                              return ChatListItem(
                                conversation: c,
                                title: title,
                                subtitle: subtitle,
                                unreadCount: unreadCount,
                                trailingTimeLabel: timeLabel,
                                isPinned: _isPinnedInActiveFolder(c.id),
                                avatarUrl: avatarUrl,
                                isOnline: isOnline,
                                unreadReactionEmoji: unreadReactionEmoji,
                                onTap: () => context.push('/chats/${c.id}'),
                                onLongPress: () =>
                                    _openChatActionsMenu(context, c),
                                onFoldersTap: _isSavedConversation(c)
                                    ? null
                                    : () => _openChatFoldersDialog(context, c),
                                onClearTap: () => _clearChatHistory(context, c),
                                onDeleteTap:
                                    (!c.data.isGroup &&
                                        !_isSavedConversation(c))
                                    ? () => _deleteConversation(context, c)
                                    : null,
                                allowDelete:
                                    !c.data.isGroup && !_isSavedConversation(c),
                                enableSwipeActions: true,
                              );
                            },
                          ),
                    ),
                  ),
                  ChatBottomNav(
                    activeTab: ChatBottomNavTab.chats,
                    onChatsTap: () => context.go('/chats'),
                    onContactsTap: () => context.go('/contacts'),
                    onCallsTap: () => context.go('/calls'),
                    onMeetingsTap: () => context.go('/meetings'),
                    onProfileTap: () => context.push('/account'),
                    avatarUrl: selfAvatar,
                    userTitle: selfName,
                    bottomNavAppearance: bottomNavAppearance,
                    bottomNavIconNames: bottomNavIconNames,
                    bottomNavIconGlobalStyle: bottomNavGlobalStyle,
                    bottomNavIconStyles: bottomNavIconStyles,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState({
    required BuildContext context,
    required String title,
    required String description,
    required bool showCreateButton,
    required VoidCallback onCreateTap,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.35,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
            if (showCreateButton) ...[
              const SizedBox(height: 18),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF58D5E4), Color(0xFF7BE1C8)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF58D5E4).withValues(alpha: 0.24),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: onCreateTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 34,
                        vertical: 14,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.chat_list_action_create,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF123238),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _headerIconButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final dark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surface;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dark
                  ? Colors.white.withValues(alpha: 0.06)
                  : surface.withValues(alpha: 0.76),
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 23,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateFolderModal(
    BuildContext context, {
    required Map<String, UserProfile> profiles,
    required UserProfile? selfProfile,
    required Map<String, ContactLocalProfile> contactProfiles,
  }) async {
    final controller = TextEditingController();
    final searchController = TextEditingController();
    final focus = FocusNode();
    final searchFocus = FocusNode();
    final selectableChats = _buildFolderCandidates(
      profiles: profiles,
      selfProfile: selfProfile,
      contactProfiles: contactProfiles,
    );
    final selectedIds = <String>{};

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          final scheme = Theme.of(ctx).colorScheme;
          final dark = scheme.brightness == Brightness.dark;

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                24,
                12,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  final sheetL10n = AppLocalizations.of(ctx)!;
                  final modalBg = dark
                      ? const Color(0xFF0C0D11).withValues(alpha: 0.96)
                      : scheme.surfaceContainerHigh;
                  final modalFg = scheme.onSurface;
                  final query = searchController.text.trim().toLowerCase();
                  final filteredChats = selectableChats
                      .where((chat) {
                        if (query.isEmpty) return true;
                        return ruEnSubstringMatch(chat.title, query);
                      })
                      .toList(growable: false);
                  final canCreate =
                      controller.text.trim().isNotEmpty &&
                      selectedIds.isNotEmpty;

                  Future<void> submit() async {
                    if (!canCreate) return;
                    final repo = ref.read(chatFoldersRepositoryProvider);
                    if (repo == null) return;
                    final folderName = controller.text.trim();
                    final folderConversationIds = selectedIds.toList(
                      growable: false,
                    );
                    Navigator.of(ctx).pop();
                    try {
                      await repo.createFolder(
                        userId: widget.currentUserId,
                        name: folderName,
                        conversationIds: folderConversationIds,
                      );
                    } catch (e) {
                      if (!mounted) return;
                      final errL10n = AppLocalizations.of(this.context)!;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text(errL10n.chat_list_error_generic(e)),
                        ),
                      );
                    }
                  }

                  return Container(
                    constraints: BoxConstraints(
                      maxWidth: 760,
                      maxHeight: MediaQuery.of(ctx).size.height * 0.84,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: modalBg,
                      border: Border.all(
                        color: modalFg.withValues(alpha: dark ? 0.12 : 0.14),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: dark ? 0.35 : 0.14,
                          ),
                          blurRadius: dark ? 34 : 20,
                          offset: Offset(0, dark ? 18 : 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 86,
                                height: 86,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(
                                        0xFF2E86FF,
                                      ).withValues(alpha: 0.20),
                                      const Color(
                                        0xFF9A18FF,
                                      ).withValues(alpha: 0.18),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF2A79FF,
                                    ).withValues(alpha: 0.40),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF2A79FF,
                                      ).withValues(alpha: 0.22),
                                      blurRadius: 24,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.create_new_folder_rounded,
                                  size: 40,
                                  color: Color(0xFF5DA2FF),
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sheetL10n.chat_list_create_folder_title,
                                      style: TextStyle(
                                        fontSize: 28 / 2,
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      sheetL10n.chat_list_create_folder_subtitle,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.onSurface.withValues(
                                          alpha: dark ? 0.55 : 0.62,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Divider(
                            height: 1,
                            color: scheme.onSurface.withValues(
                              alpha: dark ? 0.12 : 0.20,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              sheetL10n.chat_list_create_folder_name_label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7,
                                color: scheme.onSurface.withValues(
                                  alpha: dark ? 0.50 : 0.56,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: controller,
                            focusNode: focus,
                            autofocus: true,
                            onChanged: (_) => setModalState(() {}),
                            textInputAction: TextInputAction.done,
                            textCapitalization: TextCapitalization.sentences,
                            cursorColor: scheme.primary,
                            cursorHeight: 18,
                            style: TextStyle(
                              color: modalFg,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)!
                                  .settings_chats_icon_picker_search_hint,
                              hintStyle: TextStyle(
                                color: modalFg.withValues(alpha: 0.36),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              filled: true,
                              fillColor: modalFg.withValues(
                                alpha: dark ? 0.06 : 0.05,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: modalFg.withValues(
                                    alpha: dark ? 0.16 : 0.18,
                                  ),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: modalFg.withValues(
                                    alpha: dark ? 0.16 : 0.18,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2A79FF),
                                  width: 1.4,
                                ),
                              ),
                            ),
                            onSubmitted: (_) => submit(),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  sheetL10n.chat_list_create_folder_chats_label(
                                    selectedIds.length,
                                  ),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.7,
                                    color: scheme.onSurface.withValues(
                                      alpha: dark ? 0.50 : 0.56,
                                    ),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: selectableChats.isEmpty
                                    ? null
                                    : () => setModalState(() {
                                        selectedIds
                                          ..clear()
                                          ..addAll(
                                            selectableChats.map((c) => c.id),
                                          );
                                      }),
                                child: Text(
                                  sheetL10n.chat_list_create_folder_select_all,
                                  style: const TextStyle(
                                    color: Color(0xFF2E86FF),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: selectedIds.isEmpty
                                    ? null
                                    : () => setModalState(selectedIds.clear),
                                child: Text(
                                  sheetL10n.chat_list_create_folder_reset,
                                  style: TextStyle(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.60,
                                    ),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: modalFg.withValues(
                                alpha: dark ? 0.06 : 0.05,
                              ),
                              border: Border.all(
                                color: modalFg.withValues(
                                  alpha: dark ? 0.10 : 0.12,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  size: 27,
                                  color: modalFg.withValues(alpha: 0.42),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: searchController,
                                    focusNode: searchFocus,
                                    onChanged: (_) => setModalState(() {}),
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    cursorColor: scheme.primary,
                                    cursorHeight: 18,
                                    style: TextStyle(
                                      color: modalFg,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlignVertical: TextAlignVertical.center,
                                    decoration: InputDecoration(
                                      hintText: sheetL10n
                                          .chat_list_create_folder_search_hint,
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                      hintStyle: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: modalFg.withValues(alpha: 0.40),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: filteredChats.isEmpty
                                ? Center(
                                    child: Text(
                                      sheetL10n
                                          .chat_list_create_folder_no_matches,
                                      style: TextStyle(
                                        color: modalFg.withValues(alpha: 0.56),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.zero,
                                    itemCount: filteredChats.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 18),
                                    itemBuilder: (context, index) {
                                      final chat = filteredChats[index];
                                      final selected = selectedIds.contains(
                                        chat.id,
                                      );
                                      return InkWell(
                                        onTap: () => setModalState(() {
                                          if (selected) {
                                            selectedIds.remove(chat.id);
                                          } else {
                                            selectedIds.add(chat.id);
                                          }
                                        }),
                                        borderRadius: BorderRadius.circular(18),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 2,
                                            vertical: 2,
                                          ),
                                          child: Row(
                                            children: [
                                              Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  CircleAvatar(
                                                    radius: 22,
                                                    backgroundColor: modalFg
                                                        .withValues(
                                                          alpha: 0.10,
                                                        ),
                                                    backgroundImage:
                                                        chat.avatarUrl ==
                                                                null ||
                                                            chat
                                                                .avatarUrl!
                                                                .isEmpty
                                                        ? null
                                                        : NetworkImage(
                                                            chat.avatarUrl!,
                                                          ),
                                                    child:
                                                        chat.avatarUrl ==
                                                                null ||
                                                            chat
                                                                .avatarUrl!
                                                                .isEmpty
                                                        ? Text(
                                                            _initials(
                                                              chat.title,
                                                            ),
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: modalFg,
                                                            ),
                                                          )
                                                        : null,
                                                  ),
                                                  Positioned(
                                                    right: -2,
                                                    top: -2,
                                                    child: AnimatedContainer(
                                                      duration: const Duration(
                                                        milliseconds: 180,
                                                      ),
                                                      width: 20,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: selected
                                                            ? const Color(
                                                                0xFF2E86FF,
                                                              )
                                                            : modalFg
                                                                  .withValues(
                                                                    alpha: 0.12,
                                                                  ),
                                                        border: Border.all(
                                                          color: selected
                                                              ? const Color(
                                                                  0xFF5DA2FF,
                                                                )
                                                              : modalFg
                                                                    .withValues(
                                                                      alpha:
                                                                          0.12,
                                                                    ),
                                                        ),
                                                      ),
                                                      child: selected
                                                          ? const Icon(
                                                              Icons
                                                                  .check_rounded,
                                                              size: 14,
                                                              color:
                                                                  Colors.white,
                                                            )
                                                          : null,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      chat.title,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: modalFg,
                                                      ),
                                                    ),
                                                    if (chat.subtitle != null &&
                                                        chat
                                                            .subtitle!
                                                            .isNotEmpty)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              top: 2,
                                                            ),
                                                        child: Text(
                                                          chat.subtitle!,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: modalFg
                                                                .withValues(
                                                                  alpha: 0.46,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 14),
                          Divider(
                            height: 1,
                            color: scheme.onSurface.withValues(
                              alpha: dark ? 0.12 : 0.20,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(58),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    foregroundColor: modalFg,
                                    backgroundColor: modalFg.withValues(
                                      alpha: dark ? 0.04 : 0.06,
                                    ),
                                    side: BorderSide(
                                      color: modalFg.withValues(
                                        alpha: dark ? 0.22 : 0.20,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    sheetL10n.common_cancel,
                                    style: TextStyle(
                                      color: modalFg,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Container(
                                  height: 58,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    gradient: canCreate
                                        ? const LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              Color(0xFF2E86FF),
                                              Color(0xFF5F90FF),
                                              Color(0xFF9A18FF),
                                            ],
                                          )
                                        : LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              scheme.onSurface.withValues(
                                                alpha: 0.14,
                                              ),
                                              scheme.onSurface.withValues(
                                                alpha: 0.14,
                                              ),
                                            ],
                                          ),
                                  ),
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    onPressed: canCreate ? submit : null,
                                    child: Text(
                                      sheetL10n.chat_list_action_create,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: canCreate
                                            ? Colors.white
                                            : modalFg.withValues(alpha: 0.40),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    } finally {
      controller.dispose();
      searchController.dispose();
      focus.dispose();
      searchFocus.dispose();
    }
  }

  List<_FolderCandidateChat> _buildFolderCandidates({
    required Map<String, UserProfile> profiles,
    required UserProfile? selfProfile,
    required Map<String, ContactLocalProfile> contactProfiles,
  }) {
    final uniqueByKey = <String, _FolderCandidateChat>{};
    int tsScore(ConversationWithId c) =>
        DateTime.tryParse(
          c.data.lastMessageTimestamp ?? '',
        )?.millisecondsSinceEpoch ??
        0;

    for (final c in widget.conversations) {
      if (isSavedMessagesConversation(c.data, widget.currentUserId)) continue;

      String title;
      String? subtitle;
      String? avatarUrl;
      String key;

      if (c.data.isGroup) {
        title = groupConversationDisplayTitle(c, l10n: AppLocalizations.of(context)!);
        subtitle = null;
        avatarUrl = c.data.photoUrl;
        key = 'conv:${c.id}';
      } else {
        final p = c.data.participantIds
            .where((id) => id.trim().isNotEmpty)
            .toList(growable: false);
        final other = p.firstWhere(
          (id) => id != widget.currentUserId,
          orElse: () => '',
        );
        final profile = profiles[other];
        title = dmConversationDisplayTitle(
          currentUserId: widget.currentUserId,
          conversation: c,
          otherUserId: other,
          profiles: profiles,
          contactProfiles: contactProfiles,
          l10n: AppLocalizations.of(context)!,
        );
        subtitle = _usernameLabel(profile?.username);
        avatarUrl =
            profile?.avatarThumb ??
            profile?.avatar ??
            c.data.participantInfo?[other]?.avatarThumb ??
            c.data.participantInfo?[other]?.avatar ??
            selfProfile?.avatarThumb;
        key = other.isEmpty ? 'conv:${c.id}' : 'dm:$other';
      }

      final candidate = _FolderCandidateChat(
        id: c.id,
        title: title,
        subtitle: subtitle,
        avatarUrl: avatarUrl,
        sortTs: tsScore(c),
      );
      final prev = uniqueByKey[key];
      if (prev == null || candidate.sortTs >= prev.sortTs) {
        uniqueByKey[key] = candidate;
      }
    }

    final list = uniqueByKey.values.toList(growable: false)
      ..sort((a, b) => b.sortTs.compareTo(a.sortTs));
    return list;
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  String? _usernameLabel(String? username) {
    final raw = (username ?? '').trim();
    if (raw.isEmpty) return null;
    return raw.startsWith('@') ? raw : '@$raw';
  }
}

class _FolderCandidateChat {
  const _FolderCandidateChat({
    required this.id,
    required this.title,
    required this.sortTs,
    this.subtitle,
    this.avatarUrl,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? avatarUrl;
  final int sortTs;
}

class _ChatMenuButton extends StatelessWidget {
  const _ChatMenuButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.labelColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = labelColor ?? Theme.of(context).colorScheme.onSurface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
