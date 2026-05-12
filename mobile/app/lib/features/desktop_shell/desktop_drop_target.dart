import 'dart:io' show File, Platform;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../chat/data/share_intent_payload.dart';

/// Глобальный приёмник drag&drop файлов на desktop. Перехватывает все файлы,
/// сброшенные на окно приложения, и роутит их через существующий
/// `/share` flow — пользователь выбирает целевой чат, как при системном
/// «Поделиться».
///
/// Должна быть выше [Router] в дереве (используется в `MaterialApp.builder`).
class DesktopDropTarget extends StatefulWidget {
  const DesktopDropTarget({super.key, required this.child, this.router});

  final Widget child;

  /// Опционально — `GoRouter`, если построение дерева расходится. Если null,
  /// берётся через `GoRouter.of(context)`.
  final GoRouter? router;

  static bool get isActive {
    if (kIsWeb) return false;
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  @override
  State<DesktopDropTarget> createState() => _DesktopDropTargetState();
}

class _DesktopDropTargetState extends State<DesktopDropTarget> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    if (!DesktopDropTarget.isActive) return widget.child;
    return DropTarget(
      onDragEntered: (_) => setState(() => _hovering = true),
      onDragExited: (_) => setState(() => _hovering = false),
      onDragDone: (detail) => _handleDrop(detail.files),
      child: Stack(
        children: [
          widget.child,
          if (_hovering)
            const Positioned.fill(
              child: IgnorePointer(
                child: _DropOverlay(),
              ),
            ),
        ],
      ),
    );
  }

  void _handleDrop(List<XFile> files) {
    setState(() => _hovering = false);
    if (files.isEmpty) return;

    // Конвертируем в формат composer'а. desktop_drop отдаёт XFile уже
    // нативные (с path), text-only drop игнорируем.
    final accepted = <XFile>[];
    for (final f in files) {
      final path = f.path.trim();
      if (path.isEmpty) continue;
      if (!File(path).existsSync()) continue;
      accepted.add(f);
    }
    if (accepted.isEmpty) return;

    final payload = ShareIntentPayload(files: accepted);
    final router = widget.router ?? GoRouter.of(context);
    router.push('/share', extra: payload);
  }
}

class _DropOverlay extends StatelessWidget {
  const _DropOverlay();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color, width: 3),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.upload_file, size: 32, color: color),
              const SizedBox(width: 12),
              Text(
                'Отпустите, чтобы поделиться',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
