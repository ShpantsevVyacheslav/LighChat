import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

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

enum _CircleCaptureState {
  preparing,
  recordingHold,
  preview,
  sending,
  error,
}

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

  int _cameraIndex = 0;
  bool _flashOn = false;
  bool _flashSupported = false;

  DateTime? _recordStartedAt;
  Duration _recordElapsed = Duration.zero;
  Timer? _recordTicker;

  double _dragDx = 0;
  bool _isClosing = false;

  bool get _isRecordingState => _state == _CircleCaptureState.recordingHold;

  bool get _isBusy =>
      _state == _CircleCaptureState.preparing ||
      _state == _CircleCaptureState.sending;

  bool get _isFrontCamera {
    if (_cameras.isEmpty ||
        _cameraIndex < 0 ||
        _cameraIndex >= _cameras.length) {
      return true;
    }
    return _cameras[_cameraIndex].lensDirection == CameraLensDirection.front;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_openCameraAndStart());
  }

  @override
  void dispose() {
    _recordTicker?.cancel();
    unawaited(_cam?.dispose());
    _previewC?.dispose();
    super.dispose();
  }

  void _startRecordTicker() {
    _recordTicker?.cancel();
    _recordTicker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final s = _recordStartedAt;
      if (!mounted || s == null) return;
      setState(() => _recordElapsed = DateTime.now().difference(s));
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
          _error = 'Камера недоступна';
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
      _recordStartedAt = DateTime.now();
      _recordElapsed = Duration.zero;
      _startRecordTicker();

      setState(() {
        _state = _CircleCaptureState.recordingHold;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _CircleCaptureState.error;
        _error = 'Не удалось открыть камеру: $e';
      });
    }
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
      final wasFront = _isFrontCamera;
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
        _error = 'Ошибка записи: $e';
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
          _error = 'Файл записи не найден';
        });
      }
      return;
    }

    final c = VideoPlayerController.file(ioFile);
    _previewC = c;
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.play();
      if (mounted) setState(() {});
    } catch (_) {
      await c.dispose();
      _previewC = null;
      if (mounted) {
        setState(() {
          _state = _CircleCaptureState.error;
          _error = 'Не удалось воспроизвести запись';
        });
      }
    }
  }

  Future<void> _discardPreviewAndRestart() async {
    final rec = _recorded;
    if (rec != null) {
      unawaited(_deleteFileSilently(rec.path));
    }
    _recorded = null;
    _fileIsMirrored = false;
    await _disposePreview();
    await _openCameraAndStart(useIndex: _cameraIndex);
  }

  Future<void> _send() async {
    final rec = _recorded;
    if (rec == null || _state == _CircleCaptureState.sending) return;

    setState(() => _state = _CircleCaptureState.sending);
    try {
      await widget.onSend(rec);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Не удалось отправить: $e')));
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

    final next = (_cameraIndex + 1) % _cameras.length;
    try {
      await cc.setDescription(_cameras[next]);
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
        SnackBar(content: Text('Не удалось переключить камеру: $e')),
      );
    }
  }

  Future<void> _toggleFlash() async {
    if (!_isRecordingState || _isBusy || !_flashSupported) return;
    final cc = _cam;
    if (cc == null) return;
    final next = !_flashOn;
    try {
      await cc.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _flashOn = next);
    } catch (_) {
      if (mounted) setState(() => _flashSupported = false);
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
    final availableHeight =
        math.max(0.0, size.height - _bottomPanelReserve);
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
              _error ?? 'Ошибка камеры',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _openCameraAndStart,
              child: const Text('Повторить'),
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
      final mirrorRecorded = !_fileIsMirrored;
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
    // The circle preview is always mirrored while recording — matches
    // a selfie/webcam UX independently of which camera is active.
    return _buildCircleFrame(
      side: side,
      borderColor: scheme.primary.withValues(alpha: 0.38),
      child: cc != null && cc.value.isInitialized
          ? Transform.flip(
              flipX: true,
              child: VideoCircleCameraPreview(controller: cc),
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
      return Row(
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
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Center(
                child: Text(
                  _state == _CircleCaptureState.sending
                      ? 'Отправка...'
                      : 'Кружок записан',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
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
                    'Влево - отмена',
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

