import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../data/meeting_providers.dart';
import 'meeting_join_screen.dart';
import 'meeting_room_screen.dart';

/// Параметры, которые MeetingJoinScreen передаёт MeetingEntryScreen
/// при тапе «Enter room». Публичный класс, потому что используется
/// как тип callback'а в MeetingJoinScreen.
class MeetingRoomEntryArgs {
  const MeetingRoomEntryArgs({
    required this.name,
    required this.avatar,
    required this.avatarThumb,
    required this.role,
    required this.initialMicMuted,
    required this.initialCameraOff,
  });
  final String name;
  final String? avatar;
  final String? avatarThumb;
  final String? role;
  final bool initialMicMuted;
  final bool initialCameraOff;
}

/// Resolver-экран для `/meetings/:meetingId`.
///
/// Отвечает за «подготовку» пользователя к показу `MeetingJoinScreen`:
///   * если есть основной аккаунт — берём uid/displayName/photoURL;
///   * если аккаунта нет — делаем `signInAnonymously()` (гостевой режим)
///     и пробрасываем в join-экран пустое имя, чтобы пользователь ввёл сам.
///
/// ВАЖНО (архитектура): этот экран РЕНДЕРИТ MeetingJoinScreen ИЛИ
/// MeetingRoomScreen внутри одной GoRouter page'и через `setState`.
/// Никаких `Navigator.pushReplacement` от Join → Room.
///
/// Почему: GoRouter использует декларативный Pages API. Если делать
/// `Navigator.of(context).pushReplacement` в GoRouter-managed Navigator'е,
/// маршрут добавляется императивно, но при следующем rebuild GoRouter
/// сбрасывает Navigator pages к СВОЕЙ модели → imperative route
/// исчезает, а оригинальный JoinScreen «возвращается» в стек. Это
/// проявлялось как «утечка X+Join при /chats после back-arrow».
class MeetingEntryScreen extends ConsumerStatefulWidget {
  const MeetingEntryScreen({super.key, required this.meetingId});

  final String meetingId;

  @override
  ConsumerState<MeetingEntryScreen> createState() => _MeetingEntryScreenState();
}

class _MeetingEntryScreenState extends ConsumerState<MeetingEntryScreen> {
  late final Future<User> _signInFuture;

  /// `null` — пока пользователь в лобби (MeetingJoinScreen).
  /// Заполнено — пользователь нажал «Enter room»; рендерим RoomScreen.
  MeetingRoomEntryArgs? _roomArgs;

  @override
  void initState() {
    super.initState();
    _signInFuture = ref.read(meetingGuestAuthProvider).ensureSignedIn();
  }

  void _enterRoom(MeetingRoomEntryArgs args) {
    setState(() => _roomArgs = args);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<User>(
      future: _signInFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return _LoadingScreen(label: l10n.meeting_entry_connecting);
        }
        if (snap.hasError || snap.data == null) {
          return _ErrorScreen(
            message: l10n.meeting_entry_auth_failed(snap.error.toString()),
          );
        }
        final user = snap.data!;
        final args = _roomArgs;
        if (args != null) {
          return MeetingRoomScreen(
            meetingId: widget.meetingId,
            selfUid: user.uid,
            selfName: args.name,
            selfAvatar: args.avatar,
            selfAvatarThumb: args.avatarThumb,
            selfRole: args.role,
            initialMicMuted: args.initialMicMuted,
            initialCameraOff: args.initialCameraOff,
          );
        }
        final displayName = (user.displayName ?? '').trim();
        return MeetingJoinScreen(
          meetingId: widget.meetingId,
          selfUid: user.uid,
          isGuest: user.isAnonymous,
          initialName: displayName.isNotEmpty
              ? displayName
              : (user.isAnonymous ? '' : l10n.meeting_entry_participant_fallback),
          initialAvatar: user.photoURL,
          onEnterRoom: _enterRoom,
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(AppLocalizations.of(context)!.meeting_entry_back),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
