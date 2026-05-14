import 'dart:ui' show ImageFilter;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../shared/ui/platform_keyboard_dismiss_behavior.dart';

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
    barrierColor: Colors.black.withValues(alpha: 0.45),
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
  void initState() {
    super.initState();
    _commentController.addListener(() {
      if (mounted) setState(() {});
    });
  }

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

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Material(
              color: scheme.surface.withValues(alpha: 0.92),
              child: SafeArea(
                top: false,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.92,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    l10n.report_title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isMessage
                                        ? l10n.report_subtitle_message
                                        : l10n.report_subtitle_user,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _loading
                                  ? null
                                  : () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: ListView(
                          keyboardDismissBehavior:
                              platformScrollKeyboardDismissBehavior(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          shrinkWrap: true,
                          children: [
                            for (final r in _ReportReason.values)
                              _ReasonTile(
                                label: _reasonLabel(r, l10n),
                                selected: _selected == r,
                                enabled: !_loading,
                                onTap: () => setState(() => _selected = r),
                              ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _commentController,
                              enabled: !_loading,
                              maxLines: 3,
                              minLines: 2,
                              maxLength: 500,
                              textCapitalization: TextCapitalization.sentences,
                              scrollPadding:
                                  const EdgeInsets.only(bottom: 240),
                              decoration: InputDecoration(
                                labelText: l10n.report_comment_hint,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 54,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: (_selected == null || _loading)
                                        ? [
                                            scheme.onSurface
                                                .withValues(alpha: 0.12),
                                            scheme.onSurface
                                                .withValues(alpha: 0.12),
                                          ]
                                        : const [
                                            Color(0xFF2E86FF),
                                            Color(0xFF5F90FF),
                                            Color(0xFF9A18FF),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: TextButton(
                                  onPressed:
                                      (_selected == null || _loading)
                                          ? null
                                          : _submit,
                                  style: TextButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    foregroundColor: Colors.white,
                                    disabledForegroundColor: scheme.onSurface
                                        .withValues(alpha: 0.45),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          l10n.report_submit,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = const Color(0xFF2F86FF);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? accent.withValues(alpha: 0.14)
                  : scheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? accent.withValues(alpha: 0.6)
                    : scheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                _RadioDot(selected: selected, accent: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: scheme.onSurface
                          .withValues(alpha: enabled ? 1.0 : 0.5),
                    ),
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

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected, required this.accent});

  final bool selected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 20,
      height: 20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? accent
                : scheme.onSurface.withValues(alpha: 0.35),
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: selected
            ? Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                ),
              )
            : null,
      ),
    );
  }
}
