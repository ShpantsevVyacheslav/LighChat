import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../../../l10n/app_localizations.dart';
import '../data/google_maps_urls.dart';
import '../data/live_location_duration_options.dart';
import 'chat_cached_network_image.dart';

/// Inline-превью pending location share над композером (Phase 10,
/// iMessage-paritет). Компактная карта 360×120 (примерно — заполняет
/// доступную ширину) + бейдж длительности слева сверху + крестик
/// справа сверху для отмены. Видна только пока юзер не отправил
/// сообщение или не отменил шаринг.
///
/// Сама карта — статичный OSM-тайл через `buildChatLocationStaticPreviewUrl`,
/// в центре маркер pin'а.
class ComposerPendingLocationPreview extends StatelessWidget {
  const ComposerPendingLocationPreview({
    super.key,
    required this.share,
    required this.durationId,
    required this.onCancel,
  });

  final ChatLocationShare share;

  /// id из [liveLocationDurationOptions]: `once` / `h1` /
  /// `until_end_of_day` / `forever`. Если null — длительность ещё не
  /// выбрана, бейджа нет (но превью уже показывается, юзер выбирает
  /// длительность в action sheet поверх).
  final String? durationId;

  final VoidCallback? onCancel;

  /// HTTP-заголовки для OSM тайлов: серверу нужен явный User-Agent.
  static const _kHeaders = <String, String>{
    'User-Agent':
        'LighChatMobile/1.0 (composer location preview; contact: app)',
  };

  String _badgeLabel(AppLocalizations l10n) {
    final id = durationId;
    if (id == null) return l10n.share_location_title;
    final opt = liveLocationDurationOptions(l10n).firstWhere(
      (o) => o.id == id,
      orElse: () => liveLocationDurationOptions(l10n).first,
    );
    return opt.label;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 120,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ChatCachedNetworkImage(
              url: buildChatLocationStaticPreviewUrl(
                share.lat,
                share.lng,
              ),
              httpHeaders: _kHeaders,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorOverride: const _PreviewFallback(),
            ),
            // Маркер pin'а в центре карты.
            const IgnorePointer(
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x47000000),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
            // Бейдж длительности — слева сверху, как в Apple Messages.
            Positioned(
              left: 8,
              top: 8,
              child: _Badge(
                icon: Icons.timer_outlined,
                label: _badgeLabel(l10n),
              ),
            ),
            // Крестик отмены — справа сверху.
            if (onCancel != null)
              Positioned(
                right: 6,
                top: 6,
                child: Material(
                  color: const Color(0x99000000),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onCancel,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC000000),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.92)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewFallback extends StatelessWidget {
  const _PreviewFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF1B1E25),
      child: Center(
        child: Icon(
          Icons.map_outlined,
          color: Colors.white.withValues(alpha: 0.45),
          size: 32,
        ),
      ),
    );
  }
}
