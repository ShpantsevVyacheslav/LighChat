import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lighchat_mobile/app_providers.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseReady = ref.watch(firebaseReadyProvider);
    final userAsync = ref.watch(authUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                firebaseReady
                    ? 'Firebase initialized. You can sign in.'
                    : 'Firebase is not ready. Check logs and `firebase_options.dart`.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              userAsync.when(
                data: (user) {
                  if (user != null) {
                    return FilledButton(
                      onPressed: () => context.go('/chats'),
                      child: const Text('Continue'),
                    );
                  }
                  return FilledButton(
                    onPressed: firebaseReady
                        ? () async {
                          try {
                            final repo = ref.read(authRepositoryProvider);
                            if (repo == null) return;
                            await repo.signInAnonymously();
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Auth error: $e')),
                            );
                          }
                          }
                        : null,
                    child: const Text('Sign in anonymously'),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => SelectableText(
                  'Auth error: $e\n\n'
                  'If you see invalid app / options, register this app in Firebase Console '
                  'and run FlutterFire configure to refresh app IDs.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.error,
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

