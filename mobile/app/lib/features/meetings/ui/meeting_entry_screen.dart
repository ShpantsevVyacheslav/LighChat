import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/meeting_providers.dart';
import 'meeting_join_screen.dart';

/// Resolver-экран для `/meetings/:meetingId`.
///
/// Отвечает за «подготовку» пользователя к показу `MeetingJoinScreen`:
///   * если есть основной аккаунт — берём uid/displayName/photoURL;
///   * если аккаунта нет — делаем `signInAnonymously()` (гостевой режим)
///     и пробрасываем в join-экран пустое имя, чтобы пользователь ввёл сам.
///
/// Отдельный screen позволяет прятать асинхронную авторизацию за единой
/// «загрузкой комнаты» и не плодить условия в самом `MeetingJoinScreen`.
class MeetingEntryScreen extends ConsumerStatefulWidget {
  const MeetingEntryScreen({super.key, required this.meetingId});

  final String meetingId;

  @override
  ConsumerState<MeetingEntryScreen> createState() => _MeetingEntryScreenState();
}

class _MeetingEntryScreenState extends ConsumerState<MeetingEntryScreen> {
  late final Future<User> _signInFuture;

  @override
  void initState() {
    super.initState();
    _signInFuture = ref.read(meetingGuestAuthProvider).ensureSignedIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: _signInFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const _LoadingScreen(label: 'Подключаемся к митингу…');
        }
        if (snap.hasError || snap.data == null) {
          return _ErrorScreen(message: 'Не удалось войти: ${snap.error}');
        }
        final user = snap.data!;
        final displayName = (user.displayName ?? '').trim();
        return MeetingJoinScreen(
          meetingId: widget.meetingId,
          selfUid: user.uid,
          initialName: displayName.isNotEmpty
              ? displayName
              : (user.isAnonymous ? '' : 'Участник'),
          initialAvatar: user.photoURL,
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
                child: const Text('Назад'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
