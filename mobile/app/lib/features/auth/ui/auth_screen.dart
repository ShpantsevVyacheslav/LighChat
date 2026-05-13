import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:lighchat_mobile/app_providers.dart';

import '../registration_profile_gate.dart';
import 'auth_brand_header.dart';
import 'login_form.dart';
import 'register_form.dart';
import 'telegram_sign_in_webview_screen.dart';
import 'yandex_sign_in_webview_screen.dart';
import '../../shared/ui/app_back_button.dart';
import '../../shared/ui/platform_keyboard_dismiss_behavior.dart';
import '../../../l10n/app_localizations.dart';
import '../../analytics/analytics_events.dart';
import '../../analytics/analytics_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

/// Этап stepper'а на экране входа.
///  - [entry] — две большие CTA: «Войти» (→ /auth/qr) и «Создать аккаунт».
///  - [methods] — текущая форма email/password + OAuth-сетка.
enum _AuthStage { entry, methods }

/// Возвращает `true`, если OAuth (Google/Apple/Yandex/Telegram через
/// webview/provider) недоступен на текущей desktop-платформе. Показывает
/// пользователю осмысленное сообщение через SnackBar вместо unhandled
/// exception.
///
/// - **macOS**: `firebase_auth_macos` не реализует `signInWithProvider`.
/// - **Windows**: нет нативного плагина `webview_flutter` →
///   `WebViewController()` бросает `Null check operator used on a null
///   value`. То же касается `cloud_functions` (`Unable to establish
///   connection on channel`).
///
/// На обоих desktop-платформах рекомендуем email/QR-вход.
bool oauthBlockedOnMacOSCheck(BuildContext context) {
  if (kIsWeb) return false;
  final isMac = defaultTargetPlatform == TargetPlatform.macOS;
  final isWindows = defaultTargetPlatform == TargetPlatform.windows;
  final isLinux = defaultTargetPlatform == TargetPlatform.linux;
  if (!isMac && !isWindows && !isLinux) return false;

  final platformName =
      isMac ? 'macOS' : (isWindows ? 'Windows' : 'Linux');
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(
      content: Text(
        'Вход через Google/Apple/Яндекс/Telegram на $platformName-Desktop '
        'пока недоступен (нет нативного firebase_auth / webview SDK). '
        'Используйте email + пароль или QR-вход.',
      ),
      duration: const Duration(seconds: 6),
    ),
  );
  return true;
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _busy = false;
  String? _error;
  bool _redirectingSignedInUser = false;
  _AuthStage _stage = _AuthStage.entry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).logEvent(
            AnalyticsEvents.authScreenView,
            const <String, Object?>{'initial_method_hint': 'entry'},
          );
    });
  }

  Future<void> _openRegisterSheet() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const _RegisterFullScreenPage()),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    if (!mounted) return;
    GoRouter.of(context).push('/legal/privacy-policy');
  }

  Future<void> _continueOAuthAndRoute(
    AuthRepository repo,
    Future<void> Function() signIn,
  ) async {
    if (oauthBlockedOnMacOSCheck(context)) return;
    final ok = await _run(signIn, goChatsOnSuccess: false);
    if (!ok || !mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go('/auth');
      return;
    }
    final status = await getFirestoreRegistrationProfileStatusWithDeadline(
      user,
    );
    if (!mounted) return;
    final next = googleRouteFromProfileStatus(status);
    if (next == null) {
      context.go('/chats');
      return;
    }
    context.go(next);
  }

  /// Контент entry-этапа (две CTA: войти / создать аккаунт). Альтернативная
  /// форма с email и OAuth-сеткой открывается по «Войти другим способом».
  List<Widget> _buildEntryStage({
    required AppLocalizations l10n,
    required bool dark,
    required ColorScheme scheme,
    required bool firebaseReady,
  }) {
    return [
      const SizedBox(height: 6),
      // Главная CTA: тот же градиент, что у «Sign in» в LoginForm и у
      // «Sign in with QR» на methods-этапе. Один визуальный аккорд для
      // primary-действия на любой стадии экрана входа.
      _GradientPrimaryButton(
        enabled: firebaseReady,
        icon: Icons.qr_code_2,
        label: l10n.auth_entry_sign_in,
        onPressed: () => context.push('/auth/qr'),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        icon: const Icon(Icons.person_add_alt_1, size: 20),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          side: BorderSide(
            color: dark
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.12),
          ),
          backgroundColor: dark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.white.withValues(alpha: 0.50),
          foregroundColor: dark ? Colors.white : scheme.onSurface,
        ),
        onPressed: (!firebaseReady || _busy) ? null : _openRegisterSheet,
        label: Text(
          l10n.auth_entry_sign_up,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const SizedBox(height: 18),
      Center(
        child: TextButton(
          onPressed: () => setState(() => _stage = _AuthStage.methods),
          style: TextButton.styleFrom(
            foregroundColor:
                (dark ? Colors.white : scheme.onSurface).withValues(alpha: 0.7),
          ),
          child: Text(
            l10n.auth_qr_other_method,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    ];
  }

  Future<bool> _run(
    Future<void> Function() fn, {
    required bool goChatsOnSuccess,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await fn();
      if (!mounted) return true;
      if (goChatsOnSuccess) context.go('/chats');
      return true;
    } catch (e) {
      setState(() => _error = friendlyAuthError(e));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final firebaseReady = ref.watch(firebaseReadyProvider);
    final userAsync = ref.watch(authUserProvider);
    final repo = ref.watch(authRepositoryProvider);

    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final signedInUser = userAsync.asData?.value;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    if (signedInUser != null && !_redirectingSignedInUser) {
      _redirectingSignedInUser = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/chats');
      });
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _AuthLoginBackdrop(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            platformScrollKeyboardDismissBehavior(),
                        padding: EdgeInsets.fromLTRB(
                          22,
                          6,
                          22,
                          keyboardVisible ? 16 : 28,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 10),
                            const Center(child: AuthBrandHeader()),
                            const SizedBox(height: 8),
                            Text(
                              l10n.auth_brand_tagline,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 23 / 2,
                                fontWeight: FontWeight.w500,
                                color: (dark ? Colors.white : scheme.onSurface)
                                    .withValues(alpha: 0.56),
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (!firebaseReady)
                              Text(
                                l10n.auth_firebase_not_ready,
                                style: TextStyle(color: scheme.error),
                              ),
                            userAsync.when(
                              data: (u) => u == null
                                  ? const SizedBox.shrink()
                                  : Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Center(
                                        child: Column(
                                          children: [
                                            const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              l10n.auth_redirecting_to_chats,
                                              style: TextStyle(
                                                color:
                                                    (dark
                                                            ? Colors.white
                                                            : scheme.onSurface)
                                                        .withValues(
                                                          alpha: 0.62,
                                                        ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                              loading: () => const SizedBox.shrink(),
                              error: (e, _) => Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  'Auth error: $e',
                                  style: TextStyle(color: scheme.error),
                                ),
                              ),
                            ),
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: scheme.error),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            if (_stage == _AuthStage.entry)
                              ..._buildEntryStage(
                                l10n: l10n,
                                dark: dark,
                                scheme: scheme,
                                firebaseReady: firebaseReady,
                              ),
                            if (_stage == _AuthStage.methods) ...[
                              LoginForm(onDone: () => context.go('/chats')),
                              const SizedBox(height: 22),
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: (dark
                                              ? Colors.white
                                              : scheme.onSurface)
                                          .withValues(alpha: 0.12),
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: Text(
                                      l10n.auth_or,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.4,
                                        color:
                                            (dark
                                                    ? Colors.white
                                                    : scheme.onSurface)
                                                .withValues(alpha: 0.42),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: (dark
                                              ? Colors.white
                                              : scheme.onSurface)
                                          .withValues(alpha: 0.12),
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _SocialAuthIconTile(
                                      dark: dark,
                                      tooltip: 'Google',
                                      onPressed:
                                          (!firebaseReady ||
                                              repo == null ||
                                              _busy)
                                          ? null
                                          : () => _continueOAuthAndRoute(
                                              repo,
                                              () => repo.signInWithGoogle(),
                                            ),
                                      child: const _GoogleBrandIcon(),
                                    ),
                                  ),
                                  if (defaultTargetPlatform ==
                                      TargetPlatform.iOS) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _SocialAuthIconTile(
                                        dark: dark,
                                        tooltip: 'Apple',
                                        background: dark
                                            ? Colors.white.withValues(
                                                alpha: 0.08,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.88,
                                              ),
                                        iconColor: Colors.white,
                                        onPressed:
                                            (!firebaseReady ||
                                                repo == null ||
                                                _busy)
                                            ? null
                                            : () => _continueOAuthAndRoute(
                                                repo,
                                                () => repo.signInWithApple(),
                                              ),
                                        child:
                                            const Icon(Icons.apple, size: 24),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _SocialAuthIconTile(
                                      dark: dark,
                                      tooltip: 'Telegram',
                                      onPressed: (!firebaseReady || _busy)
                                          ? null
                                          : () {
                                              Navigator.of(context).push<void>(
                                                MaterialPageRoute<void>(
                                                  fullscreenDialog: true,
                                                  builder: (_) =>
                                                      const TelegramSignInWebViewScreen(),
                                                ),
                                              );
                                            },
                                      child: const _TelegramBrandIcon(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _SocialAuthIconTile(
                                      dark: dark,
                                      tooltip: 'Yandex',
                                      onPressed: (!firebaseReady || _busy)
                                          ? null
                                          : () {
                                              Navigator.of(context).push<void>(
                                                MaterialPageRoute<void>(
                                                  fullscreenDialog: true,
                                                  builder: (_) =>
                                                      const YandexSignInWebViewScreen(),
                                                ),
                                              );
                                            },
                                      child: const _YandexBrandIcon(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
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
                                onPressed: (!firebaseReady || _busy)
                                    ? null
                                    : _openRegisterSheet,
                                child: Text(l10n.auth_create_account),
                              ),
                              const SizedBox(height: 12),
                              _GradientPrimaryButton(
                                enabled: firebaseReady,
                                icon: Icons.qr_code_2,
                                label: l10n.auth_qr_use_qr_login,
                                onPressed: () => context.push('/auth/qr'),
                              ),
                            ],
                            const SizedBox(height: 4),
                            if (!keyboardVisible)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: TextButton(
                                  onPressed: _openPrivacyPolicy,
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        (dark ? Colors.white : scheme.onSurface)
                                            .withValues(alpha: 0.56),
                                    padding: EdgeInsets.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    l10n.auth_privacy_policy,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
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
          ),
        ],
      ),
    );
  }
}

/// Плитка-иконка в ряду соцвходов (как сетка на вебе).
class _SocialAuthIconTile extends StatelessWidget {
  const _SocialAuthIconTile({
    required this.dark,
    required this.tooltip,
    required this.onPressed,
    required this.child,
    this.background,
    this.iconColor,
  });

  final bool dark;
  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;
  final Color? background;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final bg =
        background ??
        (dark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.76));
    Widget icon = child;
    if (iconColor != null) {
      icon = IconTheme(
        data: IconThemeData(color: iconColor),
        child: DefaultTextStyle(
          style: TextStyle(color: iconColor),
          child: child,
        ),
      );
    }
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: dark
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.12),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: SizedBox(height: 44, child: Center(child: icon)),
        ),
      ),
    );
  }
}

class _GoogleBrandIcon extends StatelessWidget {
  const _GoogleBrandIcon();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/google_icon.png',
      width: 20,
      height: 20,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class _YandexBrandIcon extends StatelessWidget {
  const _YandexBrandIcon();

  // Раньше иконка собиралась через `<text dominant-baseline="central">` в SVG,
  // но flutter_svg рендерит этот атрибут неконсистентно — буква «Я» уходила
  // вверх. Чистый Flutter-стек гарантирует геометрическое центрирование.
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 24,
      height: 24,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFFFC3F1D),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            'Я',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.0,
              // height:1.0 убирает встроенный font leading; Center внутри
              // SizedBox 24×24 даёт точный геометрический центр.
            ),
          ),
        ),
      ),
    );
  }
}

class _TelegramBrandIcon extends StatelessWidget {
  const _TelegramBrandIcon();

  static const String _webTelegramSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path fill="currentColor" d="M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.479.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.893-.663 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    final color =
        IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    return SvgPicture.string(
      _webTelegramSvg,
      width: 24,
      height: 24,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

class _AuthLoginBackdrop extends StatelessWidget {
  const _AuthLoginBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(decoration: BoxDecoration(color: Color(0xFF04070C))),
        Positioned(
          left: -120,
          top: -80,
          child: IgnorePointer(
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1E5FFF).withValues(alpha: 0.36),
                    const Color(0xFF1E5FFF).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: -90,
          bottom: -120,
          child: IgnorePointer(
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7217FF).withValues(alpha: 0.28),
                    const Color(0xFF7217FF).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RegisterFullScreenPage extends StatelessWidget {
  const _RegisterFullScreenPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _AuthLoginBackdrop(),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const AppBackButton(fallbackLocation: '/auth'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.auth_create_account,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Expanded(
                        child: SingleChildScrollView(
                          child: _RegisterSheetBody(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterSheetBody extends ConsumerStatefulWidget {
  const _RegisterSheetBody();

  @override
  ConsumerState<_RegisterSheetBody> createState() => _RegisterSheetBodyState();
}

class _RegisterSheetBodyState extends ConsumerState<_RegisterSheetBody> {
  bool _busy = false;
  String? _oauthError;

  /// Запускает OAuth-вход и направляет: если профиль уже полный — в `/chats`,
  /// если нет — в анкету `/auth/google-complete` (там же достраивается профиль).
  /// Это и есть «регистрация через Google/Apple/Telegram/Yandex»: первый
  /// успешный signIn создаёт users/{uid} через CF onUserCreated, дальше
  /// дозаполняется при необходимости.
  Future<void> _runOAuth(Future<void> Function() signIn) async {
    debugPrint('[UI-AUTH] OAuth flow: Starting...');

    if (oauthBlockedOnMacOSCheck(context)) {
      debugPrint('[UI-AUTH] OAuth flow: Blocked on macOS/Desktop');
      return;
    }

    setState(() {
      _busy = true;
      _oauthError = null;
    });
    debugPrint('[UI-AUTH] OAuth flow: UI state set to busy');

    try {
      debugPrint('[UI-AUTH] OAuth flow: Calling signIn function...');
      await signIn();
      debugPrint('[UI-AUTH] OAuth flow: signIn completed successfully');

      if (!mounted) {
        debugPrint('[UI-AUTH] OAuth flow: Widget unmounted, returning');
        return;
      }

      debugPrint('[UI-AUTH] OAuth flow: Checking current user...');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('[UI-AUTH] OAuth flow: ERROR - No current user after sign-in!');
        return;
      }
      debugPrint('[UI-AUTH] OAuth flow: Current user: ${user.uid}');

      debugPrint('[UI-AUTH] OAuth flow: Getting registration profile status...');
      final status =
          await getFirestoreRegistrationProfileStatusWithDeadline(user);
      debugPrint('[UI-AUTH] OAuth flow: Profile status: $status');

      if (!mounted) {
        debugPrint('[UI-AUTH] OAuth flow: Widget unmounted before routing');
        return;
      }

      final next = googleRouteFromProfileStatus(status);
      debugPrint('[UI-AUTH] OAuth flow: Next route: $next');

      // Закрываем register-страницу, чтобы не остаться над dashboard'ом.
      Navigator.of(context).pop();
      if (!mounted) {
        debugPrint('[UI-AUTH] OAuth flow: Widget unmounted before navigation');
        return;
      }

      debugPrint('[UI-AUTH] OAuth flow: SUCCESS - Navigating to ${next ?? '/chats'}');
      context.go(next ?? '/chats');
    } catch (e) {
      debugPrint('[UI-AUTH] OAuth flow: ERROR - $e');
      debugPrint('[UI-AUTH] Error type: ${e.runtimeType}');
      debugPrint('[UI-AUTH] Error details: ${e.toString()}');

      if (!mounted) {
        debugPrint('[UI-AUTH] OAuth flow: Widget unmounted, error not shown');
        return;
      }

      setState(() => _oauthError = friendlyAuthError(e));
      debugPrint('[UI-AUTH] OAuth flow: Error message shown to user');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        debugPrint('[UI-AUTH] OAuth flow: UI state reset to not busy');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final firebaseReady = ref.watch(firebaseReadyProvider);
    final repo = ref.watch(authRepositoryProvider);
    // На macOS firebase_auth_macos не реализует `signInWithProvider`
    // (logs: "signInWithProvider is not supported on the MacOS platform.").
    // Поэтому OAuth-кнопки (Google/Apple/Yandex/Telegram) на macOS Debug
    // disabled до тех пор, пока не подключим Google Sign-In SDK / Yandex
    // OAuth webview напрямую и не получим customToken через CF.
    // Desktop без нативного firebase_auth_*/webview — OAuth недоступен.
    // Кнопки disabled; `oauthBlockedOnMacOSCheck` уже отшибает повторный
    // тап SnackBar'ом. См. комментарий в `auth_screen.dart::oauthBlockedOnMacOSCheck`.
    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);
    final canOAuth = firebaseReady && repo != null && !_busy && !isDesktop;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // OAuth-сетка как на этапе methods для входа: один вид UI →
        // одинаковая иконка и поведение для регистрации тоже.
        Row(
          children: [
            Expanded(
              child: _SocialAuthIconTile(
                dark: dark,
                tooltip: 'Google',
                onPressed: !canOAuth
                    ? null
                    : () => _runOAuth(() => repo.signInWithGoogle()),
                child: const _GoogleBrandIcon(),
              ),
            ),
            if (defaultTargetPlatform == TargetPlatform.iOS) ...[
              const SizedBox(width: 8),
              Expanded(
                child: _SocialAuthIconTile(
                  dark: dark,
                  tooltip: 'Apple',
                  background: dark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.88),
                  iconColor: Colors.white,
                  onPressed: !canOAuth
                      ? null
                      : () => _runOAuth(() => repo.signInWithApple()),
                  child: const Icon(Icons.apple, size: 24),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Expanded(
              child: _SocialAuthIconTile(
                dark: dark,
                tooltip: 'Telegram',
                onPressed: (!firebaseReady || _busy)
                    ? null
                    : () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            fullscreenDialog: true,
                            builder: (_) =>
                                const TelegramSignInWebViewScreen(),
                          ),
                        );
                      },
                child: const _TelegramBrandIcon(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SocialAuthIconTile(
                dark: dark,
                tooltip: 'Yandex',
                onPressed: (!firebaseReady || _busy)
                    ? null
                    : () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            fullscreenDialog: true,
                            builder: (_) =>
                                const YandexSignInWebViewScreen(),
                          ),
                        );
                      },
                child: const _YandexBrandIcon(),
              ),
            ),
          ],
        ),
        if (_oauthError != null) ...[
          const SizedBox(height: 10),
          Text(
            _oauthError!,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.error),
          ),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Divider(
                color:
                    (dark ? Colors.white : scheme.onSurface).withValues(alpha: 0.12),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                l10n.auth_or,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: (dark ? Colors.white : scheme.onSurface)
                      .withValues(alpha: 0.42),
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color:
                    (dark ? Colors.white : scheme.onSurface).withValues(alpha: 0.12),
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        RegisterForm(
          onDone: () {
            Navigator.of(context).pop();
            if (context.mounted) {
              context.go('/chats');
            }
          },
        ),
      ],
    );
  }
}

/// Главная градиентная CTA-кнопка (паритет с «Sign in» в [`login_form.dart`]).
/// Используется для «Sign in with QR» и других primary-действий, чтобы один и
/// тот же визуальный аккорд звучал на entry- и methods-этапе экрана входа.
class _GradientPrimaryButton extends StatelessWidget {
  const _GradientPrimaryButton({
    required this.enabled,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: enabled
              ? const [
                  Color(0xFF2E86FF),
                  Color(0xFF5F90FF),
                  Color(0xFF9A18FF),
                ]
              : [
                  Colors.white.withValues(alpha: 0.18),
                  Colors.white.withValues(alpha: 0.18),
                ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: SizedBox(
        height: 56,
        child: TextButton(
          onPressed: enabled ? onPressed : null,
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            foregroundColor: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
