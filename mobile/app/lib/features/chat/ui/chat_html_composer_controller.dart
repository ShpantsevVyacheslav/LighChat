import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../data/mention_token_codec.dart';

class _MentionTokenRange {
  const _MentionTokenRange({
    required this.start,
    required this.end,
    required this.token,
    required this.label,
  });

  final int start;
  final int end;
  final String token;
  final String label;

  bool containsInterior(int offset) => offset > start && offset < end;

  bool intersects(int startOffset, int endOffset) {
    return startOffset < end && endOffset > start;
  }
}

class _TextEditDiff {
  const _TextEditDiff({
    required this.oldStart,
    required this.oldEnd,
    required this.newStart,
    required this.newEnd,
  });

  final int oldStart;
  final int oldEnd;
  final int newStart;
  final int newEnd;

  int get oldLen => oldEnd - oldStart;
  int get newLen => newEnd - newStart;
  bool get isInsertion => oldLen == 0 && newLen > 0;
  bool get isDeletion => oldLen > 0 && newLen == 0;
}

/// Стили сегментов композера (паритет разметки сообщений).
class _CompStyle {
  const _CompStyle({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.code = false,
    this.spoiler = false,
    this.mention = false,
  });

  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final bool code;
  final bool spoiler;
  final bool mention;

  _CompStyle copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strike,
    bool? code,
    bool? spoiler,
    bool? mention,
  }) {
    return _CompStyle(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strike: strike ?? this.strike,
      code: code ?? this.code,
      spoiler: spoiler ?? this.spoiler,
      mention: mention ?? this.mention,
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
    if (mention) {
      s = s.copyWith(
        color: const Color(0xFF38BDF8),
        fontWeight: FontWeight.w700,
      );
    }
    return s;
  }
}

/// [TextEditingController]: в поле видно форматирование, теги HTML остаются в [text], но не отображаются.
class ChatHtmlComposerController extends TextEditingController {
  ChatHtmlComposerController({super.text});

  static bool _containsMentionMarkers(String text) {
    return text.contains(MentionTokenCodec.tokenStart) ||
        text.contains(MentionTokenCodec.tokenEnd);
  }

  @override
  set value(TextEditingValue newValue) {
    final oldValue = super.value;
    var normalized = newValue;
    final touchesMentions =
        _containsMentionMarkers(oldValue.text) ||
        _containsMentionMarkers(newValue.text);
    if (touchesMentions) {
      normalized = _normalizeMentionEdit(oldValue, newValue);
    }
    super.value = normalized;
  }

  static List<_MentionTokenRange> _mentionTokenRanges(String text) {
    final out = <_MentionTokenRange>[];
    final start = MentionTokenCodec.tokenStart;
    final end = MentionTokenCodec.tokenEnd;
    var pos = 0;
    while (pos < text.length) {
      final s = text.indexOf(start, pos);
      if (s < 0) break;
      final e = text.indexOf(end, s + start.length);
      if (e < 0) break;
      final token = text.substring(s, e + end.length);
      final decoded = MentionTokenCodec.tryDecodeToken(token);
      final label = decoded?.label.trim().isNotEmpty == true
          ? decoded!.label.trim()
          : 'Участник';
      out.add(
        _MentionTokenRange(
          start: s,
          end: e + end.length,
          token: token,
          label: label,
        ),
      );
      pos = e + end.length;
    }
    return out;
  }

  static _TextEditDiff _computeDiff(String oldText, String newText) {
    var prefix = 0;
    final minLen = oldText.length < newText.length
        ? oldText.length
        : newText.length;
    while (prefix < minLen && oldText[prefix] == newText[prefix]) {
      prefix += 1;
    }
    var oldEnd = oldText.length;
    var newEnd = newText.length;
    while (oldEnd > prefix &&
        newEnd > prefix &&
        oldText[oldEnd - 1] == newText[newEnd - 1]) {
      oldEnd -= 1;
      newEnd -= 1;
    }
    return _TextEditDiff(
      oldStart: prefix,
      oldEnd: oldEnd,
      newStart: prefix,
      newEnd: newEnd,
    );
  }

  static int _mapOldOffsetToNewStart(int oldOffset, _TextEditDiff d) {
    final delta = d.newLen - d.oldLen;
    if (oldOffset <= d.oldStart) return oldOffset;
    if (oldOffset >= d.oldEnd) return oldOffset + delta;
    return d.newStart;
  }

  static int _mapOldOffsetToNewEnd(int oldOffset, _TextEditDiff d) {
    final delta = d.newLen - d.oldLen;
    if (oldOffset <= d.oldStart) return oldOffset;
    if (oldOffset >= d.oldEnd) return oldOffset + delta;
    return d.newEnd;
  }

  static String _dropLastRunes(String input, int count) {
    if (count <= 0) return input;
    final runes = input.runes.toList(growable: false);
    if (count >= runes.length) return '';
    return String.fromCharCodes(runes.sublist(0, runes.length - count));
  }

  static TextEditingValue _replaceRangeInValue(
    TextEditingValue value,
    int start,
    int end,
    String replacement,
  ) {
    final text = value.text;
    final s = start.clamp(0, text.length);
    final e = end.clamp(0, text.length);
    if (s >= e) return value;
    final nt = text.substring(0, s) + replacement + text.substring(e);

    int mapOffset(int off) {
      if (off <= s) return off;
      if (off >= e) return off - (e - s) + replacement.length;
      return s + replacement.length;
    }

    final sel = value.selection;
    final nextSel = sel.isValid
        ? TextSelection(
            baseOffset: mapOffset(sel.baseOffset).clamp(0, nt.length),
            extentOffset: mapOffset(sel.extentOffset).clamp(0, nt.length),
          )
        : TextSelection.collapsed(
            offset: (s + replacement.length).clamp(0, nt.length),
          );

    return TextEditingValue(
      text: nt,
      selection: nextSel,
      composing: TextRange.empty,
    );
  }

  static String _mentionDisplayLabel(_MentionTokenRange tokenRange) {
    final l = tokenRange.label.trim();
    if (l.isEmpty) return '@Участник';
    return '@$l';
  }

  static TextEditingValue _normalizeTouchedMentionToken(
    TextEditingValue candidate,
    _MentionTokenRange touched,
    _TextEditDiff diff,
  ) {
    final mappedStart = _mapOldOffsetToNewStart(
      touched.start,
      diff,
    ).clamp(0, candidate.text.length);
    final mappedEnd = _mapOldOffsetToNewEnd(
      touched.end,
      diff,
    ).clamp(0, candidate.text.length);
    final s = mappedStart <= mappedEnd ? mappedStart : mappedEnd;
    final e = mappedStart <= mappedEnd ? mappedEnd : mappedStart;
    var replacement = _mentionDisplayLabel(touched);

    if (diff.isInsertion) {
      final inserted = candidate.text.substring(
        diff.newStart.clamp(0, candidate.text.length),
        diff.newEnd.clamp(0, candidate.text.length),
      );
      replacement = '$replacement$inserted';
    } else if (diff.isDeletion && diff.oldLen > 0) {
      final label = replacement.startsWith('@')
          ? replacement.substring(1)
          : replacement;
      final trimmed = _dropLastRunes(label, diff.oldLen);
      replacement = trimmed.isEmpty ? '@' : '@$trimmed';
    }

    return _replaceRangeInValue(candidate, s, e, replacement);
  }

  static TextEditingValue _snapSelectionOutOfMentionTokens(
    TextEditingValue value,
  ) {
    final tokens = _mentionTokenRanges(value.text);
    if (tokens.isEmpty || !value.selection.isValid) return value;
    var sel = value.selection;
    if (sel.isCollapsed) {
      var off = sel.extentOffset.clamp(0, value.text.length);
      for (final t in tokens) {
        if (t.containsInterior(off)) {
          off = t.end;
          break;
        }
      }
      sel = TextSelection.collapsed(offset: off.clamp(0, value.text.length));
      return value.copyWith(selection: sel, composing: TextRange.empty);
    }

    int clampOffset(int off, {required bool preferEnd}) {
      var out = off.clamp(0, value.text.length);
      for (final t in tokens) {
        if (t.containsInterior(out)) {
          out = preferEnd ? t.end : t.start;
          break;
        }
      }
      return out.clamp(0, value.text.length);
    }

    sel = TextSelection(
      baseOffset: clampOffset(sel.baseOffset, preferEnd: false),
      extentOffset: clampOffset(sel.extentOffset, preferEnd: true),
    );
    return value.copyWith(selection: sel, composing: TextRange.empty);
  }

  TextEditingValue _normalizeMentionEdit(
    TextEditingValue oldValue,
    TextEditingValue candidate,
  ) {
    final oldTokens = _mentionTokenRanges(oldValue.text);
    if (oldValue.text == candidate.text) {
      return _snapSelectionOutOfMentionTokens(candidate);
    }
    if (oldTokens.isEmpty) {
      return _snapSelectionOutOfMentionTokens(candidate);
    }
    final diff = _computeDiff(oldValue.text, candidate.text);

    _MentionTokenRange? touched;
    for (final t in oldTokens) {
      if (t.intersects(diff.oldStart, diff.oldEnd) ||
          (diff.oldStart == diff.oldEnd && t.containsInterior(diff.oldStart))) {
        touched = t;
        break;
      }
    }

    var next = candidate;
    if (touched != null) {
      next = _normalizeTouchedMentionToken(next, touched, diff);
    }
    return _snapSelectionOutOfMentionTokens(next);
  }

  static final TextStyle _invisibleTagStyle = TextStyle(
    // Должно быть реально "0-size", иначе теги (особенно `<span ...>` для @)
    // могут съедать место и ломать раскладку/курсор.
    fontSize: 0,
    height: 0,
    color: const Color(0x00FFFFFF),
    letterSpacing: 0,
  );

  static bool _classHasSpoiler(String tagLower) {
    return tagLower.contains('spoiler-text');
  }

  static bool _isMentionSpanTag(String tagLower) {
    return tagLower.contains('data-chat-mention') ||
        tagLower.contains('data-user-id');
  }

  static bool _isBrTag(String raw) {
    final t = raw.toLowerCase().trim();
    return t.startsWith('<br');
  }

  static bool _isListItemOpenTag(String raw) {
    final t = raw.toLowerCase().trim();
    return t.startsWith('<li');
  }

  static bool _isBlockTagOpen(String raw) {
    final t = raw.toLowerCase().trim();
    return t.startsWith('<p') ||
        t.startsWith('<div') ||
        t.startsWith('<blockquote') ||
        t.startsWith('<pre') ||
        t.startsWith('<h1') ||
        t.startsWith('<h2') ||
        t.startsWith('<h3') ||
        t.startsWith('<h4');
  }

  static bool _isBlockTagClose(String raw) {
    final t = raw.toLowerCase().trim();
    return t == '</p>' ||
        t == '</div>' ||
        t == '</li>' ||
        t == '</blockquote>' ||
        t == '</pre>' ||
        t == '</h1>' ||
        t == '</h2>' ||
        t == '</h3>' ||
        t == '</h4>';
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
    // Важно: не путать `<s>` с `<span ...>` (оба начинаются на "<s").
    if (t.startsWith('<s>') ||
        t.startsWith('<s ') ||
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
    if (t.startsWith('<span') && _isMentionSpanTag(t)) {
      stack.add(top.copyWith(mention: true));
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
      if (stack.length > 1 && (stack.last.spoiler || stack.last.mention)) {
        stack.removeLast();
      }
    }
  }

  bool _childrenEndWithLineBreak(List<InlineSpan> children) {
    for (var i = children.length - 1; i >= 0; i--) {
      final s = children[i];
      if (s is! TextSpan) return false;
      final t = s.text ?? '';
      if (t.isEmpty) continue;
      return t.endsWith('\n');
    }
    return false;
  }

  void _appendLineBreakIfNeeded(
    List<InlineSpan> children,
    TextStyle visibleStyle,
  ) {
    if (children.isEmpty) return;
    if (_childrenEndWithLineBreak(children)) return;
    children.add(TextSpan(text: '\n', style: visibleStyle));
  }

  static final RegExp _entityRe = RegExp(
    r'&(nbsp|amp|lt|gt|quot|#39|#x27);',
    caseSensitive: false,
  );

  String? _decodeEntity(String entity) {
    switch (entity.toLowerCase()) {
      case '&nbsp;':
        return ' ';
      case '&amp;':
        return '&';
      case '&lt;':
        return '<';
      case '&gt;':
        return '>';
      case '&quot;':
        return '"';
      case '&#39;':
      case '&#x27;':
        return "'";
      default:
        return null;
    }
  }

  void _addTextWithEntityDecode(
    List<InlineSpan> children,
    String text,
    TextStyle visibleStyle,
  ) {
    if (text.isEmpty) return;
    var pos = 0;
    for (final m in _entityRe.allMatches(text)) {
      if (m.start > pos) {
        final chunk = text.substring(pos, m.start);
        if (chunk.isNotEmpty) {
          children.add(TextSpan(text: chunk, style: visibleStyle));
        }
      }
      final entity = m.group(0) ?? '';
      final decoded = _decodeEntity(entity);
      if (decoded == null) {
        children.add(TextSpan(text: entity, style: visibleStyle));
      } else {
        children.add(TextSpan(text: decoded, style: visibleStyle));
        for (var i = 1; i < entity.length; i++) {
          children.add(
            TextSpan(
              text: entity[i],
              style: visibleStyle.merge(_invisibleTagStyle),
            ),
          );
        }
      }
      pos = m.end;
    }
    if (pos < text.length) {
      final tail = text.substring(pos);
      if (tail.isNotEmpty) {
        children.add(TextSpan(text: tail, style: visibleStyle));
      }
    }
  }

  List<InlineSpan> _buildHtmlSpans(String html, TextStyle? style, {String mentionFallback = 'Участник'}) {
    final base = style ?? const TextStyle();
    final children = <InlineSpan>[];
    final re = RegExp(r'<[^>]*>');
    final stack = <_CompStyle>[const _CompStyle()];
    var pos = 0;

    void addInvisible(String s) {
      for (final unit in s.runes) {
        children.add(
          TextSpan(
            text: String.fromCharCode(unit),
            // Важно: merge в сторону base -> invisible, иначе base (16px/цвет)
            // перетирает "невидимый" стиль и HTML-теги становятся видимыми в поле ввода.
            style: base.merge(_invisibleTagStyle),
          ),
        );
      }
    }

    for (final m in re.allMatches(html)) {
      if (m.start > pos) {
        final chunk = html.substring(pos, m.start);
        if (chunk.isNotEmpty) {
          final chunkStyle = stack.last.toVisible(base);
          if (_containsMentionMarkers(chunk)) {
            children.addAll(_buildMentionTokenSpans(chunk, chunkStyle, mentionFallback: mentionFallback));
          } else {
            _addTextWithEntityDecode(children, chunk, chunkStyle);
          }
        }
      }
      final tag = m.group(0)!;
      addInvisible(tag);
      final tl = tag.toLowerCase();
      if (tl.startsWith('</')) {
        _applyCloseTag(tag, stack);
        if (_isBlockTagClose(tl)) {
          _appendLineBreakIfNeeded(children, stack.last.toVisible(base));
        }
      } else if (_isBrTag(tag)) {
        children.add(TextSpan(text: '\n', style: stack.last.toVisible(base)));
      } else if (_isListItemOpenTag(tag)) {
        _appendLineBreakIfNeeded(children, stack.last.toVisible(base));
        children.add(TextSpan(text: '• ', style: stack.last.toVisible(base)));
        _applyOpenTag(tag, stack);
      } else if (_isBlockTagOpen(tag)) {
        _appendLineBreakIfNeeded(children, stack.last.toVisible(base));
        _applyOpenTag(tag, stack);
      } else {
        _applyOpenTag(tag, stack);
      }
      pos = m.end;
    }
    if (pos < html.length) {
      final chunk = html.substring(pos);
      if (chunk.isNotEmpty) {
        final chunkStyle = stack.last.toVisible(base);
        if (_containsMentionMarkers(chunk)) {
          children.addAll(_buildMentionTokenSpans(chunk, chunkStyle, mentionFallback: mentionFallback));
        } else {
          _addTextWithEntityDecode(children, chunk, chunkStyle);
        }
      }
    }
    return children;
  }

  int _runeLength(String s) => s.runes.length;

  void _appendMentionVisualToken(
    List<InlineSpan> children, {
    required String sourceToken,
    required String visibleLabel,
    required TextStyle base,
    required TextStyle mentionStyle,
  }) {
    final tokenRunes = sourceToken.runes.toList(growable: false);
    if (tokenRunes.isEmpty) return;
    final visibleLen = _runeLength(visibleLabel);
    if (visibleLen >= tokenRunes.length) {
      final trimmed = String.fromCharCodes(
        visibleLabel.runes.take(tokenRunes.length),
      );
      children.add(TextSpan(text: trimmed, style: mentionStyle));
      return;
    }
    children.add(TextSpan(text: visibleLabel, style: mentionStyle));
    for (var i = visibleLen; i < tokenRunes.length; i++) {
      children.add(
        TextSpan(
          text: String.fromCharCode(tokenRunes[i]),
          style: base.merge(_invisibleTagStyle),
        ),
      );
    }
  }

  void _appendInvisibleMarker(
    List<InlineSpan> children,
    String marker,
    TextStyle base,
  ) {
    children.add(TextSpan(text: marker, style: base.merge(_invisibleTagStyle)));
  }

  List<InlineSpan> _buildMentionTokenSpans(String text, TextStyle base, {String mentionFallback = 'Участник'}) {
    final children = <InlineSpan>[];
    final start = MentionTokenCodec.tokenStart;
    final end = MentionTokenCodec.tokenEnd;
    var pos = 0;
    final mentionStyle = base.copyWith(
      color: const Color(0xFF38BDF8),
      fontWeight: FontWeight.w700,
    );
    while (pos < text.length) {
      final s = text.indexOf(start, pos);
      final strayEnd = text.indexOf(end, pos);
      if (strayEnd >= 0 && (s < 0 || strayEnd < s)) {
        if (strayEnd > pos) {
          final chunk = text.substring(pos, strayEnd);
          if (chunk.isNotEmpty) {
            _addTextWithEntityDecode(children, chunk, base);
          }
        }
        _appendInvisibleMarker(children, end, base);
        pos = strayEnd + end.length;
        continue;
      }
      if (s < 0) {
        final tail = text.substring(pos);
        if (tail.isNotEmpty) {
          _addTextWithEntityDecode(children, tail, base);
        }
        break;
      }
      if (s > pos) {
        final chunk = text.substring(pos, s);
        if (chunk.isNotEmpty) {
          _addTextWithEntityDecode(children, chunk, base);
        }
      }
      final e = text.indexOf(end, s + start.length);
      if (e < 0) {
        final broken = text.substring(s);
        final fallback = _fallbackMentionFromMalformedToken(broken, mentionFallback: mentionFallback);
        _appendMentionVisualToken(
          children,
          sourceToken: broken,
          visibleLabel: fallback,
          base: base,
          mentionStyle: mentionStyle,
        );
        break;
      }
      final token = text.substring(s, e + end.length);
      final decoded = MentionTokenCodec.tryDecodeToken(token);
      if (decoded == null) {
        final fallback = _fallbackMentionFromMalformedToken(token, mentionFallback: mentionFallback);
        _appendMentionVisualToken(
          children,
          sourceToken: token,
          visibleLabel: fallback,
          base: base,
          mentionStyle: mentionStyle,
        );
      } else {
        final label = decoded.label.trim().isEmpty
            ? mentionFallback
            : decoded.label.trim();
        _appendMentionVisualToken(
          children,
          sourceToken: token,
          visibleLabel: '@$label',
          base: base,
          mentionStyle: mentionStyle,
        );
      }
      pos = e + end.length;
    }
    return children;
  }

  String _fallbackMentionFromMalformedToken(String raw, {required String mentionFallback}) {
    final stripped = raw
        .replaceAll(MentionTokenCodec.tokenStart, '')
        .replaceAll(MentionTokenCodec.tokenEnd, '')
        .trim();
    if (stripped.isEmpty) return '@$mentionFallback';
    final decoded = MentionTokenCodec.tryDecodeToken(
      '${MentionTokenCodec.tokenStart}$stripped${MentionTokenCodec.tokenEnd}',
    );
    if (decoded != null) {
      final label = decoded.label.trim().isEmpty
          ? mentionFallback
          : decoded.label.trim();
      return '@$label';
    }
    return '@$mentionFallback';
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final value = this.value;
    final t = value.text;
    // Не подменять разметку на «сырой» текст при IME: иначе снова видны `<strong>` и т.п.
    // Для обычного текста без тегов composing по-прежнему отдаём plain span (подчёркивание IME).
    if (withComposing &&
        value.composing.isValid &&
        !value.composing.isCollapsed &&
        !t.contains('<')) {
      return TextSpan(style: style, text: t);
    }
    if (t.isEmpty) {
      return TextSpan(text: '', style: style);
    }
    final hasMentionMarkers = _containsMentionMarkers(t);
    if (!t.contains('<') && !hasMentionMarkers) {
      return TextSpan(text: t, style: style);
    }
    final mf = AppLocalizations.of(context)?.mention_fallback_label_capitalized ?? 'Участник';
    if (!t.contains('<') && hasMentionMarkers) {
      final base = style ?? const TextStyle();
      return TextSpan(style: style, children: _buildMentionTokenSpans(t, base, mentionFallback: mf));
    }
    return TextSpan(style: style, children: _buildHtmlSpans(t, style, mentionFallback: mf));
  }
}
