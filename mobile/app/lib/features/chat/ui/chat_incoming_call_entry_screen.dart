import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/chat_calls_providers.dart';
import 'chat_audio_call_screen.dart';
import 'chat_shell_backdrop.dart';
import 'chat_video_call_screen.dart';

/// Route target for native incoming-call actions (`/calls/incoming/:callId`).
///
/// Loads `calls/{callId}` and opens the correct audio/video call screen with
/// `existingCallId`, so accept from CallKit/full-screen notification enters
/// the active call flow directly.
class ChatIncomingCallEntryScreen extends ConsumerStatefulWidget {
  const ChatIncomingCallEntryScreen({super.key, required this.callId});

  final String callId;

  @override
  ConsumerState<ChatIncomingCallEntryScreen> createState() =>
      _ChatIncomingCallEntryScreenState();
}

class _ChatIncomingCallEntryScreenState
    extends ConsumerState<ChatIncomingCallEntryScreen> {
  bool _opening = false;
  String? _openedCallId;

  Future<void> _openCallIfReady({
    required String callId,
    required String currentUserId,
    required String currentUserName,
    required String peerUserId,
    required String peerUserName,
    required bool isVideo,
  }) async {
    if (_opening || _openedCallId == callId) return;
    _opening = true;
    _openedCallId = callId;

    final route = MaterialPageRoute<void>(
      builder: (_) => isVideo
          ? ChatVideoCallScreen(
              currentUserId: currentUserId,
              currentUserName: currentUserName,
              peerUserId: peerUserId,
              peerUserName: peerUserName,
              existingCallId: callId,
            )
          : ChatAudioCallScreen(
              currentUserId: currentUserId,
              currentUserName: currentUserName,
              peerUserId: peerUserId,
              peerUserName: peerUserName,
              existingCallId: callId,
            ),
    );

    await Navigator.of(context).pushReplacement<void, void>(route);
    if (mounted) {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    final callAsync = ref.watch(chatCallDocProvider(widget.callId));

    return callAsync.when(
      data: (call) {
        if (authUid == null || authUid.trim().isEmpty) {
          return const _IncomingStateBody(
            title: 'Необходим вход',
            subtitle: 'Откройте приложение и войдите в аккаунт.',
          );
        }
        if (call == null) {
          return _IncomingStateBody(
            title: 'Звонок не найден',
            subtitle: 'Вызов уже завершён или удалён.',
            actionLabel: 'К звонкам',
            onAction: () => context.go('/calls'),
          );
        }
        if (call.status == 'rejected' || call.status == 'ended') {
          return _IncomingStateBody(
            title: 'Звонок завершён',
            subtitle: 'Этот вызов уже недоступен.',
            actionLabel: 'К звонкам',
            onAction: () => context.go('/calls'),
          );
        }

        final meIsCaller = call.callerId == authUid;
        final peerUserId = meIsCaller ? call.receiverId : call.callerId;
        final peerUserName = meIsCaller
            ? ((call.receiverName?.trim().isNotEmpty ?? false)
                  ? call.receiverName!.trim()
                  : 'Собеседник')
            : call.callerName.trim().isNotEmpty
            ? call.callerName.trim()
            : 'Собеседник';
        final currentUserName = meIsCaller
            ? (call.callerName.trim().isNotEmpty
                  ? call.callerName.trim()
                  : authUid)
            : ((call.receiverName?.trim().isNotEmpty ?? false)
                  ? call.receiverName!.trim()
                  : authUid);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          unawaited(
            _openCallIfReady(
              callId: call.id,
              currentUserId: authUid,
              currentUserName: currentUserName,
              peerUserId: peerUserId,
              peerUserName: peerUserName,
              isVideo: call.isVideo,
            ),
          );
        });

        return _IncomingStateBody(
          title: 'Открываем звонок…',
          subtitle: call.isVideo
              ? 'Подключение к видеозвонку'
              : 'Подключение к аудиозвонку',
          loading: true,
        );
      },
      loading: () => const _IncomingStateBody(
        title: 'Открываем звонок…',
        subtitle: 'Загрузка данных вызова',
        loading: true,
      ),
      error: (e, _) => _IncomingStateBody(
        title: 'Ошибка открытия звонка',
        subtitle: '$e',
        actionLabel: 'К звонкам',
        onAction: () => context.go('/calls'),
      ),
    );
  }
}

class _IncomingStateBody extends StatelessWidget {
  const _IncomingStateBody({
    required this.title,
    required this.subtitle,
    this.loading = false,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final bool loading;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ChatShellBackdrop(),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 14),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: dark ? Colors.white : scheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: (dark ? Colors.white : scheme.onSurface)
                            .withValues(alpha: 0.72),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: onAction,
                        child: Text(actionLabel!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
