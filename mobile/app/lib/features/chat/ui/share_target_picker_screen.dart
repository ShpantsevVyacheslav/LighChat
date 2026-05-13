import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_mobile/app_providers.dart';

import '../../../l10n/app_localizations.dart';
import '../../../platform/native_nav_bar/nav_bar_config.dart';
import '../../../platform/native_nav_bar/native_nav_scaffold.dart';
import '../data/forward_recipients.dart';
import '../data/share_intent_payload.dart';
import '../data/user_profile.dart';
import 'chat_avatar.dart';

/// Экран выбора чата при системном «Поделиться в LighChat».
///
/// Отдельный от [ChatForwardScreen]: payload — это произвольные
/// файлы/текст из внешнего приложения (не пересылка `ChatMessage`),
/// и поведение — single‑select tap-to-open вместо мульти‑select bulk.
/// Список получателей строится тем же [buildForwardRecipientRows], что
/// гарантирует одинаковый порядок и фильтрацию.
class ShareTargetPickerScreen extends ConsumerStatefulWidget {
  const ShareTargetPickerScreen({super.key, required this.payload});

  final ShareIntentPayload payload;

  @override
  ConsumerState<ShareTargetPickerScreen> createState() =>
      _ShareTargetPickerScreenState();
}

class _ShareTargetPickerScreenState
    extends ConsumerState<ShareTargetPickerScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openChat(String conversationId) {
    if (conversationId.isEmpty) return;
    // Заменяем /share в стеке (а не push), чтобы при `Back` пользователь
    // не возвращался на picker, а уходил из приложения / в предыдущее окно.
    context.pushReplacement('/chats/$conversationId', extra: widget.payload);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userAsync = ref.watch(authUserProvider);

    if (widget.payload.isEmpty) {
      return NativeNavScaffold(
        top: NavBarTopConfig(title: NavBarTitle(title: l10n.share_picker_title)),
        onBack: () => Navigator.of(context).pop(),
        body: Center(child: Text(l10n.share_picker_empty_payload)),
      );
    }

    return NativeNavScaffold(
      top: NavBarTopConfig(
        title: NavBarTitle(
          title: l10n.share_picker_title,
          subtitle: _payloadSummary(l10n),
        ),
      ),
      onBack: () => Navigator.of(context).pop(),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(child: Text(l10n.forward_error_not_authorized));
          }
          final uid = user.uid;
          final contactsAsync = ref.watch(userContactsIndexProvider(uid));
          final indexAsync = ref.watch(userChatIndexProvider(uid));
          return contactsAsync.when(
            skipLoadingOnReload: true,
            data: (contacts) {
              final allowedPeers = contacts.contactIds
                  .where((id) => id.isNotEmpty && id != uid)
                  .toSet();
              return indexAsync.when(
                skipLoadingOnReload: true,
                data: (idx) {
                  final ids = idx?.conversationIds ?? const <String>[];
                  if (ids.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.forward_empty_no_recipients,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  final convAsync = ref.watch(
                    conversationsProvider((key: conversationIdsCacheKey(ids))),
                  );
                  return convAsync.when(
                    skipLoadingOnReload: true,
                    data: (convs) {
                      final profileIds = <String>{uid, ...allowedPeers};
                      for (final c in convs) {
                        for (final p in c.data.participantIds) {
                          if (p.isNotEmpty) profileIds.add(p);
                        }
                      }
                      final profilesRepo = ref.watch(
                        userProfilesRepositoryProvider,
                      );
                      final stream =
                          profilesRepo?.watchUsersByIds(profileIds.toList()) ??
                          Stream.value(const <String, UserProfile>{});
                      return StreamBuilder<Map<String, UserProfile>>(
                        stream: stream,
                        builder: (context, snap) {
                          final profiles =
                              snap.data ?? const <String, UserProfile>{};
                          final rows = buildForwardRecipientRows(
                            l10n: l10n,
                            currentUserId: uid,
                            convs: convs,
                            allowedPeerIds: allowedPeers,
                            profiles: profiles,
                            contactProfiles: contacts.contactProfiles,
                          );
                          // Phase 1 (MVP): шеринг только в существующие
                          // чаты — для contactOnly нужен createOrOpenDirectChat
                          // + профили обоих сторон, что усложняет poll
                          // bridge. Добавим в Phase B-2 при необходимости.
                          final eligible = rows
                              .where((r) => r.conversation != null)
                              .toList();
                          final q = _search.text.trim().toLowerCase();
                          final filtered = q.isEmpty
                              ? eligible
                              : eligible.where((r) {
                                  bool m(String? s) =>
                                      (s ?? '').toLowerCase().contains(q);
                                  return m(r.displayName) ||
                                      m(r.subtitle) ||
                                      m(r.username);
                                }).toList();
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12, 4, 12, 8,
                                ),
                                child: TextField(
                                  controller: _search,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.search),
                                    hintText: l10n.forward_search_hint,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    isDense: true,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              Expanded(
                                child: filtered.isEmpty
                                    ? Center(
                                        child: Text(
                                          eligible.isEmpty
                                              ? l10n
                                                  .forward_empty_no_available_recipients
                                              : l10n.forward_empty_not_found,
                                          textAlign: TextAlign.center,
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: filtered.length,
                                        itemBuilder: (context, i) {
                                          final r = filtered[i];
                                          return ListTile(
                                            leading: ChatAvatar(
                                              avatarUrl: r.avatarUrl,
                                              title: r.displayName,
                                              radius: 22,
                                            ),
                                            title: Text(
                                              r.displayName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            subtitle: r.subtitle.isEmpty
                                                ? null
                                                : Text(
                                                    r.subtitle,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                            onTap: () => _openChat(
                                              r.conversation!.id,
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (e, _) => Center(
                      child: Text(l10n.chat_conversation_error(e)),
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (e, _) => Center(
                  child: Text(l10n.chat_conversation_error(e)),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(l10n.chat_conversation_error(e)),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.chat_auth_error(e))),
      ),
    );
  }

  String _payloadSummary(AppLocalizations l10n) {
    final n = widget.payload.files.length;
    final hasText = (widget.payload.text ?? '').trim().isNotEmpty;
    if (n == 0 && hasText) return l10n.share_picker_summary_text_only;
    if (n > 0 && !hasText) return l10n.share_picker_summary_files_count(n);
    return l10n.share_picker_summary_files_with_text(n);
  }
}
