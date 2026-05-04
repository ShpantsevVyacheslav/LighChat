/// QR-login экран (initiator) — новое устройство показывает QR, который
/// сканирует уже залогиненное устройство. После подтверждения сервер выдаёт
/// custom token, мы делаем `signInWithCustomToken` и переходим в чаты.
///
/// Дизайн повторяет [`auth_screen.dart`](./auth_screen.dart): тот же фоновой
/// градиент `_AuthLoginBackdrop`, brand-header и стеклянная карточка.
library;

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../l10n/app_localizations.dart';
import '../../shared/ui/app_back_button.dart';
import 'auth_brand_header.dart';
import 'auth_glass.dart';

class QrLoginScreen extends ConsumerStatefulWidget {
  const QrLoginScreen({super.key});

  @override
  ConsumerState<QrLoginScreen> createState() => _QrLoginScreenState();
}

enum _QrPhase { loading, ready, approving, rejected, error }

class _QrLoginScreenState extends ConsumerState<QrLoginScreen> {
  _QrPhase _phase = _QrPhase.loading;
  String? _error;
  String? _encodedQr;
  String? _sessionId;
  DateTime? _expiresAt;
  Timer? _ticker;
  Timer? _refreshTimer;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  bool _consuming = false;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _refreshTimer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    _ticker?.cancel();
    _refreshTimer?.cancel();
    await _sub?.cancel();
    _sub = null;
    _consuming = false;
    if (!mounted) return;
    setState(() {
      _phase = _QrPhase.loading;
      _error = null;
    });

    try {
      final identity = await getOrCreateMobileDeviceIdentity();
      final platform = Theme.of(context).platform == TargetPlatform.iOS
          ? 'ios'
          : 'android';
      final label = 'mobile/$platform';

      final functions = FirebaseFunctions.instanceFor(
        app: Firebase.app(),
        region: 'us-central1',
      );
      final callable = functions.httpsCallable(
        'requestQrLogin',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
      );
      final res = await callable.call<dynamic>(<String, Object?>{
        'ephemeralPubKeySpki': identity.publicKeySpkiB64,
        'devicePlatform': platform,
        'deviceLabel': label,
        'deviceId': identity.deviceId,
      });
      final raw = res.data;
      final m = raw is Map ? raw : const <Object?, Object?>{};
      final sessionId = m['sessionId']?.toString() ?? '';
      final nonce = m['nonce']?.toString() ?? '';
      final expiresIso = m['expiresAt']?.toString() ?? '';
      if (sessionId.isEmpty || nonce.isEmpty) {
        throw StateError('QR_LOGIN_BAD_RESPONSE');
      }
      final encoded = _encodeLoginQrPayload(
        sessionId: sessionId,
        nonce: nonce,
      );
      final expiresAt = DateTime.tryParse(expiresIso) ??
          DateTime.now().add(const Duration(seconds: 90));

      if (!mounted) return;
      setState(() {
        _phase = _QrPhase.ready;
        _encodedQr = encoded;
        _sessionId = sessionId;
        _expiresAt = expiresAt;
      });

      _sub = FirebaseFirestore.instance
          .collection('qrLoginSessions')
          .doc(sessionId)
          .snapshots()
          .listen(_onSession);

      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final left =
            _expiresAt?.difference(DateTime.now()).inSeconds ?? 0;
        setState(() => _secondsLeft = left < 0 ? 0 : left);
      });

      // Автообновление за 5 секунд до TTL.
      final refreshDelay = (expiresAt.difference(DateTime.now()) -
              const Duration(seconds: 5));
      _refreshTimer = Timer(
        refreshDelay.isNegative ? const Duration(seconds: 1) : refreshDelay,
        _start,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _QrPhase.error;
        _error = e.toString();
      });
    }
  }

  Future<void> _onSession(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) async {
    if (_consuming) return;
    if (!snap.exists) return;
    final data = snap.data() ?? const <String, dynamic>{};
    final state = data['state']?.toString();
    if (state == 'approved') {
      final customToken = data['customToken']?.toString() ?? '';
      if (customToken.isEmpty) return;
      _consuming = true;
      if (!mounted) return;
      setState(() => _phase = _QrPhase.approving);
      try {
        await FirebaseAuth.instance.signInWithCustomToken(customToken);
        // Удаляем сессию (best-effort) — customToken одноразовый.
        try {
          await FirebaseFirestore.instance
              .collection('qrLoginSessions')
              .doc(snap.id)
              .delete();
        } catch (_) {
          // cleanup CF добьёт.
        }
        if (!mounted) return;
        context.go('/chats');
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _phase = _QrPhase.error;
          _error = e.toString();
          _consuming = false;
        });
      }
    } else if (state == 'rejected') {
      if (!mounted) return;
      setState(() => _phase = _QrPhase.rejected);
      // Через 2с авторефреш.
      _refreshTimer?.cancel();
      _refreshTimer = Timer(const Duration(seconds: 2), _start);
    }
  }

  /// base64-url JSON `{v:'lighchat-login-v1',sessionId,nonce}`.
  /// Дублирует [`buildQrLoginPayload`](../../../../packages/lighchat_firebase/lib/src/qr-login/protocol.ts)
  /// (web-сторона), не делая публичный API в lighchat_firebase: парсер уже там
  /// есть, а билдер нужен только для этого экрана.
  String _encodeLoginQrPayload({
    required String sessionId,
    required String nonce,
  }) {
    final json = jsonEncode(<String, Object?>{
      'v': 'lighchat-login-v1',
      'sessionId': sessionId,
      'nonce': nonce,
    });
    final b64 = base64.encode(utf8.encode(json));
    return b64
        .replaceAll('+', '-')
        .replaceAll('/', '_')
        .replaceAll('=', '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: Row(
                      children: const [
                        AppBackButton(fallbackLocation: '/auth'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 4),
                          const Center(child: AuthBrandHeader()),
                          const SizedBox(height: 12),
                          Text(
                            l10n.auth_qr_title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: dark ? Colors.white : scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.auth_qr_hint,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: (dark ? Colors.white : scheme.onSurface)
                                  .withValues(alpha: 0.62),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Center(
                            child: GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: SizedBox(
                                width: 248,
                                height: 248,
                                child: _buildQrCenter(dark, scheme, l10n),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (_phase == _QrPhase.ready && _secondsLeft > 0)
                            Center(
                              child: Text(
                                l10n.auth_qr_refresh_in(_secondsLeft),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                  color:
                                      (dark ? Colors.white : scheme.onSurface)
                                          .withValues(alpha: 0.45),
                                ),
                              ),
                            ),
                          const SizedBox(height: 14),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              side: BorderSide(
                                color: dark
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : Colors.black.withValues(alpha: 0.12),
                              ),
                              backgroundColor: dark
                                  ? Colors.white.withValues(alpha: 0.03)
                                  : Colors.white.withValues(alpha: 0.50),
                              foregroundColor:
                                  dark ? Colors.white : scheme.onSurface,
                            ),
                            onPressed: () => context.go('/auth'),
                            child: Text(l10n.auth_qr_other_method),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQrCenter(
    bool dark,
    ColorScheme scheme,
    AppLocalizations l10n,
  ) {
    switch (_phase) {
      case _QrPhase.loading:
        return const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case _QrPhase.ready:
        final encoded = _encodedQr;
        if (encoded == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return QrImageView(
          data: encoded,
          version: QrVersions.auto,
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          foregroundColor: dark ? Colors.white : Colors.black,
          eyeStyle: QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: dark ? Colors.white : Colors.black,
          ),
          dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: dark ? Colors.white : Colors.black,
          ),
        );
      case _QrPhase.approving:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified_user,
                color: Color(0xFF34D399),
                size: 36,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.auth_qr_approving,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: (dark ? Colors.white : scheme.onSurface)
                      .withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        );
      case _QrPhase.rejected:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cancel_outlined,
                color: Colors.amber,
                size: 36,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.auth_qr_rejected,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: (dark ? Colors.white : scheme.onSurface)
                      .withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        );
      case _QrPhase.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 36,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _error ?? l10n.auth_qr_unknown_error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.redAccent,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _start,
                child: Text(l10n.auth_qr_retry),
              ),
            ],
          ),
        );
    }
  }
}
