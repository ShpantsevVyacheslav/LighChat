import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ручная отправка push-уведомлений через CF `adminSendPush`.
///
/// Параметры: целевой uid (или `all` для broadcast — на бэке валидируется
/// роль), title, body, опциональные data-поля.
class AdminPushNotificationsScreen extends ConsumerStatefulWidget {
  const AdminPushNotificationsScreen({super.key});

  @override
  ConsumerState<AdminPushNotificationsScreen> createState() =>
      _AdminPushNotificationsScreenState();
}

class _AdminPushNotificationsScreenState
    extends ConsumerState<AdminPushNotificationsScreen> {
  final _uidCtrl = TextEditingController();
  final _titleCtrl = TextEditingController(text: 'LighChat');
  final _bodyCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  bool _busy = false;
  String? _lastResult;

  @override
  void dispose() {
    _uidCtrl.dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _uidCtrl,
              decoration: const InputDecoration(
                labelText: 'UID получателя (или "all" для broadcast)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Body',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _linkCtrl,
              decoration: const InputDecoration(
                labelText: 'Deep link (необязательно, lighchat://...)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: const Text('Отправить'),
              onPressed: _busy ? null : _send,
            ),
            if (_lastResult != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(_lastResult!),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    final uid = _uidCtrl.text.trim();
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (uid.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('UID и body обязательны')),
      );
      return;
    }
    setState(() {
      _busy = true;
      _lastResult = null;
    });
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('adminSendPush');
      final res = await callable.call<dynamic>({
        'uid': uid,
        'title': title,
        'body': body,
        if (_linkCtrl.text.trim().isNotEmpty)
          'data': {'link': _linkCtrl.text.trim()},
      });
      setState(() {
        _lastResult = 'OK: ${res.data}';
      });
    } catch (e) {
      setState(() {
        _lastResult = 'Ошибка: $e';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
