import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../../../l10n/app_localizations.dart';
import '../data/user_profile.dart';
import 'chat_partner_profile_sheet.dart';
import 'chat_shell_backdrop.dart';

class ChatContactProfileScreen extends ConsumerWidget {
  const ChatContactProfileScreen({super.key, required this.userId});

  final String userId;

  String _canonicalDirectChatId(String left, String right) {
    final ids = <String>[left.trim(), right.trim()]..sort();
    String part(String v) => '${v.length}:$v';
    return 'dm_${part(ids[0])}_${part(ids[1])}';
  }

  bool _isDirectForPair(Conversation data, String ownerId, String partnerId) {
    if (data.isGroup) return false;
    if (data.participantIds.length != 2) return false;
    return data.participantIds.contains(ownerId) &&
        data.participantIds.contains(partnerId);
  }

  int _conversationTimestampScore(Conversation data) {
    final raw = data.lastMessageTimestamp;
    if (raw == null || raw.trim().isEmpty) return 0;
    return DateTime.tryParse(raw)?.millisecondsSinceEpoch ?? 0;
  }

  ConversationWithId? _findDirectConversation({
    required List<ConversationWithId> conversations,
    required String ownerId,
    required String partnerId,
  }) {
    ConversationWithId? best;
    var bestScore = -1;
    for (final c in conversations) {
      if (!_isDirectForPair(c.data, ownerId, partnerId)) continue;
      final score = _conversationTimestampScore(c.data);
      if (best == null || score > bestScore) {
        best = c;
        bestScore = score;
      }
    }
    return best;
  }

  Conversation _buildFallbackDirectConversation({
    required String ownerId,
    required String partnerId,
    required UserProfile? selfProfile,
    required UserProfile? partnerProfile,
    required String fallbackUserLabel,
  }) {
    final selfName = (selfProfile?.name ?? '').trim().isNotEmpty
        ? selfProfile!.name.trim()
        : fallbackUserLabel;
    final peerName = (partnerProfile?.name ?? '').trim().isNotEmpty
        ? partnerProfile!.name.trim()
        : fallbackUserLabel;
    return Conversation(
      isGroup: false,
      participantIds: <String>[ownerId, partnerId],
      adminIds: const <String>[],
      participantInfo: <String, ConversationParticipantInfo>{
        ownerId: ConversationParticipantInfo(
          name: selfName,
          avatar: selfProfile?.avatar,
          avatarThumb: selfProfile?.avatarThumb,
        ),
        partnerId: ConversationParticipantInfo(
          name: peerName,
          avatar: partnerProfile?.avatar,
          avatarThumb: partnerProfile?.avatarThumb,
        ),
      },
      unreadCounts: <String, int>{ownerId: 0, partnerId: 0},
      unreadThreadCounts: <String, int>{ownerId: 0, partnerId: 0},
      lastMessageText: '',
      lastMessageTimestamp: null,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authUserProvider);
    final scheme = Theme.of(context).colorScheme;
    final shellBg = scheme.brightness == Brightness.dark
        ? const Color(0xFF04070C)
        : const Color(0xFFF3F6FC);
    return Scaffold(
      backgroundColor: shellBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ChatShellBackdrop(),
          SafeArea(
            child: authAsync.when(
              data: (authUser) {
                if (authUser == null) {
                  return const Center(child: CupertinoActivityIndicator());
                }
                final ownerId = authUser.uid;
                final profilesRepo = ref.watch(userProfilesRepositoryProvider);
                final profileStream = profilesRepo?.watchUsersByIds(<String>[
                  ownerId,
                  userId,
                ]);

                final indexAsync = ref.watch(userChatIndexProvider(ownerId));
                final conversationIds =
                    indexAsync.asData?.value?.conversationIds ??
                    const <String>[];
                final conversationsAsync = ref.watch(
                  conversationsProvider((
                    key: conversationIdsCacheKey(conversationIds),
                  )),
                );

                return StreamBuilder<Map<String, UserProfile>>(
                  stream: profileStream,
                  builder: (context, snap) {
                    final profileMap =
                        snap.data ?? const <String, UserProfile>{};
                    final selfProfile = profileMap[ownerId];
                    final partnerProfile = profileMap[userId];

                    final loadedConversations =
                        conversationsAsync.asData?.value ??
                        const <ConversationWithId>[];
                    final direct = _findDirectConversation(
                      conversations: loadedConversations,
                      ownerId: ownerId,
                      partnerId: userId,
                    );

                    final conversationId =
                        direct?.id ?? _canonicalDirectChatId(ownerId, userId);
                    final conversation =
                        direct?.data ??
                        _buildFallbackDirectConversation(
                          ownerId: ownerId,
                          partnerId: userId,
                          selfProfile: selfProfile,
                          partnerProfile: partnerProfile,
                          fallbackUserLabel: AppLocalizations.of(context)!.contact_profile_user_fallback,
                        );

                    return ChatPartnerProfileSheet(
                      conversationId: conversationId,
                      conversation: conversation,
                      currentUserId: ownerId,
                      selfProfile: selfProfile,
                      partnerProfile: partnerProfile,
                      fullScreen: true,
                      showChatsAction: true,
                    );
                  },
                );
              },
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (e, _) => Center(
                child: Text(
                  AppLocalizations.of(context)!.contact_profile_error(e.toString()),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
