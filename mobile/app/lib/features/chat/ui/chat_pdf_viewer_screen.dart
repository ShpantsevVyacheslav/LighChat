import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ChatPdfViewerScreen extends StatefulWidget {
  const ChatPdfViewerScreen({
    super.key,
    required this.uri,
    required this.title,
  });

  final Uri uri;
  final String title;

  static void open(
    BuildContext context, {
    required Uri uri,
    required String title,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatPdfViewerScreen(uri: uri, title: title),
      ),
    );
  }

  @override
  State<ChatPdfViewerScreen> createState() => _ChatPdfViewerScreenState();
}

class _ChatPdfViewerScreenState extends State<ChatPdfViewerScreen> {
  final PdfViewerController _controller = PdfViewerController();
  PdfAnnotationMode _annotationMode = PdfAnnotationMode.none;
  bool _showMarkupTools = false;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setAnnotationMode(PdfAnnotationMode mode) {
    setState(() {
      _annotationMode = mode;
      _controller.annotationMode = mode;
    });
  }

  Future<void> _exportAnnotatedCopy() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _controller.saveDocument();
      final tmp = await getTemporaryDirectory();
      final name = _suggestOutputName(widget.title);
      final file = File('${tmp.path}/$name');
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(files: <XFile>[XFile(file.path)]),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сохранить копию PDF')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _suggestOutputName(String input) {
    final trimmed = input.trim().isEmpty ? 'document.pdf' : input.trim();
    final dot = trimmed.lastIndexOf('.');
    if (dot <= 0) return '${trimmed}_annotated.pdf';
    final base = trimmed.substring(0, dot);
    return '${base}_annotated.pdf';
  }

  Future<void> _shareOriginalLinkOrFile() async {
    if (widget.uri.isScheme('file')) {
      await SharePlus.instance.share(
        ShareParams(files: <XFile>[XFile(widget.uri.toFilePath())]),
      );
      return;
    }
    await SharePlus.instance.share(ShareParams(text: widget.uri.toString()));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              title: widget.title,
              busy: _busy,
              showMarkupTools: _showMarkupTools,
              onClose: () => Navigator.of(context).pop(),
              onToggleMarkup: () {
                setState(() => _showMarkupTools = !_showMarkupTools);
              },
              onShare: _shareOriginalLinkOrFile,
              onExportAnnotated: _exportAnnotatedCopy,
            ),
            if (_showMarkupTools) _buildMarkupToolbar(scheme),
            Expanded(child: _buildPdfView()),
            _BottomBar(
              busy: _busy,
              onZoomOut: () {
                final next = (_controller.zoomLevel - 0.25).clamp(1.0, 5.0);
                _controller.zoomLevel = next;
              },
              onZoomIn: () {
                final next = (_controller.zoomLevel + 0.25).clamp(1.0, 5.0);
                _controller.zoomLevel = next;
              },
              onExportAnnotated: _exportAnnotatedCopy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfView() {
    final uri = widget.uri;
    if (uri.isScheme('file')) {
      return SfPdfViewer.file(
        File(uri.toFilePath()),
        controller: _controller,
        canShowScrollHead: true,
        canShowScrollStatus: true,
      );
    }
    if (uri.isScheme('http') || uri.isScheme('https')) {
      return SfPdfViewer.network(
        uri.toString(),
        controller: _controller,
        canShowScrollHead: true,
        canShowScrollStatus: true,
      );
    }
    return const Center(
      child: Text(
        'Неподдерживаемый источник PDF',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildMarkupToolbar(ColorScheme scheme) {
    Widget modeButton({
      required String title,
      required PdfAnnotationMode mode,
      required IconData icon,
    }) {
      final selected = _annotationMode == mode;
      return ChoiceChip(
        selected: selected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(title),
          ],
        ),
        onSelected: (_) => _setAnnotationMode(mode),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        border: Border(
          bottom: BorderSide(color: scheme.outline.withValues(alpha: 0.35)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            modeButton(
              title: 'Курсор',
              mode: PdfAnnotationMode.none,
              icon: Icons.touch_app_outlined,
            ),
            const SizedBox(width: 8),
            modeButton(
              title: 'Highlight',
              mode: PdfAnnotationMode.highlight,
              icon: Icons.highlight_alt_outlined,
            ),
            const SizedBox(width: 8),
            modeButton(
              title: 'Underline',
              mode: PdfAnnotationMode.underline,
              icon: Icons.format_underline,
            ),
            const SizedBox(width: 8),
            modeButton(
              title: 'Strike',
              mode: PdfAnnotationMode.strikethrough,
              icon: Icons.strikethrough_s,
            ),
            const SizedBox(width: 8),
            modeButton(
              title: 'Squiggly',
              mode: PdfAnnotationMode.squiggly,
              icon: Icons.gesture_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.busy,
    required this.showMarkupTools,
    required this.onClose,
    required this.onToggleMarkup,
    required this.onShare,
    required this.onExportAnnotated,
  });

  final String title;
  final bool busy;
  final bool showMarkupTools;
  final VoidCallback onClose;
  final VoidCallback onToggleMarkup;
  final Future<void> Function() onShare;
  final Future<void> Function() onExportAnnotated;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(color: scheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Закрыть',
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Разметка',
            onPressed: onToggleMarkup,
            icon: Icon(
              showMarkupTools ? Icons.edit_note : Icons.edit_outlined,
              color: Colors.white,
            ),
          ),
          PopupMenuButton<_PdfMenuAction>(
            iconColor: Colors.white,
            enabled: !busy,
            onSelected: (action) async {
              switch (action) {
                case _PdfMenuAction.shareOriginal:
                  await onShare();
                  return;
                case _PdfMenuAction.exportAnnotated:
                  await onExportAnnotated();
                  return;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _PdfMenuAction.shareOriginal,
                child: Text('Поделиться'),
              ),
              PopupMenuItem(
                value: _PdfMenuAction.exportAnnotated,
                child: Text('Сохранить копию с разметкой'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.busy,
    required this.onZoomOut,
    required this.onZoomIn,
    required this.onExportAnnotated,
  });

  final bool busy;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;
  final Future<void> Function() onExportAnnotated;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: scheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Уменьшить',
            onPressed: onZoomOut,
            icon: const Icon(Icons.zoom_out, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Увеличить',
            onPressed: onZoomIn,
            icon: const Icon(Icons.zoom_in, color: Colors.white),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: busy ? null : onExportAnnotated,
            icon: const Icon(Icons.save_alt_rounded),
            label: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}

enum _PdfMenuAction { shareOriginal, exportAnnotated }
