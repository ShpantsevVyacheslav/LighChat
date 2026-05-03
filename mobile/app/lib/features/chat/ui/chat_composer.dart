import 'dart:async' show unawaited;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:image_picker/image_picker.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../data/composer_html_editing.dart';
import '../data/link_preview_url_extractor.dart';
import '../../../l10n/app_localizations.dart';
import 'composer_attachment_menu.dart';
import 'composer_editing_banner.dart';
import 'composer_formatting_toolbar.dart';
import 'composer_link_preview.dart';
import 'composer_pending_attachments_strip.dart';
import 'composer_clipboard_selection_controls.dart';
import 'composer_reply_banner.dart';
import 'message_html_text.dart';
import '../data/group_mention_candidates.dart';
import '../data/mention_editor_query.dart';
import 'group_mention_suggestions.dart';
import 'hold_to_record_mic_button.dart';
import 'voice_message_record_sheet.dart';
import 'chat_wallpaper_scope.dart';
import 'chat_wallpaper_tone.dart';

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
    this.onSendLongPress,
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
    this.groupMentionCandidates,
    this.onVoiceHoldRecorded,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  /// Долгое нажатие на кнопку «Отправить» — открывает диалог планирования
  /// (Telegram-style). Если null — long-press отключён.
  final VoidCallback? onSendLongPress;
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

  /// Участники группы для подсказок @. Если null/пусто — упоминания отключены.
  final List<GroupMentionCandidate>? groupMentionCandidates;

  /// Telegram-like hold-to-record: результат записи (без bottom sheet).
  final Future<void> Function(VoiceMessageRecordResult result)?
  onVoiceHoldRecorded;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  /// Как строка поиска на экране списка чатов (`chat_list_screen`: высота 40, radius 14).
  static const double _kComposerControlSize = 40;
  /// Согласовано с `fontSize: 16` без forceStrut — курсор не растягивается на всю капсулу.
  static const double _kComposerCursorHeight = 18;
  final GlobalKey _composerColumnKey = GlobalKey();
  final GlobalKey _sendButtonKey = GlobalKey();
  OverlayEntry? _attachmentOverlayEntry;
  OverlayEntry? _sendLongPressMenuEntry;
  bool _hasTypedText = false;
  String? _mentionQuery;
  int? _mentionAtStartOffset;
  List<GroupMentionCandidate> _mentionFiltered = const [];
  bool _holdRecordOverlayVisible = false;
  String? _linkPreviewUrl;
  final Set<String> _dismissedLinkPreviewUrls = <String>{};

  bool _computeHasTypedText() {
    final prepared = ComposerHtmlEditing.prepareChatMessageHtmlForSend(
      widget.controller.text,
    );
    if (prepared.isEmpty) return false;
    return messageHtmlToPlainText(prepared).trim().isNotEmpty;
  }

  void _onComposerTextChanged() {
    final next = _computeHasTypedText();
    final mentionChanged = _recomputeMentionState();
    final linkChanged = _recomputeLinkPreview();
    if (next == _hasTypedText && !mentionChanged && !linkChanged) return;
    if (mounted) {
      setState(() {
        _hasTypedText = next;
      });
    }
  }

  bool _recomputeLinkPreview() {
    final plain = messageHtmlToPlainText(widget.controller.text);
    final extracted = extractFirstHttpUrl(plain);
    final next = (extracted == null ||
            _dismissedLinkPreviewUrls.contains(extracted))
        ? null
        : extracted;
    if (next == _linkPreviewUrl) return false;
    _linkPreviewUrl = next;
    return true;
  }

  bool _recomputeMentionState() {
    final candidates = widget.groupMentionCandidates;
    if (candidates == null || candidates.isEmpty) {
      final had = _mentionQuery != null;
      _mentionQuery = null;
      _mentionAtStartOffset = null;
      _mentionFiltered = const [];
      return had;
    }
    final v = widget.controller.value;
    final sel = v.selection;
    if (!sel.isValid || !sel.isCollapsed) {
      final had = _mentionQuery != null;
      _mentionQuery = null;
      _mentionAtStartOffset = null;
      _mentionFiltered = const [];
      return had;
    }
    final caret = sel.baseOffset.clamp(0, v.text.length);
    final rawBefore = v.text.substring(0, caret);

    // Basic "not inside tag" check: if last '<' after last '>', assume user is typing a tag.
    final lastLt = rawBefore.lastIndexOf('<');
    final lastGt = rawBefore.lastIndexOf('>');
    if (lastLt > lastGt) {
      final had = _mentionQuery != null;
      _mentionQuery = null;
      _mentionAtStartOffset = null;
      _mentionFiltered = const [];
      return had;
    }

    // Find last '@' that starts a token (start or whitespace before).
    var at = rawBefore.lastIndexOf('@');
    while (at >= 0) {
      final prev = at == 0 ? '' : rawBefore[at - 1];
      final okPrev = at == 0 || RegExp(r'\s').hasMatch(prev);
      if (okPrev) break;
      at = rawBefore.lastIndexOf('@', at - 1);
    }
    if (at < 0) {
      final had = _mentionQuery != null;
      _mentionQuery = null;
      _mentionAtStartOffset = null;
      _mentionFiltered = const [];
      return had;
    }

    final afterAtRaw = rawBefore.substring(at + 1);
    if (afterAtRaw.contains(RegExp(r'[\s\n\r]'))) {
      final had = _mentionQuery != null;
      _mentionQuery = null;
      _mentionAtStartOffset = null;
      _mentionFiltered = const [];
      return had;
    }

    final boundaryNames = buildMentionBoundaryNameList([
      for (final c in candidates) c.name,
      for (final c in candidates) c.username,
    ]);
    final query = resolveMentionQueryFromAfterAt(afterAtRaw, boundaryNames);
    if (query == null) {
      final had = _mentionQuery != null;
      _mentionQuery = null;
      _mentionAtStartOffset = null;
      _mentionFiltered = const [];
      return had;
    }

    final q = query.trim().toLowerCase();
    List<GroupMentionCandidate> filtered;
    if (q.isEmpty) {
      filtered = candidates;
    } else {
      filtered = candidates
          .where((c) {
            final n = c.name.toLowerCase();
            final u = c.username.toLowerCase();
            return n.contains(q) || u.contains(q);
          })
          .toList(growable: false);
    }
    _mentionQuery = query;
    _mentionAtStartOffset = at;
    _mentionFiltered = filtered;
    return true;
  }

  void _pickMention(GroupMentionCandidate c) {
    final at = _mentionAtStartOffset;
    if (at == null) return;
    widget.controller.value = ComposerHtmlEditing.insertGroupMention(
      value: widget.controller.value,
      atStartOffset: at,
      userId: c.id,
      label: c.name.trim().isNotEmpty ? c.name.trim() : c.username.trim(),
      fallbackMentionLabel: AppLocalizations.of(context)!.mention_default_label,
    );
    widget.focusNode.requestFocus();
    setState(() {
      _mentionQuery = null;
      _mentionAtStartOffset = null;
      _mentionFiltered = const [];
    });
  }

  @override
  void initState() {
    super.initState();
    _hasTypedText = _computeHasTypedText();
    _recomputeMentionState();
    _recomputeLinkPreview();
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
    _recomputeMentionState();
    _recomputeLinkPreview();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onComposerTextChanged);
    _attachmentOverlayEntry?.remove();
    _sendLongPressMenuEntry?.remove();
    super.dispose();
  }

  /// Glass-popup над кнопкой «Отправить» с одним пунктом «Запланировать
  /// отправку». Заменяет нативный Flutter Tooltip — тот всплывал ПОД
  /// клавиатурой и не был кликабельным.
  void _showSendLongPressMenu() {
    final cb = widget.onSendLongPress;
    if (cb == null) return;
    final ctx = _sendButtonKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final overlay = Overlay.of(ctx);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return;

    HapticFeedback.lightImpact();

    final buttonTopLeft = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    final buttonSize = box.size;
    final overlaySize = overlayBox.size;

    _sendLongPressMenuEntry?.remove();

    void dismiss() {
      _sendLongPressMenuEntry?.remove();
      _sendLongPressMenuEntry = null;
    }

    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    _sendLongPressMenuEntry = OverlayEntry(
      builder: (_) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: dismiss,
              ),
            ),
            Positioned(
              right: overlaySize.width - buttonTopLeft.dx - buttonSize.width,
              bottom: overlaySize.height - buttonTopLeft.dy + 8,
              child: Material(
                type: MaterialType.transparency,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: (dark ? const Color(0xFF0D1A24) : Colors.white)
                            .withValues(alpha: dark ? 0.86 : 0.95),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: dark ? 0.18 : 0.42,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.30),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          dismiss();
                          cb();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_send_rounded,
                                size: 18,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                l10n.schedule_message_long_press_hint,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: dark
                                      ? Colors.white.withValues(alpha: 0.95)
                                      : scheme.onSurface,
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
            ),
          ],
        );
      },
    );
    overlay.insert(_sendLongPressMenuEntry!);
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
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final wallpaper = ChatWallpaperScope.of(context);
    final fg = chatWallpaperAdaptivePrimaryTextColor(
      context: context,
      wallpaper: wallpaper,
    );
    final hintFg = chatWallpaperAdaptiveSecondaryTextColor(
      context: context,
      wallpaper: wallpaper,
    );
    final paste = widget.onClipboardToolbarPaste;
    final tf = TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      textCapitalization: TextCapitalization.sentences,
      cursorColor: scheme.primary,
      cursorHeight: _kComposerCursorHeight,
      selectionControls: paste == null
          ? null
          : ComposerClipboardMaterialSelectionControls(onPaste: paste),
      minLines: 1,
      maxLines: 1,
      keyboardType: TextInputType.multiline,
      textAlignVertical: TextAlignVertical.center,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: fg,
      ),
      decoration: InputDecoration(
        hintText: l10n.chat_composer_hint_message,
        hintStyle: TextStyle(
          color: hintFg,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        border: InputBorder.none,
        isDense: true,
        // Сдвинуто на 2 px вниз: визуальный центр глифов Roboto/SF выше
        // геометрического из-за более короткого descender'а; асимметричный
        // padding компенсирует эту оптическую несимметрию в капсуле 40 px.
        contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
        isCollapsed: false,
        suffixIcon: IconButton(
                tooltip: l10n.chat_composer_tooltip_stickers,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                onPressed: widget.sendBusy ? null : _openStickersPanel,
                icon: Icon(
                  Icons.emoji_emotions_outlined,
                  size: 20,
                  color: widget.sendBusy
                      ? hintFg.withValues(alpha: 0.65)
                      : fg.withValues(alpha: 0.88),
                ),
              ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 34,
          minHeight: 34,
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
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final wallpaper = ChatWallpaperScope.of(context);
    final fg = chatWallpaperAdaptivePrimaryTextColor(
      context: context,
      wallpaper: wallpaper,
    );
    final muted = chatWallpaperAdaptiveSecondaryTextColor(
      context: context,
      wallpaper: wallpaper,
    );
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final showSendButton =
        _hasTypedText || widget.pendingAttachments.isNotEmpty;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          key: _composerColumnKey,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.editingPreviewPlain != null &&
                widget.onCancelEdit != null)
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
            if (_mentionQuery != null &&
                widget.e2eeDisabledBanner == null &&
                widget.pendingAttachments.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GroupMentionSuggestions(
                  items: _mentionFiltered,
                  onPick: _pickMention,
                ),
              ),
            if (_linkPreviewUrl != null &&
                widget.e2eeDisabledBanner == null &&
                _mentionQuery == null)
              ComposerLinkPreview(
                url: _linkPreviewUrl!,
                onDismiss: () {
                  final url = _linkPreviewUrl;
                  if (url == null) return;
                  setState(() {
                    _dismissedLinkPreviewUrls.add(url);
                    _linkPreviewUrl = null;
                  });
                },
              ),
            if (widget.e2eeDisabledBanner != null)
              // Phase 0: если чат зашифрован — полностью заменяем input‑строку
              // баннером. Никаких кнопок микрофона/стикеров, чтобы не провоцировать
              // попытку записать войс в E2EE‑чат, которую пока не поддерживаем.
              widget.e2eeDisabledBanner!
            else
              AnimatedOpacity(
                opacity: _holdRecordOverlayVisible ? 0 : 1,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                // Важно: не размонтируем input‑ряд во время записи, иначе
                // уничтожается HoldToRecordMicButton и рекордер мгновенно сбрасывается.
                // Визуально ряд скрывается, а полоса записи в Overlay остаётся
                // на его месте (эффект "замены строки ввода").
                child: Row(
                  key: const ValueKey('composer-input-row'),
                  children: [
                    Container(
                      width: _kComposerControlSize,
                      height: _kComposerControlSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(
                          alpha: chatWallpaperPrefersLightForeground(wallpaper)
                              ? (dark ? 0.18 : 0.16)
                              : (dark ? 0.06 : 0.08),
                        ),
                        border: Border.all(
                          color: fg.withValues(alpha: 0.18),
                        ),
                      ),
                      child: IconButton(
                        tooltip: l10n.chat_composer_tooltip_attachments,
                        onPressed: widget.attachmentsEnabled && !widget.sendBusy
                            ? _openAttachmentMenu
                            : null,
                        iconSize: 17,
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.add_rounded,
                          color: widget.attachmentsEnabled && !widget.sendBusy
                              ? fg.withValues(alpha: 0.92)
                              : muted.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: _kComposerControlSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.black.withValues(
                            alpha: chatWallpaperPrefersLightForeground(wallpaper)
                                ? (dark ? 0.18 : 0.16)
                                : (dark ? 0.06 : 0.08),
                          ),
                          border: Border.all(
                            color: fg.withValues(alpha: 0.18),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: _kComposerControlSize,
                          ),
                          child: _buildComposerTextField(keyboardOpen),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: _kComposerControlSize,
                      height: _kComposerControlSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: showSendButton
                            ? const Color(0xFF2A79FF)
                            : Colors.black.withValues(
                                alpha: chatWallpaperPrefersLightForeground(
                                  wallpaper,
                                )
                                    ? (dark ? 0.18 : 0.16)
                                    : (dark ? 0.06 : 0.08),
                              ),
                        border: showSendButton
                            ? null
                            : Border.all(
                                color: fg.withValues(alpha: 0.18),
                              ),
                        boxShadow: showSendButton
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF2A79FF,
                                  ).withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      child: widget.sendBusy
                          ? const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : (showSendButton
                                ? GestureDetector(
                                    onLongPress: widget.onSendLongPress == null
                                        ? null
                                        : _showSendLongPressMenu,
                                    child: IconButton(
                                      key: _sendButtonKey,
                                      onPressed: widget.onSend,
                                      iconSize: 18,
                                      icon: const Icon(
                                        Icons.send_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : () {
                                    final canInlineVoice =
                                        !widget.sendBusy &&
                                        widget.onVoiceHoldRecorded != null;
                                    if (!canInlineVoice) {
                                      return IconButton(
                                        onPressed: widget.onMicTap,
                                        iconSize: 20,
                                        icon: Icon(
                                          Icons.mic_rounded,
                                          color: fg.withValues(alpha: 0.92),
                                        ),
                                      );
                                    }
                                    return HoldToRecordMicButton(
                                      enabled: true,
                                      tapToRecord: true,
                                      onTap: () {},
                                      onOverlayVisibilityChanged: (visible) {
                                        if (_holdRecordOverlayVisible ==
                                                visible ||
                                            !mounted) {
                                          return;
                                        }
                                        setState(() {
                                          _holdRecordOverlayVisible = visible;
                                        });
                                      },
                                      onRecorded: (r) async {
                                        final cb = widget.onVoiceHoldRecorded;
                                        if (cb == null) return;
                                        await cb(r);
                                      },
                                      child: Center(
                                        child: Icon(
                                          Icons.mic_rounded,
                                          size: 20,
                                          color: fg.withValues(alpha: 0.92),
                                        ),
                                      ),
                                    );
                                  }()),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
