import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../l10n/app_localizations.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../data/chat_attachment_upload.dart';
import '../data/giphy_cache_store.dart';
import '../data/giphy_gif_search.dart';
import '../data/user_sticker_item_attachment.dart';
import '../data/recent_stickers_store.dart';
import '../data/user_sticker_packs_repository.dart';
import '../../settings/data/energy_saving_preference.dart';

/// Нижняя панель «Стикеры / GIF» (паритет `ChatStickerGifPanel` + `UserStickersTab`).
///
/// [directUploadConversationId] — если задан, вверху вкладки «Стикеры» показывается
/// блок «С устройства»: выбор из галереи и сразу отправка в чат (как системные стикеры).
Future<void> showComposerStickerGifSheet({
  required BuildContext context,
  required String userId,
  required UserStickerPacksRepository repo,
  required void Function(ChatAttachment attachment) onPickAttachment,
  void Function(String emoji)? onEmojiTapped,
  String? directUploadConversationId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final h = MediaQuery.sizeOf(ctx).height * 0.48;
      return SizedBox(
        height: h,
        child: ComposerStickerGifPanel(
          userId: userId,
          repo: repo,
          directUploadConversationId: directUploadConversationId,
          onPickAttachment: onPickAttachment,
          onEmojiTapped: onEmojiTapped,
          onClose: () => Navigator.of(ctx).pop(),
        ),
      );
    },
  );
}

class ComposerStickerGifPanel extends ConsumerStatefulWidget {
  const ComposerStickerGifPanel({
    super.key,
    required this.userId,
    required this.repo,
    required this.onPickAttachment,
    required this.onClose,
    this.sharedSearchQuery = '',
    this.onSearchHintChanged,
    this.onFullscreenModeChanged,
    this.onEmojiTapped,
    this.directUploadConversationId,
  });

  final String userId;
  final UserStickerPacksRepository repo;
  final String? directUploadConversationId;
  final void Function(ChatAttachment attachment) onPickAttachment;
  final void Function(String emoji)? onEmojiTapped;
  final String sharedSearchQuery;
  final ValueChanged<String>? onSearchHintChanged;
  final ValueChanged<bool>? onFullscreenModeChanged;
  final VoidCallback onClose;

  @override
  ConsumerState<ComposerStickerGifPanel> createState() =>
      _ComposerStickerGifPanelState();
}

/// Эмодзи для быстрых GIF-фильтров (Telegram-style).
const _kGifEmojiFilters = <String>[
  '😂',
  '❤️',
  '🔥',
  '👍',
  '😍',
  '🎉',
  '😢',
  '🤔',
  '🙏',
  '😎',
  '😴',
  '🤯',
];

class _ComposerStickerGifPanelState
    extends ConsumerState<ComposerStickerGifPanel>
    with TickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  String? _myPackId;

  List<ChatAttachment> _recentStickers = [];

  final _gifQueryController = TextEditingController();
  final _gifScrollController = ScrollController();
  Timer? _gifDebounce;
  List<GiphyGifItem> _gifItems = [];
  bool _gifLoading = false;
  bool _gifLoadingMore = false;
  bool _gifHasMore = false;
  int _gifTotal = 0;
  String _gifLastQuery = '';
  String? _gifTranslatedHint;
  bool _gifMissingKey = false;
  String? _activeEmojiFilter;
  List<GiphyGifItem> _recentGifs = [];

  // Анимированные эмодзи (GIPHY v2/emoji).
  final _emojiQueryController = TextEditingController();
  Timer? _emojiDebounce;
  String _emojiLastQuery = '';
  List<GiphyGifItem> _animEmojis = [];
  bool _animEmojisLoading = false;
  bool _animEmojisLoadingMore = false;
  bool _animEmojisHasMore = true;
  final _animEmojisScrollController = ScrollController();

  // GIPHY-стикеры (вкладка «Стикеры» → scope=library).
  final _libraryQueryController = TextEditingController();
  final _libraryScrollController = ScrollController();
  Timer? _libraryDebounce;
  List<GiphyGifItem> _libraryItems = [];
  bool _libraryLoading = false;
  bool _libraryLoadingMore = false;
  bool _libraryHasMore = false;
  int _libraryTotal = 0;
  String _libraryLastQuery = '';
  String? _libraryActiveFilter;
  String? _libraryTranslatedHint;

  bool _deviceDirectBusy = false;

  // Единый флаг видимости всего «chrome'а» шторки (верхние строки каждой
  // вкладки + нижний taб-бар). Скрывается при скролле контента вниз
  // (UserScroll.reverse) и возвращается при скролле вверх (forward) —
  // стандартное «collapsing header» поведение в Telegram/iOS.
  bool _chromeVisible = true;

  // Режим менеджера паков (Telegram-style список паков с возможностью
  // удаления/переименования). Активен только для scope=My и переключается
  // sub-toggle'ом «Stickers / Packs» под scope-toggle'ом.
  bool _showPackManager = false;

  bool _allowGifAutoplay = true;
  bool _allowAnimatedStickers = true;
  bool _allowAnimatedEmoji = true;
  bool _allowInterfaceAnimations = true;
  bool _lastFullscreenMode = false;

  Duration get _uiAnimDuration => _allowInterfaceAnimations
      ? const Duration(milliseconds: 200)
      : Duration.zero;

  Duration get _uiAnimDurationFast => _allowInterfaceAnimations
      ? const Duration(milliseconds: 160)
      : Duration.zero;

  bool get _isFullscreenMode => _tabs.index == 1 && _showPackManager;

  void _syncFullscreenMode() {
    final next = _isFullscreenMode;
    if (_lastFullscreenMode == next) return;
    _lastFullscreenMode = next;
    widget.onFullscreenModeChanged?.call(next);
  }

  bool _recentStickerTickerEnabled(ChatAttachment att) {
    final name = att.name.toLowerCase();
    if (name.startsWith('sticker_emoji_giphy_')) return _allowAnimatedEmoji;
    if (name.startsWith('sticker_')) return _allowAnimatedStickers;
    final type = (att.type ?? '').toLowerCase();
    if (name.startsWith('gif_') || type == 'image/gif') {
      return _allowGifAutoplay;
    }
    return true;
  }

  bool _onTabScroll(ScrollNotification n) {
    if (n is UserScrollNotification && n.metrics.axis == Axis.vertical) {
      if (n.direction == ScrollDirection.reverse && _chromeVisible) {
        setState(() => _chromeVisible = false);
      } else if (n.direction == ScrollDirection.forward && !_chromeVisible) {
        setState(() => _chromeVisible = true);
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _tabs.addListener(_onTabChanged);
    _emojiQueryController.addListener(_scheduleEmojiSearch);
    _emojiQueryController.addListener(_onEmojiQueryChanged);
    _gifQueryController.addListener(_scheduleGifSearch);
    _gifQueryController.addListener(_onGifQueryChanged);
    _gifScrollController.addListener(_onGifScroll);
    _libraryQueryController.addListener(_scheduleLibrarySearch);
    _libraryQueryController.addListener(_onLibraryQueryChanged);
    _animEmojisScrollController.addListener(_onAnimEmojisScroll);
    _libraryScrollController.addListener(_onLibraryScroll);
    _loadInitialData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applySharedSearchQuery(widget.sharedSearchQuery);
      _emitSearchHint();
      _syncFullscreenMode();
    });
  }

  void _onTabChanged() {
    if (!mounted || _tabs.indexIsChanging) return;
    _applySharedSearchQuery(widget.sharedSearchQuery);
    _emitSearchHint();
    _syncFullscreenMode();
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant ComposerStickerGifPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sharedSearchQuery != widget.sharedSearchQuery) {
      _applySharedSearchQuery(widget.sharedSearchQuery);
    }
  }

  TextEditingController _activeSearchController() {
    return switch (_tabs.index) {
      0 => _emojiQueryController,
      1 => _libraryQueryController,
      _ => _gifQueryController,
    };
  }

  String _activeSearchHintText() {
    final l10n = AppLocalizations.of(context)!;
    return switch (_tabs.index) {
      0 => '${l10n.common_search} ${l10n.sticker_tab_emoji.toLowerCase()}',
      1 => l10n.sticker_library_search_hint,
      _ => l10n.gif_search_hint,
    };
  }

  void _emitSearchHint() {
    final cb = widget.onSearchHintChanged;
    if (cb == null) return;
    cb(_activeSearchHintText());
  }

  void _applySharedSearchQuery(String next) {
    final active = _activeSearchController();
    if (active.text == next) return;
    active.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
      composing: TextRange.empty,
    );
  }

  void _scheduleLibrarySearch() {
    _libraryDebounce?.cancel();
    _libraryDebounce = Timer(const Duration(milliseconds: 350), () async {
      final raw = _libraryQueryController.text.trim();
      final effective = raw.isEmpty ? (_libraryActiveFilter ?? '') : raw;
      _libraryLastQuery = effective;
      final cached = await GiphyCacheStore.instance.get(
        GiphyType.stickers,
        effective,
      );
      if (cached != null && cached.isNotEmpty) {
        if (mounted) {
          setState(() {
            _libraryItems = cached;
            _libraryLoading = false;
            _libraryTotal = cached.length;
            _libraryHasMore = true;
            _libraryTranslatedHint = null;
          });
        }
        return;
      }
      if (!mounted) return;
      setState(() => _libraryLoading = true);
      final r = await searchGifs(effective, type: GiphyType.stickers);
      if (!mounted) return;
      setState(() {
        _libraryLoading = false;
        _libraryItems = r.items;
        _libraryTotal = r.total;
        _libraryHasMore = r.hasMore;
        _libraryTranslatedHint =
            (r.translatedFrom != null &&
                r.effectiveQuery != null &&
                r.effectiveQuery != r.translatedFrom)
            ? r.effectiveQuery
            : null;
      });
      if (r.items.isNotEmpty) {
        unawaited(
          GiphyCacheStore.instance.save(GiphyType.stickers, effective, r.items),
        );
      }
    });
  }

  void _selectLibraryEmojiFilter(String? emoji) {
    setState(() => _libraryActiveFilter = emoji);
    _libraryQueryController.clear();
    _scheduleLibrarySearch();
  }

  void _onLibraryScroll() {
    if (!_libraryHasMore || _libraryLoadingMore || _libraryLoading) return;
    final pos = _libraryScrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      unawaited(_loadMoreLibraryStickers());
    }
  }

  Future<void> _loadMoreLibraryStickers() async {
    if (_libraryLoadingMore || !_libraryHasMore) return;
    setState(() => _libraryLoadingMore = true);
    final r = await searchGifs(
      _libraryLastQuery,
      type: GiphyType.stickers,
      offset: _libraryItems.length,
    );
    if (!mounted) return;
    final merged = <GiphyGifItem>[..._libraryItems];
    final existingIds = merged.map((e) => e.id).toSet();
    for (final it in r.items) {
      if (!existingIds.contains(it.id)) merged.add(it);
    }
    setState(() {
      _libraryItems = merged;
      _libraryLoadingMore = false;
      _libraryTotal = r.total > 0 ? r.total : _libraryTotal;
      _libraryHasMore = merged.length < _libraryTotal;
    });
    if (merged.isNotEmpty) {
      unawaited(
        GiphyCacheStore.instance.save(
          GiphyType.stickers,
          _libraryLastQuery,
          merged,
        ),
      );
    }
  }

  void _onGifScroll() {
    if (!_gifHasMore || _gifLoadingMore || _gifLoading) return;
    final pos = _gifScrollController.position;
    // Триггер за 300px до конца — даём время подгрузить.
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      unawaited(_loadMoreGifs());
    }
  }

  Future<void> _loadMoreGifs() async {
    if (_gifLoadingMore || !_gifHasMore) return;
    setState(() => _gifLoadingMore = true);
    final r = await searchGifs(_gifLastQuery, offset: _gifItems.length);
    if (!mounted) return;
    final merged = <GiphyGifItem>[..._gifItems];
    final existingIds = merged.map((e) => e.id).toSet();
    for (final it in r.items) {
      if (!existingIds.contains(it.id)) merged.add(it);
    }
    setState(() {
      _gifItems = merged;
      _gifLoadingMore = false;
      _gifTotal = r.total > 0 ? r.total : _gifTotal;
      _gifHasMore = merged.length < _gifTotal;
    });
    // Аккумулируем в кеш под тем же ключом.
    if (merged.isNotEmpty) {
      unawaited(
        GiphyCacheStore.instance.save(GiphyType.gifs, _gifLastQuery, merged),
      );
    }
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadRecentStickers(),
      _loadRecentGifs(),
      _bootstrapTrendingGifs(),
      _bootstrapTrendingStickers(),
      _bootstrapLibraryStickers(),
    ]);
  }

  Future<void> _bootstrapLibraryStickers() async {
    final cached = await GiphyCacheStore.instance.getTrending(
      GiphyType.stickers,
    );
    if (cached != null && cached.isNotEmpty) {
      if (mounted) {
        setState(() {
          _libraryItems = cached;
          _libraryTotal = cached.length;
          _libraryHasMore = true;
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() => _libraryLoading = true);
    final r = await searchGifs('', type: GiphyType.stickers);
    if (!mounted) return;
    setState(() {
      _libraryLoading = false;
      _libraryItems = r.items;
      _libraryTotal = r.total;
      _libraryHasMore = r.hasMore;
    });
    if (r.items.isNotEmpty) {
      unawaited(
        GiphyCacheStore.instance.saveTrending(GiphyType.stickers, r.items),
      );
    }
  }

  Future<void> _loadRecentGifs() async {
    final list = await GiphyCacheStore.instance.getRecent();
    if (mounted) setState(() => _recentGifs = list);
  }

  Future<void> _bootstrapTrendingGifs() async {
    final cached = await GiphyCacheStore.instance.getTrending(GiphyType.gifs);
    if (cached != null && cached.isNotEmpty) {
      if (mounted) {
        setState(() {
          _gifItems = cached;
          _gifTotal = cached.length;
          _gifHasMore = true;
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() => _gifLoading = true);
    final r = await searchGifs('');
    if (!mounted) return;
    setState(() {
      _gifLoading = false;
      _gifItems = r.items;
      _gifMissingKey = r.missingKey;
      _gifTotal = r.total;
      _gifHasMore = r.hasMore;
    });
    if (r.items.isNotEmpty) {
      unawaited(GiphyCacheStore.instance.saveTrending(GiphyType.gifs, r.items));
    }
  }

  /// Загружает анимированные эмодзи (GIPHY v2/emoji — именно эмодзи).
  /// Из кеша берёт всё что было сохранено (включая ранее догруженные страницы),
  /// затем при первом скролле подгружает следующие порции (см. [_loadMoreAnimEmojis]).
  Future<void> _bootstrapTrendingStickers() async {
    final cached = await GiphyCacheStore.instance.getTrending(GiphyType.emoji);
    if (cached != null && cached.isNotEmpty) {
      if (mounted) {
        setState(() {
          _animEmojis = cached;
          // У кеша нет инфы о hasMore — разрешаем дозагрузку при скролле.
          _animEmojisHasMore = true;
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() => _animEmojisLoading = true);
    final r = await searchGifs('', type: GiphyType.emoji);
    if (!mounted) return;
    setState(() {
      _animEmojisLoading = false;
      _animEmojis = r.items;
      _animEmojisHasMore = r.hasMore;
    });
    if (r.items.isNotEmpty) {
      unawaited(
        GiphyCacheStore.instance.saveTrending(GiphyType.emoji, r.items),
      );
    }
  }

  Future<void> _loadMoreAnimEmojis() async {
    if (_animEmojisLoadingMore || !_animEmojisHasMore) return;
    setState(() => _animEmojisLoadingMore = true);
    final r = await searchGifs(
      _emojiLastQuery,
      type: GiphyType.emoji,
      offset: _animEmojis.length,
    );
    if (!mounted) return;
    final merged = <GiphyGifItem>[..._animEmojis];
    // Дедуп по id и url — защита от случая когда GIPHY возвращает
    // одну и ту же позицию с разными внутренними id (или наоборот).
    final existingIds = merged.map((e) => e.id).toSet();
    final existingUrls = merged.map((e) => e.url).toSet();
    for (final it in r.items) {
      if (existingIds.contains(it.id) || existingUrls.contains(it.url)) {
        continue;
      }
      merged.add(it);
      existingIds.add(it.id);
      existingUrls.add(it.url);
    }
    final addedCount = merged.length - _animEmojis.length;
    setState(() {
      _animEmojis = merged;
      _animEmojisLoadingMore = false;
      // Останавливаемся когда сервер сказал «больше нет», пришла пустая
      // страница, или вся страница оказалась дубликатами (защита от
      // бесконечного фетча на конце GIPHY).
      _animEmojisHasMore = addedCount > 0 && r.hasMore;
    });
    // Эмодзи-кеш: TTL не применяется (см. GiphyCacheStore), поэтому
    // накопленный список доступен между сессиями навсегда.
    if (merged.isNotEmpty) {
      unawaited(GiphyCacheStore.instance.saveTrending(GiphyType.emoji, merged));
    }
  }

  void _onAnimEmojisScroll() {
    if (!_animEmojisHasMore || _animEmojisLoadingMore) return;
    final pos = _animEmojisScrollController.position;
    // Триггер за 200px до конца (горизонтальная полоса).
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      unawaited(_loadMoreAnimEmojis());
    }
  }

  void _scheduleEmojiSearch() {
    _emojiDebounce?.cancel();
    _emojiDebounce = Timer(const Duration(milliseconds: 350), () async {
      final q = _emojiQueryController.text.trim();
      if (!mounted) return;
      _emojiLastQuery = q;
      setState(() => _animEmojisLoading = true);
      final r = await searchGifs(q, type: GiphyType.emoji);
      if (!mounted) return;
      setState(() {
        _animEmojisLoading = false;
        _animEmojis = r.items;
        _animEmojisHasMore = r.hasMore;
      });
      if (q.isEmpty && r.items.isNotEmpty) {
        unawaited(
          GiphyCacheStore.instance.saveTrending(GiphyType.emoji, r.items),
        );
      }
    });
  }

  void _onGifQueryChanged() {
    if (mounted) setState(() {});
  }

  void _onEmojiQueryChanged() {
    if (mounted) setState(() {});
  }

  void _onLibraryQueryChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadRecentStickers() async {
    final list = await RecentStickersStore.instance.getRecents();
    final filtered = list
        .where(
          (att) => !att.name.toLowerCase().startsWith('sticker_emoji_giphy_'),
        )
        .toList(growable: false);
    if (mounted) setState(() => _recentStickers = filtered);
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _emojiDebounce?.cancel();
    _emojiQueryController.removeListener(_scheduleEmojiSearch);
    _emojiQueryController.removeListener(_onEmojiQueryChanged);
    _emojiQueryController.dispose();
    _gifDebounce?.cancel();
    _libraryDebounce?.cancel();
    _gifQueryController.removeListener(_scheduleGifSearch);
    _gifQueryController.removeListener(_onGifQueryChanged);
    _gifQueryController.dispose();
    _gifScrollController.removeListener(_onGifScroll);
    _gifScrollController.dispose();
    _libraryQueryController.removeListener(_scheduleLibrarySearch);
    _libraryQueryController.removeListener(_onLibraryQueryChanged);
    _animEmojisScrollController.removeListener(_onAnimEmojisScroll);
    _animEmojisScrollController.dispose();
    _libraryQueryController.dispose();
    _libraryScrollController.removeListener(_onLibraryScroll);
    _libraryScrollController.dispose();
    _tabs.dispose();
    super.dispose();
  }

  void _scheduleGifSearch() {
    _gifDebounce?.cancel();
    _gifDebounce = Timer(const Duration(milliseconds: 350), () async {
      final q = _gifQueryController.text;
      if (!mounted) return;
      final effectiveQuery = q.trim().isEmpty
          ? (_activeEmojiFilter ?? '')
          : q.trim();
      _gifLastQuery = effectiveQuery;
      // Проверяем кеш по конкретному запросу/фильтру (TTL 24h, LRU 20 ключей).
      final cached = await GiphyCacheStore.instance.get(
        GiphyType.gifs,
        effectiveQuery,
      );
      if (cached != null && cached.isNotEmpty) {
        if (mounted) {
          setState(() {
            _gifItems = cached;
            _gifLoading = false;
            // У кеша нет инфы о total → разрешаем дозагрузку, дочитаем при скролле.
            _gifTotal = cached.length;
            _gifHasMore = true;
            _gifTranslatedHint = null;
          });
        }
        return;
      }
      setState(() => _gifLoading = true);
      final r = await searchGifs(effectiveQuery);
      if (!mounted) return;
      setState(() {
        _gifLoading = false;
        _gifItems = r.items;
        _gifMissingKey = r.missingKey;
        _gifTotal = r.total;
        _gifHasMore = r.hasMore;
        _gifTranslatedHint =
            (r.translatedFrom != null &&
                r.effectiveQuery != null &&
                r.effectiveQuery != r.translatedFrom)
            ? r.effectiveQuery
            : null;
      });
      if (r.items.isNotEmpty) {
        unawaited(
          GiphyCacheStore.instance.save(
            GiphyType.gifs,
            effectiveQuery,
            r.items,
          ),
        );
      }
    });
  }

  void _selectEmojiFilter(String? emoji) {
    setState(() => _activeEmojiFilter = emoji);
    _gifQueryController.clear();
    _scheduleGifSearch();
  }

  Future<void> _onPickGif(GiphyGifItem item) async {
    final att = giphyItemToSendAttachment(item);
    unawaited(GiphyCacheStore.instance.addRecent(item));
    widget.onPickAttachment(att);
    // обновим список «недавних» в UI
    unawaited(_loadRecentGifs());
  }

  /// Анимированный эмодзи отправляется как маленький анимированный sticker
  /// (`sticker_emoji_giphy_*`). Раньше пытались вставить inline custom-emoji
  /// span в html-композер — это ломалось на mobile (TextField не рендерит
  /// WidgetSpan, теги становились видимыми при удалении). Sticker-ветка уже
  /// поддерживается рендерером сообщений и UX совпадает с Telegram.
  void _onPickAnimEmoji(GiphyGifItem item) {
    HapticFeedback.selectionClick();
    final att = giphyItemToSendAttachment(item, asAnimatedEmoji: true);
    widget.onPickAttachment(att);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<String?> _promptNewPackName() async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: l10n.sticker_default_pack_name);
    final id = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF17191D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.sticker_new_pack_dialog_title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ctrl,
                    textCapitalization: TextCapitalization.sentences,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: l10n.sticker_pack_name_hint,
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 42,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2A79FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: () async {
                        final name = ctrl.text;
                        final pid = await widget.repo.createPack(
                          widget.userId,
                          name,
                          l10n: AppLocalizations.of(ctx),
                        );
                        if (ctx.mounted) Navigator.pop(ctx, pid);
                      },
                      child: Text(l10n.common_create),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.11),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.common_cancel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return id;
  }

  Future<String?> _pickPackSheet() async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1a1a1e),
      builder: (ctx) {
        return SafeArea(
          child: StreamBuilder<List<UserStickerPackRow>>(
            stream: widget.repo.watchMyPacks(widget.userId),
            builder: (context, snap) {
              final packs = snap.data ?? [];
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      AppLocalizations.of(context)!.sticker_save_to_pack,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (packs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        AppLocalizations.of(context)!.sticker_no_packs_hint,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final p in packs)
                            ListTile(
                              title: Text(p.name),
                              onTap: () => Navigator.pop(ctx, p.id),
                            ),
                        ],
                      ),
                    ),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: Text(
                      AppLocalizations.of(context)!.sticker_new_pack_option,
                    ),
                    onTap: () async {
                      final id = await _promptNewPackName();
                      if (id != null && ctx.mounted) Navigator.pop(ctx, id);
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _pickFromGalleryAndSendDirect() async {
    final convId = widget.directUploadConversationId;
    if (convId == null || convId.isEmpty) return;
    if (_deviceDirectBusy) return;

    final picker = ImagePicker();
    try {
      final list = await picker.pickMultipleMedia(imageQuality: 92);
      if (list.isEmpty || !mounted) return;
      final images = list.where((x) {
        final m = x.mimeType?.toLowerCase() ?? '';
        final n = x.name.toLowerCase();
        return m.startsWith('image/') ||
            n.endsWith('.gif') ||
            n.endsWith('.png') ||
            n.endsWith('.jpg') ||
            n.endsWith('.jpeg') ||
            n.endsWith('.webp') ||
            n.endsWith('.heic');
      }).toList();
      if (images.isEmpty) {
        _snack(AppLocalizations.of(context)!.sticker_pick_image_or_gif);
        return;
      }
      setState(() => _deviceDirectBusy = true);
      final x = images.first;
      final lower = x.path.toLowerCase();
      String ext = 'jpg';
      if (lower.endsWith('.png')) {
        ext = 'png';
      } else if (lower.endsWith('.gif')) {
        ext = 'gif';
      } else if (lower.endsWith('.webp')) {
        ext = 'webp';
      } else if (lower.endsWith('.heic')) {
        ext = 'heic';
      }
      final att = await uploadChatAttachmentFromXFile(
        storage: FirebaseStorage.instance,
        conversationId: convId,
        file: x,
        displayName: 'sticker_${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      if (!mounted) return;
      setState(() => _deviceDirectBusy = false);
      widget.onPickAttachment(att);
    } catch (e) {
      if (mounted) {
        setState(() => _deviceDirectBusy = false);
        _snack(AppLocalizations.of(context)!.sticker_send_failed(e.toString()));
      }
    }
  }

  Future<void> _saveRemoteToPack(ChatAttachment att) async {
    final packId = await _pickPackSheet();
    if (packId == null || !mounted) return;
    final ok = await widget.repo.addRemoteImageToPack(
      userId: widget.userId,
      packId: packId,
      att: att,
    );
    if (!mounted) return;
    if (ok) {
      _snack(AppLocalizations.of(context)!.sticker_saved_to_pack);
    } else {
      _snack(AppLocalizations.of(context)!.sticker_save_gif_failed);
    }
  }

  Future<void> _confirmDeletePack(String packId, String name) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF17191D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.sticker_delete_pack_title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.sticker_delete_pack_body(name),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 13.5,
                      height: 1.24,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 42,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE24D59),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(21),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.common_delete),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.11),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.common_cancel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (ok != true || !mounted) return;
    final success = await widget.repo.deletePack(widget.userId, packId);
    if (!mounted) return;
    _snack(
      success
          ? AppLocalizations.of(context)!.sticker_pack_deleted
          : AppLocalizations.of(context)!.sticker_pack_delete_failed,
    );
    if (success && _myPackId == packId) {
      setState(() => _myPackId = null);
    }
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildBottomTabs() {
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      l10n.sticker_tab_emoji,
      l10n.sticker_tab_stickers,
      l10n.sticker_tab_gif,
    ];
    Widget pill(int i) {
      final active = _tabs.index == i;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _tabs.animateTo(i),
        child: AnimatedContainer(
          duration: _uiAnimDurationFast,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                labels[i],
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: Colors.white.withValues(alpha: active ? 1.0 : 0.65),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: _uiAnimDurationFast,
                width: 34,
                height: 2,
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withValues(alpha: 0.95)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bottomInset = MediaQuery.of(context).padding.bottom;
    // Bug #4/#5: фон табов прозрачный, под ними просматривается контент
    // (стикеры/эмодзи/гифки). Никакой отдельной полосы внизу — табы парят
    // поверх. Лёгкий gradient-shadow сверху просто намекает на overlay.
    return IgnorePointer(
      ignoring: false,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0),
              Colors.black.withValues(alpha: 0.22),
            ],
          ),
        ),
        padding: EdgeInsets.fromLTRB(0, 6, 0, bottomInset + 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [pill(0), pill(1), pill(2)],
        ),
      ),
    );
  }

  /// Высота нижней tab-полосы для расчёта sliver-padding,
  /// чтобы последние элементы можно было доскроллить из-под табов.
  double _tabBarOverlayHeight(BuildContext context) {
    final inset = MediaQuery.of(context).padding.bottom;
    // 6 (top gradient) + 30 (pill) + 4 (gap) = 40 + inset.
    return inset + 40;
  }

  @override
  Widget build(BuildContext context) {
    final energy = ref.watch(energySavingProvider);
    _allowGifAutoplay = energy.effectiveAutoplayGif;
    _allowAnimatedStickers = energy.effectiveAnimatedStickers;
    _allowAnimatedEmoji = energy.effectiveAnimatedEmoji;
    _allowInterfaceAnimations = energy.effectiveInterfaceAnimations;
    return _glassCard(
      child: Stack(
        children: [
          // Контент занимает всю шторку до самого низа — табы поверх
          // полупрозрачны, контент просвечивает (Bug #4/#5).
          Positioned.fill(
            child: TabBarView(
              controller: _tabs,
              children: [_emojiTab(), _stickersTab(), _gifTab()],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: !_chromeVisible,
              child: AnimatedSlide(
                duration: _uiAnimDurationFast,
                curve: Curves.easeOut,
                offset: _chromeVisible ? Offset.zero : const Offset(0, 1),
                child: AnimatedOpacity(
                  duration: _uiAnimDurationFast,
                  opacity: _chromeVisible ? 1 : 0,
                  child: _buildBottomTabs(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentStickersStrip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recentStickers.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final att = _recentStickers[i];
                return Material(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => widget.onPickAttachment(att),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: TickerMode(
                          enabled: _recentStickerTickerEnabled(att),
                          child: CachedNetworkImage(
                            imageUrl: att.url,
                            fit: BoxFit.contain,
                            placeholder: (_, _) => const SizedBox.shrink(),
                            errorWidget: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
        ],
      ),
    );
  }

  Widget _stickersTab() {
    return NotificationListener<ScrollNotification>(
      onNotification: _onTabScroll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSize(
            duration: _uiAnimDuration,
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _chromeVisible
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 4),
                      // Bug #7/#8: «Galéry» с верха страницы убрана —
                      // загрузка из галереи теперь живёт внутри каждого
                      // пака в менеджере (плюсик в строке пака).
                      _stickersSubToggle(),
                      if (!_showPackManager && _recentStickers.isNotEmpty)
                        _recentStickersStrip(),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: _showPackManager
                ? _packManagerView()
                : _libraryStickersBody(),
          ),
        ],
      ),
    );
  }

  Widget _stickersSubToggle() {
    Widget pill({
      required String label,
      required bool active,
      required VoidCallback onTap,
    }) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: _uiAnimDurationFast,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: active
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Colors.white.withValues(alpha: active ? 1.0 : 0.72),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          pill(
            label: AppLocalizations.of(context)!.sticker_tab_stickers,
            active: !_showPackManager,
            onTap: () => _setPackManager(false),
          ),
          const SizedBox(width: 12),
          pill(
            label: 'Packs',
            active: _showPackManager,
            onTap: () => _setPackManager(true),
          ),
        ],
      ),
    );
  }

  void _setPackManager(bool v) {
    if (_showPackManager == v) return;
    setState(() => _showPackManager = v);
    _syncFullscreenMode();
  }

  /// Telegram-style список моих стикерпаков с возможностью удалить/создать.
  /// Каждая строка: квадратная превью (первый стикер), название, количество
  /// стикеров, кнопка-корзина справа. Сверху — компактная кнопка «+ New pack».
  Widget _packManagerView() {
    final l10n = AppLocalizations.of(context)!;
    final convId = widget.directUploadConversationId;
    return StreamBuilder<List<UserStickerPackRow>>(
      stream: widget.repo.watchMyPacks(widget.userId),
      builder: (context, snap) {
        final packs = snap.data ?? const <UserStickerPackRow>[];
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
            12,
            4,
            12,
            _tabBarOverlayHeight(context) + 8,
          ),
          itemCount: packs.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (context, i) {
            if (i == 0) {
              return _PackManagerNewRow(
                label: l10n.sticker_new_pack_option,
                onTap: () async {
                  final id = await _promptNewPackName();
                  if (id != null && mounted) {
                    setState(() => _myPackId = id);
                    _snack(l10n.sticker_pack_created);
                  }
                },
              );
            }
            final p = packs[i - 1];
            return _PackManagerRow(
              pack: p,
              allowAnimation: _allowAnimatedStickers,
              itemsStream: widget.repo.watchMyPackItems(widget.userId, p.id),
              onTap: () {
                setState(() => _myPackId = p.id);
              },
              onDelete: () => _confirmDeletePack(p.id, p.name),
              onAddFromGallery: (convId == null || convId.isEmpty)
                  ? null
                  : () => unawaited(_pickFromGalleryAndSendDirect()),
            );
          },
        );
      },
    );
  }

  /// Библиотека стикеров из GIPHY (поиск + trending + эмодзи-фильтры).
  Widget _libraryStickersBody() {
    return Column(
      children: [
        if (_libraryTranslatedHint != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
            child: Row(
              children: [
                Icon(
                  Icons.translate_rounded,
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    AppLocalizations.of(
                      context,
                    )!.gif_translated_hint(_libraryTranslatedHint!),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        // Эмодзи-фильтры (паритет с GIF-вкладкой).
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _kGifEmojiFilters.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return _emojiFilterChip(
                    label: AppLocalizations.of(context)!.gif_filter_all,
                    active: _libraryActiveFilter == null,
                    onTap: () => _selectLibraryEmojiFilter(null),
                  );
                }
                final emoji = _kGifEmojiFilters[i - 1];
                return _emojiFilterChip(
                  label: emoji,
                  active: _libraryActiveFilter == emoji,
                  onTap: () => _selectLibraryEmojiFilter(emoji),
                );
              },
            ),
          ),
        ),
        Expanded(
          child: _libraryLoading
              ? const Center(child: CircularProgressIndicator())
              : _libraryItems.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context)!.sticker_gif_nothing_found,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                )
              : CustomScrollView(
                  controller: _libraryScrollController,
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 6)),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                            ),
                        delegate: SliverChildBuilderDelegate((context, i) {
                          final item = _libraryItems[i];
                          return Material(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(10),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                widget.onPickAttachment(
                                  giphyItemToSendAttachment(
                                    item,
                                    asSticker: true,
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: TickerMode(
                                  enabled: _allowAnimatedStickers,
                                  child: CachedNetworkImage(
                                    imageUrl: item.url,
                                    fit: BoxFit.contain,
                                    placeholder: (_, _) =>
                                        const SizedBox.shrink(),
                                    errorWidget: (_, _, _) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }, childCount: _libraryItems.length),
                      ),
                    ),
                    if (_libraryLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ),
                    // Запас под плавающей tab-полосой: контент проходит
                    // ПОД ней, последние элементы можно доскроллить.
                    SliverToBoxAdapter(
                      child: SizedBox(height: _tabBarOverlayHeight(context)),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _gifTab() {
    final hasRecent = _recentGifs.isNotEmpty;
    final showRecent =
        hasRecent &&
        _gifQueryController.text.trim().isEmpty &&
        _activeEmojiFilter == null;
    return NotificationListener<ScrollNotification>(
      onNotification: _onTabScroll,
      child: Column(
        children: [
          AnimatedSize(
            duration: _uiAnimDuration,
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _chromeVisible
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_gifTranslatedHint != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.translate_rounded,
                                size: 12,
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.gif_translated_hint(_gifTranslatedHint!),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.55),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      _gifEmojiFiltersRow(),
                      if (_gifMissingKey)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!.gif_search_unavailable,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: _gifLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
                    controller: _gifScrollController,
                    slivers: [
                      // Микро-отступ перед первой строкой gif'ов / recent header.
                      const SliverToBoxAdapter(child: SizedBox(height: 6)),
                      if (showRecent) ...[
                        SliverToBoxAdapter(
                          child: _gifSectionHeader(
                            Icons.history_rounded,
                            AppLocalizations.of(context)!.sticker_tab_recent,
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          sliver: _gifGridSliver(_recentGifs),
                        ),
                        SliverToBoxAdapter(
                          child: _gifSectionHeader(
                            Icons.trending_up_rounded,
                            'TRENDING',
                          ),
                        ),
                      ],
                      if (_gifItems.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.sticker_gif_nothing_found,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        )
                      else ...[
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          sliver: _gifGridSliver(_gifItems),
                        ),
                        if (_gifLoadingMore)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                      // Запас под плавающей tab-полосой.
                      SliverToBoxAdapter(
                        child: SizedBox(height: _tabBarOverlayHeight(context)),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _gifSectionHeader(IconData icon, String label) {
    final muted = Colors.white.withValues(alpha: 0.45);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: Row(
        children: [
          Icon(icon, size: 12, color: muted),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gifGridSliver(List<GiphyGifItem> items) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      delegate: SliverChildBuilderDelegate((context, i) {
        final item = items[i];
        return Stack(
          fit: StackFit.expand,
          children: [
            Material(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => _onPickGif(item),
                borderRadius: BorderRadius.circular(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: TickerMode(
                    enabled: _allowGifAutoplay,
                    child: CachedNetworkImage(
                      imageUrl: item.url,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 2,
              right: 2,
              child: Material(
                color: Colors.black.withValues(alpha: 0.55),
                shape: const CircleBorder(),
                child: IconButton(
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  onPressed: () =>
                      _saveRemoteToPack(giphyItemToSendAttachment(item)),
                  icon: const Icon(Icons.bookmark_add_outlined),
                ),
              ),
            ),
          ],
        );
      }, childCount: items.length),
    );
  }

  Widget _gifEmojiFiltersRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _kGifEmojiFilters.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (context, i) {
            if (i == 0) {
              final active = _activeEmojiFilter == null;
              return _emojiFilterChip(
                label: AppLocalizations.of(context)!.gif_filter_all,
                active: active,
                onTap: () => _selectEmojiFilter(null),
              );
            }
            final emoji = _kGifEmojiFilters[i - 1];
            final active = _activeEmojiFilter == emoji;
            return _emojiFilterChip(
              label: emoji,
              active: active,
              onTap: () => _selectEmojiFilter(emoji),
            );
          },
        ),
      ),
    );
  }

  Widget _emojiFilterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    // «All»/текст — узкий pill с мелким шрифтом; эмодзи — кружок 30×30.
    // Эмодзи центрируем через FittedBox, чтобы глиф попал точно в центр
    // кружка независимо от внутренних метрик шрифта (часть эмодзи имеют
    // асимметричный bounding box).
    final isText = label.length > 2;
    final bg = active
        ? const Color(0xFF2A79FF).withValues(alpha: 0.28)
        : Colors.white.withValues(alpha: 0.07);
    final borderColor = active
        ? const Color(0xFF2A79FF).withValues(alpha: 0.6)
        : null;

    if (isText) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 30,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(15),
            border: borderColor != null
                ? Border.all(color: borderColor, width: 1)
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              fontSize: 11,
              height: 1.0,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: active ? 1.0 : 0.85),
            ),
          ),
        ),
      );
    }

    // Кружок с эмодзи. У эмодзи асимметричный bounding box (descender'ы
    // глифа сильно меньше), поэтому Text сам по себе уезжает вверх/вбок
    // в круглой рамке. Решение: рисуем эмодзи через `RichText` с явным
    // strut + textHeightBehavior(applyHeightToFirstAscent:false,
    // applyHeightToLastDescent:false) — отключаем «дыхание» под глиф и
    // выравниваем по геометрическому центру через Alignment.center.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: borderColor != null
              ? Border.all(color: borderColor, width: 1)
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
            leadingDistribution: TextLeadingDistribution.even,
          ),
          strutStyle: const StrutStyle(
            forceStrutHeight: true,
            fontSize: 16,
            height: 1.0,
            leading: 0,
          ),
          style: const TextStyle(
            fontSize: 16,
            height: 1.0,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ============ ВКЛАДКА «ЭМОДЗИ» ============

  Widget _emojiTab() {
    final showAnimRow = _animEmojisLoading || _animEmojis.isNotEmpty;
    return NotificationListener<ScrollNotification>(
      onNotification: _onTabScroll,
      child: Column(
        children: [
          AnimatedSize(
            duration: _uiAnimDuration,
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: (_chromeVisible && showAnimRow)
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_animEmojisLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: SizedBox(
                            height: 64,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        )
                      else ...[
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 48,
                          child: ListView.builder(
                            controller: _animEmojisScrollController,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount:
                                _animEmojis.length +
                                ((_animEmojisHasMore || _animEmojisLoadingMore)
                                    ? 1
                                    : 0),
                            itemBuilder: (context, i) {
                              if (i >= _animEmojis.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              final item = _animEmojis[i];
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _onPickAnimEmoji(item),
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: TickerMode(
                                          enabled: _allowAnimatedEmoji,
                                          child: CachedNetworkImage(
                                            imageUrl: item.url,
                                            fit: BoxFit.contain,
                                            placeholder: (_, _) =>
                                                const SizedBox.shrink(),
                                            errorWidget: (_, _, _) =>
                                                const SizedBox.shrink(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 4),
                        Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ],
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          // Обычные unicode-эмодзи.
          Expanded(
            child: widget.onEmojiTapped == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        AppLocalizations.of(context)!.sticker_emoji_unavailable,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, c) {
                      // Bug #5: пикер растягиваем на всю доступную высоту,
                      // чтобы под ним не было «полосы» пустоты — последние
                      // эмодзи скроллятся под полупрозрачные табы.
                      final h = c.maxHeight.isFinite && c.maxHeight > 0
                          ? c.maxHeight
                          : 320.0;
                      return EmojiPicker(
                        onEmojiSelected: (cat, emoji) {
                          widget.onEmojiTapped?.call(emoji.emoji);
                          HapticFeedback.selectionClick();
                        },
                        config: Config(
                          height: h,
                          emojiViewConfig: EmojiViewConfig(
                            backgroundColor: Colors.transparent,
                            columns: 8,
                            emojiSizeMax: 22,
                          ),
                          categoryViewConfig: CategoryViewConfig(
                            backgroundColor: Colors.transparent,
                            indicatorColor: const Color(0xFF2A79FF),
                            iconColor: Colors.white.withValues(alpha: 0.55),
                            iconColorSelected: Colors.white,
                          ),
                          bottomActionBarConfig: const BottomActionBarConfig(
                            enabled: false,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Telegram-style строка пака: имя + количество на верхней линии + кнопки
/// действий справа (плюсик «добавить из галереи» + корзина), на нижней
/// линии — превью первых 5 стикеров.
class _PackManagerRow extends StatelessWidget {
  const _PackManagerRow({
    required this.pack,
    required this.allowAnimation,
    required this.itemsStream,
    required this.onTap,
    required this.onDelete,
    this.onAddFromGallery,
  });

  final UserStickerPackRow pack;
  final bool allowAnimation;
  final Stream<List<StickerItemRow>> itemsStream;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onAddFromGallery;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StickerItemRow>>(
      stream: itemsStream,
      builder: (context, snap) {
        final items = snap.data ?? const <StickerItemRow>[];
        final preview = items.take(5).toList(growable: false);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              pack.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${items.length} '
                              '${AppLocalizations.of(context)!.sticker_tab_stickers.toLowerCase()}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onAddFromGallery != null) ...[
                        _PackIconButton(
                          icon: Icons.add_rounded,
                          onTap: onAddFromGallery!,
                          tone: _PackIconTone.accent,
                          tooltip: AppLocalizations.of(
                            context,
                          )!.sticker_gallery,
                        ),
                        const SizedBox(width: 6),
                      ],
                      // Действие — удалить пак (Telegram-style mini-pill).
                      _PackActionPill(
                        label: AppLocalizations.of(
                          context,
                        )!.common_delete.toUpperCase(),
                        onTap: onDelete,
                        kind: _PackActionKind.destructive,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (preview.isEmpty)
                    SizedBox(
                      height: 46,
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.sticker_pack_empty_hint,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 46,
                      child: Row(
                        children: [
                          for (final it in preview) ...[
                            SizedBox(
                              width: 46,
                              height: 46,
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: TickerMode(
                                  enabled: allowAnimation,
                                  child: CachedNetworkImage(
                                    imageUrl: it.downloadUrl,
                                    fit: BoxFit.contain,
                                    placeholder: (_, _) =>
                                        const SizedBox.shrink(),
                                    errorWidget: (_, _, _) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _PackActionKind { destructive }

class _PackActionPill extends StatelessWidget {
  const _PackActionPill({
    required this.label,
    required this.onTap,
    required this.kind,
  });

  final String label;
  final VoidCallback onTap;
  final _PackActionKind kind;

  @override
  Widget build(BuildContext context) {
    final color = kind == _PackActionKind.destructive
        ? const Color(0xFFE24D59)
        : const Color(0xFF2A79FF);
    return Material(
      color: color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }
}

enum _PackIconTone { accent }

class _PackIconButton extends StatelessWidget {
  const _PackIconButton({
    required this.icon,
    required this.onTap,
    required this.tone,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final _PackIconTone tone;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFF2A79FF);
    final btn = Material(
      color: color.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

/// Компактная «+ New pack» — небольшой pill сверху списка паков, без
/// крупного блока (Bug #9).
class _PackManagerNewRow extends StatelessWidget {
  const _PackManagerNewRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFF2A79FF);
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    letterSpacing: 0.3,
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
