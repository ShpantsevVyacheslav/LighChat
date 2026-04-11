import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:lighchat_mobile/app_providers.dart';

import '../registration_profile_gate.dart';
import 'auth_glass.dart';
import 'auth_brand_header.dart';
import 'auth_styles.dart';
import 'login_form.dart';
import 'register_form.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _openRegisterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        final maxH = media.size.height * 0.92;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: media.viewInsets.bottom + 16,
              top: 16,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 520, maxHeight: maxH),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Создать аккаунт',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Expanded(
                      child: SingleChildScrollView(child: _RegisterSheetBody()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
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

    return Scaffold(
      body: SafeArea(
        child: AuthBackground(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: AuthBrandHeader()),
                      const SizedBox(height: 12),
                      const SizedBox(height: 6),
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
                                child: FilledButton(
                                  onPressed: () => context.go('/chats'),
                                  child: const Text('Продолжить'),
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
                      const SizedBox(height: 12),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _error!,
                            style: TextStyle(color: scheme.error),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      LoginForm(onDone: () => context.go('/chats')),
                      const SizedBox(height: 12),
                      Text(
                        'или',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.4,
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        style: authOutlineButtonStyle(context),
                        onPressed: (!firebaseReady || repo == null || _busy)
                            ? null
                            : () async {
                                final ok = await _run(
                                  () => repo.signInWithGoogle(),
                                  goChatsOnSuccess: false,
                                );
                                if (!ok) return;
                                if (!context.mounted) return;
                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) {
                                  context.go('/auth');
                                  return;
                                }
                                final status =
                                    await getFirestoreRegistrationProfileStatusWithDeadline(
                                      user,
                                    );
                                if (!context.mounted) return;
                                final next = googleRouteFromProfileStatus(
                                  status,
                                );
                                if (next == null) {
                                  context.go('/chats');
                                  return;
                                }
                                context.go(next);
                              },
                        child: const Text('Продолжить с Google'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: (!firebaseReady || _busy)
                            ? null
                            : _openRegisterSheet,
                        child: const Text('Создать аккаунт'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
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
        if (context.mounted) context.go('/chats');
      },
    );
  }
}
