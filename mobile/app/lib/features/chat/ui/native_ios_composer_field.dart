import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show PlatformViewHitTestBehavior;
import 'package:flutter/services.dart';

/// Phase 1 нативного iOS composer'а: оборачивает [UiKitView] с
/// PlatformView'ем `lighchat/native_composer` (см. Swift
/// `NativeComposerFactory`/`NativeComposerView`).
///
/// Зачем: Flutter `TextField` рендерится Skia и не получает системные
/// Cut/Copy/Paste/Replace/AutoFill/Writing Tools / диктовку. Нативный
/// `UITextView` даёт всё это бесплатно.
///
/// **Scope Phase 1:**
///  - двусторонняя синхронизация text + selection с [controller],
///  - управление фокусом через [focusNode] (resign/becomeFirstResponder),
///  - стили (font, цвета, hint),
///  - auto-grow по contentHeight в пределах `minLines..maxLines`.
///
/// Не покрыто Phase 1 (см. Phase 2/3 в плане):
///  - mentions @ (нужен dart-side picker, отдельные команды
///    `insertMention(label, userId, range)`),
///  - paste файлов из буфера (нужен `UITextPasteDelegate`),
///  - bold/italic formatting toolbar (нужен NSAttributedString sync),
///  - sticker keyboard accessory.
///
/// На Android/desktop возвращает [TextField] fallback — нативного аналога
/// нет, и логика композера на тех платформах остаётся прежней.
class NativeIosComposerField extends StatefulWidget {
  const NativeIosComposerField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hint,
    this.textStyle,
    this.hintStyle,
    this.cursorColor,
    this.minLines = 1,
    this.maxLines = 6,
    this.onSubmitted,
    this.onPasteRequested,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? hint;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final Color? cursorColor;
  final int minLines;
  final int maxLines;
  final ValueChanged<String>? onSubmitted;

  /// Срабатывает когда юзер тапнул «Paste» в системном контекстном меню
  /// и pasteboard содержит изображение/файл (а не только plain text).
  /// Caller обрабатывает через [readComposerClipboardPayload] +
  /// добавление в `pendingAttachments`.
  final Future<void> Function()? onPasteRequested;

  @override
  State<NativeIosComposerField> createState() => NativeIosComposerFieldState();
}

class NativeIosComposerFieldState extends State<NativeIosComposerField> {
  static const _viewType = 'lighchat/native_composer';

  MethodChannel? _channel;
  double _lineHeight = 20;
  double _measuredHeight = 0;
  bool _suppressControllerListener = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant NativeIosComposerField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
    if (old.focusNode != widget.focusNode) {
      old.focusNode.removeListener(_onFocusChanged);
      widget.focusNode.addListener(_onFocusChanged);
    }
    if (old.hint != widget.hint ||
        old.textStyle != widget.textStyle ||
        old.hintStyle != widget.hintStyle ||
        old.cursorColor != widget.cursorColor) {
      _pushStyle();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  // ── Controller / focus sync ─────────────────────────────────────

  void _onControllerChanged() {
    if (_suppressControllerListener) return;
    final c = _channel;
    if (c == null) return;
    // Передаём selection в plain-text offsets'ах — native сам мапит в
    // visible offsets attributed-string'а (для корректной позиции
    // курсора после вставки mention-токена, который «сжимается» в
    // `@label` в attributed-представлении).
    final sel = widget.controller.selection;
    unawaited(c.invokeMethod<void>('setText', {
      'text': widget.controller.text,
      if (sel.isValid && sel.isCollapsed) 'selectionStart': sel.baseOffset,
    }));
  }

  void _onFocusChanged() {
    final c = _channel;
    if (c == null) return;
    if (widget.focusNode.hasFocus) {
      unawaited(c.invokeMethod<void>('focus'));
    } else {
      unawaited(c.invokeMethod<void>('unfocus'));
    }
  }

  Future<void> _pushStyle() async {
    final c = _channel;
    if (c == null) return;
    unawaited(c.invokeMethod<void>('setStyle', _styleArgs()));
  }

  /// Phase 4 Format sheet: переключает inline-формат на selection (или
  /// typingAttributes если selection пустое). `tag` — один из:
  /// `bold`, `italic`, `underline`, `strikethrough`, `code`.
  ///
  /// Native сам сериализует обновлённый attributed-text обратно в HTML
  /// (`<strong>`, `<em>`, `<u>`, `<s>`, `<code>`) и шлёт через
  /// `textChanged`, так что controller.text сразу в нужном формате.
  void toggleFormat(String tag) {
    final c = _channel;
    if (c == null) return;
    unawaited(c.invokeMethod<void>('toggleFormat', {'tag': tag}));
  }


  Map<String, Object?> _styleArgs() {
    final ts = widget.textStyle;
    final hs = widget.hintStyle;
    return {
      'fontSize': ts?.fontSize ?? 16.0,
      'fontWeight': _weightAsInt(ts?.fontWeight),
      'textColorHex': _hexFromColor(ts?.color),
      'hintColorHex': _hexFromColor(hs?.color),
      'cursorColorHex': _hexFromColor(widget.cursorColor),
      'hint': widget.hint ?? '',
    };
  }

  int _weightAsInt(FontWeight? w) {
    if (w == null) return 500;
    // FontWeight.values уже отсортирован w100..w900.
    final idx = FontWeight.values.indexOf(w);
    return idx >= 0 ? (idx + 1) * 100 : 500;
  }

  String? _hexFromColor(Color? c) {
    if (c == null) return null;
    final v = c.toARGB32();
    return '#${v.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  // ── PlatformView events ─────────────────────────────────────────

  Future<void> _onNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'textChanged':
        final map = (call.arguments as Map?)?.cast<String, Object?>() ?? {};
        final text = (map['text'] as String?) ?? '';
        final selStart = (map['selectionStart'] as num?)?.toInt() ?? text.length;
        if (widget.controller.text != text) {
          _suppressControllerListener = true;
          widget.controller.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: selStart.clamp(0, text.length)),
          );
          _suppressControllerListener = false;
        }
        break;
      case 'selectionChanged':
        final map = (call.arguments as Map?)?.cast<String, Object?>() ?? {};
        final start = (map['start'] as num?)?.toInt() ?? 0;
        final end = (map['end'] as num?)?.toInt() ?? start;
        final t = widget.controller.text;
        final clampedStart = start.clamp(0, t.length);
        final clampedEnd = end.clamp(0, t.length);
        if (widget.controller.selection.baseOffset != clampedStart ||
            widget.controller.selection.extentOffset != clampedEnd) {
          _suppressControllerListener = true;
          widget.controller.selection = TextSelection(
            baseOffset: clampedStart,
            extentOffset: clampedEnd,
          );
          _suppressControllerListener = false;
        }
        break;
      case 'focusChanged':
        final map = (call.arguments as Map?)?.cast<String, Object?>() ?? {};
        final focused = (map['focused'] as bool?) ?? false;
        if (focused && !widget.focusNode.hasFocus) {
          widget.focusNode.requestFocus();
        } else if (!focused && widget.focusNode.hasFocus) {
          widget.focusNode.unfocus();
        }
        break;
      case 'contentHeightChanged':
        final map = (call.arguments as Map?)?.cast<String, Object?>() ?? {};
        final h = (map['height'] as num?)?.toDouble() ?? 0;
        if ((h - _measuredHeight).abs() >= 0.5) {
          setState(() => _measuredHeight = h);
        }
        break;
      case 'pasteRequested':
        // Native перехватил Paste с файлом/картинкой. Делегируем в Dart-
        // pipeline композера; если callback не задан — fallback silent
        // (native уже заблокировал дефолтную вставку plain-text'а).
        final cb = widget.onPasteRequested;
        if (cb != null) {
          unawaited(cb());
        }
        break;
    }
  }

  void _onPlatformViewCreated(int id) {
    final c = MethodChannel('lighchat/native_composer_$id');
    _channel = c;
    c.setMethodCallHandler(_onNativeCall);
    // Если controller к моменту mount уже что-то содержит — синкаем.
    if (widget.controller.text.isNotEmpty) {
      unawaited(c.invokeMethod<void>('setText', {'text': widget.controller.text}));
    }
    // Push style (для случая когда didUpdateWidget не сработал).
    unawaited(c.invokeMethod<void>('setStyle', _styleArgs()));
    if (widget.focusNode.hasFocus) {
      unawaited(c.invokeMethod<void>('focus'));
    }
  }

  // ── Layout ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      // Fallback. Это нужно компилироваться на Android — но в реальности
      // на других платформах виджет НЕ должен инстанциироваться: caller
      // (chat_composer) проверяет [NativeComposerFlag.isEnabled].
      return TextField(controller: widget.controller, focusNode: widget.focusNode);
    }

    // Approx line-height на основе fontSize × 1.25 — пока native не
    // сообщил настоящий contentHeight (первый кадр).
    final fontSize = widget.textStyle?.fontSize ?? 16;
    _lineHeight = fontSize * 1.25;
    final minH = _lineHeight * widget.minLines;
    final maxH = _lineHeight * widget.maxLines + 8;
    final height = _measuredHeight.clamp(minH, maxH);

    return SizedBox(
      height: height == 0 ? minH : height,
      child: UiKitView(
        viewType: _viewType,
        creationParams: <String, Object?>{
          'initialText': widget.controller.text,
          ..._styleArgs(),
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
        // Hybrid composition даёт корректное z-order'инг Flutter-виджетов
        // поверх native input (важно для будущего mention-picker'а), но
        // дороже по перфу. Если станет лагать — переключаемся на virtual.
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
      ),
    );
  }
}
