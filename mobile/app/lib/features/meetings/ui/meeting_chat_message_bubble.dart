import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../data/meeting_chat_message.dart';

/// Набор быстрых реакций над контекстным меню — совпадает с web и
/// общим чатом мобилки.
const List<String> kMeetingChatQuickReactions = <String>[
  '❤️', '👍', '🔥', '🎉', '😂', '😮', '😢', '🙏', '👏', '🤔', '👀', '💯', '🚀',
];

/// Результат, возвращаемый контекстным меню сообщения. `null` — отмена.
sealed class MeetingChatMenuResult {
  const MeetingChatMenuResult();
}

class MeetingChatMenuReply extends MeetingChatMenuResult {
  const MeetingChatMenuReply();
}

class MeetingChatMenuCopy extends MeetingChatMenuResult {
  const MeetingChatMenuCopy();
}

class MeetingChatMenuEdit extends MeetingChatMenuResult {
  const MeetingChatMenuEdit();
}

class MeetingChatMenuDelete extends MeetingChatMenuResult {
  const MeetingChatMenuDelete();
}

class MeetingChatMenuReact extends MeetingChatMenuResult {
  const MeetingChatMenuReact(this.emoji);
  final String emoji;
}

/// Пузырёк сообщения чата митинга: текст, сетка изображений, файлы,
/// long-press → меню (паритет с основным чатом мобилки). Внешние коллбеки
/// отвечают за бизнес-логику.
class MeetingChatMessageBubble extends StatelessWidget {
  const MeetingChatMessageBubble({
    super.key,
    required this.message,
    required this.isSelf,
    required this.selfUserId,
    this.onEditText,
    this.onDelete,
    this.onReply,
    this.onToggleReaction,
  });

  final MeetingChatMessage message;
  final bool isSelf;
  final String selfUserId;
  final void Function(MeetingChatMessage msg)? onEditText;
  final VoidCallback? onDelete;
  final void Function(MeetingChatMessage msg)? onReply;
  final void Function(MeetingChatMessage msg, String emoji, bool currentlyReacted)?
      onToggleReaction;

  String _timeLabel() {
    final d = message.createdAt?.toLocal();
    if (d == null) return '';
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _openUrl(String url) async {
    final u = Uri.tryParse(url);
    if (u == null) return;
    await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(color: Colors.white54),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(ctx).padding.top + 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onLongPress(BuildContext context) async {
    if (message.isDeleted) return;
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.selectionClick();

    final canEdit = isSelf && onEditText != null &&
        (message.text != null && message.text!.isNotEmpty);
    final canDelete = isSelf && onDelete != null;
    final canCopy = message.text != null && message.text!.isNotEmpty;
    final canReply = onReply != null;
    final canReact = onToggleReaction != null;

    final result = await showGeneralDialog<MeetingChatMenuResult>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'meeting-chat-menu',
      // Прозрачный barrier — фон будем сами размывать ImageFilter'ом
      // внутри transition'а; иначе чёрная подложка перекрывает blur.
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, anim, _) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, _) {
        final eased = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return Stack(
          fit: StackFit.expand,
          children: [
            // Полноэкранный blur + лёгкое затемнение — как в основном чате.
            FadeTransition(
              opacity: eased,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.32),
                ),
              ),
            ),
            FadeTransition(
              opacity: eased,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1.0).animate(eased),
                child: _MeetingChatMenu(
                  message: message,
                  selfUserId: selfUserId,
                  isSelf: isSelf,
                  canReply: canReply,
                  canReact: canReact,
                  canCopy: canCopy,
                  canEdit: canEdit,
                  canDelete: canDelete,
                  l10n: l10n,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result == null || !context.mounted) return;
    switch (result) {
      case MeetingChatMenuReply():
        onReply?.call(message);
      case MeetingChatMenuCopy():
        await Clipboard.setData(ClipboardData(text: message.text ?? ''));
        if (context.mounted) {
          HapticFeedback.selectionClick();
          _showCopiedToast(context, l10n.meeting_chat_copied);
        }
      case MeetingChatMenuEdit():
        onEditText?.call(message);
      case MeetingChatMenuDelete():
        onDelete?.call();
      case MeetingChatMenuReact(:final emoji):
        final reacted =
            (message.reactions[emoji] ?? const <String>[]).contains(selfUserId);
        onToggleReaction?.call(message, emoji, reacted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (message.isDeleted) {
      return Align(
        alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_outline_rounded,
                  size: 14, color: Colors.white38),
              const SizedBox(width: 6),
              Text(
                l10n.meeting_chat_deleted,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final images = message.attachments.where((a) => a.isImage).toList();
    final files = message.attachments.where((a) => !a.isImage).toList();
    final bg = isSelf ? const Color(0xFF2563EB) : const Color(0xFF1F2937);
    final fg = Colors.white;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: Radius.circular(isSelf ? 14 : 4),
      bottomRight: Radius.circular(isSelf ? 4 : 14),
    );
    final hasReactions = message.reactions.isNotEmpty;
    return Align(
      alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: GestureDetector(
          onLongPress: () => _onLongPress(context),
          child: Column(
            crossAxisAlignment:
                isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(color: bg, borderRadius: radius),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isSelf)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                        child: Text(
                          message.senderName,
                          style: const TextStyle(
                            color: Color(0xFF93C5FD),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (message.replyTo != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                        child: _ReplyQuote(reply: message.replyTo!),
                      ),
                    if (images.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: images.length > 1 ? 2 : 1,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                          ),
                          itemCount: images.length,
                          itemBuilder: (ctx, i) {
                            final a = images[i];
                            return GestureDetector(
                              onTap: () => _showFullImage(context, a.url),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: CachedNetworkImage(
                                  imageUrl: a.url,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.black26,
                                    child: const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.black38,
                                    child: const Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    if (files.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                        child: Column(
                          children: files
                              .map(
                                (a) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    Icons.insert_drive_file_rounded,
                                    color: fg.withValues(alpha: 0.9),
                                  ),
                                  title: Text(
                                    a.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: fg, fontSize: 13),
                                  ),
                                  onTap: () => _openUrl(a.url),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    if (message.text != null)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          12,
                          !isSelf || message.replyTo != null ? 4 : 8,
                          12,
                          0,
                        ),
                        child: Text(
                          message.text!,
                          style: TextStyle(
                              color: fg, fontSize: 14, height: 1.25),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _timeLabel(),
                            style: TextStyle(
                              color: fg.withValues(alpha: 0.55),
                              fontSize: 10,
                            ),
                          ),
                          if (message.updatedAt != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              l10n.meeting_chat_edited_mark,
                              style: TextStyle(
                                color: fg.withValues(alpha: 0.55),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (hasReactions)
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 4),
                  child: _ReactionsRow(
                    reactions: message.reactions,
                    selfUserId: selfUserId,
                    onTap: onToggleReaction == null
                        ? null
                        : (emoji, reacted) =>
                            onToggleReaction!(message, emoji, reacted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplyQuote extends StatelessWidget {
  const _ReplyQuote({required this.reply});
  final MeetingChatReplyTo reply;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: Colors.white.withValues(alpha: 0.55),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            reply.senderName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (reply.preview.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              reply.preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReactionsRow extends StatelessWidget {
  const _ReactionsRow({
    required this.reactions,
    required this.selfUserId,
    required this.onTap,
  });
  final Map<String, List<String>> reactions;
  final String selfUserId;
  final void Function(String emoji, bool currentlyReacted)? onTap;

  @override
  Widget build(BuildContext context) {
    final entries = reactions.entries.toList(growable: false);
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final e in entries)
          _ReactionChip(
            emoji: e.key,
            count: e.value.length,
            reacted: e.value.contains(selfUserId),
            onTap: onTap == null
                ? null
                : () => onTap!(e.key, e.value.contains(selfUserId)),
          ),
      ],
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.reacted,
    required this.onTap,
  });
  final String emoji;
  final int count;
  final bool reacted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: reacted
              ? const Color(0xFF2563EB).withValues(alpha: 0.30)
              : Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: reacted
                ? const Color(0xFF60A5FA).withValues(alpha: 0.60)
                : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            if (count > 1) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Полупрозрачное контекстное меню сообщения. Зеркалит структуру меню
/// основного чата мобилки — лента быстрых реакций сверху и список действий
/// ниже.
class _MeetingChatMenu extends StatelessWidget {
  const _MeetingChatMenu({
    required this.message,
    required this.selfUserId,
    required this.isSelf,
    required this.canReply,
    required this.canReact,
    required this.canCopy,
    required this.canEdit,
    required this.canDelete,
    required this.l10n,
  });

  final MeetingChatMessage message;
  final String selfUserId;
  final bool isSelf;
  final bool canReply;
  final bool canReact;
  final bool canCopy;
  final bool canEdit;
  final bool canDelete;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // Material обёртка кругом всего диалога: убирает «жёлтые подчёркивания»
    // под текстом (Text без Material-предка получает дефолтный textStyle
    // с TextDecoration.underline жёлтого цвета).
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Превью исходного сообщения сверху — как в основном чате
                // (см. screenshot #4: «SENT» metadata + сам пузырёк).
                _SourceMessagePreview(message: message, isSelf: isSelf),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0x99101521),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (canReact) _reactionStrip(context),
                          if (canReact)
                            Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          if (canReply)
                            _tile(
                              context,
                              icon: Icons.reply_rounded,
                              label: l10n.meeting_chat_reply,
                              onTap: () => Navigator.of(context)
                                  .pop(const MeetingChatMenuReply()),
                            ),
                          if (canCopy)
                            _tile(
                              context,
                              icon: Icons.copy_rounded,
                              label: l10n.meeting_chat_copy,
                              onTap: () => Navigator.of(context)
                                  .pop(const MeetingChatMenuCopy()),
                            ),
                          if (canEdit)
                            _tile(
                              context,
                              icon: Icons.edit_rounded,
                              label: l10n.meeting_chat_edit,
                              onTap: () => Navigator.of(context)
                                  .pop(const MeetingChatMenuEdit()),
                            ),
                          if (canDelete)
                            _tile(
                              context,
                              icon: Icons.delete_outline_rounded,
                              label: l10n.meeting_chat_delete,
                              danger: true,
                              onTap: () => Navigator.of(context)
                                  .pop(const MeetingChatMenuDelete()),
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
    );
  }

  /// Лента быстрых реакций. ВАЖНО: контейнер фиксированной ширины
  /// (ConstrainedBox в build()), а эмодзи скроллятся по горизонтали внутри.
  /// Раньше Wrap растягивал меню вширь под количество эмодзи.
  Widget _reactionStrip(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ScrollConfiguration(
        // Прячем скроллбар на эмодзи-ленте — лента короткая, скролл-индикатор
        // отвлекает внимание.
        behavior: const ScrollBehavior().copyWith(scrollbars: false),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          physics: const BouncingScrollPhysics(),
          itemCount: kMeetingChatQuickReactions.length,
          separatorBuilder: (_, _) => const SizedBox(width: 2),
          itemBuilder: (ctx, i) {
            final e = kMeetingChatQuickReactions[i];
            final reacted = (message.reactions[e] ?? const <String>[])
                .contains(selfUserId);
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () =>
                  Navigator.of(context).pop(MeetingChatMenuReact(e)),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: reacted
                      ? const Color(0xFF2563EB).withValues(alpha: 0.30)
                      : Colors.transparent,
                ),
                child:
                    Text(e, style: const TextStyle(fontSize: 24, height: 1)),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final color = danger ? const Color(0xFFF87171) : Colors.white;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                // Без явного decoration: none ловим дефолтное жёлтое
                // подчёркивание из навигатора (без MaterialApp).
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Кратковременный текстовый тоаст «Скопировано» по центру верха.
/// Раньше использовали SnackBar внизу — пользователь его не замечал
/// (нижняя панель управления митингом перекрывала).
void _showCopiedToast(BuildContext context, String label) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _CopiedToast(
      label: label,
      onDone: () {
        entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _CopiedToast extends StatefulWidget {
  const _CopiedToast({required this.label, required this.onDone});
  final String label;
  final VoidCallback onDone;

  @override
  State<_CopiedToast> createState() => _CopiedToastState();
}

class _CopiedToastState extends State<_CopiedToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    _fade = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 12),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 28),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 12),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 88),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (ctx, _) {
            return Transform.translate(
              offset: Offset(0, _slide.value),
              child: Opacity(
                opacity: _fade.value,
                child: Padding(
                  padding: const EdgeInsets.only(top: 56),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xE6101521),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 18,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF34D399), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            widget.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
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

/// Заголовок диалога: превью исходного сообщения + плашка «SENT … READ …».
/// Дизайн зеркалит screen #4 из основного чата.
class _SourceMessagePreview extends StatelessWidget {
  const _SourceMessagePreview({required this.message, required this.isSelf});

  final MeetingChatMessage message;
  final bool isSelf;

  String _format(DateTime d) {
    final loc = d.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(loc.day)}.${two(loc.month)}.${loc.year} '
        '${two(loc.hour)}:${two(loc.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final bg = isSelf ? const Color(0xFF2563EB) : const Color(0xFF1F2937);
    final text = message.text;
    final sent = message.createdAt;
    return Align(
      alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          crossAxisAlignment:
              isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isSelf ? 14 : 4),
                  bottomRight: Radius.circular(isSelf ? 4 : 14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isSelf)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        message.senderName,
                        style: const TextStyle(
                          color: Color(0xFF93C5FD),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  if (text != null && text.isNotEmpty)
                    Text(
                      text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        decoration: TextDecoration.none,
                      ),
                    )
                  else if (message.attachments.isNotEmpty)
                    Text(
                      '📎 ${message.attachments.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        decoration: TextDecoration.none,
                      ),
                    ),
                ],
              ),
            ),
            if (sent != null) ...[
              const SizedBox(height: 6),
              Text(
                _format(sent),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
