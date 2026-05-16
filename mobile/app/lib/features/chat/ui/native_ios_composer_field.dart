import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show PlatformViewHitTestBehavior;
import 'package:flutter/services.dart';

/// Нативный iOS composer (Phase 1–7): оборачивает [UiKitView] с
/// PlatformView'ем `lighchat/native_composer` (см. Swift
/// `NativeComposerFactory`/`NativeComposerView`).
///
/// Зачем: Flutter `TextField` рендерится Skia и не получает системные
/// Cut/Copy/Paste/Replace/AutoFill/Writing Tools / диктовку. Нативный
/// `UITextView` даёт всё это бесплатно.
///
/// **Что реализовано:**
///  - двусторонняя синхронизация text + selection с [controller]
///    (Swift конвертирует visible→plain offset через
///    `MentionAttributedString.visibleOffsetToPlain`, чтобы курсор после
///    chip-токена / HTML-форматирования корректно попадал в Dart-плэйн
///    текст и mention-логика типа `_recomputeMentionState` срабатывала
///    после первой @-метки в сообщении),
///  - управление фокусом через [focusNode],
///  - стили (font, цвета, hint), auto-grow по contentHeight,
///  - mention-chip render + атомарное удаление backspace'ом
///    (chip-suggestions overlay живёт на Flutter-стороне; `@`-триггер
///    распознаётся прозрачно через controller listener),
///  - paste файлов из буфера через `pasteRequested` → Dart pipeline,
///  - inline-форматирование B/I/U/S/code и animated effects через
///    [toggleFormat] (Phase 4–6),
///  - HTML round-trip с `<strong>/<em>/<u>/<s>/<code>/<span data-anim>`.
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
    this.onAttachmentInserted,
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

  /// Phase 8: пользователь вставил стикер / memoji / genmoji через
  /// системную emoji-клавиатуру → Swift извлёк UIImage в tmp PNG-файл
  /// и сообщает абсолютные пути. Caller должен добавить их в
  /// `pendingAttachments` как обычные image-вложения.
  final Future<void> Function(List<String> paths)? onAttachmentInserted;

  @override
  State<NativeIosComposerField> createState() => NativeIosComposerFieldState();
}

class NativeIosComposerFieldState extends State<NativeIosComposerField> {
  static const _viewType = 'lighchat/native_composer';

  MethodChannel? _channel;
  double _lineHeight = 20;
  double _measuredHeight = 0;
  bool _suppressControllerListener = false;
  /// Если `focus()` был вызван до того как PlatformView создался —
  /// применяем при первой возможности (см. `_onPlatformViewCreated`).
  bool _pendingFocus = false;

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
    debugPrint(
      '[panel-toggle] dart→native focus listener: '
      'hasFocus=${widget.focusNode.hasFocus}',
    );
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
  /// Bug A: переключение типа return-key (UIReturnKeyType) native
  /// UITextView'я. В режиме location-share пробрасываем `'search'`,
  /// иначе `'default'` (обычная клавиатура с Enter→newline).
  void setReturnKeyType(String type) {
    final c = _channel;
    if (c == null) return;
    unawaited(c.invokeMethod<void>('setReturnKeyType', {'type': type}));
  }

  void toggleFormat(String tag) {
    final c = _channel;
    if (c == null) return;
    unawaited(c.invokeMethod<void>('toggleFormat', {'tag': tag}));
  }

  /// Запасной путь для tap-to-dismiss-keyboard: явно резигнит
  /// firstResponder в UITextView без полагания на Flutter focusNode
  /// listener (который иногда даёт гонку если Flutter primaryFocus
  /// держит не наш focusNode).
  void unfocus() {
    final c = _channel;
    if (c == null) return;
    unawaited(c.invokeMethod<void>('unfocus'));
  }

  /// Зеркальный к [unfocus]: напрямую дёргает Swift becomeFirstResponder
  /// через method-channel. Если PlatformView ещё не создан (`_channel == null`),
  /// ставим `_pendingFocus = true` — `_onPlatformViewCreated` применит focus
  /// сразу после готовности channel'а. Это критично для panel→keyboard
  /// сценария, где запрос на focus приходит в первый кадр после mount,
  /// когда PlatformView ещё не успел зарегистрироваться.
  void focus() {
    final c = _channel;
    if (c == null) {
      _pendingFocus = true;
      return;
    }
    unawaited(c.invokeMethod<void>('focus'));
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
        debugPrint(
          '[panel-toggle] native→dart focusChanged: native=$focused '
          'dartHasFocus=${widget.focusNode.hasFocus}',
        );
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
      case 'submitRequested':
        // Bug A: native перехватил Return-key (только когда
        // returnKeyType=.search — режим location-share). Эмитим
        // onSubmitted с текущим контейнером — caller решает, что
        // делать (форсировать forwardGeocode / hide keyboard и т.п.).
        widget.onSubmitted?.call(widget.controller.text);
        break;
      case 'attachmentInserted':
        // Phase 8: системная emoji-клавиатура вставила inline-стикер
        // (Sticker/Memoji/Genmoji). Native сохранил картинку в tmp PNG
        // и удалил attachment-run из attributedText. Здесь добавляем
        // путь в pendingAttachments как обычное изображение.
        final cb = widget.onAttachmentInserted;
        if (cb == null) break;
        final map = (call.arguments as Map?)?.cast<String, Object?>() ?? {};
        final raw = map['paths'];
        final paths = <String>[];
        if (raw is List) {
          for (final p in raw) {
            if (p is String && p.isNotEmpty) paths.add(p);
          }
        }
        if (paths.isNotEmpty) {
          unawaited(cb(paths));
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
    // Применяем фокус если он был запрошен до создания PlatformView:
    // через `_pendingFocus` (явный вызов `focus()` от caller'a) или
    // через `widget.focusNode.hasFocus` (Flutter focus tree уже
    // зафокусил наш node). Это спасает panel→keyboard transition,
    // где запрос приходит в первый кадр после mount.
    if (_pendingFocus || widget.focusNode.hasFocus) {
      _pendingFocus = false;
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
