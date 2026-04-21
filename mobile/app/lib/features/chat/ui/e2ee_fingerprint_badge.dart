/// Phase 8 — mobile-бэйдж с отпечатком E2EE собеседника.
///
/// Зеркало web-компонента `src/components/chat/E2eeFingerprintBadge.tsx`:
/// читает активные v2-устройства пользователя, считает sha-256 от SPKI-байтов
/// всех публичных ключей и выводит первые 32 hex-символа, сгруппированные
/// по 4 ('xxxx xxxx …').
///
/// Usage: вставляется в DM-профиль ниже строки «Шифрование», если e2ee включено.
/// Почему безопасно: только чтение из Firestore, без мутаций. Ошибки попадают
/// в встроенный error-state и не ломают родительский экран.

library;

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';

/// Форматирует hex-строку в группы по 4 символа через пробел.
String _formatFingerprintHex(String hex) {
  final normalized = hex.toLowerCase();
  final groups = <String>[];
  for (var i = 0; i < normalized.length; i += 4) {
    groups.add(
      normalized.substring(
        i,
        i + 4 > normalized.length ? normalized.length : i + 4,
      ),
    );
  }
  return groups.join(' ');
}

/// Читает `users/{uid}/e2eeDevices` и возвращает только не-revoked документы,
/// у которых есть publicKeySpkiB64. Паритет `listActiveE2eeDevicesV2`.
Future<List<String>> _fetchActiveDeviceSpkis({
  required FirebaseFirestore firestore,
  required String userId,
}) async {
  final snap = await firestore
      .collection('users/$userId/e2eeDevices')
      .get();
  final spkis = <String>[];
  for (final doc in snap.docs) {
    final data = doc.data();
    if (data['revoked'] == true) continue;
    final spki = data['publicKeySpkiB64'];
    if (spki is String && spki.isNotEmpty) {
      spkis.add(spki);
    }
  }
  return spkis;
}

/// SHA-256 конкатенации sorted SPKI bytes. Та же логика, что
/// `computeUserFingerprintV2` на web — порядок детерминирован.
Future<String> _computeFingerprint(List<String> spkiB64List) async {
  if (spkiB64List.isEmpty) return '';
  final sorted = [...spkiB64List]..sort();
  final bytes = <int>[];
  for (final b64 in sorted) {
    bytes.addAll(base64.decode(b64));
  }
  final digest = crypto.sha256.convert(bytes);
  // Возьмём всё (64 hex), дальше форматер режет по 4 и можно показать первые 32.
  return digest.toString();
}

class E2eeFingerprintBadge extends StatefulWidget {
  const E2eeFingerprintBadge({
    super.key,
    required this.firestore,
    required this.userId,
    this.userLabel,
  });

  final FirebaseFirestore firestore;
  final String userId;
  final String? userLabel;

  @override
  State<E2eeFingerprintBadge> createState() => _E2eeFingerprintBadgeState();
}

class _E2eeFingerprintBadgeState extends State<E2eeFingerprintBadge> {
  String? _fingerprint;
  int? _devicesCount;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant E2eeFingerprintBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.firestore != widget.firestore) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final spkis = await _fetchActiveDeviceSpkis(
        firestore: widget.firestore,
        userId: widget.userId,
      );
      if (spkis.isEmpty) {
        if (!mounted) return;
        setState(() {
          _fingerprint = null;
          _devicesCount = 0;
          _loading = false;
        });
        return;
      }
      final fp = await _computeFingerprint(spkis);
      if (!mounted) return;
      setState(() {
        _fingerprint = fp;
        _devicesCount = spkis.length;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    if (_loading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text('Загружаем отпечаток…', style: labelStyle),
        ],
      );
    }
    if (_error != null) {
      return Text(
        'Не удалось получить отпечаток: $_error',
        style: labelStyle?.copyWith(color: theme.colorScheme.error),
      );
    }
    if (_fingerprint == null || _devicesCount == 0) {
      return Text(
        'У ${widget.userLabel ?? 'пользователя'} нет активных E2EE-устройств.',
        style: labelStyle,
      );
    }
    final displayHex = _fingerprint!.substring(0, 32);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.fingerprint,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Отпечаток E2EE'
                '${widget.userLabel != null ? ' • ${widget.userLabel}' : ''}'
                ' ($_devicesCount устр.)',
                style: labelStyle,
              ),
              const SizedBox(height: 2),
              SelectableText(
                _formatFingerprintHex(displayHex),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  letterSpacing: 0.1,
                ),
                semanticsLabel: 'E2EE fingerprint',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
