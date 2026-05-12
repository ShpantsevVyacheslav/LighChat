import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../platform/platform_capabilities.dart';

/// Глобальные клавиатурные шорткаты для десктопа.
///
/// На mobile (compact) — no-op, дерево widget'ов проходит как есть.
/// На desktop оборачивает [child] в Shortcuts+Actions, которые маршрутят:
///   - `Cmd/Ctrl+N` — новый чат → `/new`
///   - `Cmd/Ctrl+,` — настройки → `/settings`
///   - `Cmd/Ctrl+K` — глобальный поиск (открывает search dialog)
///   - `Esc` — закрыть текущий диалог / вернуться (handled by Navigator)
///
/// Хелпер вставляется один раз на корне приложения (см. main.dart),
/// чтобы шорткаты работали независимо от того, какой экран открыт.
class DesktopShortcuts extends StatelessWidget {
  const DesktopShortcuts({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!defaultPlatformCapabilities.isDesktop) return child;

    final isMac = defaultTargetPlatform == TargetPlatform.macOS;
    final cmd = isMac
        ? const SingleActivator(LogicalKeyboardKey.keyN, meta: true)
        : const SingleActivator(LogicalKeyboardKey.keyN, control: true);
    final settings = isMac
        ? const SingleActivator(LogicalKeyboardKey.comma, meta: true)
        : const SingleActivator(LogicalKeyboardKey.comma, control: true);
    final search = isMac
        ? const SingleActivator(LogicalKeyboardKey.keyK, meta: true)
        : const SingleActivator(LogicalKeyboardKey.keyK, control: true);

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        cmd: const _NewChatIntent(),
        settings: const _OpenSettingsIntent(),
        search: const _OpenSearchIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _NewChatIntent: CallbackAction<_NewChatIntent>(
            onInvoke: (_) {
              context.push('/new');
              return null;
            },
          ),
          _OpenSettingsIntent: CallbackAction<_OpenSettingsIntent>(
            onInvoke: (_) {
              context.push('/settings');
              return null;
            },
          ),
          _OpenSearchIntent: CallbackAction<_OpenSearchIntent>(
            onInvoke: (_) {
              showDialog<void>(
                context: context,
                builder: (ctx) => const _GlobalSearchPlaceholder(),
              );
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}

class _NewChatIntent extends Intent {
  const _NewChatIntent();
}

class _OpenSettingsIntent extends Intent {
  const _OpenSettingsIntent();
}

class _OpenSearchIntent extends Intent {
  const _OpenSearchIntent();
}

/// Заглушка под global-search dialog. Реальный поиск (по сообщениям, чатам,
/// контактам) подключим, когда будет готов `searchProvider`.
class _GlobalSearchPlaceholder extends StatelessWidget {
  const _GlobalSearchPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 400),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.search),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Глобальный поиск',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Чаты, контакты, сообщения…',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Поиск пока в разработке. На клиенте можно открыть нужный '
                  'чат вручную через список слева.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
