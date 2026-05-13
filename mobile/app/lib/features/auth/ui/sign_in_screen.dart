import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lighchat_mobile/app_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../platform/native_nav_bar/nav_bar_config.dart';
import '../../../platform/native_nav_bar/native_nav_scaffold.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final firebaseReady = ref.watch(firebaseReadyProvider);
    final userAsync = ref.watch(authUserProvider);

    return NativeNavScaffold(
      top: NavBarTopConfig(title: NavBarTitle(title: l10n.sign_in_title)),
      onBack: () => Navigator.of(context).maybePop(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                firebaseReady
                    ? l10n.sign_in_firebase_ready
                    : l10n.sign_in_firebase_not_ready,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              userAsync.when(
                data: (user) {
                  if (user != null) {
                    return FilledButton(
                      onPressed: () => context.go('/chats'),
                      child: Text(l10n.sign_in_continue),
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
                              SnackBar(content: Text(l10n.sign_in_auth_error(e.toString()))),
                            );
                          }
                          }
                        : null,
                    child: Text(l10n.sign_in_anonymously),
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

