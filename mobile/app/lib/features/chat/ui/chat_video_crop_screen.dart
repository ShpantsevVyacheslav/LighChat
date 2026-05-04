import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../l10n/app_localizations.dart';

class ChatVideoCropResult {
  const ChatVideoCropResult({
    required this.cropRect,
    required this.rotationQuarterTurns,
    required this.selectedAspectRatio,
  });

  /// Normalized crop rect (0..1) in oriented video coordinates.
  final Rect cropRect;

  /// Rotation applied to the video preview/output (0..3).
  final int rotationQuarterTurns;

  /// Selected aspect ratio for crop frame, or null for свободно/original.
  final double? selectedAspectRatio;
}

class ChatVideoCropScreen extends StatefulWidget {
  const ChatVideoCropScreen({
    super.key,
    required this.file,
    required this.initialCropRect,
    required this.initialRotationQuarterTurns,
    required this.initialAspectRatio,
  });

  final File file;
  final Rect initialCropRect;
  final int initialRotationQuarterTurns;
  final double? initialAspectRatio;

  static Future<ChatVideoCropResult?> open(
    BuildContext context, {
    required File file,
    required Rect initialCropRect,
    required int initialRotationQuarterTurns,
    required double? initialAspectRatio,
  }) {
    return Navigator.of(context).push<ChatVideoCropResult>(
      MaterialPageRoute(
        builder: (_) => ChatVideoCropScreen(
          file: file,
          initialCropRect: initialCropRect,
          initialRotationQuarterTurns: initialRotationQuarterTurns,
          initialAspectRatio: initialAspectRatio,
        ),
      ),
    );
  }

  @override
  State<ChatVideoCropScreen> createState() => _ChatVideoCropScreenState();
}

class _ChatVideoCropScreenState extends State<ChatVideoCropScreen> {
  static const double _minCropSizeFraction = 0.12;
  static const double _cropHitTolerance = 26;
  static const Rect _fullCropRect = Rect.fromLTWH(0, 0, 1, 1);

  static List<_AspectPreset> _buildPresets(AppLocalizations l10n) =>
      <_AspectPreset>[
        _AspectPreset(label: l10n.crop_aspect_original, ratio: null),
        _AspectPreset(label: l10n.crop_aspect_square, ratio: 1),
        _AspectPreset(label: '3:2', ratio: 3 / 2),
        _AspectPreset(label: '4:3', ratio: 4 / 3),
        _AspectPreset(label: '16:9', ratio: 16 / 9),
      ];

  VideoPlayerController? _player;
  bool _loading = true;
  String? _error;

  int _rotationQuarterTurns = 0;
  Rect _cropDraftRect = _fullCropRect;
  double? _selectedAspectRatio;

  _CropDragHandle? _activeHandle;
  Rect? _panStartRect;
  Offset? _panStartLocal;

  @override
  void initState() {
    super.initState();
    _rotationQuarterTurns = widget.initialRotationQuarterTurns % 4;
    _selectedAspectRatio = widget.initialAspectRatio;
    _cropDraftRect = _normalizeCropRect(widget.initialCropRect);
    if (_selectedAspectRatio != null) {
      _cropDraftRect =
          _constrainRectToAspect(_cropDraftRect, _selectedAspectRatio!);
    }
    unawaited(_initPlayer());
  }

  @override
  void dispose() {
    unawaited(_player?.dispose());
    super.dispose();
  }

  Future<void> _initPlayer() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final c = VideoPlayerController.file(
      widget.file,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    try {
      await c.initialize();
      await c.pause();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _player = c;
        _loading = false;
      });
    } catch (e) {
      await c.dispose();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.video_crop_load_error(e.toString());
      });
    }
  }

  Rect _normalizeCropRect(Rect rect) {
    var left = rect.left.clamp(0.0, 1.0);
    var top = rect.top.clamp(0.0, 1.0);
    var right = rect.right.clamp(0.0, 1.0);
    var bottom = rect.bottom.clamp(0.0, 1.0);
    if (right - left < _minCropSizeFraction) {
      right = (left + _minCropSizeFraction).clamp(0.0, 1.0);
      left = (right - _minCropSizeFraction).clamp(0.0, 1.0);
    }
    if (bottom - top < _minCropSizeFraction) {
      bottom = (top + _minCropSizeFraction).clamp(0.0, 1.0);
      top = (bottom - _minCropSizeFraction).clamp(0.0, 1.0);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  Rect _constrainRectToAspect(Rect rect, double aspectRatio) {
    if (!aspectRatio.isFinite || aspectRatio <= 0) {
      return _normalizeCropRect(rect);
    }

    var width = rect.width.clamp(_minCropSizeFraction, 1.0);
    var height = rect.height.clamp(_minCropSizeFraction, 1.0);
    final currentRatio = width / height;
    if (currentRatio > aspectRatio) {
      width = height * aspectRatio;
    } else {
      height = width / aspectRatio;
    }

    if (width < _minCropSizeFraction) {
      width = _minCropSizeFraction;
      height = width / aspectRatio;
    }
    if (height < _minCropSizeFraction) {
      height = _minCropSizeFraction;
      width = height * aspectRatio;
    }
    if (width > 1.0) {
      width = 1.0;
      height = width / aspectRatio;
    }
    if (height > 1.0) {
      height = 1.0;
      width = height * aspectRatio;
    }

    final maxLeft = (1.0 - width).clamp(0.0, 1.0);
    final maxTop = (1.0 - height).clamp(0.0, 1.0);
    final left = (rect.center.dx - width / 2).clamp(0.0, maxLeft);
    final top = (rect.center.dy - height / 2).clamp(0.0, maxTop);
    return Rect.fromLTWH(left, top, width, height);
  }

  void _setAspectRatio(double? ratio) {
    setState(() {
      _selectedAspectRatio = ratio;
      if (ratio == null) {
        _cropDraftRect = _normalizeCropRect(_cropDraftRect);
      } else {
        _cropDraftRect = _constrainRectToAspect(_cropDraftRect, ratio);
      }
      _activeHandle = null;
      _panStartRect = null;
    });
  }

  void _resetCrop() {
    setState(() {
      final ratio = _selectedAspectRatio;
      _cropDraftRect =
          ratio == null ? _fullCropRect : _constrainRectToAspect(_fullCropRect, ratio);
      _activeHandle = null;
      _panStartRect = null;
    });
  }

  void _rotateRight() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
    });
  }

  void _rotateLeft() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 3) % 4;
    });
  }

  Future<void> _pickAspectRatio() async {
    final l10n = AppLocalizations.of(context)!;
    final presets = _buildPresets(l10n);
    final picked = await showModalBottomSheet<_AspectPreset>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF12151E).withValues(alpha: 0.92),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: presets.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  itemBuilder: (context, i) {
                    final p = presets[i];
                    final isActive = _selectedAspectRatio == null
                        ? p.ratio == null
                        : (p.ratio != null &&
                            (_selectedAspectRatio! - p.ratio!).abs() < 0.0001);
                    return ListTile(
                      title: Text(
                        p.label,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      trailing: isActive
                          ? const Icon(Icons.check_rounded, color: Color(0xFF2F86FF))
                          : null,
                      onTap: () => Navigator.of(ctx).pop(p),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
    if (!mounted || picked == null) return;
    _setAspectRatio(picked.ratio);
  }

  _VideoGeometry? _buildGeometry(BoxConstraints constraints) {
    final c = _player;
    if (c == null || !c.value.isInitialized) return null;
    final sourceW = c.value.size.width;
    final sourceH = c.value.size.height;
    if (sourceW <= 0 || sourceH <= 0) return null;

    final turns = _rotationQuarterTurns % 4;
    final orientedW = turns.isEven ? sourceW : sourceH;
    final orientedH = turns.isEven ? sourceH : sourceW;
    final maxW = constraints.maxWidth;
    final maxH = constraints.maxHeight;
    if (maxW <= 0 || maxH <= 0) return null;

    final scale = math.min(maxW / orientedW, maxH / orientedH);
    final displayW = orientedW * scale;
    final displayH = orientedH * scale;
    final left = (maxW - displayW) / 2;
    final top = (maxH - displayH) / 2;
    return _VideoGeometry(rect: Rect.fromLTWH(left, top, displayW, displayH));
  }

  Rect _toLocalCropRect(Rect normalized, Rect videoRect) {
    return Rect.fromLTRB(
      videoRect.left + normalized.left * videoRect.width,
      videoRect.top + normalized.top * videoRect.height,
      videoRect.left + normalized.right * videoRect.width,
      videoRect.top + normalized.bottom * videoRect.height,
    );
  }

  _CropDragHandle? _hitHandle(Offset local, Rect cropLocalRect) {
    if (!cropLocalRect.inflate(_cropHitTolerance).contains(local)) return null;

    final topLeft = cropLocalRect.topLeft;
    final topRight = cropLocalRect.topRight;
    final bottomLeft = cropLocalRect.bottomLeft;
    final bottomRight = cropLocalRect.bottomRight;
    if ((local - topLeft).distance <= _cropHitTolerance) return _CropDragHandle.topLeft;
    if ((local - topRight).distance <= _cropHitTolerance) return _CropDragHandle.topRight;
    if ((local - bottomLeft).distance <= _cropHitTolerance) return _CropDragHandle.bottomLeft;
    if ((local - bottomRight).distance <= _cropHitTolerance) return _CropDragHandle.bottomRight;

    final nearLeft =
        (local.dx - cropLocalRect.left).abs() <= _cropHitTolerance &&
            local.dy >= cropLocalRect.top - _cropHitTolerance &&
            local.dy <= cropLocalRect.bottom + _cropHitTolerance;
    if (nearLeft) return _CropDragHandle.left;
    final nearRight =
        (local.dx - cropLocalRect.right).abs() <= _cropHitTolerance &&
            local.dy >= cropLocalRect.top - _cropHitTolerance &&
            local.dy <= cropLocalRect.bottom + _cropHitTolerance;
    if (nearRight) return _CropDragHandle.right;
    final nearTop =
        (local.dy - cropLocalRect.top).abs() <= _cropHitTolerance &&
            local.dx >= cropLocalRect.left - _cropHitTolerance &&
            local.dx <= cropLocalRect.right + _cropHitTolerance;
    if (nearTop) return _CropDragHandle.top;
    final nearBottom =
        (local.dy - cropLocalRect.bottom).abs() <= _cropHitTolerance &&
            local.dx >= cropLocalRect.left - _cropHitTolerance &&
            local.dx <= cropLocalRect.right + _cropHitTolerance;
    if (nearBottom) return _CropDragHandle.bottom;

    if (cropLocalRect.contains(local)) return _CropDragHandle.move;
    return null;
  }

  // --- Pointer-based drag handlers ---
  //
  // We use a raw Listener (instead of GestureDetector.onPanStart) so the
  // handle hit-test is evaluated at the EXACT touch-down position. With a
  // pan recognizer, `onPanStart` fires only after the kTouchSlop (~18 px)
  // is exceeded, which can push the reported position beyond the corner
  // tolerance and cause the drag to be ignored — preventing the crop
  // frame from resizing via its corners/sides.
  void _onPointerDown(PointerDownEvent event, _VideoGeometry geo) {
    final cropLocalRect = _toLocalCropRect(_cropDraftRect, geo.rect);
    final handle = _hitHandle(event.localPosition, cropLocalRect);
    if (handle == null) {
      _activeHandle = null;
      _panStartRect = null;
      _panStartLocal = null;
      return;
    }
    _activeHandle = handle;
    _panStartRect = _cropDraftRect;
    _panStartLocal = event.localPosition;
  }

  void _onPointerMove(PointerMoveEvent event, _VideoGeometry geo) {
    final handle = _activeHandle;
    final startRect = _panStartRect;
    final startLocal = _panStartLocal;
    if (handle == null || startRect == null || startLocal == null) return;
    if (geo.rect.width <= 0 || geo.rect.height <= 0) return;

    final dx = (event.localPosition.dx - startLocal.dx) / geo.rect.width;
    final dy = (event.localPosition.dy - startLocal.dy) / geo.rect.height;

    Rect next;
    switch (handle) {
      case _CropDragHandle.move:
        next = startRect.shift(Offset(dx, dy));
        break;
      case _CropDragHandle.left:
        next = Rect.fromLTRB(startRect.left + dx, startRect.top, startRect.right, startRect.bottom);
        break;
      case _CropDragHandle.right:
        next = Rect.fromLTRB(startRect.left, startRect.top, startRect.right + dx, startRect.bottom);
        break;
      case _CropDragHandle.top:
        next = Rect.fromLTRB(startRect.left, startRect.top + dy, startRect.right, startRect.bottom);
        break;
      case _CropDragHandle.bottom:
        next = Rect.fromLTRB(startRect.left, startRect.top, startRect.right, startRect.bottom + dy);
        break;
      case _CropDragHandle.topLeft:
        next = Rect.fromLTRB(startRect.left + dx, startRect.top + dy, startRect.right, startRect.bottom);
        break;
      case _CropDragHandle.topRight:
        next = Rect.fromLTRB(startRect.left, startRect.top + dy, startRect.right + dx, startRect.bottom);
        break;
      case _CropDragHandle.bottomLeft:
        next = Rect.fromLTRB(startRect.left + dx, startRect.top, startRect.right, startRect.bottom + dy);
        break;
      case _CropDragHandle.bottomRight:
        next = Rect.fromLTRB(startRect.left, startRect.top, startRect.right + dx, startRect.bottom + dy);
        break;
    }

    var normalized = _normalizeCropRect(next);
    final ratio = _selectedAspectRatio;
    if (ratio != null) {
      normalized = _constrainRectToAspect(normalized, ratio);
    }
    setState(() {
      _cropDraftRect = normalized;
    });
  }

  void _endPointerDrag() {
    _activeHandle = null;
    _panStartRect = null;
    _panStartLocal = null;
  }

  void _done() {
    final ratio = _selectedAspectRatio;
    var rect = _normalizeCropRect(_cropDraftRect);
    if (ratio != null) {
      rect = _constrainRectToAspect(rect, ratio);
    }
    Navigator.of(context).pop(
      ChatVideoCropResult(
        cropRect: rect,
        rotationQuarterTurns: _rotationQuarterTurns % 4,
        selectedAspectRatio: ratio,
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback? onTap,
    Color? background,
    Color? iconColor,
    double size = 44,
    double iconSize = 22,
  }) {
    return Material(
      color: background ?? Colors.white.withValues(alpha: 0.10),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: iconSize,
            color: onTap == null
                ? Colors.white.withValues(alpha: 0.35)
                : (iconColor ?? Colors.white.withValues(alpha: 0.92)),
          ),
        ),
      ),
    );
  }

  /// Квадратная иконка-инструмент в центральной панели (стиль uCrop).
  Widget _toolIconButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 48,
          height: 40,
          child: Icon(
            icon,
            size: 22,
            color: onTap == null
                ? Colors.white.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.92),
          ),
        ),
      ),
    );
  }

  Widget _buildViewport(VideoPlayerController? c) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ),
      );
    }
    if (c == null || !c.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final ratio = c.value.aspectRatio <= 0 ? 1.0 : c.value.aspectRatio;
        final geo = _buildGeometry(constraints);
        return Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Transform.rotate(
                angle: _rotationQuarterTurns * (math.pi / 2),
                child: AspectRatio(
                  aspectRatio: ratio,
                  child: VideoPlayer(c),
                ),
              ),
            ),
            if (geo != null)
              Positioned.fill(
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) => _onPointerDown(event, geo),
                  onPointerMove: (event) => _onPointerMove(event, geo),
                  onPointerUp: (_) => _endPointerDrag(),
                  onPointerCancel: (_) => _endPointerDrag(),
                  child: CustomPaint(
                    painter: _CropOverlayPainter(
                      cropRect: _cropDraftRect,
                      videoRect: geo.rect,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _player;
    return Scaffold(
      backgroundColor: const Color(0xFF05070C),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.video_crop_title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.26),
                    ),
                    child: _buildViewport(c),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _circleIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                    size: 40,
                    iconSize: 20,
                    background: Colors.white.withValues(alpha: 0.08),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _toolIconButton(
                              icon: Icons.rotate_left_rounded,
                              onTap: _rotateLeft,
                            ),
                            _toolIconButton(
                              icon: Icons.refresh_rounded,
                              onTap: _resetCrop,
                            ),
                            _toolIconButton(
                              icon: Icons.aspect_ratio_rounded,
                              onTap: _pickAspectRatio,
                            ),
                            _toolIconButton(
                              icon: Icons.rotate_right_rounded,
                              onTap: _rotateRight,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _circleIconButton(
                    icon: Icons.check_rounded,
                    onTap: _done,
                    size: 40,
                    iconSize: 22,
                    background: const Color(0xFFEAB308),
                    iconColor: Colors.white,
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

class _AspectPreset {
  const _AspectPreset({required this.label, required this.ratio});

  final String label;
  final double? ratio;
}

class _VideoGeometry {
  const _VideoGeometry({required this.rect});

  final Rect rect;
}

enum _CropDragHandle {
  move,
  left,
  right,
  top,
  bottom,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class _CropOverlayPainter extends CustomPainter {
  const _CropOverlayPainter({
    required this.cropRect,
    required this.videoRect,
  });

  final Rect cropRect;
  final Rect videoRect;

  @override
  void paint(Canvas canvas, Size size) {
    final normalized = cropRect;
    final cropLocal = Rect.fromLTRB(
      videoRect.left + normalized.left * videoRect.width,
      videoRect.top + normalized.top * videoRect.height,
      videoRect.left + normalized.right * videoRect.width,
      videoRect.top + normalized.bottom * videoRect.height,
    );

    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final frame = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.92);
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.28);

    // Scrim around
    canvas.save();
    canvas.clipRect(videoRect);
    canvas.drawRect(Rect.fromLTWH(videoRect.left, videoRect.top, videoRect.width, cropLocal.top - videoRect.top), scrim);
    canvas.drawRect(Rect.fromLTWH(videoRect.left, cropLocal.bottom, videoRect.width, videoRect.bottom - cropLocal.bottom), scrim);
    canvas.drawRect(Rect.fromLTWH(videoRect.left, cropLocal.top, cropLocal.left - videoRect.left, cropLocal.height), scrim);
    canvas.drawRect(Rect.fromLTWH(cropLocal.right, cropLocal.top, videoRect.right - cropLocal.right, cropLocal.height), scrim);
    canvas.restore();

    // Grid 3x3
    final thirdW = cropLocal.width / 3;
    final thirdH = cropLocal.height / 3;
    for (var i = 1; i <= 2; i++) {
      final x = cropLocal.left + thirdW * i;
      canvas.drawLine(Offset(x, cropLocal.top), Offset(x, cropLocal.bottom), grid);
      final y = cropLocal.top + thirdH * i;
      canvas.drawLine(Offset(cropLocal.left, y), Offset(cropLocal.right, y), grid);
    }

    // Frame
    canvas.drawRect(cropLocal, frame);

    // Corner handles
    final handlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const l = 18.0;
    void corner(Offset p, Offset dx, Offset dy) {
      canvas.drawLine(p, p + dx * l, handlePaint);
      canvas.drawLine(p, p + dy * l, handlePaint);
    }

    corner(cropLocal.topLeft, const Offset(1, 0), const Offset(0, 1));
    corner(cropLocal.topRight, const Offset(-1, 0), const Offset(0, 1));
    corner(cropLocal.bottomLeft, const Offset(1, 0), const Offset(0, -1));
    corner(cropLocal.bottomRight, const Offset(-1, 0), const Offset(0, -1));
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect || oldDelegate.videoRect != videoRect;
  }
}

