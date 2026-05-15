import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../data/chat_haptics.dart';
import '../data/document_scanner.dart';

/// Экран превью отсканированных страниц перед отправкой.
///
/// Возможности:
///  - Удалить страницу (свайп / × в углу)
///  - Переупорядочить (drag-and-drop)
///  - Снять заново (тап на странице → запускает сканер для этой страницы)
///  - Добавить ещё страницы (плюс-tile в конце)
///  - Отменить / отправить N страниц
///
/// Возвращает финальный список путей. Если пользователь отменил —
/// возвращает пустой список; вызывающий код сам решает что делать со
/// старыми временными файлами.
/// Результат preview-экрана: либо одни и те же страницы изображений,
/// либо склеенный PDF (если юзер не выключил toggle «Отправить как
/// PDF»). PDF — это **один** файл, содержащий все страницы в
/// исходном порядке.
class DocumentScanResult {
  const DocumentScanResult({required this.paths, required this.isPdf});
  final List<String> paths;
  final bool isPdf;

  bool get isEmpty => paths.isEmpty;
}

class DocumentScannerPreviewScreen extends StatefulWidget {
  const DocumentScannerPreviewScreen({
    super.key,
    required this.initialPaths,
  });

  final List<String> initialPaths;

  static Future<DocumentScanResult?> open(
    BuildContext context, {
    required List<String> initialPaths,
  }) {
    return Navigator.of(context).push<DocumentScanResult>(
      MaterialPageRoute(
        builder: (_) =>
            DocumentScannerPreviewScreen(initialPaths: initialPaths),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<DocumentScannerPreviewScreen> createState() =>
      _DocumentScannerPreviewScreenState();
}

class _DocumentScannerPreviewScreenState
    extends State<DocumentScannerPreviewScreen> {
  late List<String> _paths;
  bool _sendAsPdf = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _paths = [...widget.initialPaths];
  }

  void _delete(int index) {
    if (index < 0 || index >= _paths.length) return;
    unawaited(ChatHaptics.instance.warning());
    setState(() => _paths.removeAt(index));
  }

  void _reorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    setState(() {
      final item = _paths.removeAt(oldIndex);
      _paths.insert(newIndex, item);
    });
    unawaited(ChatHaptics.instance.selectionChanged());
  }

  Future<void> _addMore() async {
    final more = await DocumentScanner.instance.scan();
    if (!mounted || more.isEmpty) return;
    setState(() => _paths.addAll(more));
    unawaited(ChatHaptics.instance.tick());
  }

  Future<void> _retake(int index) async {
    final more = await DocumentScanner.instance.scan();
    if (!mounted || more.isEmpty) return;
    setState(() {
      // Заменяем эту страницу первой из новых, остальные — после.
      _paths[index] = more.first;
      _paths.insertAll(index + 1, more.skip(1));
    });
    unawaited(ChatHaptics.instance.tick());
  }

  void _cancel() {
    Navigator.of(context).pop<DocumentScanResult>(
      const DocumentScanResult(paths: [], isPdf: false),
    );
  }

  Future<void> _send() async {
    if (_busy || _paths.isEmpty) return;
    if (!_sendAsPdf) {
      unawaited(ChatHaptics.instance.success());
      Navigator.of(context).pop<DocumentScanResult>(
        DocumentScanResult(paths: List.of(_paths), isPdf: false),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      // Имя по умолчанию — `scan_YYYYMMDD_HHmm.pdf`, как пользователи
      // привыкли от Files / Notes сканеров.
      final now = DateTime.now();
      String two(int v) => v.toString().padLeft(2, '0');
      final filename =
          'scan_${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}.pdf';
      final pdfPath = await DocumentScanner.instance.imagesToPdf(
        _paths,
        filename: filename,
      );
      if (!mounted) return;
      if (pdfPath == null) {
        // PDF build failed — fall back на отправку изображений, чтобы
        // юзер не остался ни с чем.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.scanner_pdf_failed_fallback,
            ),
          ),
        );
        unawaited(ChatHaptics.instance.warning());
        Navigator.of(context).pop<DocumentScanResult>(
          DocumentScanResult(paths: List.of(_paths), isPdf: false),
        );
        return;
      }
      unawaited(ChatHaptics.instance.success());
      Navigator.of(context).pop<DocumentScanResult>(
        DocumentScanResult(paths: [pdfPath], isPdf: true),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1116) : const Color(0xFFF5F6F8);
    final fg = isDark ? Colors.white : const Color(0xFF14161A);
    final fgMuted = isDark
        ? const Color(0xFFA0A4AD)
        : const Color(0xFF5C6470);
    final cardBg = isDark ? const Color(0xFF1E2127) : Colors.white;
    final accent = const Color(0xFF7C8DFF);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: fg),
          onPressed: _cancel,
        ),
        title: Text(
          l10n.scanner_preview_title(_paths.length),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: fg,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l10n.scanner_preview_add,
            onPressed: _addMore,
            icon: Icon(Icons.add_a_photo_rounded, color: accent),
          ),
        ],
      ),
      body: _paths.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.document_scanner_outlined,
                      size: 64,
                      color: fgMuted.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.scanner_preview_empty,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: fgMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              itemCount: _paths.length,
              onReorder: _reorder,
              proxyDecorator: (child, _, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (ctx, _) {
                    final lifted = (animation.value * 0.04 + 1.0);
                    return Transform.scale(
                      scale: lifted,
                      child: Material(
                        elevation: 8,
                        color: Colors.transparent,
                        shadowColor: accent.withValues(alpha: 0.4),
                        child: child,
                      ),
                    );
                  },
                );
              },
              itemBuilder: (context, i) {
                final path = _paths[i];
                return Padding(
                  key: ValueKey(path),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PageTile(
                    pageNumber: i + 1,
                    path: path,
                    cardBg: cardBg,
                    fg: fg,
                    fgMuted: fgMuted,
                    onDelete: () => _delete(i),
                    onRetake: () => _retake(i),
                  ),
                );
              },
            ),
      bottomNavigationBar: _paths.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Toggle «PDF (1 файл) vs изображения (N файлов)».
                    // Default ON: документ-сканер чаще всего нужен для
                    // pdf-документов, так привычнее по UX.
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 20,
                            color: fg.withValues(alpha: 0.82),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.scanner_preview_send_as_pdf,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: fg,
                                  ),
                                ),
                                Text(
                                  l10n.scanner_preview_send_as_pdf_hint,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: fgMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _sendAsPdf,
                            onChanged: _busy
                                ? null
                                : (v) => setState(() => _sendAsPdf = v),
                            activeThumbColor: Colors.white,
                            activeTrackColor: const Color(0xFF2F86FF),
                          ),
                        ],
                      ),
                    ),
                    _SendButton(
                      label: _busy
                          ? l10n.scanner_preview_building_pdf
                          : l10n.scanner_preview_send(_paths.length),
                      accent: accent,
                      onTap: _busy ? null : _send,
                      busy: _busy,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _PageTile extends StatelessWidget {
  const _PageTile({
    required this.pageNumber,
    required this.path,
    required this.cardBg,
    required this.fg,
    required this.fgMuted,
    required this.onDelete,
    required this.onRetake,
  });

  final int pageNumber;
  final String path;
  final Color cardBg;
  final Color fg;
  final Color fgMuted;
  final VoidCallback onDelete;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 0.72, // близко к A4
            child: Image.file(File(path), fit: BoxFit.cover),
          ),
          // Затемнение снизу — для читаемости подписи / кнопок.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#$pageNumber',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          // Кнопка retake — нижний центр.
          Positioned(
            bottom: 8,
            right: 56,
            child: _MiniButton(
              icon: Icons.refresh_rounded,
              tooltip: l10n.scanner_preview_retake,
              onTap: onRetake,
            ),
          ),
          // Кнопка удалить — нижний правый.
          Positioned(
            bottom: 8,
            right: 8,
            child: _MiniButton(
              icon: Icons.delete_outline_rounded,
              tooltip: l10n.scanner_preview_delete,
              onTap: onDelete,
              danger: true,
            ),
          ),
          // Drag-handle сверху справа — индикация что можно перетаскивать.
          const Positioned(
            top: 8,
            right: 8,
            child: _DragHint(),
          ),
        ],
      ),
    );
  }
}

class _DragHint extends StatelessWidget {
  const _DragHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.drag_handle_rounded,
        color: Colors.white,
        size: 16,
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final bg = danger
        ? Colors.red.withValues(alpha: 0.92)
        : Colors.black.withValues(alpha: 0.6);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatefulWidget {
  const _SendButton({
    required this.label,
    required this.accent,
    required this.onTap,
    this.busy = false,
  });

  final String label;
  final Color accent;
  final VoidCallback? onTap;
  final bool busy;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    return AnimatedScale(
      duration: const Duration(milliseconds: 110),
      scale: _pressed ? 0.97 : 1,
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: disabled
                    ? [
                        widget.accent.withValues(alpha: 0.42),
                        widget.accent.withValues(alpha: 0.32),
                      ]
                    : [
                        widget.accent.withValues(alpha: 0.92),
                        widget.accent,
                      ],
              ),
              boxShadow: disabled
                  ? null
                  : [
                      BoxShadow(
                        color: widget.accent.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  const Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
