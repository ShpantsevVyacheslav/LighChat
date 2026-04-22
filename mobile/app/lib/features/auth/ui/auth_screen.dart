import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:lighchat_mobile/app_providers.dart';

import '../registration_profile_gate.dart';
import 'auth_brand_header.dart';
import 'login_form.dart';
import 'register_form.dart';
import 'telegram_sign_in_webview_screen.dart';
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
    final status = await getFirestoreRegistrationProfileStatusWithDeadline(user);
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
                                                color: (dark
                                                        ? Colors.white
                                                        : scheme.onSurface)
                                                    .withValues(alpha: 0.62),
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
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.white.withValues(alpha: 0.76),
                                foregroundColor: dark
                                    ? Colors.white
                                    : scheme.onSurface,
                              ),
                              onPressed:
                                  (!firebaseReady || repo == null || _busy)
                                  ? null
                                  : () => _continueOAuthAndRoute(
                                        repo,
                                        () => repo.signInWithGoogle(),
                                      ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const _GoogleBrandIcon(),
                                  const SizedBox(width: 12),
                                  const Text('Продолжить с Google'),
                                ],
                              ),
                            ),
                            if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                              const SizedBox(height: 10),
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
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.88),
                                  foregroundColor: dark
                                      ? Colors.white
                                      : Colors.white,
                                ),
                                onPressed:
                                    (!firebaseReady || repo == null || _busy)
                                    ? null
                                    : () => _continueOAuthAndRoute(
                                          repo,
                                          () => repo.signInWithApple(),
                                        ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.apple, size: 24),
                                    SizedBox(width: 10),
                                    Text('Продолжить с Apple'),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
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
                                    ? const Color(0xFF229ED9).withValues(alpha: 0.22)
                                    : const Color(0xFF229ED9).withValues(alpha: 0.14),
                                foregroundColor: dark
                                    ? Colors.white
                                    : scheme.onSurface,
                              ),
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
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 26,
                                    height: 26,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF229ED9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Text(
                                      'T',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text('Продолжить с Telegram'),
                                ],
                              ),
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
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
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
                  padding: EdgeInsets.only(
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
                          const Expanded(
                            child: Text(
                              'Создать аккаунт',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.white.withValues(alpha: 0.75),
                              border: Border.all(
                                color: (dark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.18),
                              ),
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(
                                Icons.close_rounded,
                                color: (dark ? Colors.white : scheme.onSurface)
                                    .withValues(alpha: 0.70),
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
