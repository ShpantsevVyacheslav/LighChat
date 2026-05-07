import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

/// Lightweight Markdown renderer tailored for legal documents.
///
/// Supports: ATX headings (# ##), paragraphs, blockquotes, unordered/ordered
/// lists, simple GFM tables, horizontal rules, inline `**bold**`, `*italic*`,
/// `code`, `[link](url)`. Links starting with `/legal/` are routed in-app via
/// `go_router`; everything else opens in the system browser.
class MarkdownView extends StatelessWidget {
  const MarkdownView({super.key, required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final blocks = _parseBlocks(markdown);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: blocks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _BlockWidget(block: blocks[i]),
    );
  }
}

sealed class _Block {}

class _Heading extends _Block {
  _Heading(this.level, this.text);
  final int level;
  final String text;
}

class _Paragraph extends _Block {
  _Paragraph(this.text);
  final String text;
}

class _Blockquote extends _Block {
  _Blockquote(this.text);
  final String text;
}

class _ListBlock extends _Block {
  _ListBlock(this.ordered, this.items);
  final bool ordered;
  final List<String> items;
}

class _Hr extends _Block {}

class _Table extends _Block {
  _Table(this.header, this.rows);
  final List<String> header;
  final List<List<String>> rows;
}

final _headingRe = RegExp(r'^(#{1,4})\s+(.+)$');
final _ulRe = RegExp(r'^\s*[-*]\s+(.+)$');
final _olRe = RegExp(r'^\s*\d+\.\s+(.+)$');
final _hrRe = RegExp(r'^\s*-{3,}\s*$');
final _quoteRe = RegExp(r'^>\s?(.*)$');
final _tableSepRe = RegExp(r'^\s*\|?\s*:?-+:?\s*(\|\s*:?-+:?\s*)+\|?\s*$');

List<_Block> _parseBlocks(String md) {
  final lines = md.replaceAll('\r\n', '\n').split('\n');
  final out = <_Block>[];
  var i = 0;
  while (i < lines.length) {
    final line = lines[i];
    if (line.trim().isEmpty) {
      i++;
      continue;
    }
    if (_hrRe.hasMatch(line)) {
      out.add(_Hr());
      i++;
      continue;
    }
    final h = _headingRe.firstMatch(line);
    if (h != null) {
      out.add(_Heading(h.group(1)!.length, h.group(2)!.trim()));
      i++;
      continue;
    }
    if (_quoteRe.hasMatch(line)) {
      final buf = <String>[];
      while (i < lines.length && _quoteRe.hasMatch(lines[i])) {
        buf.add(_quoteRe.firstMatch(lines[i])!.group(1)!);
        i++;
      }
      out.add(_Blockquote(buf.join(' ').trim()));
      continue;
    }
    if (_ulRe.hasMatch(line) || _olRe.hasMatch(line)) {
      final ordered = _olRe.hasMatch(line);
      final re = ordered ? _olRe : _ulRe;
      final items = <String>[];
      while (i < lines.length && re.hasMatch(lines[i])) {
        items.add(re.firstMatch(lines[i])!.group(1)!.trim());
        i++;
      }
      out.add(_ListBlock(ordered, items));
      continue;
    }
    if (line.trim().startsWith('|') &&
        i + 1 < lines.length &&
        _tableSepRe.hasMatch(lines[i + 1])) {
      final header = _splitRow(line);
      i += 2;
      final rows = <List<String>>[];
      while (i < lines.length && lines[i].trim().startsWith('|')) {
        rows.add(_splitRow(lines[i]));
        i++;
      }
      out.add(_Table(header, rows));
      continue;
    }
    final buf = <String>[];
    while (i < lines.length &&
        lines[i].trim().isNotEmpty &&
        !_headingRe.hasMatch(lines[i]) &&
        !_ulRe.hasMatch(lines[i]) &&
        !_olRe.hasMatch(lines[i]) &&
        !_quoteRe.hasMatch(lines[i]) &&
        !_hrRe.hasMatch(lines[i]) &&
        !lines[i].trim().startsWith('|')) {
      buf.add(lines[i]);
      i++;
    }
    out.add(_Paragraph(buf.join(' ').trim()));
  }
  return out;
}

List<String> _splitRow(String line) {
  final t = line.trim();
  final stripped = t
      .replaceFirst(RegExp(r'^\|'), '')
      .replaceFirst(RegExp(r'\|$'), '');
  return stripped.split('|').map((c) => c.trim()).toList();
}

class _BlockWidget extends StatelessWidget {
  const _BlockWidget({required this.block});
  final _Block block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final block = this.block;
    if (block is _Heading) {
      final style = switch (block.level) {
        1 => theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        2 => theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        3 => theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        _ => theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      };
      return Padding(
        padding: EdgeInsets.only(top: block.level == 1 ? 4 : 12, bottom: 4),
        child: _RichInline(text: block.text, baseStyle: style),
      );
    }
    if (block is _Paragraph) {
      return _RichInline(
        text: block.text,
        baseStyle: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
      );
    }
    if (block is _Blockquote) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.05),
          border: Border(
            left: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
              width: 4,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: _RichInline(
          text: block.text,
          baseStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
          ),
        ),
      );
    }
    if (block is _ListBlock) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var idx = 0; idx < block.items.length; idx++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8, top: 2),
                    child: Text(
                      block.ordered ? '${idx + 1}.' : '•',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: _RichInline(
                      text: block.items[idx],
                      baseStyle: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }
    if (block is _Hr) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Divider(),
      );
    }
    if (block is _Table) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            ),
            columns: [
              for (final h in block.header)
                DataColumn(
                  label: _RichInline(
                    text: h,
                    baseStyle: theme.textTheme.titleSmall,
                  ),
                ),
            ],
            rows: [
              for (final row in block.rows)
                DataRow(
                  cells: [
                    for (final cell in row)
                      DataCell(
                        _RichInline(
                          text: cell,
                          baseStyle: theme.textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

final _linkRe = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');
final _emphasisRe = RegExp(r'(\*\*([^*]+)\*\*|`([^`]+)`)');

class _RichInline extends StatefulWidget {
  const _RichInline({required this.text, this.baseStyle});
  final String text;
  final TextStyle? baseStyle;

  @override
  State<_RichInline> createState() => _RichInlineState();
}

class _RichInlineState extends State<_RichInline> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    final theme = Theme.of(context);
    final spans = <InlineSpan>[];
    final text = widget.text;
    var cursor = 0;
    for (final m in _linkRe.allMatches(text)) {
      if (m.start > cursor) {
        spans.addAll(_emphasisSpans(text.substring(cursor, m.start), theme));
      }
      final label = m.group(1)!;
      final href = m.group(2)!;
      final tap = TapGestureRecognizer()..onTap = () => _openLink(context, href);
      _recognizers.add(tap);
      spans.add(
        TextSpan(
          text: label,
          style: TextStyle(
            color: theme.colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
          recognizer: tap,
        ),
      );
      cursor = m.end;
    }
    if (cursor < text.length) {
      spans.addAll(_emphasisSpans(text.substring(cursor), theme));
    }
    return RichText(
      text: TextSpan(style: widget.baseStyle, children: spans),
    );
  }

  List<InlineSpan> _emphasisSpans(String text, ThemeData theme) {
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final m in _emphasisRe.allMatches(text)) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, m.start)));
      }
      if (m.group(2) != null) {
        spans.add(TextSpan(
          text: m.group(2),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ));
      } else if (m.group(3) != null) {
        spans.add(TextSpan(
          text: m.group(3),
          style: TextStyle(
            fontFamily: 'monospace',
            backgroundColor: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.6),
          ),
        ));
      }
      cursor = m.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return spans;
  }

  void _openLink(BuildContext context, String href) {
    if (href.startsWith('/legal/')) {
      final slug = href.substring('/legal/'.length);
      GoRouter.of(context).push('/legal/$slug');
      return;
    }
    if (href.startsWith('http')) {
      launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
    }
  }
}
