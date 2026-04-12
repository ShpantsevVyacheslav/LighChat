import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../data/google_maps_urls.dart';

/// Превью карты с меткой перед фактической отправкой геолокации в чат.
Future<bool> showLocationSendPreviewSheet(
  BuildContext context, {
  required double lat,
  required double lng,
  double? accuracyM,
}) async {
  final r = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 12,
          left: 12,
          right: 12,
        ),
        child: Material(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black.withValues(alpha: 0.92),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: _LocationPreviewBody(
              lat: lat,
              lng: lng,
              accuracyM: accuracyM,
              onCancel: () => Navigator.of(ctx).pop(false),
              onConfirm: () => Navigator.of(ctx).pop(true),
            ),
          ),
        ),
      );
    },
  );
  return r == true;
}

class _LocationPreviewBody extends StatefulWidget {
  const _LocationPreviewBody({
    required this.lat,
    required this.lng,
    this.accuracyM,
    required this.onCancel,
    required this.onConfirm,
  });

  final double lat;
  final double lng;
  final double? accuracyM;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  State<_LocationPreviewBody> createState() => _LocationPreviewBodyState();
}

class _LocationPreviewBodyState extends State<_LocationPreviewBody> {
  late final WebViewController _web;
  var _loading = true;
  Timer? _loadingTimeout;

  @override
  void initState() {
    super.initState();
    final html = buildOpenStreetMapLeafletHtml(widget.lat, widget.lng, zoom: 16);
    _loadingTimeout = Timer(const Duration(seconds: 12), _hideLoader);
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1a1a1a))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _hideLoader(),
          onWebResourceError: (_) => _hideLoader(),
          onHttpError: (_) => _hideLoader(),
          onProgress: (p) {
            if (p >= 90) _hideLoader();
          },
        ),
      );
    unawaited(_load(html));
  }

  void _hideLoader() {
    _loadingTimeout?.cancel();
    _loadingTimeout = null;
    if (!_loading || !mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _load(String html) async {
    try {
      await _web.setUserAgent('LighChatMobile/1.0');
    } catch (_) {}
    try {
      await _web.loadHtmlString(html, baseUrl: 'https://unpkg.com/');
    } catch (_) {
      if (mounted) _hideLoader();
    }
  }

  @override
  void dispose() {
    _loadingTimeout?.cancel();
    super.dispose();
  }

  String _accuracyLine() {
    final a = widget.accuracyM;
    if (a == null || a.isNaN) {
      return 'Точность: —';
    }
    if (a < 1000) {
      return 'Точность: ~${a.round()} м';
    }
    final km = a / 1000;
    return 'Точность: ~${km.toStringAsFixed(1)} км';
  }

  @override
  Widget build(BuildContext context) {
    final fg = Colors.white.withValues(alpha: 0.92);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Местоположение',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: fg,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${widget.lat.toStringAsFixed(5)}, ${widget.lng.toStringAsFixed(5)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: fg.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                WebViewWidget(controller: _web),
                if (_loading)
                  const ColoredBox(
                    color: Color(0xFF1a1a1a),
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _accuracyLine(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: fg.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
                child: const Text('Отмена'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: widget.onConfirm,
                icon: const Icon(Icons.near_me_rounded, size: 18),
                label: const Text('Отправить'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
