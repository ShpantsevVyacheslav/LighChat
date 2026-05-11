import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Категории жалобы — значения совпадают со строками ReportReason на бэкенде.
enum _ReportReason {
  spam,
  offensive,
  violence,
  fraud,
  other;

  /// Строковое значение, которое хранится в Firestore (совпадает с web-типом).
  String get firestoreValue => name; // spam, offensive, violence, fraud, other
}

/// Показывает bottom sheet с формой жалобы.
///
/// [reportedUserId]   — uid пользователя, на которого жалоба.
/// [conversationId]   — id чата (обязателен).
/// [messageId]        — id сообщения, если жалоба на конкретное сообщение.
/// [messageSenderName]— отображаемое имя отправителя сообщения (опционально).
/// [messageText]      — текст сообщения для контекста модератора (первые 500 симв.).
Future<void> showReportSheet(
  BuildContext context, {
  required String reportedUserId,
  required String conversationId,
  String? messageId,
  String? messageSenderName,
  String? messageText,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReportSheet(
      reportedUserId: reportedUserId,
      conversationId: conversationId,
      messageId: messageId,
      messageSenderName: messageSenderName,
      messageText: messageText,
    ),
  );
}

// ---------------------------------------------------------------------------

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({
    required this.reportedUserId,
    required this.conversationId,
    this.messageId,
    this.messageSenderName,
    this.messageText,
  });

  final String reportedUserId;
  final String conversationId;
  final String? messageId;
  final String? messageSenderName;
  final String? messageText;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  _ReportReason? _selected;
  final _commentController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _selected;
    if (reason == null) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _loading = true);
    try {
      final me = FirebaseAuth.instance.currentUser;
      if (me == null) throw Exception('not-authenticated');

      final reporterName =
          me.displayName?.trim().isNotEmpty == true ? me.displayName! : me.uid;

      await FirebaseFirestore.instance
          .collection('messageReports')
          .add(<String, Object?>{
        'reporterId': me.uid,
        'reporterName': reporterName,
        'conversationId': widget.conversationId,
        if (widget.messageId != null) 'messageId': widget.messageId,
        'messageSenderId': widget.reportedUserId,
        if (widget.messageSenderName != null)
          'messageSenderName': widget.messageSenderName,
        if (widget.messageText != null)
          'messageText': widget.messageText!.length > 500
              ? widget.messageText!.substring(0, 500)
              : widget.messageText,
        'reason': reason.firestoreValue,
        'description': _commentController.text.trim(),
        'status': 'pending',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      });

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.report_success)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.report_error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isMessage = widget.messageId != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── drag handle ──
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // ── заголовок ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  l10n.report_title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  isMessage
                      ? l10n.report_subtitle_message
                      : l10n.report_subtitle_user,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                ),
              ),
              const Divider(height: 1),
              // ── список причин ──
              RadioGroup<_ReportReason>(
                groupValue: _selected,
                onChanged: (v) {
                  if (!_loading) setState(() => _selected = v);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _ReportReason.values
                      .map(
                        (r) => RadioListTile<_ReportReason>(
                          value: r,
                          dense: true,
                          title: Text(_reasonLabel(r, l10n)),
                        ),
                      )
                      .toList(),
                ),
              ),
              // ── поле комментария ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _commentController,
                  enabled: !_loading,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: l10n.report_comment_hint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              // ── кнопка отправки ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: FilledButton(
                  onPressed: (_selected == null || _loading) ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.report_submit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _reasonLabel(_ReportReason r, AppLocalizations l10n) {
    switch (r) {
      case _ReportReason.spam:
        return l10n.report_reason_spam;
      case _ReportReason.offensive:
        return l10n.report_reason_offensive;
      case _ReportReason.violence:
        return l10n.report_reason_violence;
      case _ReportReason.fraud:
        return l10n.report_reason_fraud;
      case _ReportReason.other:
        return l10n.report_reason_other;
    }
  }
}
