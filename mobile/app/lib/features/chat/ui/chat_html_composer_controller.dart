import 'package:flutter/material.dart';

/// Стили сегментов композера (паритет разметки сообщений).
class _CompStyle {
  const _CompStyle({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.code = false,
    this.spoiler = false,
  });

  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final bool code;
  final bool spoiler;

  _CompStyle copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strike,
    bool? code,
    bool? spoiler,
  }) {
    return _CompStyle(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strike: strike ?? this.strike,
      code: code ?? this.code,
      spoiler: spoiler ?? this.spoiler,
    );
  }

  TextStyle toVisible(TextStyle base) {
    var s = base;
    if (bold) s = s.copyWith(fontWeight: FontWeight.w800);
    if (italic) s = s.copyWith(fontStyle: FontStyle.italic);
    if (underline && strike) {
      s = s.copyWith(
        decoration: TextDecoration.combine([
          TextDecoration.underline,
          TextDecoration.lineThrough,
        ]),
      );
    } else if (underline) {
      s = s.copyWith(decoration: TextDecoration.underline);
    } else if (strike) {
      s = s.copyWith(decoration: TextDecoration.lineThrough);
    }
    if (code) {
      s = s.copyWith(fontFamily: 'monospace');
    }
    if (spoiler) {
      s = s.copyWith(
        color: base.color?.withValues(alpha: 0.35) ?? Colors.white38,
      );
    }
    return s;
  }
}

/// [TextEditingController]: в поле видно форматирование, теги HTML остаются в [text], но не отображаются.
class ChatHtmlComposerController extends TextEditingController {
  ChatHtmlComposerController({super.text});

  static final TextStyle _invisibleTagStyle = TextStyle(
    fontSize: 0.05,
    height: 1.25,
    color: const Color(0x00FFFFFF),
    letterSpacing: -1,
  );

  static bool _classHasSpoiler(String tagLower) {
    return tagLower.contains('spoiler-text');
  }

  static bool _isBrTag(String raw) {
    final t = raw.toLowerCase().trim();
    return t.startsWith('<br');
  }

  static void _applyOpenTag(String raw, List<_CompStyle> stack) {
    final t = raw.toLowerCase();
    final top = stack.last;
    if (t.startsWith('<strong') || t.startsWith('<b>')) {
      stack.add(top.copyWith(bold: true));
      return;
    }
    if (t.startsWith('<em') || t.startsWith('<i>')) {
      stack.add(top.copyWith(italic: true));
      return;
    }
    if (t.startsWith('<u')) {
      stack.add(top.copyWith(underline: true));
      return;
    }
    if (t.startsWith('<s') ||
        t.startsWith('<strike') ||
        t.startsWith('<del')) {
      stack.add(top.copyWith(strike: true));
      return;
    }
    if (t.startsWith('<code')) {
      stack.add(top.copyWith(code: true));
      return;
    }
    if (t.startsWith('<span') && _classHasSpoiler(t)) {
      stack.add(top.copyWith(spoiler: true));
      return;
    }
  }

  static void _applyCloseTag(String raw, List<_CompStyle> stack) {
    final t = raw.toLowerCase().trim();
    if (t == '</strong>' || t == '</b>') {
      if (stack.length > 1) stack.removeLast();
      return;
    }
    if (t == '</em>' || t == '</i>') {
      if (stack.length > 1) stack.removeLast();
      return;
    }
    if (t == '</u>') {
      if (stack.length > 1) stack.removeLast();
      return;
    }
    if (t == '</s>' || t == '</strike>' || t == '</del>') {
      if (stack.length > 1) stack.removeLast();
      return;
    }
    if (t == '</code>') {
      if (stack.length > 1) stack.removeLast();
      return;
    }
    if (t == '</span>') {
      if (stack.length > 1 && stack.last.spoiler) {
        stack.removeLast();
      }
    }
  }

  List<InlineSpan> _buildHtmlSpans(String html, TextStyle? style) {
    final base = style ?? const TextStyle();
    final children = <InlineSpan>[];
    final re = RegExp(r'<[^>]*>');
    final stack = <_CompStyle>[const _CompStyle()];
    var pos = 0;

    void addInvisible(String s) {
      for (final unit in s.runes) {
        children.add(TextSpan(
          text: String.fromCharCode(unit),
          style: _invisibleTagStyle.merge(base),
        ));
      }
    }

    for (final m in re.allMatches(html)) {
      if (m.start > pos) {
        final chunk = html.substring(pos, m.start);
        if (chunk.isNotEmpty) {
          children.add(TextSpan(
            text: chunk,
            style: stack.last.toVisible(base),
          ));
        }
      }
      final tag = m.group(0)!;
      addInvisible(tag);
      final tl = tag.toLowerCase();
      if (tl.startsWith('</')) {
        _applyCloseTag(tag, stack);
      } else if (_isBrTag(tag)) {
        children.add(TextSpan(text: '\n', style: stack.last.toVisible(base)));
      } else {
        _applyOpenTag(tag, stack);
      }
      pos = m.end;
    }
    if (pos < html.length) {
      final chunk = html.substring(pos);
      if (chunk.isNotEmpty) {
        children.add(TextSpan(
          text: chunk,
          style: stack.last.toVisible(base),
        ));
      }
    }
    return children;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final value = this.value;
    if (withComposing &&
        value.composing.isValid &&
        !value.composing.isCollapsed) {
      return TextSpan(style: style, text: value.text);
    }
    final t = value.text;
    if (t.isEmpty) {
      return TextSpan(text: '', style: style);
    }
    if (!t.contains('<')) {
      return TextSpan(text: t, style: style);
    }
    return TextSpan(
      style: style,
      children: _buildHtmlSpans(t, style),
    );
  }
}
