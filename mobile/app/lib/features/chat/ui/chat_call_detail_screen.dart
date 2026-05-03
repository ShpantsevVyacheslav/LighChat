import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../data/chat_call_formatting.dart';
import '../data/chat_call_status.dart';
import '../data/chat_calls_providers.dart';
import '../data/contact_display_name.dart';
import '../data/user_contacts_repository.dart';
import '../data/user_block_providers.dart';
import '../data/user_block_utils.dart';
import '../data/user_chat_policy.dart';
import '../data/user_profile.dart';
import 'chat_audio_call_screen.dart';
import 'chat_avatar.dart';
import 'chat_video_call_screen.dart';
import 'chat_shell_backdrop.dart';

/// Детали одного звонка (аналог веб-диалога «Сведения о звонке»).
class ChatCallDetailScreen extends ConsumerWidget {
  const ChatCallDetailScreen({super.key, required this.callId});

  final String callId;

  Future<void> _startCallFromDetail({
    required BuildContext context,
    required WidgetRef ref,
    required String currentUserId,
    required String currentUserName,
    required String? currentUserAvatarUrl,
    required String peerUserId,
    required String peerUserName,
    required String? peerAvatarUrl,
    required bool isVideo,
    UserProfile? selfProfile,
    UserProfile? peerProfile,
  }) async {
    final myAsync = ref.read(userBlockedUserIdsProvider(currentUserId));
    final theirAsync = ref.read(userBlockedUserIdsProvider(peerUserId));
    final self = selfProfile ??
        UserProfile(
          id: currentUserId,
          name: currentUserName.trim().isNotEmpty ? currentUserName : currentUserId,
        );
    final peer = peerProfile ??
        UserProfile(
          id: peerUserId,
          name: peerUserName.trim().isNotEmpty ? peerUserName : peerUserId,
        );
    if (!canStartDirectChat(
      self,
      peer,
      partnerBlockedIdsSupplement: theirAsync.asData?.value,
      partnerUserDocDenied: theirAsync.hasError,
    )) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            directCallBlockedMessageRu(
              l10n: AppLocalizations.of(context)!,
              viewerId: currentUserId,
              viewerBlockedIds: myAsync.value ?? const <String>[],
              partnerId: peerUserId,
              partnerBlockedIds: theirAsync.asData?.value ?? peer.blockedUserIds,
              partnerUserDocDenied: theirAsync.hasError,
            ),
          ),
        ),
      );
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => isVideo
            ? ChatVideoCallScreen(
                currentUserId: currentUserId,
                currentUserName: currentUserName,
                currentUserAvatarUrl: currentUserAvatarUrl,
                peerUserId: peerUserId,
                peerUserName: peerUserName,
                peerAvatarUrl: peerAvatarUrl,
              )
            : ChatAudioCallScreen(
                currentUserId: currentUserId,
                currentUserName: currentUserName,
                currentUserAvatarUrl: currentUserAvatarUrl,
                peerUserId: peerUserId,
                peerUserName: peerUserName,
                peerAvatarUrl: peerAvatarUrl,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callAsync = ref.watch(chatCallDocProvider(callId));
    final authUid = FirebaseAuth.instance.currentUser?.uid;

    return callAsync.when(
      data: (rawCall) {
        if (authUid == null || authUid.isEmpty) {
          return Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                const ChatShellBackdrop(),
                Center(child: Text(AppLocalizations.of(context)!.call_detail_login_required)),
              ],
            ),
          );
        }
        if (rawCall == null) {
          return Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                const ChatShellBackdrop(),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      AppLocalizations.of(context)!.call_detail_not_found,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final peerId = rawCall.callerId == authUid
            ? rawCall.receiverId
            : rawCall.callerId;
        final contactsAsync = ref.watch(userContactsIndexProvider(authUid));
        final contactProfiles =
            contactsAsync.asData?.value.contactProfiles ??
            const <String, ContactLocalProfile>{};
        final profilesRepo = ref.watch(userProfilesRepositoryProvider);
        final stream = profilesRepo != null
            ? profilesRepo.watchUsersByIds(<String>[authUid, peerId])
            : Stream.value(const <String, UserProfile>{});

        return StreamBuilder<Map<String, UserProfile>>(
          stream: stream,
          builder: (context, snap) {
            final profiles = snap.data ?? const <String, UserProfile>{};
            final peer = profiles[peerId];
            final self = profiles[authUid];
            final isOutgoing = rawCall.callerId == authUid;
            final fallbackPeerName = isOutgoing
                ? (rawCall.receiverName ?? '').trim()
                : rawCall.callerName.trim();
            final peerName = resolveContactDisplayName(
              contactProfiles: contactProfiles,
              contactUserId: peerId,
              fallbackName: peer?.name.trim().isNotEmpty == true
                  ? peer!.name.trim()
                  : (fallbackPeerName.isNotEmpty
                        ? fallbackPeerName
                        : AppLocalizations.of(context)!.call_detail_unknown),
            );
            final peerAvatar = peer?.avatarThumb ?? peer?.avatar;
            final meName = self?.name.trim().isNotEmpty == true
                ? self!.name.trim()
                : authUid;
            final meAvatar = self?.avatarThumb ?? self?.avatar;

            final scheme = Theme.of(context).colorScheme;
            final dark = scheme.brightness == Brightness.dark;
            final fg = dark ? Colors.white : scheme.onSurface;
            final muted = fg.withValues(alpha: 0.62);

            final createdLocal = rawCall.createdAt.toLocal();
            final dateLabel = formatCallDetailDateRu(createdLocal, AppLocalizations.of(context)!);
            final durationLabel =
                rawCall.startedAt != null &&
                    rawCall.endedAt != null &&
                    rawCall.endedAt!.isAfter(rawCall.startedAt!)
                ? formatCallDurationSeconds(
                    rawCall.endedAt!.difference(rawCall.startedAt!).inSeconds,
                    AppLocalizations.of(context)!,
                  )
                : null;

            final resolvedStatus = resolveCallTerminalStatusForViewer(
              rawStatus: rawCall.status,
              viewerIsReceiver: rawCall.receiverId == authUid,
              callerId: rawCall.callerId,
              receiverId: rawCall.receiverId,
              endedBy: rawCall.endedBy,
            );
            final statusChipText = callStatusLabel(resolvedStatus, AppLocalizations.of(context)!);
            final statusChipColor = resolvedStatus == 'missed'
                ? scheme.error
                : resolvedStatus == 'cancelled'
                ? scheme.onSurface.withValues(alpha: 0.42)
                : const Color(0xFF22C55E);

            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                foregroundColor: fg,
                title: Text(AppLocalizations.of(context)!.call_detail_title),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/calls');
                    }
                  },
                ),
              ),
              body: Stack(
                fit: StackFit.expand,
                children: [
                  const ChatShellBackdrop(),
                  SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                            child: Column(
                              children: [
                                ChatAvatar(
                                  title: peerName,
                                  radius: 48,
                                  avatarUrl: peerAvatar,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  peerName,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: fg,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _InfoChip(
                                      icon: rawCall.isVideo
                                          ? Icons.videocam_rounded
                                          : Icons.call_rounded,
                                      label: rawCall.isVideo
                                          ? AppLocalizations.of(context)!.call_detail_video
                                          : AppLocalizations.of(context)!.call_detail_audio,
                                      fg: fg,
                                    ),
                                    _InfoChip(
                                      icon: isOutgoing
                                          ? Icons.call_made_rounded
                                          : Icons.call_received_rounded,
                                      label: isOutgoing
                                          ? AppLocalizations.of(context)!.call_detail_outgoing
                                          : AppLocalizations.of(context)!.call_detail_incoming,
                                      fg: fg,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusChipColor,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        statusChipText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: fg.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Column(
                                    children: [
                                      _LabeledRow(
                                        icon: Icons.calendar_today_outlined,
                                        label: AppLocalizations.of(context)!.call_detail_date_label,
                                        value: dateLabel,
                                        fg: fg,
                                        muted: muted,
                                      ),
                                      if (durationLabel != null) ...[
                                        const Divider(height: 20),
                                        _LabeledRow(
                                          icon: Icons.schedule_rounded,
                                          label: AppLocalizations.of(context)!.call_detail_duration_label,
                                          value: durationLabel,
                                          fg: scheme.primary,
                                          muted: muted,
                                          valueBold: true,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 22),
                                Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          unawaited(
                                            _startCallFromDetail(
                                              context: context,
                                              ref: ref,
                                              currentUserId: authUid,
                                              currentUserName: meName,
                                              currentUserAvatarUrl: meAvatar,
                                              peerUserId: peerId,
                                              peerUserName: peerName,
                                              peerAvatarUrl: peerAvatar,
                                              isVideo: false,
                                              selfProfile: self,
                                              peerProfile: peer,
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.call_rounded),
                                        label: Text(AppLocalizations.of(context)!.call_detail_call_button),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FilledButton.tonalIcon(
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          unawaited(
                                            _startCallFromDetail(
                                              context: context,
                                              ref: ref,
                                              currentUserId: authUid,
                                              currentUserName: meName,
                                              currentUserAvatarUrl: meAvatar,
                                              peerUserId: peerId,
                                              peerUserName: peerName,
                                              peerAvatarUrl: peerAvatar,
                                              isVideo: true,
                                              selfProfile: self,
                                              peerProfile: peer,
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.videocam_rounded,
                                        ),
                                        label: Text(AppLocalizations.of(context)!.call_detail_video_button),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const ChatShellBackdrop(),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
      error: (e, _) => Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const ChatShellBackdrop(),
            Center(child: Text(AppLocalizations.of(context)!.call_detail_error(e.toString()))),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, required this.fg});

  final IconData icon;
  final String label;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg.withValues(alpha: 0.85)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledRow extends StatelessWidget {
  const _LabeledRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.fg,
    required this.muted,
    this.valueBold = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color fg;
  final Color muted;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: TextStyle(color: muted, fontSize: 14)),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: valueBold ? FontWeight.w800 : FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ],
    );
  }
}
