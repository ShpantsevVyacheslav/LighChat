import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_min_gpl/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import '../../../l10n/app_localizations.dart';

import '../data/video_circle_postprocess.dart';
import 'video_circle_camera_preview.dart';

/// Полноэкранный поток: запись кружка -> превью -> отправить / удалить.
Future<void> pushVideoCircleCapturePage(
  BuildContext context, {
  required Future<void> Function(XFile file) onSend,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (ctx) => _VideoCircleCapturePage(onSend: onSend),
    ),
  );
}

enum _CircleCaptureState { preparing, recordingHold, preview, sending, error }

class _VideoCircleCapturePage extends StatefulWidget {
  const _VideoCircleCapturePage({required this.onSend});

  final Future<void> Function(XFile file) onSend;

  @override
  State<_VideoCircleCapturePage> createState() =>
      _VideoCircleCapturePageState();
}

class _VideoCircleCapturePageState extends State<_VideoCircleCapturePage> {
  static const double _actionBtn = 54;
  static const double _captureBtn = 84;
  static const double _cancelSwipeThreshold = 120;

  /// Minimum vertical clearance reserved for the bottom control panel
  /// so the full-width circle cannot overlap the capture button on
  /// short screens.
  static const double _bottomPanelReserve = 200;

  final List<CameraDescription> _cameras = <CameraDescription>[];
  CameraController? _cam;
  VideoPlayerController? _previewC;

  _CircleCaptureState _state = _CircleCaptureState.preparing;
  String? _error;
  XFile? _recorded;

  /// `true` once the recorded file has already been hflipped by
  /// [mirrorVideoCircleIfNeeded]. Used to decide whether the
  /// in-UI preview needs an additional [Transform.flip] so the
  /// recorded-clip preview matches the mirrored live preview.
  bool _fileIsMirrored = false;

  /// Камера, с которой была сделана запись (для корректного превью после стопа).
  bool _recordedWithFrontCamera = true;

  int _cameraIndex = 0;
  bool _flashOn = false;
  bool _flashSupported = false;

  /// Накопленная длительность записи до текущего активного сегмента (паузы обнуляют сегмент).
  Duration _recordingPausedTotal = Duration.zero;

  /// Пока не null — идёт «активная» запись (не на паузе плагина).
  DateTime? _recordingSegmentStartedAt;

  Duration _recordElapsed = Duration.zero;
  Timer? _recordTicker;
  Timer? _previewTicker;

  Duration _previewDuration = Duration.zero;
  double _trimStart = 0;
  double _trimEnd = 1;

  double _dragDx = 0;
  bool _isClosing = false;

  bool get _isRecordingState => _state == _CircleCaptureState.recordingHold;

  bool get _isBusy =>
      _state == _CircleCaptureState.preparing ||
      _state == _CircleCaptureState.sending;

  bool get _hasTrim =>
      _trimStart > 0.005 || _trimEnd < 0.995 || (_trimEnd - _trimStart) < 0.99;

  Duration get _trimStartDuration => Duration(
    milliseconds: (_previewDuration.inMilliseconds * _trimStart).round(),
  );

  Duration get _trimEndDuration => Duration(
    milliseconds: (_previewDuration.inMilliseconds * _trimEnd).round(),
  );

  Duration get _trimmedDuration {
    final d = _trimEndDuration - _trimStartDuration;
    return d > Duration.zero ? d : _previewDuration;
  }

  double get _minTrimFraction {
    final ms = _previewDuration.inMilliseconds;
    if (ms <= 0) return 0.04;
    return (500 / ms).clamp(0.04, 0.25);
  }

  bool get _isFrontCamera {
    if (_cameras.isEmpty ||
        _cameraIndex < 0 ||
        _cameraIndex >= _cameras.length) {
      return true;
    }
    return _cameras[_cameraIndex].lensDirection == CameraLensDirection.front;
  }

  /// На iOS фронтальный `CameraPreview` уже зеркальный на уровне платформы.
  /// На Android обычно требуется ручной `flipX` для selfie-паритета.
  bool get _needsManualFrontMirror {
    return defaultTargetPlatform == TargetPlatform.android;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_openCameraAndStart());
  }

  @override
  void dispose() {
    _recordTicker?.cancel();
    _previewTicker?.cancel();
    unawaited(_cam?.dispose());
    _previewC?.dispose();
    super.dispose();
  }

  Duration _computeRecordingElapsed() {
    var t = _recordingPausedTotal;
    final seg = _recordingSegmentStartedAt;
    if (seg != null) {
      t += DateTime.now().difference(seg);
    }
    return t;
  }

  void _flushRecordingElapsedToPausedTotal() {
    final seg = _recordingSegmentStartedAt;
    if (seg != null) {
      _recordingPausedTotal += DateTime.now().difference(seg);
      _recordingSegmentStartedAt = null;
    }
    _recordElapsed = _recordingPausedTotal;
  }

  void _startRecordTicker() {
    _recordTicker?.cancel();
    _recordTicker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted || _state != _CircleCaptureState.recordingHold) return;
      setState(() => _recordElapsed = _computeRecordingElapsed());
    });
  }

  void _stopRecordTicker() {
    _recordTicker?.cancel();
    _recordTicker = null;
  }

  Future<void> _openCameraAndStart({int? useIndex}) async {
    setState(() {
      _state = _CircleCaptureState.preparing;
      _error = null;
      _dragDx = 0;
    });

    try {
      if (_cameras.isEmpty) {
        final found = await availableCameras();
        _cameras.addAll(found);
      }
      if (_cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _state = _CircleCaptureState.error;
          _error = AppLocalizations.of(context)!.video_circle_camera_unavailable;
        });
        return;
      }

      final targetIndex = useIndex ?? _pickDefaultFrontCameraIndex();
      _cameraIndex = targetIndex.clamp(0, _cameras.length - 1);

      await _disposePreview();
      await _disposeCamera();

      final cc = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.medium,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await cc.initialize();
      await cc.prepareForVideoRecording();
      await _resetCameraOptics(cc);

      _flashSupported = false;
      _flashOn = false;
      try {
        await cc.setFlashMode(FlashMode.off);
        _flashSupported = true;
      } catch (_) {
        _flashSupported = false;
      }

      await cc.startVideoRecording();
      if (!mounted) {
        await cc.dispose();
        return;
      }

      _cam = cc;
      _recordingPausedTotal = Duration.zero;
      _recordingSegmentStartedAt = DateTime.now();
      _recordElapsed = Duration.zero;
      _startRecordTicker();

      setState(() {
        _state = _CircleCaptureState.recordingHold;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _CircleCaptureState.error;
        _error = AppLocalizations.of(context)!.video_circle_camera_error(e.toString());
      });
    }
  }

  int _pickCameraIndexForDirection(CameraLensDirection direction) {
    var fallback = -1;
    for (var i = 0; i < _cameras.length; i++) {
      final cam = _cameras[i];
      if (cam.lensDirection != direction) continue;
      fallback = i;
      final name = cam.name.toLowerCase();
      final looksMainBack =
          name.contains('wide') &&
          !name.contains('ultra') &&
          !name.contains('tele');
      if (direction == CameraLensDirection.back && looksMainBack) {
        return i;
      }
    }
    return fallback >= 0 ? fallback : _cameraIndex;
  }

  Future<void> _resetCameraOptics(CameraController cc) async {
    try {
      final minZoom = await cc.getMinZoomLevel();
      await cc.setZoomLevel(minZoom);
    } catch (_) {}
    try {
      await cc.setFocusMode(FocusMode.auto);
    } catch (_) {}
    try {
      await cc.setExposureMode(ExposureMode.auto);
    } catch (_) {}
  }

  int _pickDefaultFrontCameraIndex() {
    final i = _cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );
    return i >= 0 ? i : 0;
  }

  Future<void> _disposeCamera() async {
    final old = _cam;
    _cam = null;
    if (old != null) {
      try {
        await old.dispose();
      } catch (_) {}
    }
  }

  Future<void> _disposePreview() async {
    _previewTicker?.cancel();
    _previewTicker = null;
    final old = _previewC;
    _previewC = null;
    if (old != null) {
      try {
        await old.dispose();
      } catch (_) {}
    }
  }

  Future<void> _deleteFileSilently(String path) async {
    if (path.trim().isEmpty) return;
    try {
      await File(path).delete();
    } catch (_) {}
  }

  Future<void> _cancelAndClose() async {
    if (_isClosing || !mounted) return;
    _isClosing = true;

    _stopRecordTicker();

    final rec = _recorded;
    if (rec != null) {
      unawaited(_deleteFileSilently(rec.path));
      _recorded = null;
    }

    final cc = _cam;
    if (cc != null && cc.value.isRecordingVideo) {
      try {
        final f = await cc.stopVideoRecording();
        unawaited(_deleteFileSilently(f.path));
      } catch (_) {}
    }

    await _disposePreview();
    await _disposeCamera();

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _stopRecordingToPreview() async {
    final cc = _cam;
    if (cc == null || !_isRecordingState) return;

    setState(() => _state = _CircleCaptureState.preparing);

    try {
      _flushRecordingElapsedToPausedTotal();
      final wasFront = _isFrontCamera;
      _recordedWithFrontCamera = wasFront;
      final file = await cc.stopVideoRecording();
      _stopRecordTicker();
      await _disposeCamera();
      final processed = await mirrorVideoCircleIfNeeded(
        input: file,
        mirror: wasFront,
      );
      final didFlipFile = !identical(processed.path, file.path);
      if (didFlipFile) {
        unawaited(_deleteFileSilently(file.path));
      }
      _recorded = processed;
      _fileIsMirrored = didFlipFile;
      await _initPreview(processed);
      if (!mounted) return;
      setState(() {
        _state = _CircleCaptureState.preview;
        _dragDx = 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _CircleCaptureState.error;
        _error = AppLocalizations.of(context)!.video_circle_record_error(e.toString());
      });
    }
  }

  Future<void> _initPreview(XFile file) async {
    await _disposePreview();
    final ioFile = File(file.path);
    if (!await ioFile.exists()) {
      if (mounted) {
        setState(() {
          _state = _CircleCaptureState.error;
          _error = AppLocalizations.of(context)!.video_circle_file_not_found;
        });
      }
      return;
    }

    final c = VideoPlayerController.file(ioFile);
    _previewC = c;
    try {
      await c.initialize();
      await c.setLooping(true);
      _previewDuration =
          c.value.duration > Duration.zero
              ? c.value.duration
              : _recordElapsed;
      _trimStart = 0;
      _trimEnd = 1;
      await c.play();
      _startPreviewTicker();
      if (mounted) setState(() {});
    } catch (_) {
      await c.dispose();
      _previewC = null;
      if (mounted) {
        setState(() {
          _state = _CircleCaptureState.error;
          _error = AppLocalizations.of(context)!.video_circle_play_error;
        });
      }
    }
  }

  void _startPreviewTicker() {
    _previewTicker?.cancel();
    _previewTicker = Timer.periodic(const Duration(milliseconds: 130), (_) {
      if (!mounted) return;
      if (_state != _CircleCaptureState.preview &&
          _state != _CircleCaptureState.sending) {
        return;
      }
      final c = _previewC;
      if (c == null || !c.value.isInitialized) return;
      if (!_hasTrim) return;
      final pos = c.value.position;
      final start = _trimStartDuration;
      final end = _trimEndDuration;
      if (pos < start || pos > end) {
        unawaited(c.seekTo(start));
      }
    });
  }

  String _q(String path) => '"${path.replaceAll('"', '\\"')}"';

  String _sec(double value) => value.toStringAsFixed(3);

  Future<XFile> _buildSelectedResult() async {
    final rec = _recorded;
    if (rec == null || !_hasTrim || _previewDuration <= Duration.zero) {
      return rec!;
    }
    final inPath = rec.path.trim();
    if (inPath.isEmpty || !await File(inPath).exists()) {
      return rec;
    }

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final outPath = '${dir.path}/video_circle_trim_$stamp.mp4';
    final outPathNoAudio = '${dir.path}/video_circle_trim_${stamp}_na.mp4';
    final startSec = _trimStartDuration.inMilliseconds / 1000.0;
    final lenSec = _trimmedDuration.inMilliseconds / 1000.0;

    Future<XFile?> runTrim({
      required String out,
      required bool withAudio,
    }) async {
      final audioArgs = withAudio
          ? <String>['-c:a', 'aac', '-b:a', '128k']
          : <String>['-an'];
      final cmd = <String>[
        '-y',
        '-ss',
        _sec(startSec),
        '-t',
        _sec(lenSec),
        '-i',
        _q(inPath),
        '-c:v',
        'libx264',
        '-preset',
        'ultrafast',
        '-crf',
        '23',
        '-pix_fmt',
        'yuv420p',
        ...audioArgs,
        '-movflags',
        '+faststart',
        _q(out),
      ].join(' ');

      final session = await FFmpegKit.execute(cmd);
      final code = await session.getReturnCode();
      if (!ReturnCode.isSuccess(code)) {
        return null;
      }
      final f = File(out);
      if (!await f.exists() || await f.length() < 32) return null;
      return XFile(out, mimeType: 'video/mp4');
    }

    final withAudio = await runTrim(out: outPath, withAudio: true);
    if (withAudio != null) return withAudio;

    final noAudio = await runTrim(out: outPathNoAudio, withAudio: false);
    return noAudio ?? rec;
  }

  void _setTrimStart(double value) {
    final max = _trimEnd - _minTrimFraction;
    _trimStart = value.clamp(0.0, max.clamp(0.0, 1.0));
  }

  void _setTrimEnd(double value) {
    final min = _trimStart + _minTrimFraction;
    _trimEnd = value.clamp(min.clamp(0.0, 1.0), 1.0);
  }

  Future<void> _discardPreviewAndRestart() async {
    final rec = _recorded;
    if (rec != null) {
      unawaited(_deleteFileSilently(rec.path));
    }
    _recorded = null;
    _fileIsMirrored = false;
    _recordedWithFrontCamera = true;
    await _disposePreview();
    await _openCameraAndStart(useIndex: _cameraIndex);
  }

  Future<void> _send() async {
    final rec = _recorded;
    if (rec == null || _state == _CircleCaptureState.sending) return;

    setState(() => _state = _CircleCaptureState.sending);
    XFile? selected;
    try {
      selected = await _buildSelectedResult();
      await widget.onSend(selected);
      if (selected.path != rec.path) {
        unawaited(_deleteFileSilently(rec.path));
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (selected != null && selected.path != rec.path) {
        unawaited(_deleteFileSilently(selected.path));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.video_circle_send_error(
                e.toString(),
              ),
            ),
          ),
        );
        setState(() => _state = _CircleCaptureState.preview);
      }
    }
  }

  Future<void> _toggleCamera() async {
    if (!_isRecordingState || _isBusy || _cameras.length < 2) return;

    final cc = _cam;
    if (cc == null || !cc.value.isInitialized || !cc.value.isRecordingVideo) {
      return;
    }
    if (cc.value.isRecordingPaused) return;

    final current = _cameras[_cameraIndex].lensDirection;
    final targetDirection = current == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    final next = _pickCameraIndexForDirection(targetDirection);
    try {
      await cc.setDescription(_cameras[next]);
      await _resetCameraOptics(cc);
      if (!mounted) return;
      setState(() {
        _cameraIndex = next;
        _flashOn = false;
      });
      _flashSupported = false;
      try {
        await cc.setFlashMode(FlashMode.off);
        if (mounted) setState(() => _flashSupported = true);
      } catch (_) {
        if (mounted) setState(() => _flashSupported = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.video_circle_switch_error(e.toString()))),
      );
    }
  }

  Future<void> _toggleFlash() async {
    if (!_isRecordingState || _isBusy || !_flashSupported) return;
    final cc = _cam;
    if (cc == null || cc.value.isRecordingPaused) return;
    final next = !_flashOn;
    try {
      await cc.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _flashOn = next);
    } catch (_) {
      if (mounted) setState(() => _flashSupported = false);
    }
  }

  Future<void> _toggleRecordingPause() async {
    if (!_isRecordingState || _isBusy || _isClosing) return;
    final cc = _cam;
    if (cc == null || !cc.value.isInitialized || !cc.value.isRecordingVideo) {
      return;
    }
    final paused = cc.value.isRecordingPaused;
    try {
      if (paused) {
        await cc.resumeVideoRecording();
        _recordingSegmentStartedAt = DateTime.now();
        if (mounted) setState(() {});
      } else {
        _flushRecordingElapsedToPausedTotal();
        await cc.pauseVideoRecording();
        if (mounted) setState(() {});
      }
    } on CameraException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.video_circle_pause_error_detail(e.description ?? '', e.code),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.video_circle_pause_error(e.toString()))));
    }
  }

  void _onCapturePanUpdate(DragUpdateDetails d) {
    if (_state != _CircleCaptureState.recordingHold || _isBusy || _isClosing) {
      return;
    }

    final nextX = (_dragDx + d.delta.dx).clamp(-160.0, 0.0);

    setState(() {
      _dragDx = nextX;
    });

    if (nextX <= -_cancelSwipeThreshold) {
      unawaited(_cancelAndClose());
    }
  }

  void _onCapturePanEnd(DragEndDetails _) {
    if (_state != _CircleCaptureState.recordingHold || _isBusy || _isClosing) {
      return;
    }
    setState(() {
      _dragDx = 0;
    });
  }

  String _recordTimeLabel() {
    final total = _recordElapsed.inSeconds;
    final mm = (total ~/ 60).toString().padLeft(2, '0');
    final ss = (total % 60).toString().padLeft(2, '0');
    final cs = ((_recordElapsed.inMilliseconds % 1000) / 10)
        .round()
        .clamp(0, 99)
        .toString()
        .padLeft(2, '0');
    return '$mm:$ss,$cs';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    // Full-width circle (per design). We still cap the side by the
    // available vertical space so the circle cannot collide with the
    // bottom control panel on short devices / landscape.
    final availableHeight = math.max(0.0, size.height - _bottomPanelReserve);
    final circleSide = math.min(size.width, availableHeight);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _error != null && _state == _CircleCaptureState.error
            ? _buildErrorState()
            : Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topCenter,
                          radius: 1.15,
                          colors: [
                            const Color(0xFF1B1C24).withValues(alpha: 0.75),
                            const Color(0xFF0B0C11),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0, -0.10),
                    child: _buildCircleMain(circleSide, scheme),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IconButton(
                      onPressed: _cancelAndClose,
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 16,
                    child: _buildBottomPanel(scheme),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off_rounded,
              color: Colors.white70,
              size: 46,
            ),
            const SizedBox(height: 14),
            Text(
              _error ?? AppLocalizations.of(context)!.video_circle_camera_fallback_error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _openCameraAndStart,
              child: Text(AppLocalizations.of(context)!.video_circle_retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleMain(double side, ColorScheme scheme) {
    if (_state == _CircleCaptureState.preparing && _recorded == null) {
      return SizedBox(
        width: side,
        height: side,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.55),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 3,
            ),
          ),
          child: const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white60,
              ),
            ),
          ),
        ),
      );
    }

    if (_state == _CircleCaptureState.preview ||
        _state == _CircleCaptureState.sending) {
      final c = _previewC;
      // Mirror the recorded clip in-UI so the orientation matches the
      // live recording preview (which is always mirrored). This keeps
      // the experience consistent even if [mirrorVideoCircleIfNeeded]
      // fell back to the original file on this device.
      // Только селфи зеркалим в превью файла; задняя камера — как в записи.
      final mirrorRecorded = _recordedWithFrontCamera && !_fileIsMirrored;
      return _buildCircleFrame(
        side: side,
        borderColor: const Color(0xFF22C55E).withValues(alpha: 0.42),
        child: c != null && c.value.isInitialized
            ? Transform.flip(
                flipX: mirrorRecorded,
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: c.value.size.width,
                    height: c.value.size.height,
                    child: VideoPlayer(c),
                  ),
                ),
              )
            : const ColoredBox(color: Colors.black),
      );
    }

    final cc = _cam;
    return _buildCircleFrame(
      side: side,
      borderColor: scheme.primary.withValues(alpha: 0.38),
      child: cc != null && cc.value.isInitialized
          ? (_isFrontCamera && _needsManualFrontMirror)
                ? Transform.flip(
                    flipX: true,
                    child: VideoCircleCameraPreview(
                      controller: cc,
                      previewFit: BoxFit.cover,
                    ),
                  )
                : VideoCircleCameraPreview(
                    controller: cc,
                    // Единый crop с фронтом — иначе при смене камеры `cover`↔`contain`
                    // даёт скачок «зума» на первом кадре после setDescription.
                    previewFit: BoxFit.cover,
                  )
          : const ColoredBox(color: Colors.black),
    );
  }

  Widget _buildCircleFrame({
    required double side,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(child: child),
    );
  }

  Widget _buildBottomPanel(ColorScheme scheme) {
    final cancelProgress = (-_dragDx / _cancelSwipeThreshold).clamp(0, 1);

    if (_state == _CircleCaptureState.preview ||
        _state == _CircleCaptureState.sending) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black.withValues(alpha: 0.36),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: _VideoTrimTimeline(
              trimStart: _trimStart,
              trimEnd: _trimEnd,
              enabled: _state != _CircleCaptureState.sending,
              seed: _recorded?.path ?? 'video-circle',
              onStartChanged: (v) {
                setState(() => _setTrimStart(v));
                final c = _previewC;
                if (c != null && c.value.isInitialized) {
                  unawaited(c.seekTo(_trimStartDuration));
                }
              },
              onEndChanged: (v) {
                setState(() => _setTrimEnd(v));
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: _actionBtn,
                height: _actionBtn,
                child: IconButton(
                  onPressed: _state == _CircleCaptureState.sending
                      ? null
                      : _discardPreviewAndRestart,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                  ),
                  iconSize: 32,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.black.withValues(alpha: 0.32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _state == _CircleCaptureState.sending
                          ? AppLocalizations.of(context)!.video_circle_sending
                          : '${AppLocalizations.of(context)!.video_circle_recorded} • ${_timeLabel(_hasTrim ? _trimmedDuration : _previewDuration)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: _captureBtn,
                height: _captureBtn,
                child: _state == _CircleCaptureState.sending
                    ? const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        ),
                      )
                    : _CaptureButton(
                        color: scheme.primary,
                        icon: Icons.send_rounded,
                        onTap: _send,
                      ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ControlCircleButton(
              icon: _isFrontCamera
                  ? Icons.flip_camera_android_rounded
                  : Icons.flip_camera_ios_rounded,
              enabled: !_isBusy && _cameras.length > 1,
              onTap: _toggleCamera,
            ),
            const SizedBox(height: 10),
            _ControlCircleButton(
              icon: _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              enabled: !_isBusy && _flashSupported,
              onTap: _toggleFlash,
            ),
            const SizedBox(height: 10),
            _ControlCircleButton(
              icon: (_cam?.value.isRecordingPaused ?? false)
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
              enabled: !_isBusy && _isRecordingState,
              onTap: () => unawaited(_toggleRecordingPause()),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black.withValues(alpha: 0.32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 12, color: Color(0xFFFF4D4F)),
                const SizedBox(width: 10),
                Text(
                  _recordTimeLabel(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.video_circle_swipe_cancel,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.6 + cancelProgress * 0.4,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: _captureBtn,
          height: _captureBtn,
          child: GestureDetector(
            onPanUpdate: _onCapturePanUpdate,
            onPanEnd: _onCapturePanEnd,
            onTap: _stopRecordingToPreview,
            child: Transform.translate(
              offset: Offset(
                _state == _CircleCaptureState.recordingHold ? _dragDx : 0,
                0,
              ),
              child: _CaptureButton(
                color: scheme.primary,
                icon: Icons.camera_alt_rounded,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _timeLabel(Duration d) {
    final sec = d.inSeconds.clamp(0, 99 * 3600);
    final mm = (sec ~/ 60).toString();
    final ss = (sec % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}

class _VideoTrimTimeline extends StatelessWidget {
  const _VideoTrimTimeline({
    required this.trimStart,
    required this.trimEnd,
    required this.enabled,
    required this.seed,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  final double trimStart;
  final double trimEnd;
  final bool enabled;
  final String seed;
  final ValueChanged<double> onStartChanged;
  final ValueChanged<double> onEndChanged;

  List<double> _bars() {
    var h = seed.hashCode & 0x7fffffff;
    int next() {
      h = (h * 1103515245 + 12345) & 0x7fffffff;
      return h;
    }

    return List<double>.generate(58, (_) {
      final r = next() % 1000;
      return 0.28 + (r / 1000) * 0.72;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bars = _bars();
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              left: w * trimStart,
              width: (w * (trimEnd - trimStart)).clamp(1.0, w),
              top: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A79FF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < bars.length; i++) ...[
                    Expanded(
                      child: FractionallySizedBox(
                        heightFactor: bars[i],
                        alignment: Alignment.bottomCenter,
                        child: Builder(
                          builder: (_) {
                            final f = i / (bars.length - 1);
                            final selected = f >= trimStart && f <= trimEnd;
                            return Container(
                              width: 2,
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white.withValues(alpha: 0.92)
                                    : Colors.white.withValues(alpha: 0.32),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (i < bars.length - 1) const SizedBox(width: 1.4),
                  ],
                ],
              ),
            ),
            _TrimHandle(
              x: w * trimStart,
              enabled: enabled,
              onDrag: (dx) => onStartChanged((trimStart + dx / w)),
            ),
            _TrimHandle(
              x: w * trimEnd,
              enabled: enabled,
              onDrag: (dx) => onEndChanged((trimEnd + dx / w)),
            ),
          ],
        );
      },
    );
  }
}

class _TrimHandle extends StatelessWidget {
  const _TrimHandle({
    required this.x,
    required this.enabled,
    required this.onDrag,
  });

  final double x;
  final bool enabled;
  final ValueChanged<double> onDrag;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x - 11,
      top: 0,
      bottom: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: enabled ? (d) => onDrag(d.delta.dx) : null,
        child: Center(
          child: Container(
            width: 22,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: enabled
                  ? const Color(0xFF2A79FF).withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
            ),
            child: const Center(
              child: Icon(Icons.drag_indicator_rounded, color: Colors.white, size: 15),
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({required this.color, required this.icon, this.onTap});

  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 84,
            height: 84,
            child: Icon(icon, size: 34, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _ControlCircleButton extends StatelessWidget {
  const _ControlCircleButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: enabled ? 0.40 : 0.24),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 54,
          height: 54,
          child: Icon(
            icon,
            size: 28,
            color: Colors.white.withValues(alpha: enabled ? 0.92 : 0.42),
          ),
        ),
      ),
    );
  }
}
