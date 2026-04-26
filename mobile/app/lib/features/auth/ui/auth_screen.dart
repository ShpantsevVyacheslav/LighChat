import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:lighchat_mobile/app_providers.dart';

import '../registration_profile_gate.dart';
import 'auth_brand_header.dart';
import 'login_form.dart';
import 'register_form.dart';
import 'telegram_sign_in_webview_screen.dart';
import 'yandex_sign_in_webview_screen.dart';
import '../../shared/ui/app_back_button.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _busy = false;
  String? _error;
  bool _redirectingSignedInUser = false;

  Future<void> _openRegisterSheet() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const _RegisterFullScreenPage()),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    const url = 'https://lighchat.app/privacy';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Не удалось открыть политику конфиденциальности'),
      ),
    );
  }

  Future<void> _continueOAuthAndRoute(
    AuthRepository repo,
    Future<void> Function() signIn,
  ) async {
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
                            ScrollViewKeyboardDismissBehavior.onDrag,
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
                              'Безопасный мессенджер',
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
                                'Firebase не готов. Проверь `firebase_options.dart` и GoogleService-Info.plist.',
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
                                              'Переходим в чаты...',
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
                            LoginForm(onDone: () => context.go('/chats')),
                            const SizedBox(height: 22),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color:
                                        (dark ? Colors.white : scheme.onSurface)
                                            .withValues(alpha: 0.12),
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  child: Text(
                                    'или',
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
                                    color:
                                        (dark ? Colors.white : scheme.onSurface)
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
                                          ? Colors.white.withValues(alpha: 0.08)
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
                                    tooltip: 'Яндекс',
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
                                foregroundColor: dark
                                    ? Colors.white
                                    : scheme.onSurface,
                              ),
                              onPressed: (!firebaseReady || _busy)
                                  ? null
                                  : _openRegisterSheet,
                              child: const Text('Создать аккаунт'),
                            ),
                            const SizedBox(height: 12),
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
                                  child: const Text(
                                    'Политика конфиденциальности',
                                    style: TextStyle(
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

  static const String _yandexSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="12" fill="#FC3F1D"/>
  <text
    x="12"
    y="12"
    fill="#FFFFFF"
    font-size="16"
    font-weight="800"
    text-anchor="middle"
    dominant-baseline="central"
    font-family="Inter,system-ui,-apple-system,Segoe UI,Roboto,Arial,sans-serif"
  >Я</text>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _yandexSvg,
      width: 24,
      height: 24,
      fit: BoxFit.contain,
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
                              'Создать аккаунт',
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

class _RegisterSheetBody extends ConsumerWidget {
  const _RegisterSheetBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RegisterForm(
      onDone: () {
        Navigator.of(context).pop();
        if (context.mounted) {
          context.go('/chats');
        }
      },
    );
  }
}
