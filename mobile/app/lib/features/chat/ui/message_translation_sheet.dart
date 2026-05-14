import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/app_localizations.dart';
import '../data/local_message_translator.dart';

/// Bottom sheet с переводом текстового сообщения. On-device через ML Kit;
/// кэшируется в SQLite, повторный показ для того же сообщения — мгновенный.
class MessageTranslationSheet extends StatefulWidget {
  const MessageTranslationSheet({
    super.key,
    required this.messageId,
    required this.originalText,
    required this.from,
    required this.to,
  });

  final String messageId;
  final String originalText;
  final String from;
  final String to;

  @override
  State<MessageTranslationSheet> createState() =>
      _MessageTranslationSheetState();
}

class _MessageTranslationSheetState extends State<MessageTranslationSheet> {
  String? _translated;
  String? _error;
  TranslationPhase? _phase;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _translate());
  }

  Future<void> _translate() async {
    setState(() {
      _busy = true;
      _phase = TranslationPhase.translating;
      _error = null;
    });
    try {
      final result = await LocalMessageTranslator.instance.translate(
        cacheKey:
            'text|${widget.messageId}|${widget.from}→${widget.to}',
        text: widget.originalText,
        from: widget.from,
        to: widget.to,
        onPhase: (p) {
          if (!mounted) return;
          setState(() => _phase = p);
        },
      );
      if (!mounted) return;
      setState(() => _translated = result);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _error = e is UnsupportedTranslationException
            ? (l10n?.voice_translate_unsupported ?? e.toString())
            : (l10n?.voice_translate_failed(e.toString()) ?? e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _phase = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.translate_rounded,
                      size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.from.toUpperCase()} → ${widget.to.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: mq.size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: _buildBody(l10n, scheme),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_translated != null)
                    TextButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.maybeOf(context);
                        await Clipboard.setData(
                            ClipboardData(text: _translated!));
                        messenger?.showSnackBar(
                          SnackBar(
                            duration: const Duration(milliseconds: 1200),
                            content: Text(l10n.voice_transcript_copy),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_all_outlined, size: 18),
                      label: Text(l10n.voice_transcript_copy),
                    ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(l10n.chat_list_action_close),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, ColorScheme scheme) {
    if (_busy) {
      final label = _phase == TranslationPhase.downloading
          ? l10n.voice_translate_downloading_model
          : l10n.voice_translate_in_progress;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          _error!,
          style: TextStyle(
            fontSize: 14,
            color: scheme.error,
          ),
        ),
      );
    }
    return SelectableText(
      _translated ?? widget.originalText,
      style: TextStyle(
        fontSize: 15,
        height: 1.4,
        color: scheme.onSurface.withValues(alpha: 0.92),
      ),
    );
  }
}
