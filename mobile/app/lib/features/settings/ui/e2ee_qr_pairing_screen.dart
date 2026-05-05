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
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:lighchat_mobile/app_providers.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../l10n/app_localizations.dart';

import '../../auth/ui/auth_glass.dart';
import '../../shared/ui/app_back_button.dart';

enum _Mode { pick, initiator, donor }

/// Публичный enum для роута: позволяет открыть экран сразу в режиме
/// сканера (когда `/settings/e2ee-qr-pairing?mode=donor` вызывается
/// со страницы устройств — там promot pick не нужен).
enum E2eeQrPairingInitialMode { pick, donor }

enum _InitiatorStage { starting, waiting, awaitingAccept, completed, error }

enum _DonorStage { scanning, confirming, done, error }

/// Стадии flow подключения нового устройства через QR-логин (Telegram-style).
/// Отличается от [_DonorStage]: здесь старое устройство не передаёт свой
/// приватник, а подтверждает custom-token и переоборачивает session-keys
/// E2EE-чатов под новый publicKey (handoverDeviceAccessMobile).
enum _LoginLinkStage { idle, awaitingApprove, confirming, syncing, done, error }

class E2eeQrPairingScreen extends ConsumerStatefulWidget {
  const E2eeQrPairingScreen({
    super.key,
    this.initialMode = E2eeQrPairingInitialMode.pick,
  });

  final E2eeQrPairingInitialMode initialMode;

  @override
  ConsumerState<E2eeQrPairingScreen> createState() => _E2eeQrPairingScreenState();
}

class _E2eeQrPairingScreenState extends ConsumerState<E2eeQrPairingScreen> {
  late _Mode _mode = widget.initialMode == E2eeQrPairingInitialMode.donor
      ? _Mode.donor
      : _Mode.pick;

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

  // QR-LOGIN handover state (когда отсканировали login-QR, а не E2EE-pairing).
  _LoginLinkStage _loginStage = _LoginLinkStage.idle;
  String? _loginError;
  String? _loginPendingSessionId;
  String? _loginPendingNonce;
  String? _loginNewDeviceLabel;
  String? _loginNewDevicePlatform;
  int _loginHandoverDone = 0;
  int _loginHandoverTotal = 0;

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

    // Сначала проверяем, не login-QR ли это (Telegram-style привязка нового
    // устройства). Парсер возвращает null, если payload не совпал — тогда
    // падаем в существующий E2EE-pairing flow.
    final loginPayload = parseQrLoginPayload(raw);
    if (loginPayload != null) {
      // Сразу пытаемся подтянуть метаданные нового устройства из qrLoginSessions.
      String label = '';
      String platform = 'web';
      try {
        final docSnap = await FirebaseFirestore.instance
            .collection('qrLoginSessions')
            .doc(loginPayload.sessionId)
            .get();
        if (docSnap.exists) {
          final d = docSnap.data() ?? const <String, dynamic>{};
          label = (d['deviceLabel'] ?? '').toString();
          platform = (d['devicePlatform'] ?? 'web').toString();
        }
      } catch (_) {
        // Не критично — продолжаем без метаданных.
      }
      if (!mounted) return;
      setState(() {
        _loginStage = _LoginLinkStage.awaitingApprove;
        _loginError = null;
        _loginPendingSessionId = loginPayload.sessionId;
        _loginPendingNonce = loginPayload.nonce;
        _loginNewDeviceLabel = label.isEmpty ? null : label;
        _loginNewDevicePlatform = platform;
      });
      _donorProcessing = false;
      return;
    }

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

  // -------------------- QR-LOGIN handover (Telegram-style) --------------------

  /// На iOS в release-сборке `cloud_functions` плагин (gRPC + Swift Concurrency)
  /// даёт malloc-corruption и SIGABRT. Используем прямой HTTPS-вызов через
  /// `callFirebaseCallableHttp`. На Android и web `FirebaseFunctions.instance`
  /// стабилен — оставляем его как было.
  Future<Map<dynamic, dynamic>> _callConfirmQrLogin({
    required String sessionId,
    required String nonce,
    required bool allow,
  }) async {
    final body = <String, dynamic>{
      'sessionId': sessionId,
      'nonce': nonce,
      'allow': allow,
    };
    if (!kIsWeb && Platform.isIOS) {
      final raw = await callFirebaseCallableHttp(
        name: 'confirmQrLogin',
        region: 'us-central1',
        data: body,
        timeout: Duration(seconds: allow ? 25 : 15),
      );
      return raw is Map ? raw : const <Object?, Object?>{};
    }
    final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
    final res = await functions
        .httpsCallable(
          'confirmQrLogin',
          options: HttpsCallableOptions(
            timeout: Duration(seconds: allow ? 25 : 15),
          ),
        )
        .call<dynamic>(body);
    final raw = res.data;
    return raw is Map ? raw : const <Object?, Object?>{};
  }

  Future<void> _confirmLoginLink({required bool allow}) async {
    final sessionId = _loginPendingSessionId;
    final nonce = _loginPendingNonce;
    if (sessionId == null || nonce == null) return;
    if (!allow) {
      // Отклоняем (best-effort). Возвращаемся к сканеру.
      try {
        await _callConfirmQrLogin(sessionId: sessionId, nonce: nonce, allow: false);
      } catch (_) {
        // ignore — сессия скоро протухнет.
      }
      if (!mounted) return;
      setState(() {
        _loginStage = _LoginLinkStage.idle;
        _loginPendingSessionId = null;
        _loginPendingNonce = null;
      });
      return;
    }

    setState(() => _loginStage = _LoginLinkStage.confirming);
    try {
      final m = await _callConfirmQrLogin(
        sessionId: sessionId,
        nonce: nonce,
        allow: true,
      );
      if (m['state'] != 'approved') {
        throw StateError('CONFIRM_REJECTED');
      }
      final ephemeralPubKeySpki =
          (m['ephemeralPubKeySpki'] ?? '').toString();
      final newDeviceId = (m['deviceId'] ?? '').toString();
      final platform = (m['devicePlatform'] ?? 'web').toString();
      final label = (m['deviceLabel'] ?? '').toString();
      if (ephemeralPubKeySpki.isEmpty || newDeviceId.isEmpty) {
        throw StateError('BAD_CONFIRM_RESPONSE');
      }

      final uid = await _currentUid();
      if (uid == null) throw StateError('NO_UID');
      final donorIdentity = await getOrCreateMobileDeviceIdentity();

      if (!mounted) return;
      setState(() {
        _loginStage = _LoginLinkStage.syncing;
        _loginHandoverDone = 0;
        _loginHandoverTotal = 0;
      });

      await handoverDeviceAccessMobile(
        firestore: FirebaseFirestore.instance,
        userId: uid,
        donorIdentity: donorIdentity,
        newDevice: IncomingDeviceInfo(
          deviceId: newDeviceId,
          publicKeySpkiB64: ephemeralPubKeySpki,
          platform: platform,
          label: label.isEmpty ? '$platform-device' : label,
        ),
        onProgress: (entry, done, total) {
          if (!mounted) return;
          setState(() {
            _loginHandoverDone = done;
            _loginHandoverTotal = total;
          });
        },
      );

      if (!mounted) return;
      setState(() => _loginStage = _LoginLinkStage.done);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loginStage = _LoginLinkStage.error;
        _loginError = e.toString();
      });
    }
  }

  void _resetLoginFlow() {
    setState(() {
      _loginStage = _LoginLinkStage.idle;
      _loginError = null;
      _loginPendingSessionId = null;
      _loginPendingNonce = null;
      _loginNewDeviceLabel = null;
      _loginNewDevicePlatform = null;
      _loginHandoverDone = 0;
      _loginHandoverTotal = 0;
      _donorStage = _DonorStage.scanning;
    });
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
    // QR-login handover имеет приоритет над обычным donor flow:
    // как только сканер распознал login-QR, мы показываем UX подтверждения
    // нового устройства / прогресс синхронизации.
    if (_loginStage != _LoginLinkStage.idle) {
      return _buildLoginLink(l10n);
    }
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

  List<Widget> _buildLoginLink(AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    switch (_loginStage) {
      case _LoginLinkStage.idle:
        return const [];
      case _LoginLinkStage.awaitingApprove:
        return [
          const SizedBox(height: 8),
          Icon(
            Icons.smartphone,
            size: 44,
            color: scheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.devices_approve_title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.devices_approve_body_hint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: (dark ? Colors.white : scheme.onSurface)
                  .withValues(alpha: 0.62),
            ),
          ),
          if (_loginNewDeviceLabel != null ||
              _loginNewDevicePlatform != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (dark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _loginNewDeviceLabel ??
                      (_loginNewDevicePlatform ?? '').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.block, size: 18),
                  onPressed: () => _confirmLoginLink(allow: false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  label: Text(l10n.devices_approve_deny),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.verified_user, size: 18),
                  onPressed: () => _confirmLoginLink(allow: true),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  label: Text(l10n.devices_approve_allow),
                ),
              ),
            ],
          ),
        ];
      case _LoginLinkStage.confirming:
        return const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      case _LoginLinkStage.syncing:
        return [
          const SizedBox(height: 12),
          const Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.devices_handover_progress_title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            _loginHandoverTotal > 0
                ? l10n.devices_handover_progress_body(
                    _loginHandoverDone,
                    _loginHandoverTotal,
                  )
                : l10n.devices_handover_progress_starting,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: (dark ? Colors.white : scheme.onSurface)
                  .withValues(alpha: 0.62),
            ),
          ),
        ];
      case _LoginLinkStage.done:
        return [
          const SizedBox(height: 16),
          const Icon(
            Icons.check_circle,
            color: Color(0xFF34D399),
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.devices_handover_success_title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.devices_handover_success_body(
              _loginNewDeviceLabel ??
                  (_loginNewDevicePlatform ?? 'device'),
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: (dark ? Colors.white : scheme.onSurface)
                  .withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: FilledButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/settings/devices');
                }
              },
              child: Text(l10n.common_done),
            ),
          ),
        ];
      case _LoginLinkStage.error:
        return [
          const SizedBox(height: 16),
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 44),
          const SizedBox(height: 12),
          Text(
            _loginError ?? l10n.e2ee_qr_unknown_error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _resetLoginFlow,
              child: Text(l10n.e2ee_qr_back_to_pick_label),
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
