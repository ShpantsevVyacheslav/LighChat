import 'package:flutter/services.dart';

import '../ui/message_html_text.dart';
import 'sanitize_message_html.dart';

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
    final plainCheck = messageHtmlToPlainText(trimmedRight).trim();
    if (plainCheck.isEmpty && !trimmedRight.contains('<')) {
      return '';
    }
    final String body;
    if (_looksLikeHtml(trimmedRight)) {
      body = ensureOuterWrapper(trimmedRight.trim());
    } else {
      body = plainTextToParagraphHtml(trimmedRight.trim());
    }
    return sanitizeMessageHtml(body);
  }

  static TextEditingValue toggleInline(
    String text,
    TextSelection sel,
    String open,
    String close,
  ) {
    final s = sel.start;
    final e = sel.end;
    if (s < 0 || e < 0 || s > e || e > text.length) {
      return TextEditingValue(text: text, selection: sel);
    }
    if (s >= open.length &&
        e + close.length <= text.length &&
        text.substring(s - open.length, s) == open &&
        text.substring(e, e + close.length) == close) {
      final inner = text.substring(s, e);
      final nt =
          text.substring(0, s - open.length) + inner + text.substring(e + close.length);
      final off = s - open.length + inner.length;
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
    final u = url.trim();
    final s = sel.start;
    final e = sel.end;
    if (s < 0 || e < 0 || s > text.length || e > text.length) {
      return TextEditingValue(text: text, selection: sel);
    }
    if (u.isEmpty) {
      return TextEditingValue(text: text, selection: sel);
    }
    final hrefEsc = escapeHtmlAttribute(u);
    final label = s == e
        ? escapeHtmlText(u)
        : escapeHtmlText(text.substring(s, e));
    final frag = '<a href="$hrefEsc">$label</a>';
    final nt = text.substring(0, s) + frag + text.substring(e);
    return TextEditingValue(
      text: nt,
      selection: TextSelection.collapsed(offset: s + frag.length),
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
    return _tagDepth(b, RegExp(r'<blockquote\b'), RegExp(r'</blockquote>')) >
        0;
  }

  static bool isSpoilerActive(String text, int offset) {
    final o = offset.clamp(0, text.length);
    final b = text.substring(0, o);
    final opens =
        RegExp(r'<span[^>]*spoiler-text', caseSensitive: false).allMatches(b).length;
    final closes = RegExp(r'</span>', caseSensitive: false).allMatches(b).length;
    return opens > closes;
  }

  static bool isLinkActive(String text, int offset) {
    final o = offset.clamp(0, text.length);
    final b = text.substring(0, o);
    return _tagDepth(b, RegExp(r'<a\b'), RegExp(r'</a>')) > 0;
  }
}
