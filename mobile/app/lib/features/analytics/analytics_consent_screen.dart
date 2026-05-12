import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_provider.dart';

/// Однократный экран consent'а на аналитику. Показывается в onboarding до
/// auth-screen. Решение хранится в SharedPreferences (см. AnalyticsService).
class AnalyticsConsentScreen extends ConsumerWidget {
  const AnalyticsConsentScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.insights_outlined,
                  size: 56, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Помогите нам улучшить LighChat',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Можно ли использовать анонимную статистику использования (открытие экранов, ошибки, '
                'количество чатов) для улучшения приложения? Содержимое сообщений и звонков '
                'никогда не передаётся.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  await ref.read(analyticsServiceProvider).setConsent('all');
                  onDone();
                },
                child: const Text('Разрешить'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(analyticsServiceProvider).setConsent('required');
                  onDone();
                },
                child: const Text('Только необходимое'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
