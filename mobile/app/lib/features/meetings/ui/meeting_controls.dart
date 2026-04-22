import 'package:flutter/material.dart';

import '../data/virtual_background_controller.dart';

/// Нижняя панель управления митинга: микрофон, камера, смена камеры,
/// рука, реакция, демонстрация экрана, фон (если включён native-бэкенд),
/// участники (открыть сайдбар) и красная кнопка «Выйти».
///
/// Набор кнопок растёт — чтобы не ломаться на узких экранах, строка
/// рендерится как горизонтальный скролл. На широких экранах визуально
/// ничего не меняется.
class MeetingControls extends StatelessWidget {
  const MeetingControls({
    super.key,
    required this.micMuted,
    required this.cameraMuted,
    required this.onToggleMic,
    required this.onToggleCamera,
    required this.onSwitchCamera,
    required this.onOpenSidebar,
    required this.onLeave,
    this.participantsCount = 0,
    this.requestsCount = 0,
    this.virtualBackgroundMode,
    this.onToggleVirtualBackground,
    this.handRaised = false,
    this.onToggleHand,
    this.onSendReaction,
    this.screenSharing = false,
    this.onToggleScreenShare,
    this.screenShareSupported = false,
  });

  final bool micMuted;
  final bool cameraMuted;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleCamera;
  final VoidCallback onSwitchCamera;
  final VoidCallback onOpenSidebar;
  final VoidCallback onLeave;
  final int participantsCount;
  final int requestsCount;
  final VirtualBackgroundMode? virtualBackgroundMode;
  final VoidCallback? onToggleVirtualBackground;

  /// Поднята ли моя рука. Флаг берём из `participants/{uid}.isHandRaised`.
  final bool handRaised;
  final VoidCallback? onToggleHand;

  /// Коллбек на отправку реакции-эмодзи (одной из предустановленного набора).
  /// Если `null` — кнопка не показывается.
  final ValueChanged<String>? onSendReaction;

  /// Идёт ли сейчас демонстрация экрана от нас самих.
  final bool screenSharing;
  final VoidCallback? onToggleScreenShare;

  /// Поддерживается ли screen sharing на этой платформе (сейчас только
  /// Android). На iOS кнопка показывается disabled с подсказкой (см.
  /// `MeetingRoomScreen`).
  final bool screenShareSupported;

  static const List<String> reactionEmojis = <String>[
    '❤️',
    '👍',
    '🔥',
    '🎉',
    '😂',
  ];

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      _IconButton(
        icon: micMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
        label: micMuted ? 'Включить' : 'Выключить',
        background: micMuted ? Colors.redAccent : Colors.white24,
        onTap: onToggleMic,
      ),
      _IconButton(
        icon: cameraMuted
            ? Icons.videocam_off_rounded
            : Icons.videocam_rounded,
        label: cameraMuted ? 'Камера вкл' : 'Камера выкл',
        background: cameraMuted ? Colors.redAccent : Colors.white24,
        onTap: onToggleCamera,
      ),
      _IconButton(
        icon: Icons.cameraswitch_rounded,
        label: 'Сменить',
        background: Colors.white24,
        onTap: onSwitchCamera,
      ),
      if (onToggleHand != null)
        _IconButton(
          icon: Icons.back_hand_rounded,
          label: handRaised ? 'Опустить' : 'Рука',
          background: handRaised ? const Color(0xFFF59E0B) : Colors.white24,
          onTap: onToggleHand!,
        ),
      if (onSendReaction != null)
        _ReactionButton(onSendReaction: onSendReaction!),
      if (onToggleScreenShare != null)
        _IconButton(
          icon: screenSharing
              ? Icons.stop_screen_share_rounded
              : Icons.screen_share_rounded,
          label: screenSharing ? 'Стоп' : 'Экран',
          background: screenSharing
              ? const Color(0xFF2563EB)
              : (screenShareSupported ? Colors.white24 : Colors.white10),
          iconColor:
              screenShareSupported ? Colors.white : Colors.white54,
          onTap: onToggleScreenShare!,
        ),
      if (virtualBackgroundMode != null &&
          onToggleVirtualBackground != null)
        _IconButton(
          icon: _bgIcon(virtualBackgroundMode!),
          label: _bgLabel(virtualBackgroundMode!),
          background: virtualBackgroundMode == VirtualBackgroundMode.none
              ? Colors.white24
              : const Color(0xFF6D28D9),
          onTap: onToggleVirtualBackground!,
        ),
      _IconButton(
        icon: Icons.people_rounded,
        label: 'Участники',
        background: Colors.white24,
        onTap: onOpenSidebar,
        badge: requestsCount > 0
            ? requestsCount.toString()
            : (participantsCount > 0
                ? participantsCount.toString()
                : null),
        badgeColor: requestsCount > 0 ? Colors.amber : Colors.white70,
      ),
      _IconButton(
        icon: Icons.call_end_rounded,
        label: 'Выйти',
        background: const Color(0xFFDC2626),
        iconColor: Colors.white,
        onTap: onLeave,
      ),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final w in buttons) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: w,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

IconData _bgIcon(VirtualBackgroundMode mode) {
  switch (mode) {
    case VirtualBackgroundMode.none:
      return Icons.blur_off_rounded;
    case VirtualBackgroundMode.blur:
      return Icons.blur_on_rounded;
    case VirtualBackgroundMode.image:
      return Icons.image_rounded;
  }
}

String _bgLabel(VirtualBackgroundMode mode) {
  switch (mode) {
    case VirtualBackgroundMode.none:
      return 'Фон';
    case VirtualBackgroundMode.blur:
      return 'Размытие';
    case VirtualBackgroundMode.image:
      return 'Картинка';
  }
}

/// Кнопка-эмодзи: по тапу открывает всплывашку с 5 реакциями. Набор
/// реакций совпадает с web (`src/components/meetings/MeetingControls.tsx`).
class _ReactionButton extends StatelessWidget {
  const _ReactionButton({required this.onSendReaction});

  final ValueChanged<String> onSendReaction;

  @override
  Widget build(BuildContext context) {
    return _IconButton(
      icon: Icons.emoji_emotions_rounded,
      label: 'Реакция',
      background: Colors.white24,
      onTap: () => _showPicker(context),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final e in MeetingControls.reactionEmojis)
                InkResponse(
                  radius: 32,
                  onTap: () {
                    Navigator.of(ctx).maybePop();
                    onSendReaction(e);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      e,
                      style: const TextStyle(fontSize: 32),
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

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.onTap,
    this.iconColor = Colors.white,
    this.badge,
    this.badgeColor,
  });

  final IconData icon;
  final String label;
  final Color background;
  final VoidCallback onTap;
  final Color iconColor;
  final String? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              if (badge != null)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor ?? Colors.white70,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
