/// QR-login экран (initiator) — новое устройство показывает QR, который
/// сканирует уже залогиненное устройство. После подтверждения сервер выдаёт
/// custom token, мы делаем `signInWithCustomToken` и переходим в чаты.
///
/// Дизайн повторяет [`auth_screen.dart`](./auth_screen.dart): тот же фоновой
/// градиент `_AuthLoginBackdrop`, brand-header и стеклянная карточка.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, TargetPlatform, kIsWeb;
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

class _QrLoginScreenState extends ConsumerState<QrLoginScreen>
    with SingleTickerProviderStateMixin {
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

  /// Контроллер «луча маяка» — диагональный shimmer, идущий по QR-коду.
  /// Полный цикл — 2.6с, потом перезапуск; не зависит от состояния, чтобы
  /// анимация не моргала при автообновлении QR.
  late final AnimationController _shineCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _shineCtrl.dispose();
    _ticker?.cancel();
    _refreshTimer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    _ticker?.cancel();
    _refreshTimer?.cancel();
    try {
      await _sub?.cancel();
    } catch (_) {
      // ignore
    }
    _sub = null;
    _consuming = false;
    if (!mounted) return;
    setState(() {
      _phase = _QrPhase.loading;
      _error = null;
    });

    // Платформу считаем сразу из const — `Theme.of(context).platform` не
    // обращаемся, чтобы не уронить экран на ранней стадии mount.
    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : 'android';
    final label = 'mobile/$platform';

    String? deviceId;
    String? publicKeySpkiB64;
    try {
      final identity = await getOrCreateMobileDeviceIdentity();
      deviceId = identity.deviceId;
      publicKeySpkiB64 = identity.publicKeySpkiB64;
    } catch (e, st) {
      debugPrint('[qr-login] identity init failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _phase = _QrPhase.error;
        _error = 'Не удалось получить ключ устройства: $e';
      });
      return;
    }

    Map<dynamic, dynamic> resData;
    try {
      final body = <String, dynamic>{
        'ephemeralPubKeySpki': publicKeySpkiB64,
        'devicePlatform': platform,
        'deviceLabel': label,
        'deviceId': deviceId,
      };
      // На iOS в release-сборке `cloud_functions` (gRPC + Swift Concurrency)
      // даёт malloc-corruption / SIGABRT. На iOS используем прямой HTTPS-вызов
      // через `callFirebaseCallableHttp` — он работает на чистом
      // dart:io HttpClient и обходит проблемный плагин. На Android и web
      // `FirebaseFunctions.instance` стабилен.
      if (!kIsWeb && Platform.isIOS) {
        final raw = await callFirebaseCallableHttp(
          name: 'requestQrLogin',
          region: 'us-central1',
          data: body,
          timeout: const Duration(seconds: 20),
          allowUnauthenticated: true,
        );
        resData = raw is Map ? raw : const <Object?, Object?>{};
      } else {
        final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
        final callable = functions.httpsCallable(
          'requestQrLogin',
          options:
              HttpsCallableOptions(timeout: const Duration(seconds: 20)),
        );
        final res = await callable.call<dynamic>(body);
        final raw = res.data;
        resData = raw is Map ? raw : const <Object?, Object?>{};
      }
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('[qr-login] requestQrLogin callable failed: ${e.code}: ${e.message}\n$st');
      if (!mounted) return;
      setState(() {
        _phase = _QrPhase.error;
        _error = 'Сервер: ${e.code} ${e.message ?? ''}';
      });
      return;
    } on FirebaseCallableHttpException catch (e, st) {
      debugPrint('[qr-login] requestQrLogin http failed: ${e.code}: ${e.message}\n$st');
      if (!mounted) return;
      setState(() {
        _phase = _QrPhase.error;
        _error = 'Сервер: ${e.code} ${e.message}';
      });
      return;
    } catch (e, st) {
      debugPrint('[qr-login] requestQrLogin unexpected: $e\n$st');
      if (!mounted) return;
      setState(() {
        _phase = _QrPhase.error;
        _error = e.toString();
      });
      return;
    }

    final sessionId = resData['sessionId']?.toString() ?? '';
    final nonce = resData['nonce']?.toString() ?? '';
    final expiresIso = resData['expiresAt']?.toString() ?? '';
    if (sessionId.isEmpty || nonce.isEmpty) {
      if (!mounted) return;
      setState(() {
        _phase = _QrPhase.error;
        _error = 'QR_LOGIN_BAD_RESPONSE';
      });
      return;
    }

    String encoded;
    try {
      encoded = buildQrLoginPayload(sessionId: sessionId, nonce: nonce);
    } catch (e, st) {
      debugPrint('[qr-login] encode failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _phase = _QrPhase.error;
        _error = 'Не удалось сгенерировать QR: $e';
      });
      return;
    }
    final expiresAt = DateTime.tryParse(expiresIso) ??
        DateTime.now().add(const Duration(seconds: 90));

    if (!mounted) return;
    setState(() {
      _phase = _QrPhase.ready;
      _encodedQr = encoded;
      _sessionId = sessionId;
      _expiresAt = expiresAt;
    });

    try {
      _sub = FirebaseFirestore.instance
          .collection('qrLoginSessions')
          .doc(sessionId)
          .snapshots()
          .listen(
            _onSession,
            onError: (Object e, StackTrace st) {
              debugPrint('[qr-login] firestore listener error: $e\n$st');
              // Самая частая причина — `firestore.rules` не задеплоены и
              // коллекция `qrLoginSessions` падает по default-deny. Без
              // листенера экран бесполезен — выводим понятную ошибку,
              // вместо тихого «вечный QR».
              final msg = e.toString();
              final isPermission =
                  msg.contains('permission-denied') ||
                      msg.contains('PERMISSION_DENIED') ||
                      msg.contains('Missing or insufficient permissions');
              if (!mounted) return;
              setState(() {
                _phase = _QrPhase.error;
                _error = isPermission
                    ? 'Нет доступа к qrLoginSessions. Задеплойте правила:\n'
                        '`firebase deploy --only firestore:rules`'
                    : 'Listener: $msg';
              });
            },
          );
    } catch (e, st) {
      debugPrint('[qr-login] failed to subscribe to session: $e\n$st');
    }

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final left = _expiresAt?.difference(DateTime.now()).inSeconds ?? 0;
      setState(() => _secondsLeft = left < 0 ? 0 : left);
    });

    // Автообновление за 5 секунд до TTL.
    final refreshDelay =
        expiresAt.difference(DateTime.now()) - const Duration(seconds: 5);
    _refreshTimer = Timer(
      refreshDelay.isNegative ? const Duration(seconds: 1) : refreshDelay,
      () {
        if (mounted) _start();
      },
    );
  }

  Future<void> _onSession(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) async {
    // Любая ошибка внутри листенера в release-iOS пропадает в Zone и роняет
    // приложение через SIGABRT. Полный try/catch на всё тело — обязателен.
    try {
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
        } catch (e, st) {
          debugPrint('[qr-login] signInWithCustomToken failed: $e\n$st');
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
        _refreshTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) _start();
        });
      }
    } catch (e, st) {
      debugPrint('[qr-login] _onSession unexpected: $e\n$st');
      if (!mounted) return;
      setState(() {
        _phase = _QrPhase.error;
        _error = 'Snapshot handler: $e';
        _consuming = false;
      });
    }
  }

  // Билдер payload вынесен в публичный `buildQrLoginPayload` в
  // `lighchat_firebase`, чтобы Dart-тесты могли проверять roundtrip
  // против `parseQrLoginPayload`.

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
                              padding: const EdgeInsets.all(14),
                              child: SizedBox(
                                width: 304,
                                height: 304,
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
        // QR с врезанным маяком и анимированным диагональным shimmer-«лучом».
        // Маяк рендерится **поверх** QR ручным Stack'ом (не через
        // qr_flutter `embeddedImage`, который даёт некрасивые артефакты на
        // тёмном фоне) — чёткий PNG в белом круге. ECC поднят до high,
        // чтобы 30% перекрытие данных оставалось восстанавливаемым.
        //
        // Порядок слоёв критически важен:
        //   [0] QR (модули)
        //   [1] shimmer-overlay (полупрозрачная диагональная полоса)
        //   [2] **маяк сверху всех** — чтобы shimmer его не затирал
        // Иначе анимированный «луч» с alpha 30-40% ослабляет PNG до
        // полупрозрачности, и в release-сборке он визуально пропадает.
        final qrColor = dark ? Colors.white : Colors.black;
        return Stack(
          alignment: Alignment.center,
          // НЕ ставим `fit: StackFit.passthrough` — он передаёт tight
          // constraints (304×304) во все non-positioned children, и
          // SizedBox маяка раздувается до размера всего Stack. Default
          // loose-fit оставляет SizedBox в его реальных размерах.
          children: [
            QrImageView(
              data: encoded,
              version: QrVersions.auto,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              padding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: qrColor,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: qrColor,
              ),
            ),
            // Shimmer — ПОД маяком, чтобы свет шёл по QR-модулям, но не
            // приглушал брендовый PNG в центре.
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _shineCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _LightSweepPainter(
                      progress: _shineCtrl.value,
                      color: qrColor,
                    ),
                  ),
                ),
              ),
            ),
            // Брендовый маяк — самым верхним слоем.
            //
            // Размер 36×36 (~12% стороны QR при 304px box). Паритет с
            // Telegram-style QR (≈12%). ECC level H (~30% избыточности)
            // покрывает с большим запасом, сканер читает уверенно.
            //
            // Center-обёртка явно фиксирует layout: SizedBox получает
            // loose-constraints от Center, а не tight от Stack — иначе
            // SizedBox(36×36) визуально раздувается до размеров Stack.
            const Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: ColoredBox(
                      // Brand navy — контраст маяку независимо от темы QR.
                      color: Color(0xFF1E3A5F),
                      child: Padding(
                        padding: EdgeInsets.all(3),
                        child: Image(
                          image: AssetImage('assets/lighchat_mark.png'),
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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

/// Анимированный «луч маяка» поверх QR-кода: диагональная полоса с soft-edges,
/// которая ездит из левого верхнего угла в правый нижний и обратно.
///
/// Использует обычный [BlendMode.srcOver] (default) с полупрозрачным
/// градиентом — это безопасно на любом GPU, в т.ч. в release-iOS, где
/// `BlendMode.plus` через `saveLayer` мог падать на старых устройствах.
/// Эффект «свечения» получается за счёт alpha 25-40% поверх QR.
class _LightSweepPainter extends CustomPainter {
  _LightSweepPainter({required this.progress, required this.color});

  /// 0..1, замкнутая фаза анимации (контроллер `repeat()`).
  final double progress;

  /// Базовый цвет QR — берётся из foreground/eye/dataModule. Луч светит
  /// «осветлённой» версией этого цвета: для тёмной темы — белый, для
  /// светлой — мягкий тёплый белый, чтобы не выглядеть как засветка камеры.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || !size.isFinite) return;
    // Полоса шириной ~32% — заметно шире, чем раньше, чтобы переход света
    // был хорошо виден поверх QR-модулей.
    final stripeWidth = size.shortestSide * 0.32;
    final travel = size.shortestSide + stripeWidth;
    final t = progress.clamp(0.0, 1.0);
    final dx = -stripeWidth + travel * t;
    final dy = -stripeWidth + travel * t;

    // Заметная альфа — чтобы «луч маяка» был хорошо различим даже на
    // плотном QR-узоре. Тёплый кремовый оттенок ассоциируется со светом
    // лампы маяка.
    final isDark = color.computeLuminance() > 0.5;
    final highlight = isDark
        ? const Color(0xFFFFF5DC).withValues(alpha: 0.70)
        : const Color(0xFFFFE8B0).withValues(alpha: 0.55);

    final gradientRect = Rect.fromLTWH(
      dx,
      dy,
      size.width + stripeWidth,
      size.height + stripeWidth,
    );
    final shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.transparent,
        highlight.withValues(alpha: 0.0),
        highlight,
        highlight.withValues(alpha: 0.0),
        Colors.transparent,
      ],
      stops: const [0.0, 0.40, 0.5, 0.60, 1.0],
    ).createShader(gradientRect);

    final paint = Paint()..shader = shader;
    // Default BlendMode.srcOver — поверх QR ложится полупрозрачный слой,
    // никаких saveLayer/Plus, на любом GPU это работает одинаково.
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _LightSweepPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
