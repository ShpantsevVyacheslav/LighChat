import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/meeting_models.dart';
import '../data/meeting_providers.dart';
import 'meeting_room_screen.dart';

/// Pre-join screen: вход в приватный митинг (waiting room) или прямой джойн
/// в публичный. Поддерживает два сценария:
///
/// 1. Залогиненный пользователь (`FirebaseAuth.currentUser != null, isAnonymous == false`):
///    берём его имя/аватар из параметра `currentUser*`.
/// 2. Гость (`isAnonymous == true`): `MeetingJoinScreen` обязательно вызывается с
///    заранее подписанным анонимным `selfUid`, имя вводит пользователь; аватар
///    генерируется DiceBear-URL как в вебе.
///
/// В `initState` выбираем путь по `meeting.isPrivate`: для приватного открываем
/// waiting-room, для публичного — сразу пропускаем на `MeetingRoomScreen`.
class MeetingJoinScreen extends ConsumerStatefulWidget {
  const MeetingJoinScreen({
    super.key,
    required this.meetingId,
    required this.selfUid,
    this.initialName,
    this.initialAvatar,
    this.initialAvatarThumb,
    this.role,
  });

  final String meetingId;
  final String selfUid;
  final String? initialName;
  final String? initialAvatar;
  final String? initialAvatarThumb;
  final String? role;

  @override
  ConsumerState<MeetingJoinScreen> createState() => _MeetingJoinScreenState();
}

class _MeetingJoinScreenState extends ConsumerState<MeetingJoinScreen> {
  late final TextEditingController _nameCtrl;
  late final String _requestId;
  bool _requestSubmitted = false;
  bool _sendingRequest = false;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _requestId = _generateRequestId();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _generateRequestId() {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random.secure();
    final buf = StringBuffer();
    for (var i = 0; i < 10; i++) {
      buf.write(alphabet[rnd.nextInt(alphabet.length)]);
    }
    return buf.toString();
  }

  String _avatarUrl() {
    return widget.initialAvatar ??
        'https://api.dicebear.com/7.x/avataaars/svg?seed=${widget.selfUid}';
  }

  Future<void> _submitRequest() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _lastError = 'Укажите имя');
      return;
    }
    setState(() {
      _sendingRequest = true;
      _lastError = null;
    });
    try {
      await ref.read(meetingCallablesProvider).requestMeetingAccess(
            meetingId: widget.meetingId,
            name: name,
            avatar: _avatarUrl(),
            requestId: _requestId,
          );
      if (!mounted) return;
      setState(() {
        _requestSubmitted = true;
        _sendingRequest = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sendingRequest = false;
        _lastError = e.toString();
      });
    }
  }

  void _goToRoom() {
    final name = _nameCtrl.text.trim().isEmpty
        ? (widget.initialName ?? 'Гость')
        : _nameCtrl.text.trim();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => MeetingRoomScreen(
          meetingId: widget.meetingId,
          selfUid: widget.selfUid,
          selfName: name,
          selfAvatar: _avatarUrl(),
          selfAvatarThumb: widget.initialAvatarThumb,
          selfRole: widget.role,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meetingAsync = ref.watch(meetingDocProvider(widget.meetingId));
    final ownRequestAsync = ref.watch(
      meetingOwnRequestProvider(
        MeetingOwnRequestKey(
          meetingId: widget.meetingId,
          userId: widget.selfUid,
        ),
      ),
    );

    // Если гость уже одобрен — сразу переходим в комнату.
    final ownRequest = ownRequestAsync.asData?.value;
    if (_requestSubmitted && ownRequest?.status == 'approved') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _goToRoom();
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Присоединиться',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: meetingAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (e, _) => _error('Ошибка загрузки митинга: $e'),
        data: (meeting) {
          if (meeting == null) {
            return _error('Митинг не найден или закрыт');
          }
          return Padding(
            padding: const EdgeInsets.all(24),
            child: _body(context, meeting, ownRequest),
          );
        },
      ),
    );
  }

  Widget _body(
    BuildContext context,
    MeetingDoc meeting,
    MeetingRequestDoc? ownRequest,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          meeting.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          meeting.isPrivate
              ? 'Приватная встреча: после заявки хост решит, пустить ли вас.'
              : 'Открытая встреча: присоединяйтесь по ссылке без ожидания.',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Ваше имя',
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (_lastError != null) ...[
          const SizedBox(height: 8),
          Text(
            _lastError!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ],
        const SizedBox(height: 20),
        if (meeting.isPrivate && !meeting.isAdmin(widget.selfUid))
          _privateJoinFlow(ownRequest)
        else
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _goToRoom,
            child: const Text(
              'Войти в комнату',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _privateJoinFlow(MeetingRequestDoc? ownRequest) {
    if (!_requestSubmitted) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: _sendingRequest ? null : _submitRequest,
        child: _sendingRequest
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Попросить присоединиться',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      );
    }
    final status = ownRequest?.status ?? 'pending';
    if (status == 'approved') {
      return const _StatusBanner(
        icon: Icons.check_circle_rounded,
        color: Color(0xFF34D399),
        title: 'Одобрено',
        subtitle: 'Перенаправляем в комнату…',
      );
    }
    if (status == 'denied') {
      return Column(
        children: const [
          _StatusBanner(
            icon: Icons.block_rounded,
            color: Colors.redAccent,
            title: 'Отклонено',
            subtitle: 'Хост отклонил вашу заявку.',
          ),
        ],
      );
    }
    return const _StatusBanner(
      icon: Icons.hourglass_top_rounded,
      color: Color(0xFFF59E0B),
      title: 'Ожидаем подтверждения',
      subtitle: 'Хост увидит вашу заявку и решит, когда впустить.',
    );
  }

  Widget _error(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
