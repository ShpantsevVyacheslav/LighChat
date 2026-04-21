/// Экран "Мои устройства" (E2EE v2) для мобайла. Паритет web
/// `src/components/settings/DevicesPanel.tsx`.
///
/// Возможности:
///  - список активных и revoked устройств (`users/{uid}/e2eeDevices`);
///  - badge "Это устройство";
///  - короткий fingerprint (24 hex символа от SHA-256(publicKeySpki));
///  - rename (inline-диалог);
///  - revoke — запускает клиентскую ротацию эпох во всех E2EE-чатах пользователя
///    с прогрессом; ошибки по отдельным чатам не прерывают общий процесс.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:lighchat_mobile/app_providers.dart';

import '../../auth/ui/auth_glass.dart';
import '../../shared/ui/app_back_button.dart';

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  List<E2eeDeviceDoc>? _devices;
  MobileDeviceIdentityV2? _identity;
  String? _loadError;
  bool _revoking = false;
  int _progressDone = 0;
  int _progressTotal = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final firestore = FirebaseFirestore.instance;
    final user = await ref.read(authUserProvider.future);
    if (user == null) return;
    try {
      final identity = await getOrCreateMobileDeviceIdentity();
      await publishMobileDevice(
        firestore: firestore,
        userId: user.uid,
        identity: identity,
      );
      if (!mounted) return;
      setState(() => _identity = identity);
      await _loadDevices(user.uid);
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    }
  }

  Future<void> _loadDevices(String uid) async {
    try {
      final list = await listAllMobileDevices(
        firestore: FirebaseFirestore.instance,
        userId: uid,
      );
      list.sort((a, b) {
        final ar = a.revoked ? 1 : 0;
        final br = b.revoked ? 1 : 0;
        if (ar != br) return ar - br;
        return b.lastSeenAt.compareTo(a.lastSeenAt);
      });
      if (mounted) {
        setState(() {
          _devices = list;
          _loadError = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    }
  }

  String _shortFingerprint(String spkiB64) {
    try {
      final bytes = base64.decode(spkiB64);
      final hash = sha256.convert(Uint8List.fromList(bytes));
      final hex = hash.toString();
      final head = hex.substring(0, 24).toUpperCase();
      final buf = StringBuffer();
      for (var i = 0; i < head.length; i += 4) {
        if (i > 0) buf.write(' ');
        buf.write(head.substring(i, i + 4));
      }
      return buf.toString();
    } catch (_) {
      return '';
    }
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final local = dt.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _onRename(E2eeDeviceDoc d) async {
    final user = await ref.read(authUserProvider.future);
    if (user == null) return;
    if (!mounted) return;
    final controller = TextEditingController(text: d.label);
    final newLabel = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Переименовать устройство'),
          content: TextField(
            controller: controller,
            maxLength: 120,
            decoration: const InputDecoration(
              hintText: 'Например, iPhone 15 — Safari',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
    if (newLabel == null || newLabel.isEmpty) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await renameMobileDevice(
        firestore: FirebaseFirestore.instance,
        userId: user.uid,
        deviceId: d.deviceId,
        newLabel: newLabel,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Переименовано')),
      );
      await _loadDevices(user.uid);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Не удалось переименовать: $e')),
      );
    }
  }

  Future<void> _onRevoke(E2eeDeviceDoc d) async {
    final user = await ref.read(authUserProvider.future);
    if (user == null) return;
    final identity = _identity;
    if (identity == null) return;
    if (!mounted) return;

    final isCurrent = identity.deviceId == d.deviceId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Отозвать устройство?'),
        content: Text(
          isCurrent
              ? 'Вы собираетесь отозвать ТЕКУЩЕЕ устройство. После этого вы не сможете читать новые сообщения в зашифрованных чатах с этого клиента.'
              : 'Устройство больше не сможет читать новые сообщения в зашифрованных чатах. Старые сообщения останутся доступны на нём.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Отозвать'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _revoking = true;
      _progressDone = 0;
      _progressTotal = 0;
    });
    try {
      final result = await revokeDeviceAndRekeyMobile(
        firestore: FirebaseFirestore.instance,
        userId: user.uid,
        revokerIdentity: identity,
        deviceIdToRevoke: d.deviceId,
        onProgress: (entry, done, total) {
          if (!mounted) return;
          setState(() {
            _progressDone = done;
            _progressTotal = total;
          });
        },
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Устройство отозвано. Обновлено чатов: ${result.rekeyed}'
            '${result.failed > 0 ? ', ошибок: ${result.failed}' : ''}',
          ),
        ),
      );
      await _loadDevices(user.uid);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Ошибка revoke: $e')),
      );
    } finally {
      if (mounted) setState(() => _revoking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 2),
              const Row(
                children: [
                  AppBackButton(fallbackLocation: '/settings/privacy'),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Мои устройства',
                        style: TextStyle(
                          fontSize: 38,
                          height: 1.06,
                          fontWeight: FontWeight.w800,
                          color: dark ? Colors.white : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Список устройств, на которых опубликован ваш публичный ключ шифрования. Отзыв автоматически создаёт новую эпоху ключей во всех зашифрованных чатах — отозванное устройство больше не увидит новые сообщения.',
                        style: TextStyle(
                          fontSize: 16,
                          color: dark
                              ? Colors.white.withValues(alpha: 0.7)
                              : scheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_loadError != null)
                        Text(
                          _loadError!,
                          style: TextStyle(color: scheme.error),
                        ),
                      if (_devices == null && _loadError == null)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      if (_devices != null && _devices!.isEmpty)
                        Text(
                          'Устройств пока нет.',
                          style: TextStyle(
                            color: dark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      if (_devices != null)
                        for (final d in _devices!)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _DeviceCard(
                              device: d,
                              isCurrent:
                                  _identity?.deviceId == d.deviceId,
                              fingerprint:
                                  _shortFingerprint(d.publicKeySpkiB64),
                              createdAt: _formatDate(d.createdAt),
                              lastSeenAt: _formatDate(d.lastSeenAt),
                              onRename: () => _onRename(d),
                              onRevoke: _revoking ? null : () => _onRevoke(d),
                            ),
                          ),
                      if (_revoking && _progressTotal > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Обновление чатов: $_progressDone / $_progressTotal',
                                style: TextStyle(
                                  color: dark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.device,
    required this.isCurrent,
    required this.fingerprint,
    required this.createdAt,
    required this.lastSeenAt,
    required this.onRename,
    required this.onRevoke,
  });

  final E2eeDeviceDoc device;
  final bool isCurrent;
  final String fingerprint;
  final String createdAt;
  final String lastSeenAt;
  final VoidCallback onRename;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final isRevoked = device.revoked;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: (dark ? const Color(0xFF08111B) : Colors.white).withValues(
          alpha: dark ? 0.86 : 0.84,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: dark ? 0.12 : 0.44),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  device.label.isNotEmpty ? device.label : device.deviceId,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: dark ? Colors.white : scheme.onSurface,
                  ),
                ),
              ),
              _TinyChip(
                label: device.platform.toUpperCase(),
                color: scheme.primary.withValues(alpha: 0.15),
                textColor: scheme.primary,
              ),
              if (isCurrent && !isRevoked) ...[
                const SizedBox(width: 6),
                _TinyChip(
                  label: 'Это устройство',
                  color: scheme.primary,
                  textColor: scheme.onPrimary,
                ),
              ],
              if (isRevoked) ...[
                const SizedBox(width: 6),
                _TinyChip(
                  label: 'Отозвано',
                  color: scheme.error.withValues(alpha: 0.15),
                  textColor: scheme.error,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Создано: $createdAt  •  Активность: $lastSeenAt',
            style: TextStyle(
              fontSize: 12,
              color: dark ? Colors.white60 : Colors.black54,
            ),
          ),
          if (fingerprint.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              fingerprint,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: dark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
          if (isRevoked && device.revokedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Отозвано: ${device.revokedAt}',
              style: TextStyle(fontSize: 12, color: scheme.error),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: isRevoked ? null : onRename,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Rename'),
              ),
              const SizedBox(width: 6),
              FilledButton.tonalIcon(
                onPressed: isRevoked ? null : onRevoke,
                icon: const Icon(Icons.shield_outlined, size: 16),
                label: const Text('Revoke'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TinyChip extends StatelessWidget {
  const _TinyChip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
