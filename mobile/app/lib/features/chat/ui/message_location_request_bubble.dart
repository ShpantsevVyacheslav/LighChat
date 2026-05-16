import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../../../l10n/app_localizations.dart';

/// Bubble для location request message (Phase 12.3, iMessage-paritет).
///
/// Состояния (управляется `request.status`):
///   - **pending** + `isMine` → «Вы запросили локацию» + анимированный
///     pulsing pin (показывает что юзер ждёт ответа).
///   - **pending** + `!isMine` → «X запрашивает вашу локацию» + кнопки
///     `Accept` / `Decline`.
///   - **accepted** → «X поделился локацией» (location-card сама
///     рендерится отдельным сообщением, на которое ссылается
///     `acceptedShareMessageId`).
///   - **declined** → «X отклонил запрос локации» (нейтральная серая
///     иконка).
class MessageLocationRequestBubble extends StatefulWidget {
  const MessageLocationRequestBubble({
    super.key,
    required this.request,
    required this.isMine,
    required this.onAccept,
    required this.onDecline,
    this.requesterName,
    this.onRemove,
  });

  final ChatLocationRequest request;
  final bool isMine;
  final String? requesterName;

  /// Тап «Accept» (только для !isMine + pending). Caller должен
  /// открыть location-panel и после выбора duration вызвать
  /// `respondToLocationRequest(accepted: true, ...)`.
  final VoidCallback onAccept;

  /// Тап «Decline» (только для !isMine + pending).
  final VoidCallback onDecline;

  /// Bug #17: для своего ещё незавершённого запроса (isMine + pending)
  /// показываем маленький X в правом верхнем углу — это «удалить
  /// у себя», а не «отменить запрос» (отмена запроса как отдельная
  /// операция не предусмотрена: собеседник может всё равно ответить).
  /// Если null — иконка не рисуется (например, для received-bubble
  /// удаление доступно через стандартный long-press menu).
  final VoidCallback? onRemove;

  @override
  State<MessageLocationRequestBubble> createState() =>
      _MessageLocationRequestBubbleState();
}

class _MessageLocationRequestBubbleState
    extends State<MessageLocationRequestBubble>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void initState() {
    super.initState();
    _ensurePulse();
  }

  @override
  void didUpdateWidget(covariant MessageLocationRequestBubble old) {
    super.didUpdateWidget(old);
    _ensurePulse();
  }

  void _ensurePulse() {
    final shouldPulse = widget.request.isPending && widget.isMine;
    if (shouldPulse && _pulse == null) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      )..repeat();
    } else if (!shouldPulse && _pulse != null) {
      _pulse!.dispose();
      _pulse = null;
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  String _label(AppLocalizations l10n) {
    final rawName = widget.requesterName?.trim();
    final name = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : l10n.location_request_unknown_contact;
    if (widget.request.isAccepted) {
      return widget.isMine
          ? l10n.location_request_accepted_mine
          : l10n.location_request_accepted_other_with_name(name);
    }
    if (widget.request.isDeclined) {
      // Для receiver-side fallback используем «Вы» если имя
      // отсутствует — текст звучит как «Вы отклонили запрос».
      final whoName = (rawName != null && rawName.isNotEmpty)
          ? rawName
          : l10n.location_request_you;
      return widget.isMine
          ? l10n.location_request_declined_mine
          : l10n.location_request_declined_other_with_name(whoName);
    }
    // pending
    return widget.isMine
        ? l10n.location_request_pending_mine
        : l10n.location_request_pending_other_with_name(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.primary;
    final fg = widget.isMine ? scheme.onPrimary : scheme.onSurface;

    final iconColor = widget.request.isDeclined
        ? fg.withValues(alpha: 0.45)
        : accent;

    final showRemove = widget.request.isPending &&
        widget.isMine &&
        widget.onRemove != null;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _PulsingIcon(
                  controller: _pulse,
                  color: iconColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _label(l10n),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: fg.withValues(alpha: 0.92),
                    ),
                  ),
                ),
                if (showRemove)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: InkWell(
                      onTap: widget.onRemove,
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: fg.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Кнопки Accept/Decline — только для pending request
            // полученного НЕ нами.
            if (widget.request.isPending && !widget.isMine)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: l10n.location_request_action_decline,
                        filled: false,
                        fg: fg,
                        onTap: widget.onDecline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        label: l10n.location_request_action_accept,
                        filled: true,
                        fg: fg,
                        onTap: widget.onAccept,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pin-icon с pulsing scale animation (для pending+isMine стейта —
/// «крутящаяся песочная подсказка»).
class _PulsingIcon extends StatelessWidget {
  const _PulsingIcon({required this.controller, required this.color});
  final AnimationController? controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.pin_drop_rounded, size: 22, color: color);
    final ctrl = controller;
    if (ctrl == null) return icon;
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, child) {
        final t = ctrl.value;
        // 1.0 → 1.18 → 1.0 синусоидально, opacity 0.6 → 1.0.
        final scale = 1.0 + 0.18 * (t < 0.5 ? t * 2 : (1 - t) * 2);
        final opacity = 0.6 + 0.4 * (t < 0.5 ? t * 2 : (1 - t) * 2);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: icon,
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.filled,
    required this.fg,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Material(
      color: filled ? accent : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: filled
            ? BorderSide.none
            : BorderSide(color: fg.withValues(alpha: 0.32)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: filled
                    ? Colors.white
                    : fg.withValues(alpha: 0.92),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
