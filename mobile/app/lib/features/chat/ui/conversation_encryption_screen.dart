import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:lighchat_models/lighchat_models.dart';

/// Экран включения / отключения сквозного шифрования для конкретного личного чата.
class ConversationEncryptionScreen extends StatefulWidget {
  const ConversationEncryptionScreen({
    super.key,
    required this.conversationId,
    required this.currentUserId,
    required this.conversation,
  });

  final String conversationId;
  final String currentUserId;
  final Conversation conversation;

  @override
  State<ConversationEncryptionScreen> createState() =>
      _ConversationEncryptionScreenState();
}

class _ConversationEncryptionScreenState
    extends State<ConversationEncryptionScreen> {
  bool _busy = false;

  bool get _e2eeOn =>
      widget.conversation.e2eeEnabled == true &&
      (widget.conversation.e2eeKeyEpoch ?? 0) > 0;

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _enable() async {
    if (_busy || _e2eeOn) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: const Text('Включить шифрование?'),
          content: Text(
            'Новые сообщения будут доступны только на ваших устройствах и у собеседника. '
            'Старые сообщения останутся как есть.',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.85),
              height: 1.35,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Включить'),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final identity = await getOrCreateMobileDeviceIdentity();
      final did = await tryAutoEnableE2eeNewDirectChatMobile(
        firestore: firestore,
        conversationId: widget.conversationId,
        currentUserId: widget.currentUserId,
        identity: identity,
        options: const AutoEnableE2eeOptions(
          userWants: true,
          platformWants: true,
        ),
      );
      if (!mounted) return;
      if (did) {
        _toast('Шифрование включено');
      } else {
        _toast(
          'Шифрование уже включено или не удалось создать ключи. '
          'Проверьте сеть и наличие ключей у собеседника.',
        );
      }
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final s = e.toString();
      if (s.contains('E2EE_NO_DEVICE')) {
        _toast(
          'Не удалось включить: у собеседника нет активного устройства с ключом.',
        );
      } else {
        _toast('Не удалось включить шифрование: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disable() async {
    if (_busy || !_e2eeOn) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: const Text('Отключить шифрование?'),
          content: Text(
            'Новые сообщения пойдут без сквозного шифрования. '
            'Ранее отправленные зашифрованные сообщения останутся в ленте.',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.85),
              height: 1.35,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Отключить'),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      // Читаем старую epoch до update, чтобы положить её в system-event.
      // Если чтение упало — divider всё равно отрендерим, просто без epoch.
      var previousEpoch = 0;
      try {
        final snap = await FirebaseFirestore.instance
            .collection('conversations')
            .doc(widget.conversationId)
            .get();
        final raw = snap.data();
        final v = raw?['e2eeKeyEpoch'];
        if (v is int) previousEpoch = v;
        if (v is num) previousEpoch = v.toInt();
      } catch (_) {}

      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update(<String, Object?>{
            'e2eeEnabled': false,
            'e2eeKeyEpoch': 0,
          });

      // Публикуем divider «Сквозное шифрование отключено». Ошибку ловим:
      // маркер — cosmetic, не должен откатывать сам disable.
      try {
        await ChatSystemEventFactories.e2eeDisabled(
          firestore: FirebaseFirestore.instance,
          conversationId: widget.conversationId,
          previousEpoch: previousEpoch,
          actorUserId: widget.currentUserId,
        );
      } catch (_) {}

      if (!mounted) return;
      _toast('Шифрование отключено');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _toast('Не удалось отключить: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = _e2eeOn;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Шифрование'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            on
                ? 'Сквозное шифрование включено для этого чата.'
                : 'Сквозное шифрование выключено.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.92),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Когда шифрование включено, содержимое новых сообщений доступно '
            'только участникам чата на их устройствах. Отключение влияет только '
            'на новые сообщения.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: scheme.onSurface.withValues(alpha: 0.68),
            ),
          ),
          const SizedBox(height: 28),
          if (_busy)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (on)
            FilledButton.tonal(
              onPressed: _disable,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('Отключить шифрование'),
              ),
            )
          else
            FilledButton(
              onPressed: _enable,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('Включить шифрование'),
              ),
            ),
        ],
      ),
    );
  }
}
