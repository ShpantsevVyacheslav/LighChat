import 'package:flutter/services.dart';

import 'chat_link_normalization.dart';
import '../ui/message_html_text.dart';
import 'sanitize_message_html.dart';
import 'mention_token_codec.dart';

/// Редактирование HTML в композере (паритет TipTap / `FormattingToolbar.tsx`).
class ComposerHtmlEditing {
  ComposerHtmlEditing._();

  static String escapeHtmlText(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  static String escapeHtmlAttribute(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  /// Обычный текст → `<p>…</p>` с `<br>` для переносов (как TipTap).
  static String plainTextToParagraphHtml(String plain) {
    final t = plain.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (t.trim().isEmpty) return '';
    final esc = escapeHtmlText(t);
    final withBr = esc.split('\n').join('<br>');
    return '<p>$withBr</p>';
  }

  /// Только если есть похожие на чат-теги конструкции (не срабатывать на «2 < 3»).
  static bool _looksLikeHtml(String s) {
    return RegExp(
          r'<(p|br|strong|b|em|i|u|s|strike|del|a|ul|ol|li|blockquote|code|pre|span|div|h[1-4])\b',
          caseSensitive: false,
        ).hasMatch(s) ||
        RegExp(r'</[a-zA-Z]', caseSensitive: false).hasMatch(s);
  }

  static String ensureOuterWrapper(String html) {
    final s = html.trim();
    if (s.isEmpty) return '<p></p>';
    if (s.startsWith('<p') || s.startsWith('<blockquote')) {
      return s;
    }
    return '<p>$s</p>';
  }

  /// Готовит поле `text` сообщения для Firestore (HTML + санитизация).
  static String prepareChatMessageHtmlForSend(String raw) {
    final trimmedRight = raw.trimRight();
    if (trimmedRight.trim().isEmpty) return '';
    final tokenExpanded = _expandMentionTokensToHtml(trimmedRight);
    final plainCheck = messageHtmlToPlainText(tokenExpanded).trim();
    if (plainCheck.isEmpty && !trimmedRight.contains('<')) {
      return '';
    }
    final String body;
    if (_looksLikeHtml(tokenExpanded)) {
      body = ensureOuterWrapper(tokenExpanded.trim());
    } else {
      body = plainTextToParagraphHtml(tokenExpanded.trim());
    }
    return sanitizeMessageHtml(body);
  }

  static String _expandMentionTokensToHtml(String raw) {
    if (!MentionTokenCodec.containsToken(raw)) return raw;
    final start = MentionTokenCodec.tokenStart;
    final end = MentionTokenCodec.tokenEnd;
    final out = StringBuffer();
    var i = 0;
    while (i < raw.length) {
      final s = raw.indexOf(start, i);
      if (s < 0) {
        out.write(raw.substring(i));
        break;
      }
      out.write(raw.substring(i, s));
      final e = raw.indexOf(end, s + start.length);
      if (e < 0) {
        // broken token → keep as-is
        out.write(raw.substring(s));
        break;
      }
      final token = raw.substring(s, e + end.length);
      final decoded = MentionTokenCodec.tryDecodeToken(token);
      if (decoded == null) {
        out.write(token);
      } else {
        final idEsc = escapeHtmlAttribute(decoded.userId);
        final safeLabel = escapeHtmlText(decoded.label);
        out.write(
          '<span data-chat-mention="" data-user-id="$idEsc">@$safeLabel</span>',
        );
      }
      i = e + end.length;
    }
    return out.toString();
  }

  /// Inline custom-emoji span for animated emoji rendering in message text.
  ///
  /// `fallbackEmoji` must be a visible unicode emoji so plain-text surfaces
  /// (search/notifications/legacy clients) still have meaningful content.
  static String buildInlineCustomEmojiSpanHtml({
    required String emojiId,
    required String imageUrl,
    required String fallbackEmoji,
  }) {
    final id = emojiId.trim();
    final src = imageUrl.trim();
    final fallback = fallbackEmoji.trim();
    if (id.isEmpty || src.isEmpty || fallback.isEmpty) {
      return escapeHtmlText(fallbackEmoji);
    }
    final idEsc = escapeHtmlAttribute(id);
    final srcEsc = escapeHtmlAttribute(src);
    final fbEsc = escapeHtmlText(fallback);
    return '<span data-chat-custom-emoji="" '
        'data-emoji-id="$idEsc" '
        'data-emoji-src="$srcEsc">$fbEsc</span>';
  }

  static TextEditingValue toggleInline(
    String text,
    TextSelection sel,
    String open,
    String close,
  ) {
    final normalized = _normalizeHtmlSelection(text, sel);
    final s = normalized.start;
    final e = normalized.end;
    if (s < 0 || e < 0 || s > e || e > text.length) {
      return TextEditingValue(text: text, selection: sel);
    }
    final wrapped = _findWrappedRange(
      text: text,
      start: s,
      end: e,
      open: open,
      close: close,
    );
    if (wrapped != null) {
      final inner = text.substring(wrapped.innerStart, wrapped.innerEnd);
      final nt =
          text.substring(0, wrapped.innerStart - open.length) +
          inner +
          text.substring(wrapped.innerEnd + close.length);
      final off = (e - open.length - close.length).clamp(0, nt.length);
      return TextEditingValue(
        text: nt,
        selection: TextSelection.collapsed(offset: off),
      );
    }
    final inner = text.substring(s, e);
    final mid = inner.isEmpty ? '$open$close' : '$open$inner$close';
    final nt = text.substring(0, s) + mid + text.substring(e);
    if (inner.isEmpty) {
      return TextEditingValue(
        text: nt,
        selection: TextSelection.collapsed(offset: s + open.length),
      );
    }
    return TextEditingValue(
      text: nt,
      selection: TextSelection.collapsed(offset: s + mid.length),
    );
  }

  static TextEditingValue toggleBlockquote(String text, TextSelection sel) {
    const open = '<blockquote>';
    const close = '</blockquote>';
    return toggleInline(text, sel, open, close);
  }

  static TextEditingValue applyLink(
    String text,
    TextSelection sel,
    String url,
  ) {
    final u = normalizeChatLinkUrl(url);
    final normalized = _normalizeHtmlSelection(text, sel);
    final normalizedLinkRange = _expandSelectionToAnchor(
      text,
      normalized.start,
      normalized.end,
    );
    final s = normalizedLinkRange.start;
    final e = normalizedLinkRange.end;
    if (s < 0 || e < 0 || s > text.length || e > text.length) {
      return TextEditingValue(text: text, selection: sel);
    }
    if (u.isEmpty) {
      return TextEditingValue(text: text, selection: sel);
    }
    final hrefEsc = escapeHtmlAttribute(u);
    final label = s == e ? escapeHtmlText(u) : _buildLinkLabel(text, s, e);
    if (s != e && label.isEmpty) {
      return TextEditingValue(text: text, selection: sel);
    }
    final frag = '<a href="$hrefEsc">$label</a>';
    final nt = text.substring(0, s) + frag + text.substring(e);
    return TextEditingValue(
      text: nt,
      selection: TextSelection.collapsed(offset: s + frag.length),
    );
  }

  static String _buildLinkLabel(String text, int start, int end) {
    final raw = text.substring(start, end);
    if (!_looksLikeHtml(raw)) {
      return escapeHtmlText(raw);
    }
    // Avoid nested anchors and keep inner formatting tags intact.
    final withoutAnchors = raw.replaceAll(
      RegExp(r'</?a\b[^>]*>', caseSensitive: false),
      '',
    );
    return withoutAnchors;
  }

  static ({int start, int end}) _normalizeHtmlSelection(
    String text,
    TextSelection sel,
  ) {
    var s = sel.start.clamp(0, text.length);
    var e = sel.end.clamp(0, text.length);
    if (s > e) {
      final t = s;
      s = e;
      e = t;
    }
    s = _moveStartOutOfTag(text, s);
    e = _moveEndOutOfTag(text, e);

    // If hidden tag chars are fully captured at boundaries, trim them.
    while (s < e && text[s] == '<') {
      final close = text.indexOf('>', s);
      if (close < 0 || close >= e) break;
      s = close + 1;
    }
    while (e > s && text[e - 1] == '>') {
      final open = text.lastIndexOf('<', e - 1);
      if (open < s) break;
      e = open;
    }
    if (s > e) s = e;
    return (start: s, end: e);
  }

  static ({int start, int end}) _expandSelectionToAnchor(
    String text,
    int start,
    int end,
  ) {
    if (start < 0 || end < 0 || start > end || end > text.length) {
      return (start: start, end: end);
    }
    final openStart = text.lastIndexOf('<a', start);
    if (openStart < 0) return (start: start, end: end);
    final openEnd = text.indexOf('>', openStart);
    if (openEnd < 0) return (start: start, end: end);
    final closeBeforeStart = text.lastIndexOf(
      '</a>',
      start == 0 ? 0 : start - 1,
    );
    if (closeBeforeStart > openStart) {
      return (start: start, end: end);
    }
    if (openEnd >= start && openEnd >= end) {
      return (start: start, end: end);
    }
    final closeStart = text.indexOf('</a>', end);
    if (closeStart < 0) return (start: start, end: end);
    final innerAnchorOpen = text.indexOf('<a', openEnd + 1);
    if (innerAnchorOpen >= 0 && innerAnchorOpen < closeStart) {
      return (start: start, end: end);
    }
    return (start: openStart, end: closeStart + '</a>'.length);
  }

  static int _moveStartOutOfTag(String text, int offset) {
    var o = offset.clamp(0, text.length);
    while (_isInsideTag(text, o)) {
      final gt = text.indexOf('>', o);
      if (gt < 0) return text.length;
      o = (gt + 1).clamp(0, text.length);
    }
    return o;
  }

  static int _moveEndOutOfTag(String text, int offset) {
    var o = offset.clamp(0, text.length);
    while (_isInsideTag(text, o)) {
      final lt = text.lastIndexOf('<', o - 1);
      if (lt < 0) return 0;
      o = lt.clamp(0, text.length);
    }
    return o;
  }

  static bool _isInsideTag(String text, int offset) {
    final o = offset.clamp(0, text.length);
    final lt = text.lastIndexOf('<', o == 0 ? 0 : o - 1);
    if (lt < 0) return false;
    final gtBefore = text.lastIndexOf('>', o == 0 ? 0 : o - 1);
    if (gtBefore > lt) return false;
    final gtAfter = text.indexOf('>', o);
    return gtAfter >= 0;
  }

  static ({int innerStart, int innerEnd})? _findWrappedRange({
    required String text,
    required int start,
    required int end,
    required String open,
    required String close,
  }) {
    bool wrappedAt(int s, int e) {
      return s >= open.length &&
          e + close.length <= text.length &&
          text.substring(s - open.length, s) == open &&
          text.substring(e, e + close.length) == close;
    }

    if (wrappedAt(start, end)) {
      return (innerStart: start, innerEnd: end);
    }

    var innerStart = start;
    while (innerStart < end &&
        (text.codeUnitAt(innerStart) == 32 ||
            text.codeUnitAt(innerStart) == 9 ||
            text.codeUnitAt(innerStart) == 10 ||
            text.codeUnitAt(innerStart) == 13)) {
      innerStart++;
    }
    var innerEnd = end;
    while (innerEnd > innerStart &&
        (text.codeUnitAt(innerEnd - 1) == 32 ||
            text.codeUnitAt(innerEnd - 1) == 9 ||
            text.codeUnitAt(innerEnd - 1) == 10 ||
            text.codeUnitAt(innerEnd - 1) == 13)) {
      innerEnd--;
    }
    if (innerStart < innerEnd && wrappedAt(innerStart, innerEnd)) {
      return (innerStart: innerStart, innerEnd: innerEnd);
    }

    if (innerStart < innerEnd) {
      final selected = text.substring(innerStart, innerEnd);
      if (selected.startsWith(open) && selected.endsWith(close)) {
        final contentStart = innerStart + open.length;
        final contentEnd = innerEnd - close.length;
        if (contentStart <= contentEnd) {
          return (innerStart: contentStart, innerEnd: contentEnd);
        }
      }
    }
    return null;
  }

  static TextEditingValue insertGroupMention({
    required TextEditingValue value,
    required int atStartOffset,
    required String userId,
    required String label,
    required String fallbackMentionLabel,
  }) {
    final text = value.text;
    final sel = value.selection;
    final caret = sel.baseOffset.clamp(0, text.length);
    final start = atStartOffset.clamp(0, caret);
    final labelTrim = label.trim();
    final token = MentionTokenCodec.buildToken(
      userId: userId,
      label: labelTrim.isEmpty ? fallbackMentionLabel : labelTrim,
    );
    final frag = '$token ';
    final nt = text.substring(0, start) + frag + text.substring(caret);
    final off = start + frag.length;
    return TextEditingValue(
      text: nt,
      selection: TextSelection.collapsed(offset: off),
    );
  }

  static int _tagDepth(String before, RegExp openRe, RegExp closeRe) {
    return openRe.allMatches(before).length - closeRe.allMatches(before).length;
  }

  static bool isBoldActive(String text, int offset) {
    final o = offset.clamp(0, text.length);
    final b = text.substring(0, o);
    final d1 = _tagDepth(b, RegExp(r'<strong\b'), RegExp(r'</strong>'));
    final d2 = _tagDepth(b, RegExp(r'<b\b'), RegExp(r'</b>'));
    return d1 + d2 > 0;
  }

  static bool isItalicActive(String text, int offset) {
    final o = offset.clamp(0, text.length);
    final b = text.substring(0, o);
    final d1 = _tagDepth(b, RegExp(r'<em\b'), RegExp(r'</em>'));
    final d2 = _tagDepth(b, RegExp(r'<i\b'), RegExp(r'</i>'));
    return d1 + d2 > 0;
  }

  static bool isUnderlineActive(String text, int offset) {
    final o = offset.clamp(0, text.length);
    final b = text.substring(0, o);
    return _tagDepth(b, RegExp(r'<u\b'), RegExp(r'</u>')) > 0;
  }

  static bool isStrikeActive(String text, int offset) {
    final o = offset.clamp(0, text.length);
    final b = text.substring(0, o);
    final d1 = _tagDepth(b, RegExp(r'<s\b'), RegExp(r'</s>'));
    final d2 = _tagDepth(b, RegExp(r'<strike\b'), RegExp(r'</strike>'));
    final d3 = _tagDepth(b, RegExp(r'<del\b'), RegExp(r'</del>'));
    return d1 + d2 + d3 > 0;
  }

  static bool isCodeActive(String text, int offset) {
    final o = offset.clamp(0, text.length);
    final b = text.substring(0, o);
    return _tagDepth(b, RegExp(r'<code\b'), RegExp(r'</code>')) > 0;
  }

  static bool isBlockquoteActive(String text, int offset) {
    final o = offset.clamp(0, text.length);
    final b = text.substring(0, o);
    return _tagDepth(b, RegExp(r'<blockquote\b'), RegExp(r'</blockquote>')) > 0;
  }

  static bool isSpoilerActive(String text, int offset) {
    final o = offset.clamp(0, text.length);
    final b = text.substring(0, o);
    final opens = RegExp(
      r'<span[^>]*spoiler-text',
      caseSensitive: false,
    ).allMatches(b).length;
    final closes = RegExp(
      r'</span>',
      caseSensitive: false,
    ).allMatches(b).length;
    return opens > closes;
  }

  static bool isLinkActive(String text, int offset) {
    final o = offset.clamp(0, text.length);
    final b = text.substring(0, o);
    return _tagDepth(b, RegExp(r'<a\b'), RegExp(r'</a>')) > 0;
  }
}
