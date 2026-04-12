import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Полноэкранный поток: запись кружка → превью → отправить / удалить (паритет веб `ChatMessageInput`).
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

class _VideoCircleCapturePage extends StatefulWidget {
  const _VideoCircleCapturePage({required this.onSend});

  final Future<void> Function(XFile file) onSend;

  @override
  State<_VideoCircleCapturePage> createState() => _VideoCircleCapturePageState();
}

class _VideoCircleCapturePageState extends State<_VideoCircleCapturePage> {
  static const double _circle = 192;
  static const double _btn = 56;

  CameraController? _cam;
  bool _busy = true;
  String? _error;
  bool _recording = false;
  XFile? _recorded;
  VideoPlayerController? _previewC;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    unawaited(_openCameraAndRecord());
  }

  @override
  void dispose() {
    unawaited(_cam?.dispose());
    _previewC?.dispose();
    super.dispose();
  }

  Future<void> _openCameraAndRecord() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() {
          _busy = false;
          _error = 'Камера недоступна';
        });
        return;
      }
      final front = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );
      final cc = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await cc.initialize();
      if (!mounted) {
        await cc.dispose();
        return;
      }
      setState(() => _cam = cc);
      await cc.prepareForVideoRecording();
      await cc.startVideoRecording();
      if (mounted) {
        setState(() {
          _recording = true;
          _busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Не удалось открыть камеру: $e';
        });
      }
    }
  }

  Future<void> _stopRecording() async {
    final cc = _cam;
    if (cc == null || !_recording) return;
    setState(() => _busy = true);
    try {
      final file = await cc.stopVideoRecording();
      await cc.dispose();
      if (!mounted) return;
      setState(() {
        _cam = null;
        _recording = false;
        _recorded = file;
        _busy = false;
      });
      await _initPreview(file);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Ошибка записи: $e';
        });
      }
    }
  }

  Future<void> _initPreview(XFile file) async {
    await _previewC?.dispose();
    _previewC = null;
    final ioFile = File(file.path);
    if (!await ioFile.exists()) {
      if (mounted) {
        setState(() => _error = 'Файл записи не найден');
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
        setState(() => _error = 'Не удалось воспроизвести запись');
      }
    }
  }

  Future<void> _discard() async {
    await _previewC?.dispose();
    _previewC = null;
    _recorded = null;
    if (mounted) {
      setState(() {});
    }
    await _openCameraAndRecord();
  }

  Future<void> _send() async {
    final raw = _recorded;
    if (raw == null || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.onSend(raw);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось отправить: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: _error != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                )
              : _busy && _cam == null && _recorded == null
              ? const CircularProgressIndicator(color: Colors.white54)
              : _recorded != null
              ? _buildPreviewRow(scheme)
              : _buildRecordingRow(scheme),
        ),
      ),
    );
  }

  Widget _buildRecordingRow(ColorScheme scheme) {
    final cc = _cam;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: _btn, height: _btn),
        Container(
          width: _circle,
          height: _circle,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.35),
              width: 4,
            ),
          ),
          child: ClipOval(
            child: cc != null && cc.value.isInitialized
                ? Transform.flip(
                    flipX: true,
                    child: CameraPreview(cc),
                  )
                : const ColoredBox(color: Colors.black),
          ),
        ),
        SizedBox(
          width: _btn,
          height: _btn,
          child: _busy
              ? const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white54,
                    ),
                  ),
                )
              : IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: Colors.white,
                  ),
                  iconSize: 32,
                  onPressed: _stopRecording,
                  icon: const Icon(Icons.stop_rounded),
                ),
        ),
      ],
    );
  }

  Widget _buildPreviewRow(ColorScheme scheme) {
    final c = _previewC;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: _btn,
          height: _btn,
          child: IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            iconSize: 32,
            onPressed: _sending ? null : _discard,
          ),
        ),
        Container(
          width: _circle,
          height: _circle,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF22C55E).withValues(alpha: 0.35),
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: c != null && c.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: c.value.size.width,
                      height: c.value.size.height,
                      child: VideoPlayer(c),
                    ),
                  )
                : const ColoredBox(color: Colors.black),
          ),
        ),
        SizedBox(
          width: _btn,
          height: _btn,
          child: _sending
              ? const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white54,
                    ),
                  ),
                )
              : IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                  ),
                  iconSize: 28,
                  onPressed: _send,
                  icon: const Icon(Icons.send_rounded),
                ),
        ),
      ],
    );
  }
}
