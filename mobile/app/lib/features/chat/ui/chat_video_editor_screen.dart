import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_min_gpl/return_code.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import 'chat_video_crop_screen.dart';

class ChatVideoEditorResult {
  const ChatVideoEditorResult({required this.file, required this.caption});

  final XFile file;
  final String caption;
}

class ChatVideoEditorScreen extends StatefulWidget {
  const ChatVideoEditorScreen({
    super.key,
    required this.file,
    required this.initialCaption,
  });

  final XFile file;
  final String initialCaption;

  static Future<ChatVideoEditorResult?> open(
    BuildContext context, {
    required XFile file,
    required String initialCaption,
  }) {
    return Navigator.of(context).push<ChatVideoEditorResult>(
      MaterialPageRoute(
        builder: (_) =>
            ChatVideoEditorScreen(file: file, initialCaption: initialCaption),
      ),
    );
  }

  @override
  State<ChatVideoEditorScreen> createState() => _ChatVideoEditorScreenState();
}

class _ChatVideoEditorScreenState extends State<ChatVideoEditorScreen> {
  static const double _minTrimGap = 0.02;
  static const double _minCropSizeFraction = 0.12;
  static const Rect _fullCropRect = Rect.fromLTWH(0, 0, 1, 1);

  final TextEditingController _captionController = TextEditingController();
  VideoPlayerController? _player;

  bool _loading = true;
  bool _processing = false;
  String? _errorText;
  double _trimStart = 0;
  double _trimEnd = 1;
  int _rotationQuarterTurns = 0;
  bool _mute = false;
  bool _drawMode = false;
  double _brushSize = 8;
  Color _brushColor = const Color(0xFFEF4444);
  List<_DrawStroke> _strokes = <_DrawStroke>[];
  _DrawStroke? _activeStroke;
  Rect _cropRect = _fullCropRect;
  double? _cropAspectRatio;

  bool _timelineLoading = false;
  int _timelineLoadToken = 0;
  List<_TimelineFrame> _timelineFrames = const <_TimelineFrame>[];

  // --- In-place zoom state (Telegram-like detailed storyboard on long-press) ---
  //
  // On long-press the main storyboard bar swaps its frames for a
  // denser frame strip covering only the selected fragment, and the
  // drag position is interpreted within that fragment for precise
  // scrubbing / trim adjustment. No floating overlay is rendered.
  static const int _kZoomFrameCount = 12;
  static const double _kZoomReloadThreshold = 0.4; // 40% of window
  static const double _kZoomEdgeAutoScroll = 0.04; // proximity to bar edge (0..1)

  bool _zoomActive = false;
  double _zoomCenterFraction = 0;
  double _zoomWindowFraction = 0.15;
  int _zoomLoadToken = 0;
  List<_TimelineFrame> _zoomFrames = const <_TimelineFrame>[];
  bool _zoomFramesLoading = false;
  double _zoomLastLoadedCenter = -1;
  double _zoomHandleOriginFraction = 0;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _captionController.text = widget.initialCaption;
    unawaited(_initPlayer());
  }

  @override
  void dispose() {
    _captionController.dispose();
    _player?.removeListener(_onPlayerTick);
    unawaited(_player?.dispose());
    unawaited(_deleteTimelineFrames(_timelineFrames));
    unawaited(_deleteTimelineFrames(_zoomFrames));
    super.dispose();
  }

  Future<void> _initPlayer() async {
    setState(() {
      _loading = true;
      _errorText = null;
    });
    final c = VideoPlayerController.file(
      File(widget.file.path),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    try {
      await c.initialize();
      c.setLooping(false);
      c.addListener(_onPlayerTick);
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _player = c;
        _duration = c.value.duration;
        if (_duration <= Duration.zero) {
          _duration = const Duration(seconds: 1);
        }
        _position = Duration.zero;
        _loading = false;
      });
      unawaited(_loadTimelineFrames());
    } catch (e) {
      await c.dispose();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = 'Не удалось загрузить видео: $e';
      });
    }
  }

  void _onPlayerTick() {
    final c = _player;
    if (c == null || !mounted) return;
    final val = c.value;
    final duration = _safeDuration;
    final start = _durationFromFraction(_trimStart, duration);
    final end = _durationFromFraction(_trimEnd, duration);

    final overTrimEnd = val.position >= end && end > start;
    if (val.isPlaying && overTrimEnd) {
      unawaited(c.seekTo(start));
      unawaited(c.play());
    }

    final nextPlaying = val.isPlaying;
    final nextPos = val.position;
    if (nextPlaying != _isPlaying || nextPos != _position) {
      setState(() {
        _isPlaying = nextPlaying;
        _position = nextPos;
      });
    }
  }

  Duration get _safeDuration {
    final d = _duration;
    if (d <= Duration.zero) return const Duration(seconds: 1);
    return d;
  }

  Duration _durationFromFraction(double fraction, Duration base) {
    final ms = (base.inMilliseconds * fraction).round();
    return Duration(milliseconds: ms.clamp(0, base.inMilliseconds));
  }

  double _fractionFromDuration(Duration value, Duration base) {
    if (base.inMilliseconds <= 0) return 0;
    return (value.inMilliseconds / base.inMilliseconds).clamp(0, 1);
  }

  String _fmt(Duration d) {
    final sec = d.inSeconds.clamp(0, 99 * 3600);
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _togglePlay() async {
    final c = _player;
    if (c == null || _processing || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      await c.pause();
      return;
    }
    final duration = _safeDuration;
    final start = _durationFromFraction(_trimStart, duration);
    final end = _durationFromFraction(_trimEnd, duration);
    if (c.value.position >= end || c.value.position < start) {
      await c.seekTo(start);
    }
    await c.play();
  }

  Future<void> _seekToFraction(double value) async {
    final c = _player;
    if (c == null || !c.value.isInitialized) return;
    final duration = _safeDuration;
    final start = _durationFromFraction(_trimStart, duration);
    final end = _durationFromFraction(_trimEnd, duration);
    final rawTarget = _durationFromFraction(value, duration);
    var target = rawTarget;
    if (target < start) target = start;
    if (target > end) target = end;
    await c.seekTo(target);
  }

  void _setTrimRange(double start, double end) {
    var nextStart = start.clamp(0.0, 1.0);
    var nextEnd = end.clamp(0.0, 1.0);
    if (nextEnd - nextStart < _minTrimGap) {
      if ((nextStart - _trimStart).abs() >= (nextEnd - _trimEnd).abs()) {
        nextStart = (nextEnd - _minTrimGap).clamp(0.0, 1.0);
      } else {
        nextEnd = (nextStart + _minTrimGap).clamp(0.0, 1.0);
      }
    }
    setState(() {
      _trimStart = nextStart;
      _trimEnd = nextEnd;
    });
    final c = _player;
    if (c == null || !c.value.isInitialized) return;
    final startDur = _durationFromFraction(_trimStart, _safeDuration);
    if (c.value.position < startDur) {
      unawaited(c.seekTo(startDur));
    }
  }

  void _dragTrimStartByDelta(double deltaFraction) {
    _setTrimRange(_trimStart + deltaFraction, _trimEnd);
  }

  void _dragTrimEndByDelta(double deltaFraction) {
    _setTrimRange(_trimStart, _trimEnd + deltaFraction);
  }

  void _seekToTimelineFraction(double fraction) {
    unawaited(_seekToFraction(fraction.clamp(0.0, 1.0)));
  }

  bool get _hasEdits {
    final trimChanged =
        (_trimStart - 0).abs() > 0.001 || (_trimEnd - 1).abs() > 0.001;
    final hasPendingStroke =
        _activeStroke != null && _activeStroke!.points.isNotEmpty;
    return trimChanged ||
        _rotationQuarterTurns % 4 != 0 ||
        _mute ||
        !_isFullCrop(_cropRect) ||
        _strokes.isNotEmpty ||
        hasPendingStroke;
  }

  bool _isFullCrop(Rect rect) {
    return (rect.left - 0).abs() < 0.0001 &&
        (rect.top - 0).abs() < 0.0001 &&
        (rect.right - 1).abs() < 0.0001 &&
        (rect.bottom - 1).abs() < 0.0001;
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

  Widget _buildCropPreviewTransform({
    required Widget child,
    required _VideoDisplayGeometry geometry,
    required Rect cropRect,
  }) {
    if (_isFullCrop(cropRect)) return child;
    final normalized = _normalizeCropRect(cropRect);
    final cropWidth = normalized.width.clamp(_minCropSizeFraction, 1.0);
    final scale = (1.0 / cropWidth).clamp(1.0, 7.5);
    final centerX = normalized.left + normalized.width / 2;
    final centerY = normalized.top + normalized.height / 2;
    final tx = (0.5 - centerX) * geometry.rect.width * scale;
    final ty = (0.5 - centerY) * geometry.rect.height * scale;
    return Transform.translate(
      offset: Offset(tx, ty),
      child: Transform.scale(
        alignment: Alignment.center,
        scale: scale,
        child: child,
      ),
    );
  }

  Future<void> _openCropEditor() async {
    if (_processing || _loading) return;
    unawaited(_player?.pause());
    final res = await ChatVideoCropScreen.open(
      context,
      file: File(widget.file.path),
      initialCropRect: _cropRect,
      initialRotationQuarterTurns: _rotationQuarterTurns,
      initialAspectRatio: _cropAspectRatio,
    );
    if (!mounted || res == null) return;
    setState(() {
      _cropRect = _normalizeCropRect(res.cropRect);
      _rotationQuarterTurns = res.rotationQuarterTurns % 4;
      _cropAspectRatio = res.selectedAspectRatio;
      _drawMode = false;
      _activeStroke = null;
    });
  }

  Future<void> _deleteTimelineFrames(List<_TimelineFrame> frames) async {
    for (final frame in frames) {
      try {
        await File(frame.path).delete();
      } catch (_) {}
    }
  }

  Future<void> _loadTimelineFrames() async {
    final c = _player;
    if (c == null || !c.value.isInitialized) return;

    final oldFrames = _timelineFrames;
    final token = ++_timelineLoadToken;
    setState(() {
      _timelineLoading = true;
      _timelineFrames = const <_TimelineFrame>[];
    });
    await _deleteTimelineFrames(oldFrames);

    final duration = _safeDuration.inMilliseconds / 1000.0;
    final count = duration < 4
        ? 8
        : duration < 15
        ? 12
        : 16;
    final generated = <_TimelineFrame>[];
    final tempDir = await getTemporaryDirectory();
    for (var i = 0; i < count; i++) {
      if (!mounted || token != _timelineLoadToken) {
        await _deleteTimelineFrames(generated);
        return;
      }
      final t = count == 1 ? 0.0 : (duration * i / (count - 1));
      final outPath =
          '${tempDir.path}/chat_video_tl_${DateTime.now().microsecondsSinceEpoch}_$i.jpg';
      final cmd =
          "-y -ss ${_sec(t)} -i ${_quote(widget.file.path)} -frames:v 1 -vf ${_quote('scale=120:-1')} ${_quote(outPath)}";
      final session = await FFmpegKit.execute(cmd);
      final code = await session.getReturnCode();
      if (ReturnCode.isSuccess(code) && await File(outPath).exists()) {
        generated.add(_TimelineFrame(path: outPath, second: t));
      }
    }
    if (!mounted || token != _timelineLoadToken) {
      await _deleteTimelineFrames(generated);
      return;
    }
    setState(() {
      _timelineFrames = generated;
      _timelineLoading = false;
    });
  }

  // --- Zoom loupe: detailed frame strip shown on long-press ---

  double _computeZoomWindowFraction(Duration d) {
    final sec = d.inMilliseconds / 1000.0;
    if (sec <= 0) return 0.2;
    // 2 seconds expressed as a fraction of total duration.
    final twoSecFraction = (2.0 / sec).clamp(0.0, 1.0);
    // Default target: max(10% of video, 2 seconds), capped at 20%.
    return math.max(twoSecFraction, 0.10).clamp(0.05, 0.20);
  }

  void _openZoom({
    required _ZoomMode mode,
    required double centerFraction,
    required double barWidth,
  }) {
    if (_processing || _loading) return;
    final clamped = centerFraction.clamp(0.0, 1.0);
    final window = _computeZoomWindowFraction(_safeDuration);
    final c = _player;
    if (c != null && c.value.isInitialized && c.value.isPlaying) {
      unawaited(c.pause());
    }
    setState(() {
      _zoomActive = true;
      _zoomCenterFraction = clamped;
      _zoomWindowFraction = window;
      _zoomHandleOriginFraction = mode == _ZoomMode.trimStart
          ? _trimStart
          : (mode == _ZoomMode.trimEnd ? _trimEnd : clamped);
    });
    unawaited(_loadZoomFrames(clamped));
  }

  void _updateZoomCenter(double centerFraction) {
    if (!_zoomActive) return;
    final clamped = centerFraction.clamp(0.0, 1.0);
    if ((clamped - _zoomCenterFraction).abs() < 0.0001) return;
    setState(() {
      _zoomCenterFraction = clamped;
    });
    if (_zoomLastLoadedCenter < 0 ||
        (clamped - _zoomLastLoadedCenter).abs() >
            _zoomWindowFraction * _kZoomReloadThreshold) {
      unawaited(_loadZoomFrames(clamped));
    }
  }

  void _closeZoom() {
    if (!_zoomActive) return;
    final old = _zoomFrames;
    _zoomLoadToken++;
    setState(() {
      _zoomActive = false;
      _zoomFrames = const <_TimelineFrame>[];
      _zoomFramesLoading = false;
      _zoomLastLoadedCenter = -1;
    });
    unawaited(_deleteTimelineFrames(old));
  }

  Future<void> _loadZoomFrames(double centerFraction) async {
    final c = _player;
    if (c == null || !c.value.isInitialized) return;
    final totalSec = _safeDuration.inMilliseconds / 1000.0;
    if (totalSec <= 0) return;

    final window = _zoomWindowFraction;
    final startFraction = (centerFraction - window / 2).clamp(0.0, 1.0);
    final endFraction = (centerFraction + window / 2).clamp(0.0, 1.0);
    final startSec = totalSec * startFraction;
    final endSec = totalSec * endFraction;
    const count = _kZoomFrameCount;

    final token = ++_zoomLoadToken;
    if (mounted) {
      setState(() {
        _zoomFramesLoading = true;
      });
    }

    final tempDir = await getTemporaryDirectory();
    final generated = <_TimelineFrame>[];
    for (var i = 0; i < count; i++) {
      if (!mounted || token != _zoomLoadToken) {
        await _deleteTimelineFrames(generated);
        return;
      }
      final t = count == 1
          ? startSec
          : startSec + (endSec - startSec) * i / (count - 1);
      final outPath =
          '${tempDir.path}/chat_video_tl_zoom_${DateTime.now().microsecondsSinceEpoch}_$i.jpg';
      final cmd =
          "-y -ss ${_sec(t)} -i ${_quote(widget.file.path)} -frames:v 1 -vf ${_quote('scale=160:-1')} ${_quote(outPath)}";
      final session = await FFmpegKit.execute(cmd);
      final code = await session.getReturnCode();
      if (ReturnCode.isSuccess(code) && await File(outPath).exists()) {
        generated.add(_TimelineFrame(path: outPath, second: t));
      }
    }
    if (!mounted || token != _zoomLoadToken) {
      await _deleteTimelineFrames(generated);
      return;
    }
    final old = _zoomFrames;
    setState(() {
      _zoomFrames = generated;
      _zoomFramesLoading = false;
      _zoomLastLoadedCenter = centerFraction;
    });
    unawaited(_deleteTimelineFrames(old));
  }

  _VideoDisplayGeometry? _buildGeometry(BoxConstraints constraints) {
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
    return _VideoDisplayGeometry(
      rect: Rect.fromLTWH(left, top, displayW, displayH),
      sourceWidth: sourceW,
      sourceHeight: sourceH,
      rotationQuarterTurns: turns,
    );
  }

  Offset? _localToSource(Offset local, _VideoDisplayGeometry geometry) {
    final rect = geometry.rect;
    if (!rect.contains(local)) return null;
    final u = ((local.dx - rect.left) / rect.width).clamp(0.0, 1.0);
    final v = ((local.dy - rect.top) / rect.height).clamp(0.0, 1.0);
    final w = geometry.sourceWidth;
    final h = geometry.sourceHeight;

    late double sx;
    late double sy;
    switch (geometry.rotationQuarterTurns) {
      case 0:
        sx = u * w;
        sy = v * h;
        break;
      case 1:
        sx = v * w;
        sy = (1 - u) * h;
        break;
      case 2:
        sx = (1 - u) * w;
        sy = (1 - v) * h;
        break;
      default:
        sx = (1 - v) * w;
        sy = u * h;
        break;
    }
    return Offset(sx.clamp(0.0, w), sy.clamp(0.0, h));
  }

  void _onDrawPanStart(
    DragStartDetails details,
    _VideoDisplayGeometry geometry,
  ) {
    if (!_drawMode || _processing) return;
    final point = _localToSource(details.localPosition, geometry);
    if (point == null) return;
    setState(() {
      _activeStroke = _DrawStroke(
        color: _brushColor,
        width: (_brushSize * geometry.localToSourceScale).clamp(1.0, 256.0),
        points: <Offset>[point],
      );
    });
  }

  void _onDrawPanUpdate(
    DragUpdateDetails details,
    _VideoDisplayGeometry geometry,
  ) {
    if (!_drawMode || _processing) return;
    final current = _activeStroke;
    if (current == null) return;
    final point = _localToSource(details.localPosition, geometry);
    if (point == null) return;
    final points = List<Offset>.from(current.points);
    if (points.isNotEmpty && (points.last - point).distance < 0.8) {
      return;
    }
    points.add(point);
    setState(() {
      _activeStroke = _DrawStroke(
        color: current.color,
        width: current.width,
        points: points,
      );
    });
  }

  void _onDrawPanEnd(DragEndDetails details) {
    if (!_drawMode || _processing) return;
    final current = _activeStroke;
    if (current == null) return;
    setState(() {
      if (current.points.isNotEmpty) {
        _strokes = List<_DrawStroke>.from(_strokes)..add(current);
      }
      _activeStroke = null;
    });
  }

  void _onDrawPanCancel() {
    if (!_drawMode || _processing) return;
    final current = _activeStroke;
    if (current == null) return;
    setState(() {
      if (current.points.isNotEmpty) {
        _strokes = List<_DrawStroke>.from(_strokes)..add(current);
      }
      _activeStroke = null;
    });
  }

  void _undoStroke() {
    if (_strokes.isEmpty) return;
    setState(() {
      _strokes = List<_DrawStroke>.from(_strokes)..removeLast();
      _activeStroke = null;
    });
  }

  void _clearStrokes() {
    if (_strokes.isEmpty && _activeStroke == null) return;
    setState(() {
      _strokes = <_DrawStroke>[];
      _activeStroke = null;
    });
  }

  Future<String?> _buildDrawOverlayPngPath(Size sourceSize) async {
    if (_strokes.isEmpty) return null;
    final width = sourceSize.width.round().clamp(2, 8192);
    final height = sourceSize.height.round().clamp(2, 8192);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );
    for (final stroke in _strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;
      if (stroke.points.length == 1) {
        canvas.drawPoints(
          ui.PointMode.points,
          stroke.points,
          paint..strokeWidth = math.max(2, stroke.width),
        );
        continue;
      }
      final path = Path()
        ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (var i = 1; i < stroke.points.length; i++) {
        final p = stroke.points[i];
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
    final image = await recorder.endRecording().toImage(width, height);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) return null;
    final tempDir = await getTemporaryDirectory();
    final path =
        '${tempDir.path}/chat_video_draw_overlay_${DateTime.now().microsecondsSinceEpoch}.png';
    await File(path).writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    return path;
  }

  _CropRect? _buildCropRect(Size sourceSize) {
    if (_isFullCrop(_cropRect)) return null;
    final sourceW = sourceSize.width;
    final sourceH = sourceSize.height;
    if (sourceW <= 0 || sourceH <= 0) return null;

    final turns = _rotationQuarterTurns % 4;
    final orientedW = turns.isEven ? sourceW : sourceH;
    final orientedH = turns.isEven ? sourceH : sourceW;
    final r = _normalizeCropRect(_cropRect);
    final oLeft = r.left * orientedW;
    final oTop = r.top * orientedH;
    final oRight = r.right * orientedW;
    final oBottom = r.bottom * orientedH;

    double sx;
    double sy;
    double sw;
    double sh;
    switch (turns) {
      case 0:
        sx = oLeft;
        sy = oTop;
        sw = oRight - oLeft;
        sh = oBottom - oTop;
        break;
      case 1:
        sx = oTop;
        sy = sourceH - oRight;
        sw = oBottom - oTop;
        sh = oRight - oLeft;
        break;
      case 2:
        sx = sourceW - oRight;
        sy = sourceH - oBottom;
        sw = oRight - oLeft;
        sh = oBottom - oTop;
        break;
      default:
        sx = sourceW - oBottom;
        sy = oLeft;
        sw = oBottom - oTop;
        sh = oRight - oLeft;
        break;
    }

    var cropX = sx.round();
    var cropY = sy.round();
    var cropWidth = sw.round();
    var cropHeight = sh.round();

    if (cropWidth.isOdd) cropWidth -= 1;
    if (cropHeight.isOdd) cropHeight -= 1;
    if (cropX.isOdd) cropX -= 1;
    if (cropY.isOdd) cropY -= 1;
    cropWidth = cropWidth.clamp(2, sourceW.round());
    cropHeight = cropHeight.clamp(2, sourceH.round());
    cropX = cropX.clamp(0, sourceW.round() - cropWidth);
    cropY = cropY.clamp(0, sourceH.round() - cropHeight);
    return _CropRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight);
  }

  String _quote(String value) {
    return "'${value.replaceAll("'", "'\\''")}'";
  }

  String _sec(double value) {
    return value.toStringAsFixed(3);
  }

  Future<ChatVideoEditorResult?> _processAndBuildResult() async {
    if (_processing) return null;
    final file = widget.file;
    final caption = _captionController.text.trim();
    if (!_hasEdits) {
      return ChatVideoEditorResult(file: file, caption: caption);
    }

    final c = _player;
    if (c == null || !c.value.isInitialized) return null;

    setState(() {
      _processing = true;
      _errorText = null;
    });

    String? overlayPath;
    try {
      await c.pause();
      if (_activeStroke != null && _activeStroke!.points.isNotEmpty) {
        _strokes = List<_DrawStroke>.from(_strokes)..add(_activeStroke!);
        _activeStroke = null;
      }
      final duration = _safeDuration;
      final startSec = duration.inMilliseconds * _trimStart / 1000;
      var trimSec = duration.inMilliseconds * (_trimEnd - _trimStart) / 1000;
      trimSec = math.max(0.2, trimSec);
      final sourceSize = c.value.size;
      final crop = _buildCropRect(sourceSize);
      overlayPath = await _buildDrawOverlayPngPath(sourceSize);

      final filters = <String>[];
      if (crop != null) {
        filters.add('crop=${crop.width}:${crop.height}:${crop.x}:${crop.y}');
      }
      final turns = _rotationQuarterTurns % 4;
      if (turns == 1) {
        filters.add('transpose=1');
      } else if (turns == 2) {
        filters.add('transpose=1');
        filters.add('transpose=1');
      } else if (turns == 3) {
        filters.add('transpose=2');
      }
      filters.add('scale=trunc(iw/2)*2:trunc(ih/2)*2');
      final videoChain = filters.join(',');

      final tempDir = await getTemporaryDirectory();
      final outPath =
          '${tempDir.path}/chat_video_edit_${DateTime.now().microsecondsSinceEpoch}.mp4';

      final parts = <String>[
        '-y',
        '-ss',
        _sec(startSec),
        '-t',
        _sec(trimSec),
        '-i',
        _quote(file.path),
        if (overlayPath != null) ...['-loop', '1', '-i', _quote(overlayPath)],
      ];

      if (overlayPath == null) {
        parts.addAll(<String>[
          '-map',
          '0:v:0',
          if (videoChain.isNotEmpty) ...['-vf', _quote(videoChain)],
        ]);
      } else {
        final baseChain = videoChain.isEmpty ? 'null' : videoChain;
        final filterComplex =
            '[0:v]$baseChain[v0];[1:v]$baseChain[ov0];[v0][ov0]overlay=0:0:format=auto[vout]';
        parts.addAll(<String>[
          '-filter_complex',
          _quote(filterComplex),
          '-map',
          _quote('[vout]'),
          '-shortest',
        ]);
      }

      parts.addAll(<String>[
        if (!_mute) ...['-map', '0:a?'],
        '-c:v',
        'libx264',
        '-preset',
        'veryfast',
        '-crf',
        '23',
        '-pix_fmt',
        'yuv420p',
        if (_mute) ...['-an'] else ...['-c:a', 'aac', '-b:a', '128k'],
        '-movflags',
        '+faststart',
        _quote(outPath),
      ]);
      final command = parts.join(' ');

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      if (!ReturnCode.isSuccess(returnCode)) {
        final logs = (await session.getAllLogsAsString()) ?? '';
        throw Exception(logs.trim().isEmpty ? 'FFmpeg export failed' : logs);
      }

      final outFile = XFile(
        outPath,
        name: 'video_${DateTime.now().millisecondsSinceEpoch}.mp4',
        mimeType: 'video/mp4',
      );
      return ChatVideoEditorResult(file: outFile, caption: caption);
    } catch (e) {
      if (mounted) {
        setState(() => _errorText = 'Не удалось обработать видео: $e');
      }
      return null;
    } finally {
      if (overlayPath != null) {
        try {
          await File(overlayPath).delete();
        } catch (_) {}
      }
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _saveAndClose() async {
    final result = await _processAndBuildResult();
    if (result == null || !mounted) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final c = _player;
    final d = _safeDuration;
    final startDur = _durationFromFraction(_trimStart, d);
    final endDur = _durationFromFraction(_trimEnd, d);
    final clippedDur = endDur - startDur;

    return Scaffold(
      backgroundColor: const Color(0xFF05070C),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  _iconButton(
                    icon: Icons.close_rounded,
                    onTap: _processing
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  _iconButton(
                    icon: Icons.volume_off_rounded,
                    onTap: _processing
                        ? null
                        : () => setState(() => _mute = !_mute),
                    active: _mute,
                  ),
                  const SizedBox(width: 8),
                  _iconButton(
                    icon: Icons.crop_rounded,
                    onTap: _processing ? null : () => unawaited(_openCropEditor()),
                    active: !_isFullCrop(_cropRect) || (_rotationQuarterTurns % 4 != 0),
                  ),
                  const SizedBox(width: 8),
                  _iconButton(
                    icon: Icons.brush_rounded,
                    onTap: _processing
                        ? null
                        : () => setState(() {
                            _drawMode = !_drawMode;
                            _activeStroke = null;
                          }),
                    active: _drawMode,
                  ),
                  const SizedBox(width: 8),
                  _iconButton(
                    icon: Icons.undo_rounded,
                    onTap: _processing || _strokes.isEmpty ? null : _undoStroke,
                  ),
                  const SizedBox(width: 8),
                  _iconButton(
                    icon: Icons.layers_clear_rounded,
                    onTap:
                        _processing ||
                            (_strokes.isEmpty && _activeStroke == null)
                        ? null
                        : _clearStrokes,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.black.withValues(alpha: 0.26),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : (_errorText != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                    _errorText!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : (c == null || !c.value.isInitialized
                                  ? const SizedBox.shrink()
                                  : LayoutBuilder(
                                      builder: (context, constraints) {
                                        final ratio = c.value.aspectRatio <= 0
                                            ? 1.0
                                            : c.value.aspectRatio;
                                        final geometry = _buildGeometry(
                                          constraints,
                                        );
                                        Widget mediaLayer = Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Center(
                                              child: Transform.rotate(
                                                angle:
                                                    _rotationQuarterTurns *
                                                    (math.pi / 2),
                                                child: AspectRatio(
                                                  aspectRatio: ratio,
                                                  child: VideoPlayer(c),
                                                ),
                                              ),
                                            ),
                                            if (geometry != null &&
                                                (_strokes.isNotEmpty ||
                                                    _activeStroke != null))
                                              Positioned.fill(
                                                child: IgnorePointer(
                                                  child: CustomPaint(
                                                    painter:
                                                        _VideoDrawOverlayPainter(
                                                          geometry: geometry,
                                                          committed: _strokes,
                                                          active: _activeStroke,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        );
                                        if (geometry != null) {
                                          mediaLayer = _buildCropPreviewTransform(
                                            child: mediaLayer,
                                            geometry: geometry,
                                            cropRect: _cropRect,
                                          );
                                        }
                                        return Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Positioned.fill(child: mediaLayer),
                                            Positioned.fill(
                                              child: GestureDetector(
                                                behavior: HitTestBehavior.opaque,
                                                onTap: (_processing || _drawMode)
                                                    ? null
                                                    : _togglePlay,
                                                onPanStart:
                                                    (_drawMode && !_processing && geometry != null)
                                                        ? (details) =>
                                                            _onDrawPanStart(details, geometry)
                                                        : null,
                                                onPanUpdate:
                                                    (_drawMode && !_processing && geometry != null)
                                                        ? (details) =>
                                                            _onDrawPanUpdate(details, geometry)
                                                        : null,
                                                onPanEnd:
                                                    (_drawMode && !_processing) ? _onDrawPanEnd : null,
                                                onPanCancel:
                                                    (_drawMode && !_processing) ? _onDrawPanCancel : null,
                                              ),
                                            ),
                                            if (!_drawMode)
                                              Positioned.fill(
                                                child: IgnorePointer(
                                                  child: Center(
                                                    child: AnimatedOpacity(
                                                      duration: const Duration(
                                                        milliseconds: 180,
                                                      ),
                                                      opacity: _isPlaying
                                                          ? 0
                                                          : 1,
                                                      child: Container(
                                                        width: 76,
                                                        height: 76,
                                                        decoration:
                                                            BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              color: Colors
                                                                  .black
                                                                  .withValues(
                                                                    alpha: 0.45,
                                                                  ),
                                                              border: Border.all(
                                                                color: Colors
                                                                    .white
                                                                    .withValues(
                                                                      alpha:
                                                                          0.2,
                                                                    ),
                                                              ),
                                                            ),
                                                        child: const Icon(
                                                          Icons
                                                              .play_arrow_rounded,
                                                          size: 40,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            if (_processing)
                                              Positioned.fill(
                                                child: Container(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.5),
                                                  child: const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    ))),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Row(
                children: [
                  Text(
                    _fmt(startDur),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStoryboardTimeline()),
                  const SizedBox(width: 8),
                  Text(
                    _fmt(endDur),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Длительность: ${_fmt(clippedDur)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            if (_drawMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Кисть',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Slider(
                            value: _brushSize,
                            min: 2,
                            max: 42,
                            onChanged: _processing
                                ? null
                                : (v) => setState(() => _brushSize = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _drawColorDot(Colors.white),
                        _drawColorDot(const Color(0xFFEF4444)),
                        _drawColorDot(const Color(0xFF3B82F6)),
                        _drawColorDot(const Color(0xFF22C55E)),
                        _drawColorDot(const Color(0xFFFACC15)),
                      ],
                    ),
                  ],
                ),
              ),
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Text(
                  _errorText!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontSize: 12.5,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _captionController,
                      maxLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Добавить подпись...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.42),
                        ),
                        prefixIcon: Icon(
                          Icons.videocam_rounded,
                          color: Colors.white.withValues(alpha: 0.52),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF2F86FF),
                          ),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: FilledButton(
                      onPressed: (_loading || _processing || _errorText != null)
                          ? null
                          : _saveAndClose,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                        backgroundColor: const Color(0xFF2F86FF),
                      ),
                      child: _processing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 22),
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

  Widget _buildStoryboardTimeline() {
    return SizedBox(
      height: 74,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth <= 1 ? 1.0 : constraints.maxWidth;

          // When the zoom is active the main bar displays only the
          // zoom window — every X coordinate therefore has to be mapped
          // from total-duration fractions into this smaller range.
          final zoomStartFraction = _zoomActive
              ? (_zoomCenterFraction - _zoomWindowFraction / 2).clamp(0.0, 1.0)
              : 0.0;
          final zoomEndFraction = _zoomActive
              ? (_zoomCenterFraction + _zoomWindowFraction / 2).clamp(0.0, 1.0)
              : 1.0;
          final zoomSpan =
              (zoomEndFraction - zoomStartFraction).clamp(0.0001, 1.0);

          double barXFromFraction(double fraction) {
            if (!_zoomActive) return fraction * width;
            return ((fraction - zoomStartFraction) / zoomSpan) * width;
          }

          double fractionFromBarX(double x) {
            final norm = (x / width).clamp(0.0, 1.0);
            if (!_zoomActive) return norm;
            return (zoomStartFraction + norm * zoomSpan).clamp(0.0, 1.0);
          }

          // dx(px) -> fraction delta, used by the trim-handle drag
          // handlers so that inside the zoom window a full-width drag
          // equals exactly one zoom window.
          double deltaPxToFraction(double dx) {
            if (!_zoomActive) return dx / width;
            return (dx / width) * _zoomWindowFraction;
          }

          final startX = barXFromFraction(_trimStart);
          final endX = barXFromFraction(_trimEnd);
          final playheadFraction =
              (_fractionFromDuration(_position, _safeDuration))
                  .clamp(_trimStart, _trimEnd);
          final playheadX = barXFromFraction(playheadFraction.toDouble());

          // During zoom the main bar shows the zoom frames; otherwise
          // the regular storyboard frames.
          final List<_TimelineFrame> frames =
              _zoomActive ? _zoomFrames : _timelineFrames;
          final bool framesLoading =
              _zoomActive ? _zoomFramesLoading : _timelineLoading;
          final frameCount = frames.length;

          final bar = ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Positioned.fill(
                  child: frameCount == 0
                      ? Container(
                          color: Colors.white.withValues(alpha: 0.08),
                          alignment: Alignment.center,
                          child: framesLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  Icons.videocam_rounded,
                                  color: Colors.white.withValues(alpha: 0.45),
                                ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final frame in frames)
                              Expanded(
                                // SizedBox.expand forces the Image to
                                // receive the full Expanded size, so
                                // BoxFit.cover reliably fills the bar
                                // height without vertical whitespace.
                                child: SizedBox.expand(
                                  child: Image.file(
                                    File(frame.path),
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            ColoredBox(
                                              color: Colors.white.withValues(
                                                alpha: 0.08,
                                              ),
                                            ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_processing || _zoomActive)
                        ? null
                        : (details) => _seekToTimelineFraction(
                            fractionFromBarX(details.localPosition.dx),
                          ),
                    onHorizontalDragStart: (_processing || _zoomActive)
                        ? null
                        : (details) => _seekToTimelineFraction(
                            fractionFromBarX(details.localPosition.dx),
                          ),
                    onHorizontalDragUpdate: (_processing || _zoomActive)
                        ? null
                        : (details) => _seekToTimelineFraction(
                            fractionFromBarX(details.localPosition.dx),
                          ),
                    onLongPressStart: _processing
                        ? null
                        : (details) {
                            final fraction =
                                (details.localPosition.dx / width)
                                    .clamp(0.0, 1.0);
                            _openZoom(
                              mode: _ZoomMode.seek,
                              centerFraction: fraction,
                              barWidth: width,
                            );
                            _seekToTimelineFraction(fraction);
                          },
                    onLongPressMoveUpdate: _processing
                        ? null
                        : (details) {
                            // While holding, the bar is already displaying
                            // the zoom window. Interpret the finger X
                            // inside that zoom window for precise seek.
                            final norm = (details.localPosition.dx / width)
                                .clamp(0.0, 1.0);
                            final fraction =
                                fractionFromBarX(details.localPosition.dx);
                            _seekToTimelineFraction(fraction);
                            // Auto-scroll the zoom window if the user
                            // drags close to its edges.
                            if (norm <= _kZoomEdgeAutoScroll ||
                                norm >= 1 - _kZoomEdgeAutoScroll) {
                              _updateZoomCenter(fraction);
                            }
                          },
                    onLongPressEnd: _processing ? null : (_) => _closeZoom(),
                  ),
                ),
                if (!_zoomActive && startX > 0)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: startX,
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.52),
                    ),
                  ),
                if (!_zoomActive && endX < width)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: width - endX,
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.52),
                    ),
                  ),
                if (endX > 0 && startX < width)
                  Positioned(
                    left: startX.clamp(0.0, width),
                    top: 0,
                    bottom: 0,
                    width: (endX.clamp(0.0, width) - startX.clamp(0.0, width))
                        .clamp(0.0, width),
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (startX >= -18 && startX <= width + 18)
                  Positioned(
                    left: startX - 9,
                    top: 0,
                    bottom: 0,
                    width: 18,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragUpdate: _processing
                          ? null
                          : (details) => _dragTrimStartByDelta(
                                deltaPxToFraction(details.delta.dx),
                              ),
                      onLongPressStart: _processing
                          ? null
                          : (_) => _openZoom(
                                mode: _ZoomMode.trimStart,
                                centerFraction: _trimStart,
                                barWidth: width,
                              ),
                      onLongPressMoveUpdate: _processing
                          ? null
                          : (details) {
                              final newFraction = (_zoomHandleOriginFraction +
                                      deltaPxToFraction(
                                          details.localOffsetFromOrigin.dx))
                                  .clamp(0.0, 1.0);
                              _setTrimRange(newFraction, _trimEnd);
                              _updateZoomCenter(newFraction);
                            },
                      onLongPressEnd: _processing ? null : (_) => _closeZoom(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                if (endX >= -18 && endX <= width + 18)
                  Positioned(
                    left: endX - 9,
                    top: 0,
                    bottom: 0,
                    width: 18,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragUpdate: _processing
                          ? null
                          : (details) => _dragTrimEndByDelta(
                                deltaPxToFraction(details.delta.dx),
                              ),
                      onLongPressStart: _processing
                          ? null
                          : (_) => _openZoom(
                                mode: _ZoomMode.trimEnd,
                                centerFraction: _trimEnd,
                                barWidth: width,
                              ),
                      onLongPressMoveUpdate: _processing
                          ? null
                          : (details) {
                              final newFraction = (_zoomHandleOriginFraction +
                                      deltaPxToFraction(
                                          details.localOffsetFromOrigin.dx))
                                  .clamp(0.0, 1.0);
                              _setTrimRange(_trimStart, newFraction);
                              _updateZoomCenter(newFraction);
                            },
                      onLongPressEnd: _processing ? null : (_) => _closeZoom(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                if (playheadX >= 0 && playheadX <= width)
                  Positioned(
                    left: playheadX - 1,
                    top: 0,
                    bottom: 0,
                    width: 2,
                    child: IgnorePointer(
                      child: Container(color: const Color(0xFF2F86FF)),
                    ),
                  ),
              ],
            ),
          );

          return SizedBox(width: width, height: 74, child: bar);
        },
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback? onTap,
    bool active = false,
  }) {
    return Material(
      color: active
          ? const Color(0xFF2F86FF)
          : Colors.white.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            size: 22,
            color: onTap == null
                ? Colors.white.withValues(alpha: 0.35)
                : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _drawColorDot(Color color) {
    final selected = _brushColor.toARGB32() == color.toARGB32();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: _processing ? null : () => setState(() => _brushColor = color),
        child: Container(
          width: selected ? 24 : 20,
          height: selected ? 24 : 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? Colors.white : Colors.white24,
              width: selected ? 2 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _CropRect {
  const _CropRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;
}

class _TimelineFrame {
  const _TimelineFrame({required this.path, required this.second});

  final String path;
  final double second;
}

enum _ZoomMode { seek, trimStart, trimEnd }

class _DrawStroke {
  const _DrawStroke({
    required this.color,
    required this.width,
    required this.points,
  });

  final Color color;
  final double width;
  final List<Offset> points;
}

class _VideoDisplayGeometry {
  const _VideoDisplayGeometry({
    required this.rect,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.rotationQuarterTurns,
  });

  final Rect rect;
  final double sourceWidth;
  final double sourceHeight;
  final int rotationQuarterTurns;

  double get localToSourceScale {
    final orientedWidth = rotationQuarterTurns.isEven
        ? sourceWidth
        : sourceHeight;
    if (rect.width <= 0) return 1;
    return orientedWidth / rect.width;
  }

  double get sourceToLocalScale {
    final scale = localToSourceScale;
    if (scale <= 0) return 1;
    return 1 / scale;
  }

  Offset sourceToLocal(Offset source) {
    final sx = source.dx.clamp(0.0, sourceWidth);
    final sy = source.dy.clamp(0.0, sourceHeight);
    late double u;
    late double v;
    switch (rotationQuarterTurns) {
      case 0:
        u = sx / sourceWidth;
        v = sy / sourceHeight;
        break;
      case 1:
        u = 1 - (sy / sourceHeight);
        v = sx / sourceWidth;
        break;
      case 2:
        u = 1 - (sx / sourceWidth);
        v = 1 - (sy / sourceHeight);
        break;
      default:
        u = sy / sourceHeight;
        v = 1 - (sx / sourceWidth);
        break;
    }
    return Offset(rect.left + u * rect.width, rect.top + v * rect.height);
  }
}

class _VideoDrawOverlayPainter extends CustomPainter {
  const _VideoDrawOverlayPainter({
    required this.geometry,
    required this.committed,
    required this.active,
  });

  final _VideoDisplayGeometry geometry;
  final List<_DrawStroke> committed;
  final _DrawStroke? active;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(geometry.rect);
    for (final stroke in committed) {
      _paintStroke(canvas, stroke);
    }
    if (active != null) {
      _paintStroke(canvas, active!);
    }
    canvas.restore();
  }

  void _paintStroke(Canvas canvas, _DrawStroke stroke) {
    if (stroke.points.isEmpty) return;
    final localWidth = (stroke.width * geometry.sourceToLocalScale).clamp(
      1.0,
      256.0,
    );
    final paint = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = localWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    if (stroke.points.length == 1) {
      final p = geometry.sourceToLocal(stroke.points.first);
      canvas.drawPoints(ui.PointMode.points, <Offset>[
        p,
      ], paint..strokeWidth = math.max(2, localWidth));
      return;
    }

    final first = geometry.sourceToLocal(stroke.points.first);
    final path = Path()..moveTo(first.dx, first.dy);
    for (var i = 1; i < stroke.points.length; i++) {
      final p = geometry.sourceToLocal(stroke.points[i]);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _VideoDrawOverlayPainter oldDelegate) {
    return oldDelegate.geometry != geometry ||
        oldDelegate.committed != committed ||
        oldDelegate.active != active;
  }
}
