import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/composer_html_editing.dart';
import 'composer_link_sheet.dart';

/// Панель «Форматирование» (паритет `FormattingToolbar.tsx`).
class ComposerFormattingToolbar extends StatefulWidget {
  const ComposerFormattingToolbar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onBack,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onBack;

  @override
  State<ComposerFormattingToolbar> createState() =>
      _ComposerFormattingToolbarState();
}

class _ComposerFormattingToolbarState extends State<ComposerFormattingToolbar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onCtrl);
  }

  @override
  void didUpdateWidget(covariant ComposerFormattingToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onCtrl);
      widget.controller.addListener(_onCtrl);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCtrl);
    super.dispose();
  }

  void _onCtrl() {
    if (mounted) setState(() {});
  }

  void _apply(TextEditingValue next) {
    widget.controller.value = next;
    widget.focusNode.requestFocus();
  }

  Future<void> _linkDialog() async {
    final url = await showComposerLinkSheet(context);
    if (!mounted || url == null || url.trim().isEmpty) return;
    _apply(
      ComposerHtmlEditing.applyLink(
        widget.controller.text,
        widget.controller.selection,
        url,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fg = Colors.white.withValues(alpha: 0.88);
    final text = widget.controller.text;
    final sel = widget.controller.selection;
    final off = sel.isValid ? sel.extentOffset : text.length;

    Widget cell({
      required Widget child,
      required VoidCallback onTap,
      bool active = false,
    }) {
      final primary = Theme.of(context).colorScheme.primary;
      return Material(
        color: active
            ? primary.withValues(alpha: 0.38)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withValues(alpha: 0.12),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: active
                  ? Border.all(
                      color: primary.withValues(alpha: 0.85),
                      width: 1.5,
                    )
                  : null,
            ),
            child: Center(child: child),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.38),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'ФОРМАТИРОВАНИЕ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: fg.withValues(alpha: 0.65),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: widget.onBack,
                    icon: Icon(Icons.arrow_back_rounded, size: 20, color: fg),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: cell(
                          active: ComposerHtmlEditing.isBoldActive(text, off),
                          child: Text(
                            'B',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: fg,
                            ),
                          ),
                          onTap: () => _apply(
                            ComposerHtmlEditing.toggleInline(
                              text,
                              sel,
                              '<strong>',
                              '</strong>',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: cell(
                          active: ComposerHtmlEditing.isItalicActive(text, off),
                          child: Text(
                            'I',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: fg,
                            ),
                          ),
                          onTap: () => _apply(
                            ComposerHtmlEditing.toggleInline(
                              text,
                              sel,
                              '<em>',
                              '</em>',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: cell(
                          active:
                              ComposerHtmlEditing.isUnderlineActive(text, off),
                          child: Text(
                            'U',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: fg,
                            ),
                          ),
                          onTap: () => _apply(
                            ComposerHtmlEditing.toggleInline(
                              text,
                              sel,
                              '<u>',
                              '</u>',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: cell(
                          active: ComposerHtmlEditing.isStrikeActive(text, off),
                          child: Text(
                            'S',
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: fg,
                            ),
                          ),
                          onTap: () => _apply(
                            ComposerHtmlEditing.toggleInline(
                              text,
                              sel,
                              '<s>',
                              '</s>',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: cell(
                          active: ComposerHtmlEditing.isLinkActive(text, off),
                          child: Icon(Icons.link_rounded, color: fg, size: 22),
                          onTap: _linkDialog,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: cell(
                          active:
                              ComposerHtmlEditing.isSpoilerActive(text, off),
                          child: Icon(
                            Icons.visibility_off_rounded,
                            color: fg,
                            size: 22,
                          ),
                          onTap: () => _apply(
                            ComposerHtmlEditing.toggleInline(
                              text,
                              sel,
                              '<span class="spoiler-text">',
                              '</span>',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: cell(
                          active: ComposerHtmlEditing.isCodeActive(text, off),
                          child: Text(
                            '#',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              color: fg,
                              fontFamily: 'monospace',
                            ),
                          ),
                          onTap: () => _apply(
                            ComposerHtmlEditing.toggleInline(
                              text,
                              sel,
                              '<code>',
                              '</code>',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: cell(
                          active: ComposerHtmlEditing.isBlockquoteActive(
                            text,
                            off,
                          ),
                          child: Text(
                            '”',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              color: fg,
                            ),
                          ),
                          onTap: () => _apply(
                            ComposerHtmlEditing.toggleBlockquote(text, sel),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
