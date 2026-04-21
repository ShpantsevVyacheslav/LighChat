import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../data/composer_html_editing.dart';
import 'composer_attachment_menu.dart';
import 'composer_editing_banner.dart';
import 'composer_formatting_toolbar.dart';
import 'composer_pending_attachments_strip.dart';
import 'composer_clipboard_selection_controls.dart';
import 'composer_reply_banner.dart';
import 'message_html_text.dart';

/// Shared chat composer used by both `ChatScreen` and `ThreadScreen`.
///
/// This is a mechanical extraction of the old private `_ChatComposer` from
/// `chat_screen.dart` to keep behavior identical.
class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onAttachmentSelected,
    required this.pendingAttachments,
    required this.onRemovePending,
    required this.onEditPending,
    required this.attachmentsEnabled,
    required this.sendBusy,
    required this.onMicTap,
    required this.onStickersTap,
    this.replyingTo,
    this.onCancelReply,
    this.editingPreviewPlain,
    this.onCancelEdit,
    this.showFormattingToolbar = false,
    this.onCloseFormattingToolbar,
    this.onClipboardToolbarPaste,
    this.stickerSuggestionBuilder,
    this.e2eeDisabledBanner,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final void Function(ComposerAttachmentAction action) onAttachmentSelected;
  final List<XFile> pendingAttachments;
  final void Function(int index) onRemovePending;
  final Future<void> Function(int index) onEditPending;
  final bool attachmentsEnabled;
  final bool sendBusy;
  final VoidCallback onMicTap;
  final VoidCallback onStickersTap;
  final ReplyContext? replyingTo;
  final VoidCallback? onCancelReply;
  final String? editingPreviewPlain;
  final VoidCallback? onCancelEdit;
  final bool showFormattingToolbar;
  final VoidCallback? onCloseFormattingToolbar;

  /// Вставка из буфера (текст + файлы) при «Вставить» в контекстном меню поля.
  final Future<void> Function()? onClipboardToolbarPaste;

  /// Необязательный строитель строки быстрых стикеров над полем ввода.
  ///
  /// Если задан, рендерится над input‑строкой только когда клавиатура открыта,
  /// текст пуст и нет pending‑вложений — чтобы не мешать обычному вводу. Сам
  /// билдер не должен выполнять тяжёлой работы при каждом rebuild (делегируйте
  /// внутрь виджета с `StreamBuilder`/`Consumer`).
  final Widget Function()? stickerSuggestionBuilder;

  /// Phase 0: баннер «в этом чате включён E2EE — пишите с веба», который
  /// показывается вместо поля ввода, когда мобильная отправка/редактирование
  /// запрещены [E2eeNotSupportedOnMobileException]. Если задан и непустой —
  /// заменяет обычную input‑строку.
  ///
  /// Передача логики снаружи (а не хардкод внутри) нужна, чтобы чат и thread
  /// могли использовать разные тексты и чтобы тесты могли подменять виджет.
  final Widget? e2eeDisabledBanner;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final GlobalKey _composerColumnKey = GlobalKey();
  OverlayEntry? _attachmentOverlayEntry;
  bool _hasTypedText = false;

  bool _computeHasTypedText() {
    final prepared = ComposerHtmlEditing.prepareChatMessageHtmlForSend(
      widget.controller.text,
    );
    if (prepared.isEmpty) return false;
    return messageHtmlToPlainText(prepared).trim().isNotEmpty;
  }

  void _onComposerTextChanged() {
    final next = _computeHasTypedText();
    if (next == _hasTypedText) return;
    if (mounted) setState(() => _hasTypedText = next);
  }

  @override
  void initState() {
    super.initState();
    _hasTypedText = _computeHasTypedText();
    widget.controller.addListener(_onComposerTextChanged);
  }

  @override
  void didUpdateWidget(covariant ChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_onComposerTextChanged);
      widget.controller.addListener(_onComposerTextChanged);
    }
    final next = _computeHasTypedText();
    if (next != _hasTypedText) {
      _hasTypedText = next;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onComposerTextChanged);
    _attachmentOverlayEntry?.remove();
    super.dispose();
  }

  void _closeAttachmentMenu() {
    _attachmentOverlayEntry?.remove();
    _attachmentOverlayEntry = null;
  }

  void _openAttachmentMenu() {
    if (!widget.attachmentsEnabled || widget.sendBusy) return;
    _closeAttachmentMenu();
    final box =
        _composerColumnKey.currentContext?.findRenderObject() as RenderBox?;
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;
    var bottomFrom = 100.0;
    if (box != null && box.hasSize) {
      final topY = box.localToGlobal(Offset.zero).dy;
      bottomFrom = (screenH - topY).clamp(56.0, screenH);
    }
    _attachmentOverlayEntry = showComposerAttachmentOverlay(
      context: context,
      bottomFromScreenBottom: bottomFrom,
      onDismissed: () {
        _attachmentOverlayEntry = null;
      },
      onSelected: widget.onAttachmentSelected,
    );
  }

  void _openStickersPanel() {
    if (widget.sendBusy) return;
    _closeAttachmentMenu();
    widget.onStickersTap();
  }

  Widget _buildComposerTextField(bool keyboardOpen) {
    final paste = widget.onClipboardToolbarPaste;
    final tf = TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      selectionControls: paste == null
          ? null
          : ComposerClipboardMaterialSelectionControls(onPaste: paste),
      minLines: 1,
      maxLines: 6,
      keyboardType: TextInputType.multiline,
      textAlignVertical: TextAlignVertical.center,
      style: const TextStyle(
        fontSize: 15.5,
        height: 1.25,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Введите сообщение...',
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.42),
          fontWeight: FontWeight.w500,
          fontSize: 15.5,
          height: 1.25,
        ),
        border: InputBorder.none,
        isDense: true,
        // Keep text & hint vertically centered within the 44px container.
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        isCollapsed: true,
        suffixIcon: keyboardOpen
            ? IconButton(
                tooltip: 'Стикеры',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                onPressed: widget.sendBusy ? null : _openStickersPanel,
                icon: Icon(
                  Icons.emoji_emotions_outlined,
                  size: 22,
                  color: widget.sendBusy
                      ? Colors.white.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.88),
                ),
              )
            : null,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 44,
        ),
      ),
      textInputAction: TextInputAction.newline,
    );
    if (paste == null) return tf;
    return Actions(
      actions: {
        PasteTextIntent: CallbackAction<PasteTextIntent>(
          onInvoke: (_) {
            unawaited(paste());
            return true;
          },
        ),
      },
      child: tf,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final showSendButton = _hasTypedText || widget.pendingAttachments.isNotEmpty;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          key: _composerColumnKey,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.editingPreviewPlain != null && widget.onCancelEdit != null)
              ComposerEditingBanner(
                previewPlain: widget.editingPreviewPlain!,
                onCancel: widget.onCancelEdit!,
              )
            else if (widget.replyingTo != null && widget.onCancelReply != null)
              ComposerReplyBanner(
                replyTo: widget.replyingTo!,
                onCancel: widget.onCancelReply!,
              ),
            ComposerPendingAttachmentsStrip(
              files: widget.pendingAttachments,
              onRemoveAt: widget.onRemovePending,
              onEditAt: (i) => unawaited(widget.onEditPending(i)),
            ),
            if (widget.showFormattingToolbar &&
                widget.onCloseFormattingToolbar != null) ...[
              ComposerFormattingToolbar(
                controller: widget.controller,
                focusNode: widget.focusNode,
                onBack: widget.onCloseFormattingToolbar!,
              ),
              const SizedBox(height: 8),
            ],
            if (widget.stickerSuggestionBuilder != null &&
                keyboardOpen &&
                !_hasTypedText &&
                widget.pendingAttachments.isEmpty &&
                !widget.showFormattingToolbar &&
                widget.e2eeDisabledBanner == null)
              widget.stickerSuggestionBuilder!(),
            if (widget.e2eeDisabledBanner != null)
              // Phase 0: если чат зашифрован — полностью заменяем input‑строку
              // баннером. Никаких кнопок микрофона/стикеров, чтобы не провоцировать
              // попытку записать войс в E2EE‑чат, которую пока не поддерживаем.
              widget.e2eeDisabledBanner!
            else
              Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: dark ? 0.09 : 0.16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: dark ? 0.16 : 0.24),
                    ),
                  ),
                  child: IconButton(
                    tooltip: 'Вложения',
                    onPressed:
                        widget.attachmentsEnabled && !widget.sendBusy ? _openAttachmentMenu : null,
                    iconSize: 19,
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.add_rounded,
                      color: widget.attachmentsEnabled && !widget.sendBusy
                          ? Colors.white.withValues(alpha: 0.90)
                          : Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: Colors.white.withValues(alpha: dark ? 0.07 : 0.14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: dark ? 0.16 : 0.24),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: _buildComposerTextField(keyboardOpen),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: showSendButton
                        ? const Color(0xFF2A79FF)
                        : Colors.white.withValues(alpha: dark ? 0.08 : 0.14),
                    border: showSendButton
                        ? null
                        : Border.all(
                            color: Colors.white.withValues(alpha: dark ? 0.16 : 0.24),
                          ),
                    boxShadow: showSendButton
                        ? [
                            BoxShadow(
                              color: const Color(0xFF2A79FF).withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: widget.sendBusy
                      ? const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : IconButton(
                          onPressed: showSendButton ? widget.onSend : widget.onMicTap,
                          iconSize: showSendButton ? 20 : 22,
                          icon: Icon(
                            showSendButton ? Icons.send_rounded : Icons.mic_rounded,
                            color: showSendButton
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

