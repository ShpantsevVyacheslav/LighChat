import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../data/chat_emoji_only.dart';
import '../data/chat_haptics.dart';
import '../../../l10n/app_localizations.dart';
import 'chat_wallpaper_scope.dart';
import 'chat_wallpaper_tone.dart';
import 'message_attachments.dart';
import 'message_html_text.dart';

/// Паритет `MessageContextMenu.tsx` на вебе.
const kMessageContextReactionEmojis = <String>[
  '👌',
  '😁',
  '🤝',
  '😱',
  '❤️',
  '👍',
  '🔥',
  '😂',
  '😮',
  '😢',
  '👏',
  '🎉',
  '✅',
];

enum MessageMenuActionType {
  dismissed,
  reply,
  thread,
  copy,
  edit,
  pin,
  star,
  createSticker,
  saveToMyStickers,
  forward,
  select,
  delete,
  react,
  outboxRetry,
  outboxCancel,
  report,
  translate,
  readAloud,

  /// Apple Intelligence TL;DR — резюме длинного сообщения через
  /// Foundation Models (iOS 18.1+/26+). Пункт виден только когда движок
  /// доступен на устройстве И текст длиннее ~80 символов.
  summarizeAi,
}

class MessageMenuResult {
  const MessageMenuResult(this.type, {this.emoji});

  final MessageMenuActionType type;
  final String? emoji;

  static const dismissed = MessageMenuResult(MessageMenuActionType.dismissed);
}

String _formatMenuDateTime(DateTime local) {
  final d = local;
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final yyyy = d.year;
  final hh = d.hour.toString().padLeft(2, '0');
  final min = d.minute.toString().padLeft(2, '0');
  return '$dd.$mm.$yyyy $hh:$min';
}

bool _isStickerAttachmentForMenu(ChatAttachment a) {
  return a.name.toLowerCase().startsWith('sticker_');
}

bool _isGifAttachmentForMenu(ChatAttachment a) {
  final type = (a.type ?? '').toLowerCase();
  if (type == 'image/gif') return true;
  final path = a.url.split('?').first.toLowerCase();
  return path.endsWith('.gif');
}

bool _isImageAttachmentForMenu(ChatAttachment a) {
  if (_isStickerAttachmentForMenu(a) || _isGifAttachmentForMenu(a)) {
    return false;
  }
  final type = (a.type ?? '').toLowerCase();
  if (type.startsWith('image/')) return true;
  final path = a.url.split('?').first.toLowerCase();
  return path.endsWith('.jpg') ||
      path.endsWith('.jpeg') ||
      path.endsWith('.png') ||
      path.endsWith('.webp') ||
      path.endsWith('.heic');
}

ChatAttachment? messageMenuStickerAttachmentCandidate(ChatMessage message) {
  for (final att in message.attachments) {
    if (_isStickerAttachmentForMenu(att)) return att;
  }
  return null;
}

ChatAttachment? messageMenuCreateStickerAttachmentCandidate(
  ChatMessage message,
) {
  for (final att in message.attachments) {
    if (_isImageAttachmentForMenu(att)) return att;
  }
  return null;
}

Future<MessageMenuResult?> showMessageContextMenu(
  BuildContext context, {
  required ChatMessage message,
  required bool isCurrentUser,
  required bool hasText,
  required bool canEdit,
  required bool canDelete,
  bool allowCopy = true,
  bool allowForward = true,
  bool showStarAction = false,
  bool isStarred = false,
  bool showThreadAction = true,
  bool canTranslate = false,
  bool canSummarizeAi = false,
  String? e2eeDecryptedText,
  bool e2eeDecryptionFailed = false,
  String chatFontSize = 'medium',
  Color? outgoingBubbleColor,
  Color? incomingBubbleColor,
}) {
  final initiatorPureEmojiSize = pureEmojiMessageFontSize(chatFontSize);
  return showGeneralDialog<MessageMenuResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, anim, secAnim) {
      return _MessageContextMenuPage(
        message: message,
        isCurrentUser: isCurrentUser,
        hasText: hasText,
        canEdit: canEdit,
        canDelete: canDelete,
        allowCopy: allowCopy,
        allowForward: allowForward,
        showStarAction: showStarAction,
        isStarred: isStarred,
        showThreadAction: showThreadAction,
        canTranslate: canTranslate,
        canSummarizeAi: canSummarizeAi,
        e2eeDecryptedText: e2eeDecryptedText,
        e2eeDecryptionFailed: e2eeDecryptionFailed,
        initiatorPureEmojiSize: initiatorPureEmojiSize,
        outgoingBubbleColor: outgoingBubbleColor,
        incomingBubbleColor: incomingBubbleColor,
      );
    },
    transitionBuilder: (ctx, anim, secAnim, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.96,
            end: 1,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
    },
  );
}

class _MessageContextMenuPage extends StatelessWidget {
  const _MessageContextMenuPage({
    required this.message,
    required this.isCurrentUser,
    required this.hasText,
    required this.canEdit,
    required this.canDelete,
    required this.allowCopy,
    required this.allowForward,
    required this.showStarAction,
    required this.isStarred,
    required this.showThreadAction,
    required this.canTranslate,
    required this.canSummarizeAi,
    required this.e2eeDecryptedText,
    required this.e2eeDecryptionFailed,
    required this.initiatorPureEmojiSize,
    this.outgoingBubbleColor,
    this.incomingBubbleColor,
  });

  final ChatMessage message;
  final bool isCurrentUser;
  final bool hasText;
  final bool canEdit;
  final bool canDelete;
  final bool allowCopy;
  final bool allowForward;
  final bool showStarAction;
  final bool isStarred;
  final bool showThreadAction;
  final bool canTranslate;
  final bool canSummarizeAi;
  final String? e2eeDecryptedText;
  final bool e2eeDecryptionFailed;
  final double initiatorPureEmojiSize;
  final Color? outgoingBubbleColor;
  final Color? incomingBubbleColor;

  void _pop(BuildContext context, MessageMenuResult r) {
    Navigator.of(context).pop(r);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sent = message.createdAt.toLocal();
    final read = message.readAt?.toLocal();
    final expireAt = message.expireAt?.toLocal();
    final maxH = MediaQuery.sizeOf(context).height * 0.78;
    final saveStickerAtt = messageMenuStickerAttachmentCandidate(message);
    final createStickerAtt = messageMenuCreateStickerAttachmentCandidate(
      message,
    );
    final canSaveSticker = saveStickerAtt != null;
    final canCreateSticker = !canSaveSticker && createStickerAtt != null;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _pop(context, MessageMenuResult.dismissed),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(color: Colors.black.withValues(alpha: 0.40)),
              ),
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: () {},
              behavior: HitTestBehavior.deferToChild,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 272, maxHeight: maxH),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ContextMenuInitiatorPreview(
                        message: message,
                        isCurrentUser: isCurrentUser,
                        e2eeDecryptedText: e2eeDecryptedText,
                        e2eeDecryptionFailed: e2eeDecryptionFailed,
                        menuPureEmojiFontSize: initiatorPureEmojiSize,
                        outgoingBubbleColor: outgoingBubbleColor,
                        incomingBubbleColor: incomingBubbleColor,
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                          child: Container(
                            width: 272,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (message.replyTo != null)
                                  _MenuReplyQuote(replyTo: message.replyTo!),
                                _MenuHeader(
                                  sent: sent,
                                  read: read,
                                  expireAt: expireAt,
                                ),
                                _ReactionStrip(
                                  onPick: (emoji) => _pop(
                                    context,
                                    MessageMenuResult(
                                      MessageMenuActionType.react,
                                      emoji: emoji,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    4,
                                    2,
                                    4,
                                    8,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _MenuTile(
                                        icon: Icons.reply_rounded,
                                        label: l10n.message_menu_action_reply,
                                        onTap: () => _pop(
                                          context,
                                          const MessageMenuResult(
                                            MessageMenuActionType.reply,
                                          ),
                                        ),
                                      ),
                                      if (showThreadAction)
                                        _MenuTile(
                                          icon:
                                              Icons.chat_bubble_outline_rounded,
                                          label:
                                              l10n.message_menu_action_thread,
                                          onTap: () => _pop(
                                            context,
                                            const MessageMenuResult(
                                              MessageMenuActionType.thread,
                                            ),
                                          ),
                                        ),
                                      if (hasText)
                                        if (allowCopy)
                                          _MenuTile(
                                            icon: Icons.copy_rounded,
                                            label:
                                                l10n.message_menu_action_copy,
                                            onTap: () => _pop(
                                              context,
                                              const MessageMenuResult(
                                                MessageMenuActionType.copy,
                                              ),
                                            ),
                                          ),
                                      if (canTranslate)
                                        _MenuTile(
                                          icon: Icons.translate_rounded,
                                          label: l10n.message_menu_action_translate,
                                          onTap: () => _pop(
                                            context,
                                            const MessageMenuResult(
                                              MessageMenuActionType.translate,
                                            ),
                                          ),
                                        ),
                                      if (canSummarizeAi)
                                        _MenuTile(
                                          icon: Icons.auto_awesome_rounded,
                                          label: l10n.ai_action_summarize,
                                          onTap: () => _pop(
                                            context,
                                            const MessageMenuResult(
                                              MessageMenuActionType.summarizeAi,
                                            ),
                                          ),
                                        ),
                                      if (hasText)
                                        _MenuTile(
                                          icon: Icons.record_voice_over_rounded,
                                          label: l10n
                                              .message_menu_action_read_aloud,
                                          onTap: () => _pop(
                                            context,
                                            const MessageMenuResult(
                                              MessageMenuActionType.readAloud,
                                            ),
                                          ),
                                        ),
                                      if (canEdit)
                                        _MenuTile(
                                          icon: Icons.edit_rounded,
                                          label: l10n.message_menu_action_edit,
                                          onTap: () => _pop(
                                            context,
                                            const MessageMenuResult(
                                              MessageMenuActionType.edit,
                                            ),
                                          ),
                                        ),
                                      _MenuTile(
                                        icon: Icons.push_pin_outlined,
                                        label: l10n.message_menu_action_pin,
                                        onTap: () => _pop(
                                          context,
                                          const MessageMenuResult(
                                            MessageMenuActionType.pin,
                                          ),
                                        ),
                                      ),
                                      if (showStarAction)
                                        _MenuTile(
                                          icon: isStarred
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          label: isStarred
                                              ? l10n.message_menu_action_star_remove
                                              : l10n.message_menu_action_star_add,
                                          onTap: () => _pop(
                                            context,
                                            const MessageMenuResult(
                                              MessageMenuActionType.star,
                                            ),
                                          ),
                                        ),
                                      if (canCreateSticker)
                                        _MenuTile(
                                          icon: Icons
                                              .add_photo_alternate_outlined,
                                          label: l10n
                                              .message_menu_action_create_sticker,
                                          onTap: () => _pop(
                                            context,
                                            const MessageMenuResult(
                                              MessageMenuActionType
                                                  .createSticker,
                                            ),
                                          ),
                                        ),
                                      if (canSaveSticker)
                                        _MenuTile(
                                          icon: Icons.bookmark_add_outlined,
                                          label: l10n
                                              .message_menu_action_save_to_my_stickers,
                                          onTap: () => _pop(
                                            context,
                                            const MessageMenuResult(
                                              MessageMenuActionType
                                                  .saveToMyStickers,
                                            ),
                                          ),
                                        ),
                                      if (allowForward)
                                        _MenuTile(
                                          icon: Icons.forward_rounded,
                                          label:
                                              l10n.message_menu_action_forward,
                                          onTap: () => _pop(
                                            context,
                                            const MessageMenuResult(
                                              MessageMenuActionType.forward,
                                            ),
                                          ),
                                        ),
                                      _MenuTile(
                                        icon: Icons.check_box_outlined,
                                        label: l10n.message_menu_action_select,
                                        onTap: () => _pop(
                                          context,
                                          const MessageMenuResult(
                                            MessageMenuActionType.select,
                                          ),
                                        ),
                                      ),
                                      if (isCurrentUser && canDelete) ...[
                                        Divider(
                                          height: 16,
                                          thickness: 1,
                                          color: Colors.white.withValues(
                                            alpha: 0.10,
                                          ),
                                        ),
                                        _MenuTile(
                                          icon: Icons.delete_outline_rounded,
                                          label:
                                              l10n.message_menu_action_delete,
                                          danger: true,
                                          onTap: () => _pop(
                                            context,
                                            const MessageMenuResult(
                                              MessageMenuActionType.delete,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (!isCurrentUser) ...[
                                        Divider(
                                          height: 16,
                                          thickness: 1,
                                          color: Colors.white.withValues(
                                            alpha: 0.10,
                                          ),
                                        ),
                                        _MenuTile(
                                          icon: Icons.flag_outlined,
                                          label: l10n.message_menu_action_report,
                                          danger: true,
                                          onTap: () => _pop(
                                            context,
                                            const MessageMenuResult(
                                              MessageMenuActionType.report,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Превью сообщения по long-press — **без** BackdropFilter, поверх общего blur.
class _ContextMenuInitiatorPreview extends StatelessWidget {
  const _ContextMenuInitiatorPreview({
    required this.message,
    required this.isCurrentUser,
    required this.menuPureEmojiFontSize,
    this.e2eeDecryptedText,
    this.e2eeDecryptionFailed = false,
    this.outgoingBubbleColor,
    this.incomingBubbleColor,
  });

  final ChatMessage message;
  final bool isCurrentUser;
  final String? e2eeDecryptedText;
  final bool e2eeDecryptionFailed;
  final double menuPureEmojiFontSize;
  final Color? outgoingBubbleColor;
  final Color? incomingBubbleColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (message.isDeleted) {
      final l10n = AppLocalizations.of(context)!;
      final wallpaper = ChatWallpaperScope.of(context);
      final fg = chatWallpaperAdaptivePrimaryTextColor(
        context: context,
        wallpaper: wallpaper,
      );
      return Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 260),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withValues(alpha: 0.14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Text(
            l10n.message_menu_initiator_deleted,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: fg.withValues(alpha: 0.78),
            ),
          ),
        ),
      );
    }

    // Если на руках есть расшифрованный текст E2EE-сообщения — берём его;
    // иначе показываем фиксированный плейсхолдер «Зашифрованное сообщение»
    // (или ошибку дешифровки), как делает основная лента (chat_message_list).
    final l10nForE2ee = AppLocalizations.of(context)!;
    final rawSource = e2eeDecryptedText ?? (message.text ?? '');
    final html = rawSource;
    final plain = html.contains('<') ? messageHtmlToPlainText(html) : html;
    final hasRawText = plain.trim().isNotEmpty;
    final hasMedia = message.attachments.isNotEmpty;
    final pollId = (message.chatPollId ?? '').trim();
    final hasPoll = pollId.isNotEmpty;
    final hasLocation = message.locationShare != null;
    final hasE2eeOnlyCiphertext =
        message.hasE2eeCiphertext &&
        e2eeDecryptedText == null &&
        !hasRawText &&
        !hasMedia &&
        !hasPoll &&
        !hasLocation;
    final String e2eeFallback = e2eeDecryptionFailed
        ? l10nForE2ee.chat_e2ee_decrypt_failed_open_devices
        : l10nForE2ee.chat_e2ee_encrypted_message_placeholder;
    final displayPlain = hasE2eeOnlyCiphertext ? e2eeFallback : plain;
    final hasText = displayPlain.trim().isNotEmpty;

    if (pollId.isNotEmpty) {
      return _ContextMenuTextSummaryBubble(
        scheme: scheme,
        isCurrentUser: isCurrentUser,
        summary: AppLocalizations.of(context)!.chat_poll_label,
        outgoingBubbleColor: outgoingBubbleColor,
        incomingBubbleColor: incomingBubbleColor,
      );
    }
    if (message.locationShare != null && message.attachments.isEmpty) {
      return _ContextMenuTextSummaryBubble(
        scheme: scheme,
        isCurrentUser: isCurrentUser,
        summary: AppLocalizations.of(context)!.chat_location_label,
        outgoingBubbleColor: outgoingBubbleColor,
        incomingBubbleColor: incomingBubbleColor,
      );
    }

    /// Медиа (фото, стикер, GIF, видео, голос, файл) — то же превью, что в ленте, паритет с веб.
    if (hasText &&
        !hasE2eeOnlyCiphertext &&
        isOnlyEmojisMessage(html) &&
        pollId.isEmpty &&
        message.locationShare == null &&
        message.attachments.isEmpty) {
      return Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            displayPlain.trim(),
            textAlign: isCurrentUser ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              fontSize: menuPureEmojiFontSize,
              height: 1.05,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    if (message.attachments.isNotEmpty) {
      return Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: SizedBox(
          width: 272,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MessageAttachments(
                attachments: message.attachments,
                alignRight: isCurrentUser,
                messageId: message.id,
                messageCreatedAt: message.createdAt,
                isMine: isCurrentUser,
                deliveryStatus: message.deliveryStatus,
                readAt: message.readAt,
                showTimestamps: false,
              ),
              if (hasText) ...[
                const SizedBox(height: 8),
                _ContextMenuTextSummaryBubble(
                  scheme: scheme,
                  isCurrentUser: isCurrentUser,
                  summary: displayPlain.trim(),
                  outgoingBubbleColor: outgoingBubbleColor,
                  incomingBubbleColor: incomingBubbleColor,
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (hasText) {
      return _ContextMenuTextSummaryBubble(
        scheme: scheme,
        isCurrentUser: isCurrentUser,
        summary: displayPlain.trim(),
        maxLines: 5,
        outgoingBubbleColor: outgoingBubbleColor,
        incomingBubbleColor: incomingBubbleColor,
      );
    }

    return _ContextMenuTextSummaryBubble(
      scheme: scheme,
      isCurrentUser: isCurrentUser,
      summary: AppLocalizations.of(context)!.chat_message_empty_placeholder,
      outgoingBubbleColor: outgoingBubbleColor,
      incomingBubbleColor: incomingBubbleColor,
    );
  }
}

class _ContextMenuTextSummaryBubble extends StatelessWidget {
  const _ContextMenuTextSummaryBubble({
    required this.scheme,
    required this.isCurrentUser,
    required this.summary,
    this.maxLines = 5,
    this.outgoingBubbleColor,
    this.incomingBubbleColor,
  });

  final ColorScheme scheme;
  final bool isCurrentUser;
  final String summary;
  final int maxLines;
  final Color? outgoingBubbleColor;
  final Color? incomingBubbleColor;

  @override
  Widget build(BuildContext context) {
    final incomingDefault = scheme.brightness == Brightness.dark
        ? const Color(0xFF2A2D34).withValues(alpha: 0.92)
        : Colors.white;
    final bubbleBg = isCurrentUser
        ? (outgoingBubbleColor ?? const Color(0xFF2A79FF))
        : (incomingBubbleColor ?? incomingDefault);
    final fg = bubbleBg.computeLuminance() > 0.64
        ? Colors.black.withValues(alpha: 0.86)
        : Colors.white.withValues(alpha: 0.95);
    final borderColor = isCurrentUser
        ? bubbleBg.withValues(alpha: 0.86)
        : Colors.white.withValues(alpha: 0.24);

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: bubbleBg,
          border: Border.all(color: borderColor),
        ),
        child: Text(
          summary,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.25,
            color: fg,
          ),
        ),
      ),
    );
  }
}

/// Цитата «ответа» — первый блок стеклянной карточки, без зазора сверху.
class _MenuReplyQuote extends StatelessWidget {
  const _MenuReplyQuote({required this.replyTo});

  final ReplyContext replyTo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rawText = (replyTo.text ?? '').trim();
    final preview = rawText.isEmpty
        ? AppLocalizations.of(context)!.chat_message_empty_placeholder
        : (rawText.contains('<') ? messageHtmlToPlainText(rawText) : rawText);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          left: BorderSide(
            color: scheme.primary.withValues(alpha: 0.55),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyTo.senderName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader({required this.sent, this.read, this.expireAt});

  final DateTime sent;
  final DateTime? read;
  final DateTime? expireAt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final muted = Colors.white.withValues(alpha: 0.42);
    final strong = Colors.white.withValues(alpha: 0.88);
    final readBlue = const Color(0xFF60A5FA);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  l10n.message_menu_header_sent,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: muted,
                  ),
                ),
              ),
              Text(
                _formatMenuDateTime(sent),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: strong,
                ),
              ),
            ],
          ),
          if (read != null) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    l10n.message_menu_header_read,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: muted,
                    ),
                  ),
                ),
                Text(
                  _formatMenuDateTime(read!),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: readBlue,
                  ),
                ),
              ],
            ),
          ],
          if (expireAt != null) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    l10n.message_menu_header_expire_at,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: muted,
                    ),
                  ),
                ),
                Text(
                  _formatMenuDateTime(expireAt!),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: Color(0xFFFCD34D),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReactionStrip extends StatelessWidget {
  const _ReactionStrip({required this.onPick});

  final void Function(String emoji) onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            for (final e in kMessageContextReactionEmojis) ...[
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    unawaited(ChatHaptics.instance.reactionBurst());
                    onPick(e);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      e,
                      style: const TextStyle(fontSize: 28, height: 1),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final fg = danger
        ? const Color(0xFFF87171)
        : Colors.white.withValues(alpha: 0.92);
    final iconFg = danger
        ? const Color(0xFFF87171)
        : Colors.white.withValues(alpha: 0.62);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white.withValues(alpha: danger ? 0.08 : 0.12),
        highlightColor: Colors.white.withValues(alpha: danger ? 0.06 : 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconFg),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<MessageMenuResult?> showOutboxFailedContextMenu(
  BuildContext context, {
  required ChatMessage message,
  String chatFontSize = 'medium',
  Color? outgoingBubbleColor,
}) {
  final initiatorPureEmojiSize = pureEmojiMessageFontSize(chatFontSize);
  return showGeneralDialog<MessageMenuResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, anim, secAnim) {
      return _OutboxFailedContextMenuPage(
        message: message,
        initiatorPureEmojiSize: initiatorPureEmojiSize,
        outgoingBubbleColor: outgoingBubbleColor,
      );
    },
    transitionBuilder: (ctx, anim, secAnim, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.96,
            end: 1,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
    },
  );
}

class _OutboxFailedContextMenuPage extends StatelessWidget {
  const _OutboxFailedContextMenuPage({
    required this.message,
    required this.initiatorPureEmojiSize,
    this.outgoingBubbleColor,
  });

  final ChatMessage message;
  final double initiatorPureEmojiSize;
  final Color? outgoingBubbleColor;

  void _pop(BuildContext context, MessageMenuResult r) {
    Navigator.of(context).pop(r);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxH = MediaQuery.sizeOf(context).height * 0.78;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _pop(context, MessageMenuResult.dismissed),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(color: Colors.black.withValues(alpha: 0.40)),
              ),
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: () {},
              behavior: HitTestBehavior.deferToChild,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 272, maxHeight: maxH),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ContextMenuInitiatorPreview(
                        message: message,
                        isCurrentUser: true,
                        menuPureEmojiFontSize: initiatorPureEmojiSize,
                        outgoingBubbleColor: outgoingBubbleColor,
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                          child: Container(
                            width: 272,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _MenuTile(
                                    icon: Icons.refresh_rounded,
                                    label: l10n.chat_outbox_retry,
                                    onTap: () => _pop(
                                      context,
                                      const MessageMenuResult(
                                        MessageMenuActionType.outboxRetry,
                                      ),
                                    ),
                                  ),
                                  _MenuTile(
                                    icon: Icons.close_rounded,
                                    label: l10n.chat_outbox_cancel,
                                    danger: true,
                                    onTap: () => _pop(
                                      context,
                                      const MessageMenuResult(
                                        MessageMenuActionType.outboxCancel,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Копирование текста сообщения (паритет веб `onCopy`).
Future<void> copyMessageTextToClipboard(ChatMessage message) async {
  final html = (message.text ?? '').trim();
  if (html.isEmpty) return;
  final plain = html.contains('<') ? messageHtmlToPlainText(html) : html;
  await Clipboard.setData(ClipboardData(text: plain));
}
