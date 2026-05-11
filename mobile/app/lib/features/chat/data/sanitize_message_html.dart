import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// Паритет `src/lib/sanitize-message-html.ts` (DOMPurify allowlist).
const _allowedTags = <String>{
  'p',
  'br',
  'strong',
  'b',
  'em',
  'i',
  'u',
  's',
  'strike',
  'del',
  'a',
  'ul',
  'ol',
  'li',
  'blockquote',
  'code',
  'pre',
  'span',
  'div',
  'h1',
  'h2',
  'h3',
  'h4',
};

bool _attrAllowed(String tag, String attrLower) {
  if (attrLower.startsWith('on') || attrLower == 'style') return false;
  if (attrLower == 'class') return true;
  switch (tag) {
    case 'a':
      return {'href', 'title', 'target', 'rel'}.contains(attrLower);
    case 'span':
      return attrLower == 'data-chat-mention' ||
          attrLower == 'data-user-id' ||
          attrLower == 'data-chat-custom-emoji' ||
          attrLower == 'data-emoji-id' ||
          attrLower == 'data-emoji-src';
    default:
      return false;
  }
}

void _unwrapElement(dom.Element el) {
  final parent = el.parent;
  if (parent == null) {
    el.remove();
    return;
  }
  while (el.nodes.isNotEmpty) {
    parent.insertBefore(el.nodes.first, el);
  }
  el.remove();
}

void _filterAttributes(dom.Element el) {
  final tag = el.localName?.toLowerCase() ?? '';
  final remove = <String>[];
  for (final k in el.attributes.keys.map((k) => k.toString()).toList()) {
    final a = k.toLowerCase();
    if (!_attrAllowed(tag, a)) {
      remove.add(k);
    }
  }
  for (final k in remove) {
    el.attributes.remove(k);
  }
  if (tag == 'a') {
    final href = (el.attributes['href'] ?? '').trim().toLowerCase();
    if (href.startsWith('javascript:') || href.startsWith('data:')) {
      el.attributes.remove('href');
    }
  }
}

void _sanitizeNode(dom.Node parent) {
  for (var i = 0; i < parent.nodes.length;) {
    final child = parent.nodes[i];
    if (child is dom.Comment) {
      child.remove();
      continue;
    }
    if (child is! dom.Element) {
      i++;
      continue;
    }
    final el = child;
    final tag = el.localName?.toLowerCase() ?? '';
    if (tag == 'script' ||
        tag == 'iframe' ||
        tag == 'object' ||
        tag == 'embed') {
      el.remove();
      continue;
    }
    if (!_allowedTags.contains(tag)) {
      _unwrapElement(el);
      continue;
    }
    _filterAttributes(el);
    _sanitizeNode(el);
    i++;
  }
}

/// Санитизация HTML перед отправкой и (опционально) перед рендером.
String sanitizeMessageHtml(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  try {
    final frag = html_parser.parseFragment(raw);
    _sanitizeNode(frag);
    return frag.outerHtml.trim();
  } catch (_) {
    return '';
  }
}
