import 'dart:async' show unawaited;
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:url_launcher/url_launcher.dart';

import '../data/chat_link_normalization.dart';
import '../data/link_preview_url_extractor.dart';

String messageHtmlToPlainText(String input) {
  var s = input;
  s = s.replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'</div\s*>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'</li\s*>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'<li\s*>', caseSensitive: false), '• ');
  s = s.replaceAll(RegExp(r'<[^>]+>'), '');
  s = s
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&#x27;', "'");
  s = s.replaceAll(RegExp(r'\r\n?'), '\n');
  s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return s.trim();
}

/// Параметры отрисовки HTML в пузырьке (ссылки, цитаты).
class MessageHtmlRenderOpts {
  const MessageHtmlRenderOpts({
    this.linkColor,
    this.quoteAccent,
    this.quoteMaxWidth = 280,
    this.onMentionTap,
    this.mentionLabelResolver,
    this.onLinkTap,
    this.mentionFallbackLabel,
  });

  final Color? linkColor;
  final Color? quoteAccent;
  final double quoteMaxWidth;
  final Future<void> Function(String userId)? onMentionTap;
  final String Function(String userId, String fallbackLabel)?
  mentionLabelResolver;
  final void Function(String url)? onLinkTap;

  /// Localized fallback label for mentions without a name (e.g. "участник").
  final String? mentionFallbackLabel;

  static const defaults = MessageHtmlRenderOpts();
}

class _ComposeStyle {
  const _ComposeStyle({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.code = false,
    this.quote = false,
    this.linkHref,
    this.mention = false,
    this.mentionUserId,
  });

  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final bool code;
  final bool quote;
  final String? linkHref;
  final bool mention;
  final String? mentionUserId;

  _ComposeStyle copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strike,
    bool? code,
    bool? quote,
    String? linkHref,
    bool clearLink = false,
    bool? mention,
    String? mentionUserId,
    bool clearMentionUserId = false,
  }) {
    return _ComposeStyle(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strike: strike ?? this.strike,
      code: code ?? this.code,
      quote: quote ?? this.quote,
      linkHref: clearLink ? null : (linkHref ?? this.linkHref),
      mention: mention ?? this.mention,
      mentionUserId: clearMentionUserId
          ? null
          : (mentionUserId ?? this.mentionUserId),
    );
  }

  TextStyle toTextStyle(TextStyle base, MessageHtmlRenderOpts opts) {
    final hasLink = linkHref != null && linkHref!.isNotEmpty;
    var s = base;
    if (bold) s = s.copyWith(fontWeight: FontWeight.w800);
    if (italic) s = s.copyWith(fontStyle: FontStyle.italic);
    if (code) {
      s = s.copyWith(fontFamily: 'monospace');
    }

    if (hasLink) {
      final lc = opts.linkColor ?? const Color(0xFF7DD3FC);
      final decos = <TextDecoration>[TextDecoration.underline];
      if (strike) {
        decos.add(TextDecoration.lineThrough);
      } else if (underline) {
        decos.add(TextDecoration.underline);
      }
      return s.copyWith(
        color: lc,
        decoration: TextDecoration.combine(decos),
        decorationColor: lc.withValues(alpha: 0.9),
      );
    }

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
    if (mention) {
      s = s.copyWith(
        color: const Color(0xFF38BDF8),
        fontWeight: FontWeight.w700,
      );
    }
    return s;
  }
}

bool _classListContains(dom.Element el, String token) {
  final raw = el.attributes['class'];
  if (raw == null || raw.isEmpty) return false;
  return raw.split(RegExp(r'\s+')).contains(token);
}

String _flattenText(dom.Node n) {
  if (n is dom.Text) {
    return n.text;
  }
  if (n is dom.Element) {
    return n.nodes.map(_flattenText).join();
  }
  return '';
}

Future<void> _openExternalUrl(String href) async {
  final u = tryParseHttpChatLink(href);
  if (u == null) return;
  await launchUrl(u, mode: LaunchMode.externalApplication);
}

List<InlineSpan> _plainTextToLinkSpans(
  String text,
  TextStyle base, {
  Color? linkColor,
  void Function(String url)? onLinkTap,
}) {
  final out = <InlineSpan>[];
  final matches = findUrlMatches(text);
  var i = 0;
  for (final m in matches) {
    if (m.start > i) {
      out.add(TextSpan(text: text.substring(i, m.start), style: base));
    }
    final lc = linkColor ?? const Color(0xFF7DD3FC);
    final linkTap = onLinkTap;
    final url = m.normalized;
    final rec = TapGestureRecognizer()
      ..onTap = () {
        if (linkTap != null) {
          linkTap(url);
        } else {
          unawaited(_openExternalUrl(url));
        }
      };
    out.add(
      TextSpan(
        text: m.original,
        style: base.copyWith(
          color: lc,
          decoration: TextDecoration.underline,
          decorationColor: lc.withValues(alpha: 0.9),
        ),
        recognizer: rec,
      ),
    );
    i = m.end;
  }
  if (i < text.length) {
    out.add(TextSpan(text: text.substring(i), style: base));
  }
  return out;
}

List<InlineSpan> messageHtmlToStyledSpans(
  String input, {
  required TextStyle base,
  Color? linkColor,
  Color? quoteAccent,
  double quoteMaxWidth = 280,
  Future<void> Function(String userId)? onMentionTap,
  String Function(String userId, String fallbackLabel)? mentionLabelResolver,
  void Function(String url)? onLinkTap,
  String? mentionFallbackLabel,
}) {
  if (input.trim().isEmpty) return const [];
  if (!input.contains('<')) {
    return _plainTextToLinkSpans(
      input,
      base,
      linkColor: linkColor,
      onLinkTap: onLinkTap,
    );
  }
  try {
    final frag = html_parser.parseFragment(input);
    final opts = MessageHtmlRenderOpts(
      linkColor: linkColor,
      quoteAccent: quoteAccent,
      quoteMaxWidth: quoteMaxWidth,
      onMentionTap: onMentionTap,
      mentionLabelResolver: mentionLabelResolver,
      onLinkTap: onLinkTap,
      mentionFallbackLabel: mentionFallbackLabel,
    );
    final spans = _nodesToSpans(frag.nodes, base, const _ComposeStyle(), opts);
    return _trimTrailingLineBreaks(spans);
  } catch (_) {
    return [TextSpan(text: messageHtmlToPlainText(input), style: base)];
  }
}

List<InlineSpan> _trimTrailingLineBreaks(List<InlineSpan> spans) {
  if (spans.isEmpty) return spans;

  final out = List<InlineSpan>.from(spans);
  while (out.isNotEmpty) {
    final last = out.last;
    if (last is! TextSpan) break;
    if (last.children != null && last.children!.isNotEmpty) break;

    final t = last.text ?? '';
    if (t.isEmpty) {
      out.removeLast();
      continue;
    }

    // Remove trailing line breaks that create an "empty line" at the bottom
    // of the message bubble.
    final trimmed = t.replaceFirst(RegExp(r'[\n\r]+$'), '');
    if (trimmed == t) break;

    if (trimmed.isEmpty) {
      out.removeLast();
      continue;
    }

    out[out.length - 1] = TextSpan(
      text: trimmed,
      style: last.style,
      recognizer: last.recognizer,
      mouseCursor: last.mouseCursor,
      onEnter: last.onEnter,
      onExit: last.onExit,
      semanticsLabel: last.semanticsLabel,
      locale: last.locale,
      spellOut: last.spellOut,
    );
    break;
  }
  return out;
}

List<InlineSpan> _nodesToSpans(
  List<dom.Node> nodes,
  TextStyle base,
  _ComposeStyle st,
  MessageHtmlRenderOpts opts,
) {
  final out = <InlineSpan>[];
  for (final n in nodes) {
    if (n is dom.Text) {
      final t = n.text;
      if (t.isEmpty) continue;
      final display = st.quote
          ? t
                .split('\n')
                .map((line) => line.isEmpty ? line : '▌ $line')
                .join('\n')
          : t;
      final style = st.toTextStyle(base, opts);
      TapGestureRecognizer? rec;
      final href = st.linkHref;
      if (href != null && href.isNotEmpty) {
        final linkTap = opts.onLinkTap;
        rec = TapGestureRecognizer()
          ..onTap = () {
            if (linkTap != null) {
              linkTap(href);
            } else {
              unawaited(_openExternalUrl(href));
            }
          };
      } else {
        final mid = st.mentionUserId;
        final onMentionTap = opts.onMentionTap;
        if (mid != null && mid.isNotEmpty && onMentionTap != null) {
          rec = TapGestureRecognizer()
            ..onTap = () {
              unawaited(onMentionTap(mid));
            };
        }
      }
      if (rec == null && !st.mention && display.contains('.')) {
        out.addAll(
          _plainTextToLinkSpans(
            display,
            style,
            linkColor: opts.linkColor,
            onLinkTap: opts.onLinkTap,
          ),
        );
      } else {
        out.add(TextSpan(text: display, style: style, recognizer: rec));
      }
    } else if (n is dom.Element) {
      out.addAll(_elementToSpans(n, base, st, opts));
    }
  }
  return out;
}

List<InlineSpan> _elementToSpans(
  dom.Element el,
  TextStyle base,
  _ComposeStyle st,
  MessageHtmlRenderOpts opts,
) {
  final tag = el.localName?.toLowerCase() ?? '';

  if (tag == 'br') {
    return [TextSpan(text: '\n', style: st.toTextStyle(base, opts))];
  }

  if (tag == 'span' && _classListContains(el, 'spoiler-text')) {
    final inner = _flattenText(el);
    return [
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: _SpoilerInline(text: inner, style: st.toTextStyle(base, opts)),
      ),
    ];
  }

  if (tag == 'p' || tag == 'div') {
    final inner = _nodesToSpans(el.nodes, base, st, opts);
    if (inner.isEmpty) return const [];
    return [...inner, TextSpan(text: '\n', style: base)];
  }

  if (tag == 'blockquote') {
    final accent = opts.quoteAccent ?? const Color(0xFF38BDF8);
    final inner = _nodesToSpans(
      el.nodes,
      base,
      st.copyWith(quote: false),
      opts,
    );
    return [
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.20),
                  Colors.white.withValues(alpha: 0.06),
                  accent.withValues(alpha: 0.08),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: opts.quoteMaxWidth),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 3,
                      constraints: const BoxConstraints(minHeight: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [accent, accent.withValues(alpha: 0.35)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: RichText(
                        text: TextSpan(children: inner, style: base),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  if (tag == 'strong' || tag == 'b') {
    return _nodesToSpans(el.nodes, base, st.copyWith(bold: true), opts);
  }
  if (tag == 'em' || tag == 'i') {
    return _nodesToSpans(el.nodes, base, st.copyWith(italic: true), opts);
  }
  if (tag == 'u') {
    return _nodesToSpans(el.nodes, base, st.copyWith(underline: true), opts);
  }
  if (tag == 's' || tag == 'strike' || tag == 'del') {
    return _nodesToSpans(el.nodes, base, st.copyWith(strike: true), opts);
  }
  if (tag == 'code') {
    return _nodesToSpans(el.nodes, base, st.copyWith(code: true), opts);
  }
  if (tag == 'pre') {
    final t = el.text;
    if (t.isEmpty) return const [];
    return [
      TextSpan(
        text: t,
        style: st.toTextStyle(base, opts).copyWith(fontFamily: 'monospace'),
      ),
    ];
  }

  if (tag == 'a') {
    final href = normalizeChatLinkUrl(el.attributes['href'] ?? '');
    return _nodesToSpans(
      el.nodes,
      base,
      st.copyWith(linkHref: href, clearLink: false),
      opts,
    );
  }

  if (tag == 'span' && el.attributes.containsKey('data-chat-custom-emoji')) {
    final src = (el.attributes['data-emoji-src'] ?? '').trim();
    final fallbackRaw = _flattenText(el).trim();
    final fallback = fallbackRaw.isNotEmpty ? fallbackRaw : '🙂';
    final textStyle = st.toTextStyle(base, opts);
    if (src.isEmpty) {
      return [TextSpan(text: fallback, style: textStyle)];
    }
    final rawFont = textStyle.fontSize ?? base.fontSize ?? 16;
    final size = (rawFont * 1.35).clamp(16.0, 28.0).toDouble();
    return [
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.5),
          child: SizedBox(
            width: size,
            height: size,
            child: CachedNetworkImage(
              imageUrl: src,
              fit: BoxFit.contain,
              placeholder: (_, _) => const SizedBox.shrink(),
              errorWidget: (_, _, _) =>
                  Center(child: Text(fallback, style: textStyle)),
            ),
          ),
        ),
      ),
    ];
  }

  if (tag == 'span' &&
      (el.attributes.containsKey('data-chat-mention') ||
          el.attributes.containsKey('data-user-id'))) {
    final uid =
        (el.attributes['data-user-id'] ??
                el.attributes['data-chat-mention'] ??
                '')
            .trim();
    final rawLabel = _flattenText(el).trim();
    final fallbackLabel = rawLabel.replaceFirst(RegExp(r'^@+'), '').trim();
    final resolvedRaw =
        opts.mentionLabelResolver?.call(uid, fallbackLabel) ?? fallbackLabel;
    final resolved = resolvedRaw.replaceFirst(RegExp(r'^@+'), '').trim();
    final display = resolved.isNotEmpty
        ? resolved
        : (fallbackLabel.isNotEmpty
              ? fallbackLabel
              : (opts.mentionFallbackLabel ?? 'member'));
    final style = st
        .copyWith(mention: true, mentionUserId: uid, clearMentionUserId: false)
        .toTextStyle(base, opts);
    final onMentionTap = opts.onMentionTap;
    TapGestureRecognizer? rec;
    if (uid.isNotEmpty && onMentionTap != null) {
      rec = TapGestureRecognizer()
        ..onTap = () {
          unawaited(onMentionTap(uid));
        };
    }
    return [TextSpan(text: '@$display', style: style, recognizer: rec)];
  }

  if (tag == 'li') {
    return [
      const TextSpan(text: '• '),
      ..._nodesToSpans(el.nodes, base, st, opts),
      const TextSpan(text: '\n'),
    ];
  }

  if (tag == 'ul') {
    return _nodesToSpans(el.nodes, base, st, opts);
  }

  if (tag == 'ol') {
    final out = <InlineSpan>[];
    var itemNumber = 1;
    for (final n in el.nodes) {
      if (n is dom.Element && (n.localName?.toLowerCase() ?? '') == 'li') {
        out.add(
          TextSpan(text: '$itemNumber. ', style: st.toTextStyle(base, opts)),
        );
        out.addAll(_nodesToSpans(n.nodes, base, st, opts));
        out.add(const TextSpan(text: '\n'));
        itemNumber += 1;
      } else {
        out.addAll(_nodesToSpans([n], base, st, opts));
      }
    }
    return out;
  }

  if (tag == 'h1' || tag == 'h2' || tag == 'h3' || tag == 'h4') {
    final scale = switch (tag) {
      'h1' => 1.25,
      'h2' => 1.15,
      _ => 1.08,
    };
    return _nodesToSpans(
      el.nodes,
      base.copyWith(fontSize: (base.fontSize ?? 15) * scale),
      st.copyWith(bold: true),
      opts,
    );
  }

  return _nodesToSpans(el.nodes, base, st, opts);
}

class _SpoilerInline extends StatefulWidget {
  const _SpoilerInline({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_SpoilerInline> createState() => _SpoilerInlineState();
}

class _SpoilerInlineState extends State<_SpoilerInline> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    if (_revealed) {
      return Text(widget.text, style: widget.style);
    }
    return GestureDetector(
      onTap: () => setState(() => _revealed = true),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ColoredBox(
          color: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            alignment: Alignment.centerLeft,
            children: [
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 16),
                child: Text(
                  widget.text,
                  style: widget.style.copyWith(
                    color:
                        widget.style.color?.withValues(alpha: 0.92) ??
                        Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.52),
                          const Color(0xFFBFDBFE).withValues(alpha: 0.45),
                          Colors.white.withValues(alpha: 0.48),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
