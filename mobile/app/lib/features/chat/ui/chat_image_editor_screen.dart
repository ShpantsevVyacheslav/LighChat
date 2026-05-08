import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'chat_ios_image_markup.dart';

class ChatImageEditorResult {
  const ChatImageEditorResult({required this.files, required this.caption});

  final List<XFile> files;
  final String caption;
}

class ChatImageEditorScreen extends StatefulWidget {
  const ChatImageEditorScreen({
    super.key,
    required this.files,
    required this.initialIndex,
    required this.initialCaption,
  });

  final List<XFile> files;
  final int initialIndex;
  final String initialCaption;

  static Future<ChatImageEditorResult?> open(
    BuildContext context, {
    required List<XFile> files,
    required int initialIndex,
    required String initialCaption,
  }) {
    return Navigator.of(context).push<ChatImageEditorResult>(
      MaterialPageRoute(
        builder: (_) => ChatImageEditorScreen(
          files: files,
          initialIndex: initialIndex,
          initialCaption: initialCaption,
        ),
      ),
    );
  }

  @override
  State<ChatImageEditorScreen> createState() => _ChatImageEditorScreenState();
}

class _ChatImageEditorScreenState extends State<ChatImageEditorScreen> {
  // Рабочий буфер редактора всегда даунскейлится до этой стороны. Исходник
  // с камеры (12–48 MP) сам по себе съедает 48–192 MB RGBA и регулярно валил
  // приложение на iOS. 2560 px достаточно для мессенджера «за глаза».
  static const int _kWorkingMaxSide = 2560;
  // Источник для нативного кроппера: он бывает нестабилен на крупных фото.
  static const int _kCropMaxSide = 2560;
  // История — это компактные JPEG-снимки базового растра (не полноразмерный
  // RGBA-клон, как было раньше). Мазки живут отдельным оверлеем и отменяются
  // покомандно без участия базового растра.
  static const int _kMaxHistory = 8;

  final GlobalKey _imageBoxKey = GlobalKey();
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late List<XFile> _files;
  late int _currentIndex;

  final Map<int, Uint8List> _draftJpegByIndex = <int, Uint8List>{};
  final Map<int, Uint8List> _previewByIndex = <int, Uint8List>{};

  bool _loading = true;
  bool _saving = false;
  bool _drawMode = false;
  bool _opInFlight = false;

  img.Image? _working;
  Uint8List? _currentPreviewBytes;
  Size? _workingSize;

  final List<Uint8List> _baseHistory = <Uint8List>[];
  final List<_Stroke> _pendingStrokes = <_Stroke>[];
  _Stroke? _activeStroke;

  double _brushSize = 8;
  Color _brushColor = const Color(0xFFEF4444);
  int _loadToken = 0;
  final ValueNotifier<int> _strokeRevision = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _files = List<XFile>.from(widget.files);
    _currentIndex = _files.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, _files.length - 1);
    _captionController.text = widget.initialCaption;
    _loadCurrentImage();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _strokeRevision.dispose();
    super.dispose();
  }

  // ---------------- loading ----------------

  Future<void> _loadCurrentImage() async {
    if (_files.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _working = null;
          _workingSize = null;
          _currentPreviewBytes = null;
          _pendingStrokes.clear();
          _activeStroke = null;
          _baseHistory.clear();
        });
      }
      return;
    }

    final token = ++_loadToken;
    setState(() {
      _loading = true;
      _pendingStrokes.clear();
      _activeStroke = null;
      _baseHistory.clear();
    });

    final draftJpeg = _draftJpegByIndex[_currentIndex];
    try {
      final Uint8List sourceBytes =
          draftJpeg ?? await _files[_currentIndex].readAsBytes();
      final decoded = await compute<_LoadArgs, _DecodedImage?>(
        _decodeAndDownscaleIsolate,
        _LoadArgs(bytes: sourceBytes, maxSide: _kWorkingMaxSide),
      );
      if (!mounted || token != _loadToken) return;
      if (decoded == null) {
        setState(() => _loading = false);
        return;
      }
      final working = _imageFromRgba(decoded);
      // Если грузимся из драфта — драфт и есть свежий JPEG, переиспользуем.
      // Иначе кодируем один раз в изоляте и больше не пересжимаем в UI.
      final Uint8List previewJpeg = draftJpeg ??
          await compute<_EncodeArgs, Uint8List>(
            _encodeJpegIsolate,
            _EncodeArgs(
              width: decoded.width,
              height: decoded.height,
              rgba: decoded.rgba,
              quality: 90,
            ),
          );
      if (!mounted || token != _loadToken) return;
      setState(() {
        _working = working;
        _workingSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
        _currentPreviewBytes = previewJpeg;
        _loading = false;
      });
      _previewByIndex[_currentIndex] = previewJpeg;
    } catch (e, st) {
      debugPrint('chat image editor: load failed: $e\n$st');
      if (!mounted || token != _loadToken) return;
      setState(() => _loading = false);
    }
  }

  // ---------------- history ----------------

  void _pushBaseSnapshot() {
    final bytes = _currentPreviewBytes;
    if (bytes == null) return;
    _baseHistory.add(bytes);
    while (_baseHistory.length > _kMaxHistory) {
      _baseHistory.removeAt(0);
    }
  }

  bool get _canUndo => _pendingStrokes.isNotEmpty || _baseHistory.isNotEmpty;

  Future<void> _undo() async {
    if (_opInFlight) return;
    if (_pendingStrokes.isNotEmpty) {
      setState(() {
        _pendingStrokes.removeLast();
        if (_pendingStrokes.isEmpty) _activeStroke = null;
      });
      _strokeRevision.value++;
      _persistCurrentDraftCompact();
      return;
    }
    if (_baseHistory.isEmpty) return;

    setState(() => _opInFlight = true);
    try {
      final bytes = _baseHistory.removeLast();
      final decoded = await compute<_LoadArgs, _DecodedImage?>(
        _decodeAndDownscaleIsolate,
        _LoadArgs(bytes: bytes, maxSide: _kWorkingMaxSide),
      );
      if (!mounted || decoded == null) return;
      setState(() {
        _working = _imageFromRgba(decoded);
        _workingSize = Size(
          decoded.width.toDouble(),
          decoded.height.toDouble(),
        );
        _currentPreviewBytes = bytes;
      });
      _persistCurrentDraftCompact();
    } finally {
      if (mounted) setState(() => _opInFlight = false);
    }
  }

  Future<void> _resetAll() async {
    setState(() {
      _draftJpegByIndex.clear();
      _previewByIndex.clear();
      _baseHistory.clear();
      _pendingStrokes.clear();
      _activeStroke = null;
      _drawMode = false;
    });
    await _loadCurrentImage();
  }

  // Плющит висящие мазки в базовый растр (в изоляте) и обновляет превью.
  Future<void> _flattenPendingStrokes() async {
    final w = _working;
    if (w == null) return;
    if (_pendingStrokes.isEmpty) return;

    final rgba = w.getBytes(order: img.ChannelOrder.rgba);
    final strokes =
        _pendingStrokes.map(_strokeToPayload).toList(growable: false);
    final res = await compute<_FlattenArgs, _DecodedAndPreview>(
      _flattenIsolate,
      _FlattenArgs(
        width: w.width,
        height: w.height,
        rgba: rgba,
        strokes: strokes,
        encodeQuality: 90,
      ),
    );
    if (!mounted) return;
    setState(() {
      _working = _imageFromRgba(
        _DecodedImage(width: res.width, height: res.height, rgba: res.rgba),
      );
      _workingSize = Size(res.width.toDouble(), res.height.toDouble());
      _currentPreviewBytes = res.jpeg;
      _pendingStrokes.clear();
      _activeStroke = null;
    });
    _strokeRevision.value++;
  }

  void _persistCurrentDraftCompact() {
    final jpeg = _currentPreviewBytes;
    if (jpeg == null) return;
    _draftJpegByIndex[_currentIndex] = jpeg;
    _previewByIndex[_currentIndex] = jpeg;
  }

  // ---------------- destructive ops ----------------

  Future<void> _crop() async {
    if (_opInFlight) return;
    if (_working == null) return;

    File? sourceFile;
    setState(() => _opInFlight = true);
    try {
      await _flattenPendingStrokes();
      final w2 = _working;
      if (w2 == null) return;

      // Источник для нативного кроппера — уже существующий JPEG превью,
      // если он в пределах _kCropMaxSide (обычно так и есть, т.к. рабочий
      // буфер уже даунскейлен). Иначе — один доп. энкод в изоляте.
      final maxSide = math.max(w2.width, w2.height);
      final Uint8List jpegBytes;
      if (maxSide <= _kCropMaxSide && _currentPreviewBytes != null) {
        jpegBytes = _currentPreviewBytes!;
      } else {
        jpegBytes = await _encodeCropSourceJpeg(w2);
      }

      final dir = await getTemporaryDirectory();
      final sourcePath =
          '${dir.path}/chat_edit_crop_src_${DateTime.now().microsecondsSinceEpoch}.jpg';
      sourceFile = File(sourcePath);
      await sourceFile.writeAsBytes(jpegBytes, flush: true);

      final cropped = await ImageCropper().cropImage(
        sourcePath: sourceFile.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: AppLocalizations.of(context)!.image_editor_crop_title,
            toolbarColor: const Color(0xFF12151E),
            toolbarWidgetColor: Colors.white,
            backgroundColor: const Color(0xFF12151E),
            activeControlsWidgetColor: const Color(0xFF2F86FF),
            cropFrameColor: Colors.white,
            cropGridColor: Colors.white54,
          ),
          IOSUiSettings(
            title: AppLocalizations.of(context)!.image_editor_crop_title,
            doneButtonTitle: AppLocalizations.of(context)!.common_done,
            cancelButtonTitle: AppLocalizations.of(context)!.common_cancel,
          ),
        ],
      );
      if (cropped == null) return;

      final croppedBytes = await File(cropped.path).readAsBytes();
      final decoded = await compute<_LoadArgs, _DecodedImage?>(
        _decodeAndDownscaleIsolate,
        _LoadArgs(bytes: croppedBytes, maxSide: _kWorkingMaxSide),
      );
      if (decoded == null || !mounted) return;

      final previewJpeg = await compute<_EncodeArgs, Uint8List>(
        _encodeJpegIsolate,
        _EncodeArgs(
          width: decoded.width,
          height: decoded.height,
          rgba: decoded.rgba,
          quality: 90,
        ),
      );
      if (!mounted) return;

      _pushBaseSnapshot();
      setState(() {
        _working = _imageFromRgba(decoded);
        _workingSize = Size(
          decoded.width.toDouble(),
          decoded.height.toDouble(),
        );
        _currentPreviewBytes = previewJpeg;
      });
      _persistCurrentDraftCompact();
    } catch (e, st) {
      debugPrint('chat image crop failed: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.image_editor_crop_failed)),
      );
    } finally {
      if (sourceFile != null) {
        unawaited(
          sourceFile.delete().then((_) {}, onError: (_) {}),
        );
      }
      if (mounted) setState(() => _opInFlight = false);
    }
  }

  // iOS-only: открыть нативный PencilKit-разметчик (карандаш/маркер/ластик).
  // Текущее состояние редактора передаём как JPEG во временный файл, а
  // полученный обратно файл загружаем как новый рабочий растр — с пушем
  // в base history, чтобы Undo откатывал нативные правки одним шагом.
  Future<void> _openNativeMarkup() async {
    if (!Platform.isIOS) return;
    if (_opInFlight) return;
    if (_working == null) return;

    File? sourceFile;
    setState(() => _opInFlight = true);
    try {
      await _flattenPendingStrokes();
      final w2 = _working;
      if (w2 == null) return;

      final maxSide = math.max(w2.width, w2.height);
      final Uint8List jpegBytes;
      if (maxSide <= _kCropMaxSide && _currentPreviewBytes != null) {
        jpegBytes = _currentPreviewBytes!;
      } else {
        jpegBytes = await _encodeCropSourceJpeg(w2);
      }

      final dir = await getTemporaryDirectory();
      final sourcePath =
          '${dir.path}/chat_edit_markup_src_${DateTime.now().microsecondsSinceEpoch}.jpg';
      sourceFile = File(sourcePath);
      await sourceFile.writeAsBytes(jpegBytes, flush: true);

      final edited = await openIosNativeImageMarkup(XFile(sourcePath));
      if (edited == null || !mounted) return;

      final editedBytes = await File(edited.path).readAsBytes();
      final decoded = await compute<_LoadArgs, _DecodedImage?>(
        _decodeAndDownscaleIsolate,
        _LoadArgs(bytes: editedBytes, maxSide: _kWorkingMaxSide),
      );
      if (decoded == null || !mounted) return;

      final previewJpeg = await compute<_EncodeArgs, Uint8List>(
        _encodeJpegIsolate,
        _EncodeArgs(
          width: decoded.width,
          height: decoded.height,
          rgba: decoded.rgba,
          quality: 90,
        ),
      );
      if (!mounted) return;

      _pushBaseSnapshot();
      setState(() {
        _working = _imageFromRgba(decoded);
        _workingSize = Size(
          decoded.width.toDouble(),
          decoded.height.toDouble(),
        );
        _currentPreviewBytes = previewJpeg;
      });
      _persistCurrentDraftCompact();
    } catch (e, st) {
      debugPrint('chat image native markup failed: $e\n$st');
    } finally {
      if (sourceFile != null) {
        unawaited(
          sourceFile.delete().then((_) {}, onError: (_) {}),
        );
      }
      if (mounted) setState(() => _opInFlight = false);
    }
  }

  Future<Uint8List> _encodeCropSourceJpeg(img.Image src) async {
    final maxSide = math.max(src.width, src.height);
    img.Image target = src;
    if (maxSide > _kCropMaxSide) {
      final scale = _kCropMaxSide / maxSide;
      target = img.copyResize(
        src,
        width: (src.width * scale).round(),
        height: (src.height * scale).round(),
        interpolation: img.Interpolation.linear,
      );
    }
    final raw = target.getBytes(order: img.ChannelOrder.rgba);
    return compute<_EncodeArgs, Uint8List>(
      _encodeJpegIsolate,
      _EncodeArgs(
        width: target.width,
        height: target.height,
        rgba: raw,
        quality: 88,
      ),
    );
  }

  // ---------------- drawing ----------------

  Offset? _toImagePoint(Offset local) {
    final ws = _workingSize;
    final box = _imageBoxKey.currentContext?.findRenderObject() as RenderBox?;
    if (ws == null || box == null || !box.hasSize) return null;
    final boxSize = box.size;
    final fitted = applyBoxFit(BoxFit.contain, ws, boxSize);
    final dst = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & boxSize,
    );
    if (!dst.contains(local)) return null;
    final nx = (local.dx - dst.left) / dst.width;
    final ny = (local.dy - dst.top) / dst.height;
    return Offset(nx * ws.width, ny * ws.height);
  }

  void _startDraw(Offset local) {
    if (!_drawMode || _opInFlight) return;
    final p = _toImagePoint(local);
    if (p == null) return;
    final c = _brushColor;
    final rr = (c.r * 255.0).round().clamp(0, 255).toInt();
    final gg = (c.g * 255.0).round().clamp(0, 255).toInt();
    final bb = (c.b * 255.0).round().clamp(0, 255).toInt();
    final stroke = _Stroke(
      r: rr,
      g: gg,
      b: bb,
      thickness: _brushSize,
      points: <Offset>[p],
    );
    _activeStroke = stroke;
    setState(() {
      _pendingStrokes.add(stroke);
    });
    _strokeRevision.value++;
  }

  void _draw(Offset local) {
    if (!_drawMode) return;
    final s = _activeStroke;
    if (s == null) return;
    final p = _toImagePoint(local);
    if (p == null) return;
    s.points.add(p);
    // Мазок рендерится оверлеем через CustomPaint (GPU-путь): никакого
    // ре-энкода JPEG на UI-изоляте — это и был главный источник лагов.
    _strokeRevision.value++;
  }

  void _stopDraw() {
    _activeStroke = null;
    // Не плющим мазок в растр на каждом end — только перед деструктивными
    // операциями. Это сохраняет покомандный Undo и не блокирует UI на encode.
  }

  // ---------------- navigation / save ----------------

  Future<XFile> _writeEditedFile({
    required Uint8List jpegBytes,
    required int index,
  }) async {
    final dir = await getTemporaryDirectory();
    final outPath =
        '${dir.path}/chat_edit_${DateTime.now().microsecondsSinceEpoch}_$index.jpg';
    final out = File(outPath);
    await out.writeAsBytes(jpegBytes);
    return XFile(outPath);
  }

  Future<void> _saveAndClose() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _flattenPendingStrokes();
      _persistCurrentDraftCompact();

      final out = <XFile>[];
      for (var i = 0; i < _files.length; i++) {
        final jpeg = _draftJpegByIndex[i];
        if (jpeg == null) {
          out.add(_files[i]);
          continue;
        }
        out.add(await _writeEditedFile(jpegBytes: jpeg, index: i));
      }
      if (!mounted) return;
      Navigator.of(context).pop(
        ChatImageEditorResult(
          files: out,
          caption: _captionController.text.trim(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _addImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 100);
    if (picked.isEmpty || !mounted) return;
    setState(() {
      final start = _files.length;
      _files.addAll(picked);
      _currentIndex = start;
    });
    await _loadCurrentImage();
  }

  void _removeCurrentImage() {
    if (_files.isEmpty) return;
    final removeIndex = _currentIndex;
    var shouldClose = false;

    setState(() {
      _files.removeAt(removeIndex);
      _baseHistory.clear();
      _pendingStrokes.clear();
      _activeStroke = null;
      _working = null;
      _workingSize = null;
      _currentPreviewBytes = null;
      _shiftMapAfterRemove(_draftJpegByIndex, removeIndex);
      _shiftMapAfterRemove(_previewByIndex, removeIndex);
      _drawMode = false;

      if (_files.isEmpty) {
        shouldClose = true;
        return;
      }
      _currentIndex = _currentIndex.clamp(0, _files.length - 1);
    });
    if (shouldClose) {
      Navigator.of(context).pop(
        ChatImageEditorResult(
          files: const <XFile>[],
          caption: _captionController.text.trim(),
        ),
      );
      return;
    }
    unawaited(_loadCurrentImage());
  }

  void _shiftMapAfterRemove<T>(Map<int, T> source, int removedIndex) {
    final moved = <int, T>{};
    for (final e in source.entries) {
      if (e.key == removedIndex) continue;
      if (e.key > removedIndex) {
        moved[e.key - 1] = e.value;
      } else {
        moved[e.key] = e.value;
      }
    }
    source
      ..clear()
      ..addAll(moved);
  }

  Future<void> _openAtIndex(int index) async {
    if (index == _currentIndex || index < 0 || index >= _files.length) return;
    // Перед переключением плющим мазки и сохраняем компактный драфт текущего.
    if (_working != null) {
      await _flattenPendingStrokes();
      _persistCurrentDraftCompact();
    }
    setState(() => _currentIndex = index);
    await _loadCurrentImage();
  }

  // ---------------- build ----------------

  @override
  Widget build(BuildContext context) {
    final canUndo = _canUndo && !_opInFlight;
    final busy = _loading || _opInFlight;

    return Scaffold(
      backgroundColor: const Color(0xFF05070C),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Row(
                      children: [
                        _iconBtn(
                          icon: Icons.close_rounded,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
                        _iconBtn(
                          icon: Icons.delete_outline_rounded,
                          onTap: _files.isEmpty ? null : _removeCurrentImage,
                        ),
                        const SizedBox(width: 8),
                        _iconBtn(
                          icon: Icons.undo_rounded,
                          onTap: canUndo ? _undo : null,
                        ),
                        const SizedBox(width: 8),
                        _iconBtn(
                          icon: Icons.refresh_rounded,
                          onTap: busy ? null : _resetAll,
                        ),
                        const SizedBox(width: 8),
                        _iconBtn(
                          icon: Icons.edit_rounded,
                          onTap: busy
                              ? null
                              : (Platform.isIOS
                                    ? _openNativeMarkup
                                    : () => setState(() {
                                          _drawMode = !_drawMode;
                                          _activeStroke = null;
                                        })),
                          active: !Platform.isIOS && _drawMode,
                        ),
                        const SizedBox(width: 8),
                        _iconBtn(
                          icon: Icons.crop_rounded,
                          onTap: busy ? null : _crop,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: _drawMode && !busy
                            ? (d) => _startDraw(d.localPosition)
                            : null,
                        onPanUpdate: _drawMode && !busy
                            ? (d) => _draw(d.localPosition)
                            : null,
                        onPanEnd: _drawMode ? (_) => _stopDraw() : null,
                        onPanCancel: _drawMode ? () => _stopDraw() : null,
                        child: Container(
                          key: _imageBoxKey,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.black.withValues(alpha: 0.22),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _loading
                              ? const Center(child: CircularProgressIndicator())
                              : _buildCanvas(),
                        ),
                      ),
                    ),
                  ),
                  if (_drawMode)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _brushSize,
                              min: 2,
                              max: 48,
                              onChanged: busy
                                  ? null
                                  : (v) => setState(() => _brushSize = v),
                            ),
                          ),
                          _colorDot(Colors.white),
                          _colorDot(const Color(0xFFEF4444)),
                          _colorDot(const Color(0xFF3B82F6)),
                          _colorDot(const Color(0xFF22C55E)),
                          _colorDot(const Color(0xFFFACC15)),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                    child: SizedBox(
                      height: 70,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _addImages,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1.2,
                                ),
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                              child: Icon(
                                Icons.add_rounded,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _files.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final selected = index == _currentIndex;
                                final memory = _previewByIndex[index];
                                return GestureDetector(
                                  onTap: () => _openAtIndex(index),
                                  child: SizedBox.square(
                                    dimension: 56,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: selected
                                              ? const Color(0xFF2F86FF)
                                              : Colors.white.withValues(
                                                  alpha: 0.12,
                                                ),
                                          width: selected ? 2 : 1,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: memory != null
                                            ? Image.memory(
                                                memory,
                                                width: 56,
                                                height: 56,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.file(
                                                File(_files[index].path),
                                                width: 56,
                                                height: 56,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => ColoredBox(
                                                      color: Colors.black26,
                                                      child: Icon(
                                                        Icons
                                                            .image_not_supported_rounded,
                                                        color: Colors.white
                                                            .withValues(
                                                              alpha: 0.55,
                                                            ),
                                                      ),
                                                    ),
                                              ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _captionController,
                            maxLines: 1,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)!.image_editor_add_caption,
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.42),
                              ),
                              prefixIcon: Icon(
                                Icons.image_outlined,
                                color: Colors.white.withValues(alpha: 0.5),
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
                            onPressed: _saving ? null : _saveAndClose,
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: const CircleBorder(),
                              backgroundColor: const Color(0xFF2F86FF),
                            ),
                            child: _saving
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
            if (_drawMode)
              Positioned(
                left: 20,
                right: 20,
                top: 74,
                child: Text(
                  AppLocalizations.of(context)!.image_editor_draw_hint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 13,
                  ),
                ),
              ),
            if (_opInFlight && !_loading)
              const Positioned(
                right: 16,
                top: 16,
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvas() {
    final bytes = _currentPreviewBytes;
    final size = _workingSize;
    if (bytes == null || size == null) {
      return const SizedBox.shrink();
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(
          bytes,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        ),
        IgnorePointer(
          child: RepaintBoundary(
            child: ValueListenableBuilder<int>(
              valueListenable: _strokeRevision,
              builder: (_, rev, _) => CustomPaint(
                painter: _StrokesPainter(
                  imageSize: size,
                  strokes: _pendingStrokes,
                  revision: rev,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconBtn({
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
            color: onTap == null
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _colorDot(Color color) {
    final selected = _brushColor.toARGB32() == color.toARGB32();
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: GestureDetector(
        onTap: () => setState(() => _brushColor = color),
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

// =============================================================================
// Overlay painter: рисуем список мазков поверх Image.memory без повторной
// растеризации в пиксельный буфер. Координаты мазков — в image-space, тут
// пересчитываются под фактический BoxFit.contain канваса.
// =============================================================================

class _Stroke {
  _Stroke({
    required this.r,
    required this.g,
    required this.b,
    required this.thickness,
    required this.points,
  });

  final int r;
  final int g;
  final int b;
  final double thickness;
  final List<Offset> points;
}

class _StrokesPainter extends CustomPainter {
  const _StrokesPainter({
    required this.imageSize,
    required this.strokes,
    required this.revision,
  });

  final Size imageSize;
  final List<_Stroke> strokes;
  final int revision;

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.width <= 0 || imageSize.height <= 0) return;
    if (strokes.isEmpty) return;
    final fitted = applyBoxFit(BoxFit.contain, imageSize, size);
    final dst = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    final sx = dst.width / imageSize.width;
    final sy = dst.height / imageSize.height;
    canvas.save();
    canvas.translate(dst.left, dst.top);
    canvas.scale(sx, sy);
    for (final s in strokes) {
      final paint = Paint()
        ..color = Color.fromARGB(255, s.r, s.g, s.b)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = s.thickness
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;
      final pts = s.points;
      if (pts.isEmpty) continue;
      if (pts.length == 1) {
        canvas.drawCircle(
          pts.first,
          math.max(0.5, s.thickness / 2),
          Paint()..color = Color.fromARGB(255, s.r, s.g, s.b),
        );
        continue;
      }
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StrokesPainter old) =>
      old.revision != revision || old.imageSize != imageSize;
}

// =============================================================================
// Isolate payloads & workers. Всё тяжёлое — decode/resize/rotate/encode —
// выполняется здесь, а не в UI-изоляте.
// =============================================================================

class _LoadArgs {
  const _LoadArgs({required this.bytes, required this.maxSide});
  final Uint8List bytes;
  final int maxSide;
}

class _EncodeArgs {
  const _EncodeArgs({
    required this.width,
    required this.height,
    required this.rgba,
    required this.quality,
  });

  final int width;
  final int height;
  final Uint8List rgba;
  final int quality;
}

class _StrokePayload {
  const _StrokePayload({
    required this.r,
    required this.g,
    required this.b,
    required this.thickness,
    required this.points,
  });

  final int r;
  final int g;
  final int b;
  final double thickness;
  // Плоский массив координат: [x0, y0, x1, y1, ...] — дружелюбнее к передаче
  // между изолятами, чем список Offset-объектов.
  final List<double> points;
}

_StrokePayload _strokeToPayload(_Stroke s) {
  final pts = List<double>.filled(s.points.length * 2, 0);
  for (var i = 0; i < s.points.length; i++) {
    pts[i * 2] = s.points[i].dx;
    pts[i * 2 + 1] = s.points[i].dy;
  }
  return _StrokePayload(
    r: s.r,
    g: s.g,
    b: s.b,
    thickness: s.thickness,
    points: pts,
  );
}

class _FlattenArgs {
  const _FlattenArgs({
    required this.width,
    required this.height,
    required this.rgba,
    required this.strokes,
    required this.encodeQuality,
  });

  final int width;
  final int height;
  final Uint8List rgba;
  final List<_StrokePayload> strokes;
  final int encodeQuality;
}

class _DecodedImage {
  const _DecodedImage({
    required this.width,
    required this.height,
    required this.rgba,
  });

  final int width;
  final int height;
  final Uint8List rgba;
}

class _DecodedAndPreview {
  const _DecodedAndPreview({
    required this.width,
    required this.height,
    required this.rgba,
    required this.jpeg,
  });

  final int width;
  final int height;
  final Uint8List rgba;
  final Uint8List jpeg;
}

img.Image _imageFromRgba(_DecodedImage d) {
  return img.Image.fromBytes(
    width: d.width,
    height: d.height,
    bytes: d.rgba.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
}

_DecodedImage? _decodeAndDownscaleIsolate(_LoadArgs args) {
  final decoded = img.decodeImage(args.bytes);
  if (decoded == null) return null;
  final maxSide = math.max(decoded.width, decoded.height);
  img.Image out = decoded;
  if (maxSide > args.maxSide) {
    final scale = args.maxSide / maxSide;
    out = img.copyResize(
      decoded,
      width: (decoded.width * scale).round(),
      height: (decoded.height * scale).round(),
      interpolation: img.Interpolation.linear,
    );
  }
  final rgba = out.getBytes(order: img.ChannelOrder.rgba);
  return _DecodedImage(width: out.width, height: out.height, rgba: rgba);
}

Uint8List _encodeJpegIsolate(_EncodeArgs args) {
  final im = img.Image.fromBytes(
    width: args.width,
    height: args.height,
    bytes: args.rgba.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
  return Uint8List.fromList(img.encodeJpg(im, quality: args.quality));
}

_DecodedAndPreview _flattenIsolate(_FlattenArgs args) {
  final im = img.Image.fromBytes(
    width: args.width,
    height: args.height,
    bytes: args.rgba.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
  for (final s in args.strokes) {
    final c = img.ColorRgb8(s.r, s.g, s.b);
    final pts = s.points;
    if (pts.length < 2) continue;
    if (pts.length == 2) {
      final x = pts[0].round();
      final y = pts[1].round();
      img.drawLine(
        im,
        x1: x,
        y1: y,
        x2: x,
        y2: y,
        color: c,
        thickness: s.thickness,
      );
      continue;
    }
    for (var i = 2; i < pts.length; i += 2) {
      img.drawLine(
        im,
        x1: pts[i - 2].round(),
        y1: pts[i - 1].round(),
        x2: pts[i].round(),
        y2: pts[i + 1].round(),
        color: c,
        thickness: s.thickness,
      );
    }
  }
  final rgba = im.getBytes(order: img.ChannelOrder.rgba);
  final jpeg = Uint8List.fromList(
    img.encodeJpg(im, quality: args.encodeQuality),
  );
  return _DecodedAndPreview(
    width: im.width,
    height: im.height,
    rgba: rgba,
    jpeg: jpeg,
  );
}

