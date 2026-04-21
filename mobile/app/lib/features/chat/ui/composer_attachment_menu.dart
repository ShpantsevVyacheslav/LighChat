import 'dart:ui';

import 'package:flutter/material.dart';

/// Действия меню скрепки (паритет веб-меню вложений + мобильные источники).
enum ComposerAttachmentAction {
  /// Галерея / камера фото / камера видео (через подменю).
  photoVideo,

  /// Системный выбор файлов (iOS/Android).
  deviceFiles,
  clipboard,
  videoCircle,
  location,
  poll,
  stickersGif,
  format,
}

/// Стеклянная панель пунктов (иконка + подпись).
class ComposerAttachmentMenuPanel extends StatelessWidget {
  const ComposerAttachmentMenuPanel({
    super.key,
    required this.onItemTap,
    required this.onClose,
  });

  final void Function(ComposerAttachmentAction action) onItemTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final titleColor = Colors.white.withValues(alpha: 0.95);
    final labelColor = Colors.white.withValues(alpha: 0.84);
    final items =
        <
          ({
            ComposerAttachmentAction action,
            IconData icon,
            String label,
            Color color,
          })
        >[
          (
            action: ComposerAttachmentAction.photoVideo,
            icon: Icons.photo_camera_outlined,
            label: 'Фото/Видео',
            color: const Color(0xFF8B3DFF),
          ),
          (
            action: ComposerAttachmentAction.deviceFiles,
            icon: Icons.insert_drive_file_outlined,
            label: 'Файлы',
            color: const Color(0xFF2D7BFF),
          ),
          (
            action: ComposerAttachmentAction.videoCircle,
            icon: Icons.radio_button_checked_rounded,
            label: 'Кружок',
            color: const Color(0xFFFF2C9C),
          ),
          (
            action: ComposerAttachmentAction.location,
            icon: Icons.location_on_outlined,
            label: 'Локация',
            color: const Color(0xFF04C853),
          ),
          (
            action: ComposerAttachmentAction.poll,
            icon: Icons.receipt_long_rounded,
            label: 'Опрос',
            color: const Color(0xFFFF7A00),
          ),
          (
            action: ComposerAttachmentAction.stickersGif,
            icon: Icons.emoji_emotions_outlined,
            label: 'Стикеры',
            color: const Color(0xFFE8AA00),
          ),
          (
            action: ComposerAttachmentAction.clipboard,
            icon: Icons.content_paste_rounded,
            label: 'Буфер',
            color: const Color(0xFF1AB6E6),
          ),
          (
            action: ComposerAttachmentAction.format,
            icon: Icons.text_fields_rounded,
            label: 'Текст',
            color: const Color(0xFF5A56FF),
          ),
        ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final tileW = ((width - 18) / 4).clamp(66.0, 88.0);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Прикрепить',
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Material(
                        color: Colors.white.withValues(alpha: 0.10),
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: onClose,
                          customBorder: const CircleBorder(),
                          child: SizedBox(
                            width: 38,
                            height: 38,
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white.withValues(alpha: 0.78),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 12,
                    children: [
                      for (final item in items)
                        SizedBox(
                          width: tileW,
                          child: _MenuGridActionTile(
                            icon: item.icon,
                            label: item.label,
                            color: item.color,
                            labelColor: labelColor,
                            onTap: () => onItemTap(item.action),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MenuGridActionTile extends StatelessWidget {
  const _MenuGridActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.labelColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: Colors.white.withValues(alpha: 0.10),
        highlightColor: Colors.white.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.95),
                      color.withValues(alpha: 0.78),
                    ],
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Меню у нижнего края, высота по контенту; [bottomFromScreenBottom] — отступ низа панели от низа экрана
/// (до верхней границы композера).
OverlayEntry showComposerAttachmentOverlay({
  required BuildContext context,
  required double bottomFromScreenBottom,
  required void Function(ComposerAttachmentAction action) onSelected,
  void Function()? onDismissed,
}) {
  late OverlayEntry entry;
  void dismiss() {
    entry.remove();
    onDismissed?.call();
  }

  entry = OverlayEntry(
    builder: (ctx) {
      return Material(
        type: MaterialType.transparency,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: dismiss,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.40),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: bottomFromScreenBottom,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ComposerAttachmentMenuPanel(
                  onClose: dismiss,
                  onItemTap: (a) {
                    dismiss();
                    onSelected(a);
                  },
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  Overlay.of(context).insert(entry);
  return entry;
}
