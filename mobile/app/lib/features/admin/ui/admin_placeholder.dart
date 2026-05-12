import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Общий placeholder-скелет для админских экранов, ещё не перенесённых
/// полностью из веб-версии. Показывает заголовок + bullets с тем, что
/// будет реализовано + кнопку «Открыть в браузере» (на веб-версию).
class AdminPlaceholder extends StatelessWidget {
  const AdminPlaceholder({
    super.key,
    required this.title,
    required this.description,
    required this.bullets,
    required this.webRoute,
    this.icon,
  });

  final String title;
  final String description;
  final List<String> bullets;

  /// Путь в веб-версии (`/dashboard/admin/...`), куда отправить
  /// при клике «Открыть в браузере».
  final String webRoute;

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Icon(icon, size: 64, color: color.primary),
                ),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              for (final b in bullets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6, right: 12),
                        child: Icon(Icons.check_circle_outline, size: 18),
                      ),
                      Expanded(child: Text(b)),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Открыть в веб-версии'),
                onPressed: () => unawaitedLaunch(webRoute),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> unawaitedLaunch(String webRoute) async {
    final uri = Uri.parse('https://lighchat.online$webRoute');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
