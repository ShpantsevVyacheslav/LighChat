import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../data/chat_haptics.dart';
import '../data/smart_reply_service.dart';

/// Горизонтальный ряд чипов «быстрых ответов» поверх композера.
///
/// Прячется когда:
/// — нет последних сообщений / последнее сообщение свое;
/// — пользователь уже что-то печатает;
/// — Smart Reply вернул `notSupportedLanguage` (диалог не на английском).
class SmartReplyChips extends StatefulWidget {
  const SmartReplyChips({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.composerIsEmpty,
    required this.onPick,
  });

  /// Последние сообщения диалога (берём tail из max 10).
  final List<ChatMessage> messages;
  final String currentUserId;

  /// `true` если в composer пусто. Когда юзер начинает печатать — прячемся.
  final bool composerIsEmpty;

  /// Тап по предложенному варианту — вставить в composer и/или сразу
  /// отправить (политика на стороне родителя).
  final void Function(String suggestion) onPick;

  @override
  State<SmartReplyChips> createState() => _SmartReplyChipsState();
}

class _SmartReplyChipsState extends State<SmartReplyChips> {
  List<String> _suggestions = const [];
  String _signature = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scheduleRefresh();
  }

  @override
  void didUpdateWidget(covariant SmartReplyChips old) {
    super.didUpdateWidget(old);
    if (old.messages.length != widget.messages.length ||
        old.currentUserId != widget.currentUserId) {
      _scheduleRefresh();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _scheduleRefresh() {
    final last = widget.messages.isEmpty ? null : widget.messages.last;
    final sig =
        '${widget.currentUserId}|${last?.id ?? ''}|${last?.text ?? ''}';
    if (sig == _signature) return;
    _signature = sig;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final result = await SmartReplyService.instance.suggest(
        messages: widget.messages,
        currentUserId: widget.currentUserId,
      );
      if (!mounted) return;
      setState(() => _suggestions = result);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.composerIsEmpty || _suggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final fg = theme.colorScheme.onSurface.withValues(alpha: 0.9);
    final bg = theme.colorScheme.primary.withValues(alpha: 0.14);
    final border = theme.colorScheme.primary.withValues(alpha: 0.32);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _suggestions.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final text = _suggestions[i];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  ChatHaptics.instance.selectionChanged();
                  widget.onPick(text);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: border, width: 0.8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    text,
                    style: TextStyle(
                      color: fg,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
