import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../data/e2ee_data_type_policy.dart';

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
  bool _typesBusy = false;

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
          const SizedBox(height: 18),
          _E2eeDataTypesCard(
            conversationId: widget.conversationId,
            currentUserId: widget.currentUserId,
            busy: _typesBusy,
            onBusyChanged: (v) => setState(() => _typesBusy = v),
          ),
        ],
      ),
    );
  }
}

class _E2eeDataTypesCard extends StatefulWidget {
  const _E2eeDataTypesCard({
    required this.conversationId,
    required this.currentUserId,
    required this.busy,
    required this.onBusyChanged,
  });

  final String conversationId;
  final String currentUserId;
  final bool busy;
  final ValueChanged<bool> onBusyChanged;

  @override
  State<_E2eeDataTypesCard> createState() => _E2eeDataTypesCardState();
}

class _E2eeDataTypesCardState extends State<_E2eeDataTypesCard> {
  Future<E2eeDataTypePolicy> _loadGlobalPolicy() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .get();
    final raw = snap.data()?['privacySettings'];
    final m = raw is Map ? raw.map((k, v) => MapEntry(k.toString(), v)) : null;
    return E2eeDataTypePolicy.fromFirestore(m?['e2eeEncryptedDataTypes']);
  }

  Future<void> _setOverride(Map<String, Object?> patch) async {
    if (widget.busy) return;
    widget.onBusyChanged(true);
    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update(patch);
    } finally {
      if (mounted) widget.onBusyChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;

    return FutureBuilder<E2eeDataTypePolicy>(
      future: _loadGlobalPolicy(),
      builder: (context, globalSnap) {
        final global = globalSnap.data ?? E2eeDataTypePolicy.defaults;
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('conversations')
              .doc(widget.conversationId)
              .snapshots(),
          builder: (context, convSnap) {
            final data = convSnap.data?.data();
            final rawOverride = data?['e2eeEncryptedDataTypesOverride'];
            final override = rawOverride == null
                ? null
                : E2eeDataTypePolicy.fromFirestore(rawOverride);
            final hasOverride = rawOverride != null;
            final effective = resolveE2eeEffectivePolicy(
              global: global,
              override: override,
            );

            Widget row({
              required String title,
              required String subtitle,
              required bool value,
              required ValueChanged<bool> onChanged,
            }) {
              return SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: fg.withValues(alpha: 0.92),
                  ),
                ),
                subtitle: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.25,
                    color: fg.withValues(alpha: 0.62),
                  ),
                ),
                value: value,
                onChanged: widget.busy ? null : onChanged,
              );
            }

            return Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: (dark ? Colors.white : scheme.surface).withValues(
                  alpha: dark ? 0.05 : 0.82,
                ),
                border: Border.all(
                  color: fg.withValues(alpha: dark ? 0.12 : 0.10),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Типы данных',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: fg.withValues(alpha: 0.94),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Настройка не меняет протокол. Она управляет тем, какие типы данных отправлять в зашифрованном виде.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: fg.withValues(alpha: 0.62),
                    ),
                  ),
                  const SizedBox(height: 10),
                  row(
                    title: 'Переопределить для этого чата',
                    subtitle: hasOverride
                        ? 'Используются чатовые настройки.'
                        : 'Наследуются глобальные настройки.',
                    value: hasOverride,
                    onChanged: (on) async {
                      if (on) {
                        await _setOverride(<String, Object?>{
                          'e2eeEncryptedDataTypesOverride':
                              effective.toFirestoreMap(),
                        });
                      } else {
                        await _setOverride(<String, Object?>{
                          'e2eeEncryptedDataTypesOverride': null,
                        });
                      }
                    },
                  ),
                  const Divider(height: 18),
                  row(
                    title: 'Текст сообщений',
                    subtitle: 'Шифровать `message.e2ee.ciphertext`.',
                    value: effective.text,
                    onChanged: (v) async {
                      if (!hasOverride) return;
                      final next = effective.copyWith(text: v);
                      await _setOverride(<String, Object?>{
                        'e2eeEncryptedDataTypesOverride': next.toFirestoreMap(),
                      });
                    },
                  ),
                  row(
                    title: 'Вложения (медиа/файлы)',
                    subtitle:
                        'Шифровать `message.e2ee.attachments` (стикеры/GIF — всегда plaintext).',
                    value: effective.media,
                    onChanged: (v) async {
                      if (!hasOverride) return;
                      final next = effective.copyWith(media: v);
                      await _setOverride(<String, Object?>{
                        'e2eeEncryptedDataTypesOverride': next.toFirestoreMap(),
                      });
                    },
                  ),
                  row(
                    title: 'Reply-превью',
                    subtitle:
                        'Если выключить — не писать plaintext в `replyTo.text` и `mediaPreviewUrl`.',
                    value: effective.replyPreview,
                    onChanged: (v) async {
                      if (!hasOverride) return;
                      final next = effective.copyWith(replyPreview: v);
                      await _setOverride(<String, Object?>{
                        'e2eeEncryptedDataTypesOverride': next.toFirestoreMap(),
                      });
                    },
                  ),
                  if (!hasOverride) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Чтобы изменить для этого чата — включите «Переопределить».',
                      style: TextStyle(
                        fontSize: 12,
                        color: fg.withValues(alpha: 0.60),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

