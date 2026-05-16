import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../../../l10n/app_localizations.dart';
import '../data/chat_location_geocoder.dart';
import '../data/live_location_duration_options.dart';
import 'chat_location_map_view.dart';

/// Inline-превью pending location share над композером (Phase 10–11,
/// iMessage-paritет). Карта 140-высоты:
///  - **iOS**: настоящий MKMapView через PlatformView (`ChatLocationMapView`)
///    — родной Apple Maps look с системным dark-mode, 3D-зданиями.
///  - **Android/desktop**: fallback на статичный OSM тайл (как было).
///
/// Сверху на карте — бейдж длительности (слева) и крестик отмены
/// (справа). Снизу под картой — строка с адресом, который async
/// резолвится через CLGeocoder (`ChatLocationGeocoder`); до резолва
/// показываются сырые координаты как fallback.
class ComposerPendingLocationPreview extends StatefulWidget {
  const ComposerPendingLocationPreview({
    super.key,
    required this.share,
    required this.durationId,
    required this.onCancel,
  });

  final ChatLocationShare share;

  /// id из [liveLocationDurationOptions]: `once` / `h1` /
  /// `until_end_of_day` / `forever`. null до выбора (на бейдже —
  /// общий «Поделиться геолокацией»).
  final String? durationId;

  final VoidCallback? onCancel;

  @override
  State<ComposerPendingLocationPreview> createState() =>
      _ComposerPendingLocationPreviewState();
}

class _ComposerPendingLocationPreviewState
    extends State<ComposerPendingLocationPreview> {
  String? _resolvedAddress;
  String? _lastGeocodedKey;

  @override
  void initState() {
    super.initState();
    _resolveAddressIfNeeded();
  }

  @override
  void didUpdateWidget(covariant ComposerPendingLocationPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resolveAddressIfNeeded();
  }

  void _resolveAddressIfNeeded() {
    final key = '${widget.share.lat.toStringAsFixed(5)},'
        '${widget.share.lng.toStringAsFixed(5)}';
    if (key == _lastGeocodedKey) return;
    _lastGeocodedKey = key;
    _resolvedAddress = null;
    () async {
      final res = await ChatLocationGeocoder.instance.reverseGeocode(
        widget.share.lat,
        widget.share.lng,
      );
      if (!mounted || _lastGeocodedKey != key) return;
      setState(() => _resolvedAddress = res);
    }();
  }

  String _badgeLabel(AppLocalizations l10n) {
    final id = widget.durationId;
    if (id == null) return l10n.share_location_title;
    final opt = liveLocationDurationOptions(l10n).firstWhere(
      (o) => o.id == id,
      orElse: () => liveLocationDurationOptions(l10n).first,
    );
    return opt.label;
  }

  String _bottomLine() {
    final addr = _resolvedAddress;
    if (addr != null && addr.trim().isNotEmpty) return addr;
    return '${widget.share.lat.toStringAsFixed(5)}, '
        '${widget.share.lng.toStringAsFixed(5)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 140,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ChatLocationMapView(
                  lat: widget.share.lat,
                  lng: widget.share.lng,
                ),
                // Бейдж длительности — слева сверху.
                Positioned(
                  left: 8,
                  top: 8,
                  child: _Badge(
                    icon: Icons.timer_outlined,
                    label: _badgeLabel(l10n),
                  ),
                ),
                // Крестик отмены — справа сверху.
                if (widget.onCancel != null)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Material(
                      color: const Color(0x99000000),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: widget.onCancel,
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
        ),
        // Адрес / координаты под картой — iMessage показывает так же.
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
          child: Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.72),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _bottomLine(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
