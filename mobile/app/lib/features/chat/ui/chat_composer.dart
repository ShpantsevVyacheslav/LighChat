import 'dart:async' show unawaited;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback, SystemChannels;
import 'package:image_picker/image_picker.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../data/composer_attachment_limits.dart';
import '../data/composer_html_editing.dart';
import '../data/link_preview_url_extractor.dart';
import '../data/native_composer_flag.dart';
import '../../../l10n/app_localizations.dart';
import 'composer_attachment_menu.dart';
import 'composer_editing_banner.dart';
import 'composer_format_sheet.dart';
import 'composer_formatting_toolbar.dart';
import 'composer_link_preview.dart';
import 'composer_pending_attachments_strip.dart';
import 'composer_pending_location_preview.dart';
import 'composer_reply_banner.dart';
import 'native_ios_composer_field.dart';
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
    this.limitsState,
    this.sendBlockedByLimits = false,
    required this.onMicTap,
    required this.onStickersTap,
    this.onKeyboardTap,
    this.stickersPanelOpen = false,
    this.stickersPanelHideSideButtons = false,
    this.hasFooterBelow = false,
    this.stickersSearchHint,
    this.onStickersSearchChanged,
    this.replyingTo,
    this.onCancelReply,
    this.editingPreviewPlain,
    this.onCancelEdit,
    this.showFormattingToolbar = false,
    this.onCloseFormattingToolbar,
    this.aiAvailable = false,
    this.onRewriteWithAi,
    this.onClipboardToolbarPaste,
    this.onNativeStickerInserted,
    this.pendingLocationShare,
    this.pendingLocationDurationId,
    this.onCancelPendingLocationShare,
    this.locationPanelOpen = false,
    this.onCloseLocationPanel,
    this.onLocationAddressSubmit,
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

  /// Снимок лимитов вложений для текущего черновика. Когда `isOverLimit`,
  /// под полосой превью показываем предупреждение, а send-кнопку блокируем
  /// через [sendBlockedByLimits].
  final ComposerLimitsState? limitsState;

  /// Когда `true`, кнопка отправки рендерится в disabled-виде с тултипом.
  /// Не используем `sendBusy` для этого — там визуально прогресс-индикатор,
  /// и пользователь не поймёт, что причина именно в лимите.
  final bool sendBlockedByLimits;
  final VoidCallback onMicTap;
  final VoidCallback onStickersTap;
  final VoidCallback? onKeyboardTap;
  final bool stickersPanelOpen;

  /// На странице менеджера пакетов (fullscreen sticker-режим) скрываем
  /// «+» и микрофон — на этой странице нельзя отправить сообщение,
  /// и боковые кнопки только вводят в заблуждение (Bug #6).
  final bool stickersPanelHideSideButtons;

  /// Если true, под composer'ом уже зарезервирована высота (sticker-шторка,
  /// клавиатурный inset или удержанный «пол» во время перехода между ними).
  /// В таком случае composer НЕ добавляет нижний SafeArea — иначе при
  /// переключении keyboard↔panel композер прыгает на ~34 px (home-indicator).
  final bool hasFooterBelow;
  final String? stickersSearchHint;
  final ValueChanged<String>? onStickersSearchChanged;
  final ReplyContext? replyingTo;
  final VoidCallback? onCancelReply;
  final String? editingPreviewPlain;
  final VoidCallback? onCancelEdit;
  final bool showFormattingToolbar;
  final VoidCallback? onCloseFormattingToolbar;

  /// Доступен ли Apple Intelligence (iOS 18.1+/26+) — для показа кнопки
  /// «Переписать с AI» в formatting toolbar.
  final bool aiAvailable;

  /// Callback при тапе на «Переписать с AI». Открывает sheet с вариантами
  /// стиля. Если `null` — кнопка скрыта.
  final VoidCallback? onRewriteWithAi;

  /// Вставка из буфера (текст + файлы) при «Вставить» в контекстном меню поля.
  final Future<void> Function()? onClipboardToolbarPaste;

  /// Phase 8 (native composer only): пользователь вставил стикер/memoji/
  /// genmoji через системную emoji-клавиатуру. Native UITextView сохранил
  /// каждое изображение в tmp PNG-файл и передал абсолютные пути сюда.
  /// Caller должен добавить файлы в `pendingAttachments` как обычные
  /// изображения (XFile). Если callback null — стикеры будут проигнорированы.
  final Future<void> Function(List<String> paths)? onNativeStickerInserted;

  /// Phase 10 (iMessage-paritет): pending location share, который висит
  /// inline над композером после тапа «Поделиться геолокацией». Если
  /// null — превью карты не рисуется. После Send или тапа на крестик
  /// caller обнуляет state.
  final ChatLocationShare? pendingLocationShare;

  /// id выбранной длительности (`once` / `h1` / `until_end_of_day` /
  /// `forever`). Может быть null, если duration ещё не выбрана —
  /// в этом случае на превью показывается «выбрать длительность».
  final String? pendingLocationDurationId;

  /// Тап на крестик в превью карты — caller сбрасывает pending location.
  final VoidCallback? onCancelPendingLocationShare;

  /// Bug #1: открыта ли location-share панель под композером. Когда
  /// `true`, скрываем боковые кнопки «+» и микрофон и показываем
  /// справа стеклянный круглый крестик для закрытия панели.
  final bool locationPanelOpen;

  /// Bug #1: callback на тап X-кнопки в композере при открытой
  /// location panel. Caller должен закрыть панель (см.
  /// `_closeLocationPanel` в chat_screen).
  final VoidCallback? onCloseLocationPanel;

  /// Bug A: пользователь тапнул Search-кнопку клавиатуры в режиме
  /// location-share (returnKeyType=.search). Caller форсирует
  /// forwardGeocode для текущего текста + скрывает клавиатуру.
  final VoidCallback? onLocationAddressSubmit;

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
  State<ChatComposer> createState() => ChatComposerState();
}

/// Публичный State чтобы chat_screen мог через GlobalKey прицельно
/// дёрнуть focus на native composer (см. [focusComposer]) — это
/// нужно для panel→keyboard transition, где listener-путь не успевает
/// из-за async-mount PlatformView.
class ChatComposerState extends State<ChatComposer> {
  /// Как строка поиска на экране списка чатов (`chat_list_screen`: высота 40, radius 14).
  static const double _kComposerControlSize = 40;

  /// Согласовано с `fontSize: 16` без forceStrut — курсор не растягивается на всю капсулу.
  static const double _kComposerCursorHeight = 18;
  final GlobalKey _composerColumnKey = GlobalKey();
  final GlobalKey _sendButtonKey = GlobalKey();
  // GlobalKey для native composer'а — нужен чтобы [showComposerFormatSheet]
  // мог вызвать `toggleFormat` на конкретном инстансе UITextView.
  final GlobalKey<NativeIosComposerFieldState> _nativeFieldKey =
      GlobalKey<NativeIosComposerFieldState>();
  OverlayEntry? _attachmentOverlayEntry;
  OverlayEntry? _sendLongPressMenuEntry;
  bool _hasTypedText = false;
  // Feature flag: использовать ли нативный UITextView (Phase 1) вместо
  // Flutter `TextField`. Загружается асинхронно из SharedPreferences;
  // до загрузки и на не-iOS платформах — всегда false.
  bool _useNativeComposer = false;
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
    final raw = widget.controller.text;
    // Сначала ищем явные `<a href="...">` (link, добавленный через
    // Format popover) — приоритет, потому что это «пользовательский»
    // выбор URL. Если нет — fallback на URL в plain тексте.
    String? extracted = _firstHrefInHtml(raw);
    extracted ??= extractFirstHttpUrl(messageHtmlToPlainText(raw));
    final next =
        (extracted == null || _dismissedLinkPreviewUrls.contains(extracted))
        ? null
        : extracted;
    if (next == _linkPreviewUrl) return false;
    _linkPreviewUrl = next;
    return true;
  }

  /// Первая href-ссылка из `<a href="...">…</a>` тега в HTML. Берём
  /// только http/https значения (защита от javascript: / data:).
  static final RegExp _hrefRe = RegExp(
    r'<a\s+[^>]*href\s*=\s*(["' "'" r'])([^"' "'" r']+)\1',
    caseSensitive: false,
  );
  String? _firstHrefInHtml(String html) {
    if (!html.contains('<a')) return null;
    final m = _hrefRe.firstMatch(html);
    if (m == null) return null;
    final href = m.group(2)?.trim();
    if (href == null || href.isEmpty) return null;
    final lower = href.toLowerCase();
    if (!lower.startsWith('http://') && !lower.startsWith('https://')) {
      return null;
    }
    return href;
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
    unawaited(NativeComposerFlag.instance.isEnabled().then((v) {
      if (!mounted || v == _useNativeComposer) return;
      setState(() => _useNativeComposer = v);
    }));
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
    // Bug A: переключаем return-key UITextView'я native composer'а
    // когда location panel открывается/закрывается. `search` даёт лупу
    // на клавиатуре и блокирует вставку `\n` (нам не нужен новый
    // абзац — нужен submit для геокодинга).
    if (oldWidget.locationPanelOpen != widget.locationPanelOpen) {
      _nativeFieldKey.currentState?.setReturnKeyType(
        widget.locationPanelOpen ? 'search' : 'default',
      );
    }
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
                        color: (dark ? const Color(0xFF08111B) : Colors.white)
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
                                color: dark
                                    ? Colors.white.withValues(alpha: 0.72)
                                    : scheme.onSurface.withValues(alpha: 0.62),
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
    final screenW = mq.size.width;
    var bottomFrom = 100.0;
    // На desktop overlay рендерится в root Overlay, который покрывает всё
    // окно (включая rail + chat list слева). Чтобы меню не вылезало
    // за пределы detail-панели, считаем горизонтальные оффсеты от
    // RenderBox самого composer'а.
    var leftFrom = 10.0;
    var rightFrom = 10.0;
    if (box != null && box.hasSize) {
      final topLeft = box.localToGlobal(Offset.zero);
      final composerLeft = topLeft.dx;
      final composerRight = composerLeft + box.size.width;
      bottomFrom = (screenH - topLeft.dy).clamp(56.0, screenH);
      leftFrom = (composerLeft + 10).clamp(0.0, screenW);
      rightFrom = (screenW - composerRight + 10).clamp(0.0, screenW);
    }
    _attachmentOverlayEntry = showComposerAttachmentOverlay(
      context: context,
      bottomFromScreenBottom: bottomFrom,
      leftFromScreenLeft: leftFrom,
      rightFromScreenRight: rightFrom,
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

  /// Принудительный focus на native composer'е (минуя focusNode-listener
  /// путь). Используется chat_screen в `_switchFromStickersToKeyboard`
  /// чтобы panel→keyboard transition надёжно поднимал клавиатуру даже
  /// когда новый PlatformView ещё не успел зарегистрировать channel.
  void focusComposer() {
    widget.focusNode.requestFocus();
    _nativeFieldKey.currentState?.focus();
  }

  /// Зеркальный к [focusComposer]: и Flutter focusNode.unfocus(), и
  /// прямой MethodChannel `unfocus` в Swift. Нужен потому что одного
  /// `focusNode.unfocus()` мало — Flutter primaryFocus может не указывать
  /// на наш FocusNode (UITextView держит first-responder снаружи Flutter
  /// focus tree), и listener-путь не отрабатывает. Прямой канал
  /// гарантирует `resignFirstResponder` на Swift-стороне.
  ///
  /// Возвращает Future, который завершается когда Swift отработал
  /// resign. Caller'у важно `await`-ить (см. `_openStickersGifPanelImpl`):
  /// без этого открытие sticker-шторки могло начаться до того как kb
  /// успела начать сворачиваться, и обе панели висели одновременно.
  Future<void> unfocusComposer() async {
    debugPrint(
      '[panel-toggle] unfocusComposer(): focusNode.hasFocus='
      '${widget.focusNode.hasFocus} nativeKey.mounted='
      '${_nativeFieldKey.currentState != null}',
    );
    widget.focusNode.unfocus();
    final native = _nativeFieldKey.currentState;
    if (native == null) {
      debugPrint('[panel-toggle] unfocusComposer(): native=null, skip');
      return;
    }
    await native.unfocus();
    debugPrint('[panel-toggle] unfocusComposer(): done');
  }

  void _openKeyboardFromStickerMode() {
    debugPrint(
      '[panel-toggle] composer keyboard-icon tap (sticker→keyboard) '
      'focus=${widget.focusNode.hasFocus} '
      'cb=${widget.onKeyboardTap != null}',
    );
    final cb = widget.onKeyboardTap;
    if (cb != null) {
      cb();
      return;
    }
    widget.focusNode.requestFocus();
  }

  Widget _buildComposerTextField() {
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
    final inStickerSearchMode =
        widget.stickersPanelOpen && widget.onStickersSearchChanged != null;

    // Native composer (Phase 1+2+3): обычный режим, не sticker-search'е,
    // и НЕ во время hold-to-record overlay.
    //
    // Почему `_holdRecordOverlayVisible` важен: hybrid composition
    // PlatformView не уважает Flutter `AnimatedOpacity:0` снаружи —
    // UITextView рендерится в свой iOS layer поверх Flutter view, и
    // даже при opacity=0 он остаётся виден (включая жёлтую spellCheck
    // wavy-подсветку). Поэтому во время записи войса полностью
    // demount'им native widget — возвращаемся к Flutter `TextField`
    // (он же сам станет невидим под AnimatedOpacity:0).
    //
    // Sticker-search использует короткое single-line поле, нативная
    // UX-плюшка там не нужна.
    if (_useNativeComposer && !inStickerSearchMode && !_holdRecordOverlayVisible) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 6),
              child: NativeIosComposerField(
                key: _nativeFieldKey,
                controller: widget.controller,
                focusNode: widget.focusNode,
                hint: widget.locationPanelOpen
                    ? l10n.location_panel_hint_address
                    : l10n.chat_composer_hint_message,
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
                hintStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: hintFg,
                ),
                cursorColor: scheme.primary,
                minLines: 1,
                maxLines: 6,
                onPasteRequested: paste,
                onAttachmentInserted: widget.onNativeStickerInserted,
                // Bug A: тап Search-кнопки на клавиатуре в режиме
                // location-share — caller сам решает что делать
                // (обычно: пнуть forwardGeocode и спрятать
                // клавиатуру, чтобы юзер видел карту).
                onSubmitted: widget.locationPanelOpen
                    ? (_) => widget.onLocationAddressSubmit?.call()
                    : null,
              ),
            ),
          ),
          // «Aa» уехала из строки композера в floating-кнопку над
          // composer'ом (см. `_buildFormatFloatingButton`), которая
          // появляется/исчезает синхронно с клавиатурой.
          // Bug B: в режиме location-share прячем кнопку
          // стикеров/emoji — в этом контексте она ведёт в side-flow
          // (ввод адреса) и сбивает фокус.
          if (!widget.locationPanelOpen)
            IconButton(
              tooltip: l10n.chat_composer_tooltip_stickers,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              onPressed: widget.sendBusy
                  ? null
                  : (widget.stickersPanelOpen
                        ? _openKeyboardFromStickerMode
                        : _openStickersPanel),
              icon: Icon(
                widget.stickersPanelOpen
                    ? Icons.keyboard_rounded
                    : Icons.emoji_emotions_outlined,
                size: 20,
                color: widget.sendBusy
                    ? hintFg.withValues(alpha: 0.65)
                    : fg.withValues(alpha: 0.88),
              ),
            ),
        ],
      );
    }

    final tf = TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      textCapitalization: TextCapitalization.sentences,
      cursorColor: scheme.primary,
      cursorHeight: _kComposerCursorHeight,
      // Используем `contextMenuBuilder` (а не deprecated `selectionControls`),
      // чтобы получить нативный AdaptiveToolbar: Cupertino-меню на iOS,
      // Material-меню на Android. Override-им только Paste — он должен идти
      // через [paste] callback, чтобы вставлялись файлы из буфера, а не
      // только plain text.
      contextMenuBuilder: (context, editableTextState) {
        final buttonItems = editableTextState.contextMenuButtonItems;
        final patched = paste == null
            ? buttonItems
            : buttonItems.map((item) {
                if (item.type == ContextMenuButtonType.paste) {
                  return ContextMenuButtonItem(
                    onPressed: () {
                      editableTextState.hideToolbar();
                      unawaited(paste());
                    },
                    type: ContextMenuButtonType.paste,
                  );
                }
                return item;
              }).toList(growable: false);
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: patched,
        );
      },
      // В режиме поиска стикеров оставляем 1 строку (поле и так короткое).
      // В обычном composer-е разрешаем расти до 6 строк — дальше включается
      // внутренний скролл, чтобы половина экрана не уходила под composer.
      minLines: 1,
      maxLines: inStickerSearchMode ? 1 : 6,
      keyboardType: TextInputType.multiline,
      // При многострочном тексте центрирование «прижимает» курсор к
      // визуальному центру растущего поля, что выглядит как «прыжки» при
      // переносах. Используем top — каретка остаётся в начале строки.
      textAlignVertical: inStickerSearchMode
          ? TextAlignVertical.center
          : TextAlignVertical.top,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: fg),
      onChanged: inStickerSearchMode ? widget.onStickersSearchChanged : null,
      // В режиме поиска стикеров — кнопка Search на клавиатуре закрывает
      // клавиатуру и сворачивает раскрытую шторку обратно в обычный режим.
      onSubmitted: inStickerSearchMode
          ? (_) {
              widget.focusNode.unfocus();
              SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
            }
          : null,
      decoration: InputDecoration(
        hintText: inStickerSearchMode
            ? (widget.stickersSearchHint ?? l10n.common_search)
            : (widget.locationPanelOpen
                ? l10n.location_panel_hint_address
                : l10n.chat_composer_hint_message),
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
        // Bug B: прячем emoji/stickers suffix в режиме location-share.
        suffixIcon: widget.locationPanelOpen
            ? null
            : IconButton(
                tooltip: l10n.chat_composer_tooltip_stickers,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                    minWidth: 34, minHeight: 34),
                onPressed: widget.sendBusy
                    ? null
                    : (widget.stickersPanelOpen
                          ? _openKeyboardFromStickerMode
                          : _openStickersPanel),
                icon: Icon(
                  widget.stickersPanelOpen
                      ? Icons.keyboard_rounded
                      : Icons.emoji_emotions_outlined,
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
      textInputAction: inStickerSearchMode
          ? TextInputAction.search
          : TextInputAction.newline,
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
    final showSendButton =
        !widget.stickersPanelOpen &&
        // T2: в режиме location panel композер показывает крестик
        // даже при наборе текста (текст — это поисковый запрос
        // адреса, отправка идёт через search-кнопку клавиатуры /
        // «Поделиться» pill, а не send button).
        !widget.locationPanelOpen &&
        (_hasTypedText ||
            widget.pendingAttachments.isNotEmpty ||
            widget.pendingLocationShare != null);
    // Bottom safe-area теперь полностью обслуживается footer'ом снаружи
    // (chat_screen/thread_screen footerHeight включает `viewPadding.bottom`
    // в `reduce(max)`). Внутри композера SafeArea bottom больше не
    // переключаем — это был источник «прыжка»: на последнем кадре
    // kb-анимации hasFooterBelow становился false, SafeArea bottom
    // включался и подкидывал композер вверх на ~34pt после того, как
    // он съезжал вниз вместе с клавиатурой.
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
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
              limitsState: widget.limitsState,
            ),
            // Phase 10 (iMessage-paritет): inline-превью карты pending
            // location share. Показывается между attachment-strip'ом и
            // composer Row'ом, как в Apple Messages.
            if (widget.pendingLocationShare != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: ComposerPendingLocationPreview(
                  share: widget.pendingLocationShare!,
                  durationId: widget.pendingLocationDurationId,
                  onCancel: widget.onCancelPendingLocationShare,
                ),
              ),
            // Phase 4 native composer: B/I/U/S доступны через системное
            // long-press меню iOS (allowsEditingTextAttributes=true) +
            // Writing Tools (iOS 26+) — Flutter formatting toolbar
            // становится избыточным. Скрываем его на iOS-native пути,
            // оставляем для Flutter TextField (Android, ручной off-flag).
            if (widget.showFormattingToolbar &&
                widget.onCloseFormattingToolbar != null &&
                !_useNativeComposer) ...[
              ComposerFormattingToolbar(
                controller: widget.controller,
                focusNode: widget.focusNode,
                onBack: widget.onCloseFormattingToolbar!,
                aiAvailable: widget.aiAvailable,
                onRewriteWithAi: widget.onRewriteWithAi,
              ),
              const SizedBox(height: 8),
            ],
            if (_mentionQuery != null &&
                !widget.stickersPanelOpen &&
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
                !widget.stickersPanelOpen &&
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
                    if (!widget.stickersPanelHideSideButtons &&
                        !widget.locationPanelOpen) ...[
                      Container(
                        width: _kComposerControlSize,
                        height: _kComposerControlSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(
                            alpha:
                                chatWallpaperPrefersLightForeground(wallpaper)
                                ? (dark ? 0.18 : 0.16)
                                : (dark ? 0.06 : 0.08),
                          ),
                          border: Border.all(color: fg.withValues(alpha: 0.18)),
                        ),
                        child: IconButton(
                          tooltip: l10n.chat_composer_tooltip_attachments,
                          onPressed:
                              widget.attachmentsEnabled && !widget.sendBusy
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
                    ],
                    Expanded(
                      child: Container(
                        // minHeight (вместо height) даёт композеру вырасти
                        // вертикально при переносах строк до maxLines TextField
                        // (см. _buildComposerTextField — там maxLines:6).
                        constraints: const BoxConstraints(
                          minHeight: _kComposerControlSize,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.black.withValues(
                            alpha:
                                chatWallpaperPrefersLightForeground(wallpaper)
                                ? (dark ? 0.18 : 0.16)
                                : (dark ? 0.06 : 0.08),
                          ),
                          border: Border.all(color: fg.withValues(alpha: 0.18)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _buildComposerTextField(),
                      ),
                    ),
                    // Phase 14: inline «Aa» bubble — слева от send. Условие
                    // показа основано на `_hasTypedText`, а не focusNode —
                    // hasFocus у Flutter focusNode не всегда успевал
                    // синхронизироваться с native UITextView first-responder
                    // (см. предыдущие фиксы Bug 5/6). _hasTypedText
                    // вычисляется из controller.text, который реальный
                    // источник истины (нативный TextChanged пробрасывает
                    // текст в controller). Размер 40×40 совпадает с send,
                    // визуально пара кнопок справа.
                    // Bug B (parallel branch): inline Aa-кнопка не
                    // показывается в режиме location-share (форматирование
                    // адреса не нужно).
                    if (() {
                      final show = _useNativeComposer &&
                          _hasTypedText &&
                          !widget.stickersPanelOpen &&
                          !widget.locationPanelOpen &&
                          !_holdRecordOverlayVisible;
                      // Лог при каждом rebuild — видно почему Aa
                      // НЕ показывается (какое из 5 условий false).
                      debugPrint(
                        '[format-btn] inline Aa show=$show '
                        '(useNative=$_useNativeComposer '
                        'hasTypedText=$_hasTypedText '
                        'panelOpen=${widget.stickersPanelOpen} '
                        'locationOpen=${widget.locationPanelOpen} '
                        'holdRecord=$_holdRecordOverlayVisible '
                        'textLen=${widget.controller.text.length})',
                      );
                      return show;
                    }()) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: _kComposerControlSize,
                        height: _kComposerControlSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(
                            alpha:
                                chatWallpaperPrefersLightForeground(wallpaper)
                                ? (dark ? 0.18 : 0.16)
                                : (dark ? 0.06 : 0.08),
                          ),
                          border: Border.all(color: fg.withValues(alpha: 0.18)),
                        ),
                        child: IconButton(
                          tooltip: l10n.composer_formatting_title,
                          onPressed: widget.sendBusy
                              ? null
                              : () {
                                  debugPrint(
                                    '[format-popover] inline Aa tap '
                                    '(anchorMounted=${_composerColumnKey.currentContext != null})',
                                  );
                                  unawaited(
                                    showComposerFormatSheet(
                                      context: context,
                                      anchorKey: _composerColumnKey,
                                      onToggle: (tag) => _nativeFieldKey
                                          .currentState
                                          ?.toggleFormat(tag),
                                    ),
                                  );
                                },
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.text_format_rounded,
                            color: widget.sendBusy
                                ? muted.withValues(alpha: 0.75)
                                : fg.withValues(alpha: 0.92),
                          ),
                        ),
                      ),
                    ],
                    if (!widget.stickersPanelHideSideButtons ||
                        showSendButton ||
                        widget.locationPanelOpen) ...[
                      const SizedBox(width: 6),
                      Container(
                      width: _kComposerControlSize,
                      height: _kComposerControlSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: showSendButton
                            ? (widget.sendBlockedByLimits
                                ? scheme.onSurface.withValues(alpha: 0.18)
                                : const Color(0xFF2A79FF))
                            : Colors.black.withValues(
                                alpha:
                                    chatWallpaperPrefersLightForeground(
                                      wallpaper,
                                    )
                                    ? (dark ? 0.18 : 0.16)
                                    : (dark ? 0.06 : 0.08),
                              ),
                        border: showSendButton
                            ? (widget.sendBlockedByLimits
                                ? Border.all(
                                    color: fg.withValues(alpha: 0.18),
                                  )
                                : null)
                            : Border.all(color: fg.withValues(alpha: 0.18)),
                        boxShadow: showSendButton && !widget.sendBlockedByLimits
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
                                    onLongPress: widget.onSendLongPress == null ||
                                            widget.sendBlockedByLimits
                                        ? null
                                        : _showSendLongPressMenu,
                                    child: Tooltip(
                                      message: widget.sendBlockedByLimits
                                          ? l10n.composer_limit_blocking_send
                                          : '',
                                      child: IconButton(
                                        key: _sendButtonKey,
                                        onPressed: widget.sendBlockedByLimits
                                            ? null
                                            : widget.onSend,
                                        iconSize: 18,
                                        icon: Icon(
                                          Icons.send_rounded,
                                          color: widget.sendBlockedByLimits
                                              ? scheme.onSurface
                                                    .withValues(alpha: 0.38)
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                : () {
                                    // Bug #1: при открытой location panel
                                    // справа вместо микрофона — стеклянный
                                    // крестик для закрытия панели. Apple-
                                    // style: тонкий, glass blur через
                                    // прозрачный контейнер; цвет hint
                                    // muted (как иконка mic).
                                    if (widget.locationPanelOpen) {
                                      return IconButton(
                                        tooltip:
                                            l10n.share_location_cancel,
                                        onPressed:
                                            widget.onCloseLocationPanel,
                                        iconSize: 18,
                                        padding: EdgeInsets.zero,
                                        icon: Icon(
                                          Icons.close_rounded,
                                          color: fg.withValues(alpha: 0.92),
                                        ),
                                      );
                                    }
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
                  ],
                ),
              ),
          ],
        ),
    );
  }
}


