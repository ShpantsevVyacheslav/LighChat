/// QR-pairing экран для E2EE v2 (Phase 9 gap #1, mobile).
///
/// Экран поддерживает обе роли:
///  - **Initiator** (новое устройство). Генерит Firestore-сессию, рендерит QR
///    через `qr_flutter`, подписывается на документ и ждёт ответа donor'а.
///    После получения `donorPayload` показывает 6-значный код сверки; если
///    пользователь подтверждает — записывает восстановленный PKCS#8 в
///    secure-storage через `replaceMobileDeviceIdentityFromBackup`.
///  - **Donor** (старое устройство с ключом). Открывает камеру
///    (`mobile_scanner`), сканирует QR, шифрует текущий приватник под общий
///    ключ и кладёт обратно в документ. Показывает тот же 6-значный код для
///    сверки.
///
/// Изолирован от `e2ee_recovery_screen.dart`: старый UX (password-backup)
/// остаётся работоспособным и не получает новых зависимостей.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:lighchat_mobile/app_providers.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../l10n/app_localizations.dart';

import '../../auth/ui/auth_glass.dart';
import '../../shared/ui/app_back_button.dart';

enum _Mode { pick, initiator, donor }

enum _InitiatorStage { starting, waiting, awaitingAccept, completed, error }

enum _DonorStage { scanning, confirming, done, error }

class E2eeQrPairingScreen extends ConsumerStatefulWidget {
  const E2eeQrPairingScreen({super.key});

  @override
  ConsumerState<E2eeQrPairingScreen> createState() => _E2eeQrPairingScreenState();
}

class _E2eeQrPairingScreenState extends ConsumerState<E2eeQrPairingScreen> {
  _Mode _mode = _Mode.pick;

  // INITIATOR state
  MobileInitiatorSession? _initSession;
  _InitiatorStage _initStage = _InitiatorStage.starting;
  String? _initCode;
  String? _initError;
  Map<String, Object?>? _donorDocSnapshot;
  Uint8List? _pendingPkcs8;
  String? _pendingBackupId;
  StreamSubscription<Map<String, Object?>?>? _initSub;
  bool _initBusy = false;

  // DONOR state
  _DonorStage _donorStage = _DonorStage.scanning;
  String? _donorCode;
  String? _donorError;
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _donorProcessing = false;

  @override
  void dispose() {
    _initSub?.cancel();
    // Если initiator не закончил — отменяем сессию (идемпотентно).
    final session = _initSession;
    if (session != null && _initStage != _InitiatorStage.completed) {
      _rejectInitiatorSession(session.sessionId);
    }
    _scannerController.dispose();
    super.dispose();
  }

  Future<String?> _currentUid() async {
    final user = await ref.read(authUserProvider.future);
    return user?.uid;
  }

  Future<void> _rejectInitiatorSession(String sessionId) async {
    final uid = await _currentUid();
    if (uid == null) return;
    await rejectMobilePairingSession(
      firestore: FirebaseFirestore.instance,
      userId: uid,
      sessionId: sessionId,
    );
  }

  // -------------------- INITIATOR --------------------

  Future<void> _startInitiator() async {
    setState(() {
      _mode = _Mode.initiator;
      _initStage = _InitiatorStage.starting;
      _initError = null;
    });
    final uid = await _currentUid();
    if (uid == null) {
      setState(() {
        _initStage = _InitiatorStage.error;
        _initError = AppLocalizations.of(context)!.e2ee_qr_uid_error;
      });
      return;
    }
    try {
      final session = await initiateMobilePairingSession(
        firestore: FirebaseFirestore.instance,
        userId: uid,
      );
      if (!mounted) return;
      setState(() {
        _initSession = session;
        _initStage = _InitiatorStage.waiting;
      });
      _initSub = watchMobilePairingSession(
        firestore: FirebaseFirestore.instance,
        userId: uid,
        sessionId: session.sessionId,
      ).listen((data) => _onInitiatorUpdate(uid, session, data));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initStage = _InitiatorStage.error;
        _initError = e.toString();
      });
    }
  }

  Future<void> _onInitiatorUpdate(
    String uid,
    MobileInitiatorSession session,
    Map<String, Object?>? data,
  ) async {
    if (data == null) {
      if (_initStage != _InitiatorStage.completed) {
        if (!mounted) return;
        setState(() {
          _initStage = _InitiatorStage.error;
          _initError = AppLocalizations.of(context)!.e2ee_qr_session_ended_error;
        });
      }
      return;
    }
    final state = data['state'];
    if (state == 'awaiting_accept' && data['donorPayload'] != null) {
      try {
        final res = await consumeDonorPayloadMobile(
          firestore: FirebaseFirestore.instance,
          userId: uid,
          sessionId: session.sessionId,
          initiatorEphemeral: session.ephemeralKeyPair,
          donorDocument: data,
        );
        final draft = data['donorPayload'] is Map
            ? ((data['donorPayload'] as Map)['deviceDraft'] as Map?)
            : null;
        final backupId = draft != null ? draft['deviceId'] as String? : null;
        if (!mounted) return;
        setState(() {
          _donorDocSnapshot = data;
          _initCode = res.pairingCode;
          _pendingPkcs8 = res.privateKeyPkcs8;
          _pendingBackupId = backupId;
          _initStage = _InitiatorStage.awaitingAccept;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _initStage = _InitiatorStage.error;
          _initError = e.toString();
        });
      }
    }
  }

  Future<void> _confirmInitiator() async {
    final pkcs8 = _pendingPkcs8;
    final backupId = _pendingBackupId;
    if (pkcs8 == null || backupId == null) {
      setState(() {
        _initStage = _InitiatorStage.error;
        _initError = AppLocalizations.of(context)!.e2ee_qr_no_data_error;
      });
      return;
    }
    setState(() => _initBusy = true);
    try {
      final uid = await _currentUid();
      if (uid == null) throw StateError('NO_UID');
      // Нужен SPKI публичник этого устройства. Берём из `e2eeDevices/{backupId}`,
      // он совпадает с приватником (donor переносит identity, у которой уже
      // есть опубликованный публичник).
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('e2eeDevices')
          .doc(backupId)
          .get();
      if (!snap.exists) {
        throw StateError('E2EE_PAIRING_DEVICE_PUBKEY_MISSING');
      }
      final publicKeySpkiB64 = snap.data()?['publicKeySpki'] as String?;
      if (publicKeySpkiB64 == null || publicKeySpkiB64.isEmpty) {
        throw StateError('E2EE_PAIRING_DEVICE_PUBKEY_MISSING');
      }
      // Декодим SPKI и пишем в secure-storage.
      final spki = Uint8List.fromList(_decodeB64(publicKeySpkiB64));
      await replaceMobileDeviceIdentityFromBackup(
        deviceId: backupId,
        privateKeyPkcs8: pkcs8,
        publicKeySpki: spki,
      );
      if (!mounted) return;
      setState(() {
        _initStage = _InitiatorStage.completed;
        _initBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.e2ee_qr_key_transferred_toast),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initStage = _InitiatorStage.error;
        _initError = e.toString();
        _initBusy = false;
      });
    }
  }

  // -------------------- DONOR --------------------

  Future<void> _onQrScanned(String raw) async {
    if (_donorProcessing) return;
    _donorProcessing = true;
    setState(() {
      _donorStage = _DonorStage.confirming;
      _donorError = null;
    });
    try {
      final payload = parseQrPayload(raw);
      final uid = await _currentUid();
      if (uid == null) throw StateError('NO_UID');
      if (payload.uid != uid) {
        throw StateError(AppLocalizations.of(context)!.e2ee_qr_wrong_account_error);
      }
      final identity = await getOrCreateMobileDeviceIdentity();
      final pkcs8 = await identity.keyPair.exportPkcs8Private();
      // Передаём новому устройству мета-инфу текущего устройства.
      // После восстановления initiator будет использовать именно этот deviceId.
      final draft = MobileDeviceDraft(
        deviceId: identity.deviceId,
        platform: _detectPlatform(),
        label: await _currentLabel(),
        publicKeySpkiB64: identity.publicKeySpkiB64,
      );
      final code = await donorRespondToPairingMobile(
        firestore: FirebaseFirestore.instance,
        userId: uid,
        sessionId: payload.sessionId,
        initiatorEphPubSpkiB64: payload.initiatorEphPubSpkiB64,
        privateKeyPkcs8: pkcs8,
        deviceDraft: draft,
      );
      if (!mounted) return;
      setState(() {
        _donorCode = code;
        _donorStage = _DonorStage.done;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _donorStage = _DonorStage.error;
        _donorError = e.toString();
      });
    } finally {
      _donorProcessing = false;
    }
  }

  String _detectPlatform() {
    // `Platform.isIOS` требует import; чтобы не раздувать — используем Theme.
    // В крайнем случае `android` как дефолт не критично, UI UI для пользователя
    // маркируется label'ом.
    return Theme.of(context).platform == TargetPlatform.iOS ? 'ios' : 'android';
  }

  Future<String> _currentLabel() async {
    // Базовый label из платформы; детальный label уже лежит в публикации
    // устройства, это просто fallback.
    return 'mobile/${_detectPlatform()}';
  }

  List<int> _decodeB64(String s) {
    // Inline, чтобы не импортировать `dart:convert` в import-list если уже есть.
    return const Base64Decoder().convert(s);
  }

  // -------------------- UI --------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                leading: const AppBackButton(fallbackLocation: '/settings/privacy/e2ee-recovery'),
                title: Text(l10n.e2ee_qr_title),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(_buildBody()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBody() {
    switch (_mode) {
      case _Mode.pick:
        return _buildPick();
      case _Mode.initiator:
        return _buildInitiator();
      case _Mode.donor:
        return _buildDonor();
    }
  }

  List<Widget> _buildPick() {
    final l10n = AppLocalizations.of(context)!;
    return [
      _Explainer(
        title: l10n.e2ee_qr_explainer_title,
        text: l10n.e2ee_qr_explainer_text,
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _startInitiator,
        icon: const Icon(Icons.qr_code_2_rounded),
        label: Text(l10n.e2ee_qr_show_qr_label),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () => setState(() => _mode = _Mode.donor),
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: Text(l10n.e2ee_qr_scan_qr_label),
      ),
    ];
  }

  List<Widget> _buildInitiator() {
    final l10n = AppLocalizations.of(context)!;
    switch (_initStage) {
      case _InitiatorStage.starting:
        return const [Center(child: CircularProgressIndicator())];
      case _InitiatorStage.waiting:
        final s = _initSession!;
        return [
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: QrImageView(
                data: s.encoded,
                version: QrVersions.auto,
                size: 240,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.e2ee_qr_scan_hint,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                _rejectInitiatorSession(s.sessionId);
                setState(() => _mode = _Mode.pick);
              },
              child: Text(l10n.common_cancel),
            ),
          ),
        ];
      case _InitiatorStage.awaitingAccept:
        final label = (_donorDocSnapshot?['donorPayload'] is Map)
            ? ((_donorDocSnapshot!['donorPayload'] as Map)['deviceDraft'] is Map
                ? ((_donorDocSnapshot!['donorPayload'] as Map)['deviceDraft']
                    as Map)['label']
                : null)
            : null;
        return [
          const SizedBox(height: 12),
          Text(
            l10n.e2ee_qr_verify_code_label,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _initCode ?? '------',
              style: const TextStyle(
                fontSize: 36,
                fontFamily: 'monospace',
                letterSpacing: 6,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (label is String) ...[
            const SizedBox(height: 12),
            Text(
              l10n.e2ee_qr_transfer_from_device_label(label),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: _initBusy
                    ? null
                    : () {
                        final s = _initSession;
                        if (s != null) _rejectInitiatorSession(s.sessionId);
                        Navigator.of(context).pop();
                      },
                child: Text(l10n.common_cancel),
              ),
              FilledButton(
                onPressed: _initBusy ? null : _confirmInitiator,
                child: _initBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.e2ee_qr_code_match_apply_label),
              ),
            ],
          ),
        ];
      case _InitiatorStage.completed:
        return [
          const SizedBox(height: 12),
          const Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 56),
          const SizedBox(height: 12),
          Text(
            l10n.e2ee_qr_key_success_label,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.common_done),
            ),
          ),
        ];
      case _InitiatorStage.error:
        return [
          const SizedBox(height: 12),
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 44),
          const SizedBox(height: 12),
          Text(
            _initError ?? l10n.e2ee_qr_unknown_error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                _mode = _Mode.pick;
                _initSession = null;
                _initError = null;
              }),
              child: Text(l10n.e2ee_qr_back_to_pick_label),
            ),
          ),
        ];
    }
  }

  List<Widget> _buildDonor() {
    final l10n = AppLocalizations.of(context)!;
    switch (_donorStage) {
      case _DonorStage.scanning:
        return [
          SizedBox(
            height: 320,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: MobileScanner(
                controller: _scannerController,
                onDetect: (BarcodeCapture capture) {
                  for (final b in capture.barcodes) {
                    final raw = b.rawValue;
                    if (raw != null && raw.isNotEmpty) {
                      _onQrScanned(raw);
                      break;
                    }
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.e2ee_qr_donor_scan_hint,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _mode = _Mode.pick),
              child: Text(l10n.common_cancel),
            ),
          ),
        ];
      case _DonorStage.confirming:
        return const [Center(child: CircularProgressIndicator())];
      case _DonorStage.done:
        return [
          const SizedBox(height: 12),
          Text(
            l10n.e2ee_qr_donor_verify_code_label,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _donorCode ?? '------',
              style: const TextStyle(
                fontSize: 36,
                fontFamily: 'monospace',
                letterSpacing: 6,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.e2ee_qr_donor_verify_hint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.common_done),
            ),
          ),
        ];
      case _DonorStage.error:
        return [
          const SizedBox(height: 12),
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 44),
          const SizedBox(height: 12),
          Text(
            _donorError ?? l10n.e2ee_qr_unknown_error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                _donorStage = _DonorStage.scanning;
                _donorError = null;
              }),
              child: Text(l10n.common_retry),
            ),
          ),
        ];
    }
  }
}

class _Explainer extends StatelessWidget {
  const _Explainer({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
