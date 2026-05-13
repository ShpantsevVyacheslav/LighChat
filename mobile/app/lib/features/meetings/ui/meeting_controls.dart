import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

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
    this.notificationsCount = 0,
    this.onOpenNotifications,
    this.onEnterPip,
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

  /// Сумма chat-unread + активных голосований + pending заявок (для админа).
  /// Если > 0 — рисуется отдельная кнопка-«колокольчик» с бейджем.
  final int notificationsCount;
  final VoidCallback? onOpenNotifications;

  /// Свернуть конференцию в PiP-окно. Если `null` — кнопка не показывается
  /// (платформа не поддерживает PiP в текущей реализации, см.
  /// `MeetingPipController.isSupported`).
  final VoidCallback? onEnterPip;
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
    final l10n = AppLocalizations.of(context)!;
    final buttons = <Widget>[
      _IconButton(
        icon: micMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
        label: micMuted ? l10n.meeting_mic_on : l10n.meeting_mic_off,
        background: micMuted ? Colors.redAccent : Colors.white24,
        onTap: onToggleMic,
      ),
      _IconButton(
        icon: cameraMuted
            ? Icons.videocam_off_rounded
            : Icons.videocam_rounded,
        label: cameraMuted ? l10n.meeting_camera_on : l10n.meeting_camera_off,
        background: cameraMuted ? Colors.redAccent : Colors.white24,
        onTap: onToggleCamera,
      ),
      _IconButton(
        icon: Icons.cameraswitch_rounded,
        label: l10n.meeting_switch_camera,
        background: Colors.white24,
        onTap: onSwitchCamera,
      ),
      if (onToggleHand != null)
        _IconButton(
          icon: Icons.back_hand_rounded,
          label: handRaised ? l10n.meeting_hand_lower : l10n.meeting_hand_raise,
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
          label: screenSharing ? l10n.meeting_screen_stop : l10n.meeting_screen_label,
          background: screenSharing
              ? const Color(0xFF2563EB)
              : (screenShareSupported ? Colors.white24 : Colors.white10),
          iconColor:
              screenShareSupported ? Colors.white : Colors.white54,
          onTap: onToggleScreenShare!,
        ),
      // PiP-кнопка вынесена в верхнюю шапку (#7) — в нижнем баре не нужна.
      if (virtualBackgroundMode != null &&
          onToggleVirtualBackground != null)
        _IconButton(
          icon: _bgIcon(virtualBackgroundMode!),
          label: _bgLabel(virtualBackgroundMode!, l10n),
          background: virtualBackgroundMode == VirtualBackgroundMode.none
              ? Colors.white24
              : const Color(0xFF6D28D9),
          onTap: onToggleVirtualBackground!,
        ),
      if (onOpenNotifications != null)
        _IconButton(
          icon: notificationsCount > 0
              ? Icons.notifications_active_rounded
              : Icons.notifications_none_rounded,
          label: l10n.meeting_notifications_button,
          background: notificationsCount > 0
              ? const Color(0xFFDC2626)
              : Colors.white24,
          onTap: onOpenNotifications!,
          badge: notificationsCount > 0
              ? (notificationsCount > 99 ? '99+' : notificationsCount.toString())
              : null,
          badgeColor: Colors.white,
        ),
      _IconButton(
        icon: Icons.people_rounded,
        label: l10n.meeting_participants_button,
        background: Colors.white24,
        onTap: onOpenSidebar,
        badge: participantsCount > 0 ? participantsCount.toString() : null,
        badgeColor: Colors.white70,
      ),
      _IconButton(
        icon: Icons.call_end_rounded,
        label: l10n.meeting_leave,
        background: const Color(0xFFDC2626),
        iconColor: Colors.white,
        onTap: onLeave,
      ),
    ];

    // Полупрозрачная «стеклянная» подложка: панель плывёт поверх видео,
    // не съедая отдельную строку. См. MeetingRoomScreen — рендерится в Stack.
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.18),
                Colors.black.withValues(alpha: 0.40),
              ],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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

String _bgLabel(VirtualBackgroundMode mode, AppLocalizations l10n) {
  switch (mode) {
    case VirtualBackgroundMode.none:
      return l10n.meeting_bg_off;
    case VirtualBackgroundMode.blur:
      return l10n.meeting_bg_blur;
    case VirtualBackgroundMode.image:
      return l10n.meeting_bg_image;
  }
}

/// Кнопка-эмодзи: по тапу открывает всплывашку с 5 реакциями. Набор
/// реакций совпадает с web (`src/components/meetings/MeetingControls.tsx`).
class _ReactionButton extends StatelessWidget {
  const _ReactionButton({required this.onSendReaction});

  final ValueChanged<String> onSendReaction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _IconButton(
      icon: Icons.emoji_emotions_rounded,
      label: l10n.meeting_reaction,
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0x99101521),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
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
    // Прозрачные «таблеточные» кнопки: фон 30% от исходного цвета, тонкая
    // светлая рамка вместо плотного круга. Активные состояния (red/blue)
    // оставляем заметными — поэтому смешиваем альфу только для нейтральных.
    final isAccent = background != Colors.white24 && background != Colors.white10;
    final effective = isAccent
        ? background
        : Colors.black.withValues(alpha: 0.28);
    return Tooltip(
      message: label,
      child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: effective,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isAccent
                        ? Colors.white.withValues(alpha: 0.20)
                        : Colors.white.withValues(alpha: 0.16),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 26),
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
          // Текстовые подписи под иконками убраны — UX как у FaceTime/
          // Telegram: только иконка. `label` остаётся для tooltip/a11y.
        ],
      ),
      ),
    );
  }
}
