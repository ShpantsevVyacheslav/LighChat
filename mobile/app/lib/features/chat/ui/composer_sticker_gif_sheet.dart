import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../data/chat_attachment_upload.dart';
import '../data/giphy_cache_store.dart';
import '../data/giphy_gif_search.dart';
import '../data/user_sticker_item_attachment.dart';
import '../data/recent_stickers_store.dart';
import '../data/user_sticker_packs_repository.dart';

enum _StickerScope { my, public }

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
      final h = MediaQuery.sizeOf(ctx).height * 0.62;
      return SizedBox(
        height: h,
        child: _ComposerStickerGifPanel(
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

class _ComposerStickerGifPanel extends StatefulWidget {
  const _ComposerStickerGifPanel({
    required this.userId,
    required this.repo,
    required this.onPickAttachment,
    required this.onClose,
    this.onEmojiTapped,
    this.directUploadConversationId,
  });

  final String userId;
  final UserStickerPacksRepository repo;
  final String? directUploadConversationId;
  final void Function(ChatAttachment attachment) onPickAttachment;
  final void Function(String emoji)? onEmojiTapped;
  final VoidCallback onClose;

  @override
  State<_ComposerStickerGifPanel> createState() =>
      _ComposerStickerGifPanelState();
}

/// Эмодзи для быстрых GIF-фильтров (Telegram-style).
const _kGifEmojiFilters = <String>[
  '😂', '❤️', '🔥', '👍', '😍', '🎉', '😢', '🤔', '🙏', '😎', '😴', '🤯',
];

class _ComposerStickerGifPanelState extends State<_ComposerStickerGifPanel>
    with TickerProviderStateMixin {
  late final TabController _tabs =
      TabController(length: 3, vsync: this);

  _StickerScope _scope = _StickerScope.my;
  String? _myPackId;
  String? _publicPackId;

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
  bool _gifMissingKey = false;
  String? _activeEmojiFilter;
  List<GiphyGifItem> _recentGifs = [];

  // Анимированные эмодзи (GIPHY stickers).
  List<GiphyGifItem> _animEmojis = [];
  bool _animEmojisLoading = false;

  bool _deviceDirectBusy = false;

  @override
  void initState() {
    super.initState();
    _gifQueryController.addListener(_scheduleGifSearch);
    _gifQueryController.addListener(_onGifQueryChanged);
    _gifScrollController.addListener(_onGifScroll);
    _loadInitialData();
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
    final r = await searchGifs(
      _gifLastQuery,
      offset: _gifItems.length,
    );
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
      unawaited(GiphyCacheStore.instance
          .save(GiphyType.gifs, _gifLastQuery, merged));
    }
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadRecentStickers(),
      _loadRecentGifs(),
      _bootstrapTrendingGifs(),
      _bootstrapTrendingStickers(),
    ]);
  }

  Future<void> _loadRecentGifs() async {
    final list = await GiphyCacheStore.instance.getRecent();
    if (mounted) setState(() => _recentGifs = list);
  }

  Future<void> _bootstrapTrendingGifs() async {
    final cached =
        await GiphyCacheStore.instance.getTrending(GiphyType.gifs);
    if (cached != null && cached.isNotEmpty) {
      if (mounted) setState(() => _gifItems = cached);
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
    });
    if (r.items.isNotEmpty) {
      unawaited(
          GiphyCacheStore.instance.saveTrending(GiphyType.gifs, r.items));
    }
  }

  Future<void> _bootstrapTrendingStickers() async {
    final cached =
        await GiphyCacheStore.instance.getTrending(GiphyType.stickers);
    if (cached != null && cached.isNotEmpty) {
      if (mounted) setState(() => _animEmojis = cached);
      return;
    }
    if (!mounted) return;
    setState(() => _animEmojisLoading = true);
    final r = await searchGifs('', type: GiphyType.stickers);
    if (!mounted) return;
    setState(() {
      _animEmojisLoading = false;
      _animEmojis = r.items;
    });
    if (r.items.isNotEmpty) {
      unawaited(GiphyCacheStore.instance
          .saveTrending(GiphyType.stickers, r.items));
    }
  }

  void _onGifQueryChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadRecentStickers() async {
    final list = await RecentStickersStore.instance.getRecents();
    if (mounted) setState(() => _recentStickers = list);
  }

  @override
  void dispose() {
    _gifDebounce?.cancel();
    _gifQueryController.removeListener(_scheduleGifSearch);
    _gifQueryController.removeListener(_onGifQueryChanged);
    _gifQueryController.dispose();
    _gifScrollController.removeListener(_onGifScroll);
    _gifScrollController.dispose();
    _tabs.dispose();
    super.dispose();
  }

  void _scheduleGifSearch() {
    _gifDebounce?.cancel();
    _gifDebounce = Timer(const Duration(milliseconds: 350), () async {
      final q = _gifQueryController.text;
      if (!mounted) return;
      final effectiveQuery =
          q.trim().isEmpty ? (_activeEmojiFilter ?? '') : q.trim();
      _gifLastQuery = effectiveQuery;
      // Проверяем кеш по конкретному запросу/фильтру (TTL 24h, LRU 20 ключей).
      final cached =
          await GiphyCacheStore.instance.get(GiphyType.gifs, effectiveQuery);
      if (cached != null && cached.isNotEmpty) {
        if (mounted) {
          setState(() {
            _gifItems = cached;
            _gifLoading = false;
            // У кеша нет инфы о total → разрешаем дозагрузку, дочитаем при скролле.
            _gifTotal = cached.length;
            _gifHasMore = true;
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
      });
      if (r.items.isNotEmpty) {
        unawaited(GiphyCacheStore.instance
            .save(GiphyType.gifs, effectiveQuery, r.items));
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

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<String?> _promptNewPackName() async {
    final ctrl = TextEditingController(text: 'Мой пак');
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
                  const Text(
                    'Новый стикерпак',
                    style: TextStyle(
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
                      hintText: 'Название',
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
                        final pid =
                            await widget.repo.createPack(widget.userId, name);
                        if (ctx.mounted) Navigator.pop(ctx, pid);
                      },
                      child: const Text('Создать'),
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
                      child: const Text('Отмена'),
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
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Сохранить в стикерпак',
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
                        'Нет паков. Создайте пак на вкладке «Стикеры».',
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
                    title: const Text('Новый пак…'),
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
        _snack('Выберите изображение или GIF');
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
        _snack('Не удалось отправить: $e');
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
      _snack('Сохранено в стикерпак');
    } else {
      _snack('Не удалось скачать или сохранить GIF');
    }
  }

  Future<void> _confirmDeletePack(String packId, String name) async {
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
                  const Text(
                    'Удалить пак?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '«$name» и все стикеры в нём будут удалены.',
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
                      child: const Text('Удалить'),
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
                      child: const Text('Отмена'),
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
    final success =
        await widget.repo.deletePack(widget.userId, packId);
    if (!mounted) return;
    _snack(success ? 'Пак удалён' : 'Не удалось удалить пак');
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

  @override
  Widget build(BuildContext context) {
    return _glassCard(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Positioned(
                right: 4,
                child: IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.white.withValues(alpha: 0.6),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          TabBar(
            controller: _tabs,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
            tabs: const [
              Tab(text: 'ЭМОДЗИ'),
              Tab(text: 'СТИКЕРЫ'),
              Tab(text: 'GIF'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _emojiTab(),
                _stickersTab(),
                _gifTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scopeToggle() {
    final fg = Colors.white.withValues(alpha: 0.9);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Мои'),
            selected: _scope == _StickerScope.my,
            onSelected: (_) => setState(() => _scope = _StickerScope.my),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Общие'),
            selected: _scope == _StickerScope.public,
            onSelected: (_) => setState(() => _scope = _StickerScope.public),
          ),
          const Spacer(),
          if (_scope == _StickerScope.my)
            IconButton(
              tooltip: 'Новый пак',
              onPressed: () async {
                final id = await _promptNewPackName();
                if (id != null && mounted) {
                  setState(() => _myPackId = id);
                  _snack('Стикерпак создан');
                }
              },
              icon: const Icon(Icons.add_circle_outline),
              color: fg,
            ),
        ],
      ),
    );
  }

  Widget _packChipsMy(List<UserStickerPackRow> packs) {
    if (packs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Нет стикерпаков. Создайте новый.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
              ),
            ),
            _PackAddButton(
              onTap: () async {
                final id = await _promptNewPackName();
                if (id != null && mounted) setState(() => _myPackId = id);
              },
            ),
          ],
        ),
      );
    }
    final sel = _myPackId;
    final effective = (sel != null && packs.any((p) => p.id == sel))
        ? sel
        : packs.first.id;
    if (_myPackId != effective) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _myPackId = effective);
      });
    }
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: packs.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          if (i == packs.length) {
            return _PackAddButton(
              onTap: () async {
                final id = await _promptNewPackName();
                if (id != null && mounted) setState(() => _myPackId = id);
              },
            );
          }
          final p = packs[i];
          final active = p.id == effective;
          return _PackIconButton(
            packId: p.id,
            name: p.name,
            active: active,
            onTap: () => setState(() => _myPackId = p.id),
            onLongPress: () => _confirmDeletePack(p.id, p.name),
            stream: widget.repo.watchMyPackItems(widget.userId, p.id),
          );
        },
      ),
    );
  }

  Widget _packChipsPublic(List<PublicStickerPackRow> packs) {
    if (packs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Общие паки не настроены',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
        ),
      );
    }
    final sel = _publicPackId;
    final effective = (sel != null && packs.any((p) => p.id == sel))
        ? sel
        : packs.first.id;
    if (_publicPackId != effective) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _publicPackId = effective);
      });
    }
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: packs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final p = packs[i];
          final active = p.id == effective;
          return _PackIconButton(
            packId: p.id,
            name: p.name,
            active: active,
            onTap: () => setState(() => _publicPackId = p.id),
            stream: widget.repo.watchPublicPackItems(p.id),
          );
        },
      ),
    );
  }

  Widget _recentStickersStrip() {
    final muted = Colors.white.withValues(alpha: 0.45);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, size: 12, color: muted),
              const SizedBox(width: 4),
              Text(
                'НЕДАВНИЕ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 56,
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
                      width: 56,
                      height: 56,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: CachedNetworkImage(
                          imageUrl: att.url,
                          fit: BoxFit.contain,
                          placeholder: (_, _) => const SizedBox.shrink(),
                          errorWidget: (_, _, _) => const SizedBox.shrink(),
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

  Widget _stickerGrid(List<StickerItemRow> items, {required bool canDelete}) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Пак пуст. Добавьте с устройства (вкладка GIF — «В мой пак»).',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final it = items[i];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () =>
                widget.onPickAttachment(userStickerItemToAttachment(it)),
            onLongPress: !canDelete
                ? null
                : () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      barrierColor: Colors.black.withValues(alpha: 0.38),
                      builder: (ctx) => Dialog(
                        backgroundColor: const Color(0xFF17191D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 340),
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 14),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Удалить стикер?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  height: 42,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFFE24D59),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(21),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
                                    child: const Text('Удалить'),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 40,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.white
                                          .withValues(alpha: 0.11),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text('Отмена'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                    if (ok == true &&
                        _myPackId != null &&
                        mounted) {
                      await widget.repo.deleteItem(
                        widget.userId,
                        _myPackId!,
                        it.id,
                      );
                      if (mounted) _snack('Удалено');
                    }
                  },
            borderRadius: BorderRadius.circular(10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: it.downloadUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.broken_image),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _deviceDirectSection() {
    final fg = Colors.white.withValues(alpha: 0.88);
    final muted = Colors.white.withValues(alpha: 0.52);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _deviceDirectBusy ? null : _pickFromGalleryAndSendDirect,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                child: Row(
                  children: [
                    Icon(Icons.photo_library_outlined, color: fg, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Галерея',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: fg,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Фото, PNG, GIF с устройства — сразу в чат',
                            style: TextStyle(fontSize: 12, color: muted, height: 1.25),
                          ),
                        ],
                      ),
                    ),
                    if (_deviceDirectBusy)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(Icons.chevron_right_rounded, color: muted),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stickersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        if (widget.directUploadConversationId != null) ...[
          _deviceDirectSection(),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
        ],
        _scopeToggle(),
        if (_scope == _StickerScope.my)
          StreamBuilder<List<UserStickerPackRow>>(
            stream: widget.repo.watchMyPacks(widget.userId),
            builder: (context, snap) {
              final packs = snap.data ?? [];
              return _packChipsMy(packs);
            },
          )
        else
          StreamBuilder<List<PublicStickerPackRow>>(
            stream: widget.repo.watchPublicPacks(),
            builder: (context, snap) {
              final packs = snap.data ?? [];
              return _packChipsPublic(packs);
            },
          ),
        if (_scope == _StickerScope.my && _recentStickers.isNotEmpty)
          _recentStickersStrip(),
        Expanded(
          child: _scope == _StickerScope.my
              ? StreamBuilder<List<UserStickerPackRow>>(
                  stream: widget.repo.watchMyPacks(widget.userId),
                  builder: (context, packSnap) {
                    final packs = packSnap.data ?? [];
                    if (packs.isEmpty) {
                      return Center(
                        child: Text(
                          'Создайте пак кнопкой +',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    }
                    final pid = _myPackId ??
                        (packs.isNotEmpty ? packs.first.id : null);
                    if (pid == null) {
                      return const SizedBox.shrink();
                    }
                    return StreamBuilder<List<StickerItemRow>>(
                      stream:
                          widget.repo.watchMyPackItems(widget.userId, pid),
                      builder: (context, itemSnap) {
                        final items = itemSnap.data ?? [];
                        return _stickerGrid(items, canDelete: true);
                      },
                    );
                  },
                )
              : StreamBuilder<List<PublicStickerPackRow>>(
                  stream: widget.repo.watchPublicPacks(),
                  builder: (context, packSnap) {
                    final packs = packSnap.data ?? [];
                    if (packs.isEmpty) {
                      return Center(
                        child: Text(
                          'Общие паки пока недоступны',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    }
                    final pid = _publicPackId ??
                        (packs.isNotEmpty ? packs.first.id : null);
                    if (pid == null) {
                      return const SizedBox.shrink();
                    }
                    return StreamBuilder<List<StickerItemRow>>(
                      stream: widget.repo.watchPublicPackItems(pid),
                      builder: (context, itemSnap) {
                        final items = itemSnap.data ?? [];
                        return _stickerGrid(items, canDelete: false);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _gifTab() {
    final hasRecent = _recentGifs.isNotEmpty;
    final showRecent = hasRecent &&
        _gifQueryController.text.trim().isEmpty &&
        _activeEmojiFilter == null;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            controller: _gifQueryController,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Поиск GIF…',
              hintStyle:
                  TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              suffixIcon: _gifQueryController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 18,
                      ),
                      onPressed: () => _gifQueryController.clear(),
                    ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        _gifEmojiFiltersRow(),
        if (_gifMissingKey)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              'Поиск GIF временно недоступен.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ),
        Expanded(
          child: _gifLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  controller: _gifScrollController,
                  slivers: [
                    if (showRecent) ...[
                      SliverToBoxAdapter(
                        child: _gifSectionHeader(
                            Icons.history_rounded, 'НЕДАВНИЕ'),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        sliver: _gifGridSliver(_recentGifs),
                      ),
                      SliverToBoxAdapter(
                        child: _gifSectionHeader(
                            Icons.trending_up_rounded, 'TRENDING'),
                      ),
                    ],
                    if (_gifItems.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            'Ничего не найдено',
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
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                        )
                      else
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 12),
                        ),
                    ],
                  ],
                ),
        ),
      ],
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
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, i) {
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
                    child: CachedNetworkImage(
                      imageUrl: item.url,
                      fit: BoxFit.cover,
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
        },
        childCount: items.length,
      ),
    );
  }

  Widget _gifEmojiFiltersRow() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _kGifEmojiFilters.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          if (i == 0) {
            final active = _activeEmojiFilter == null;
            return _emojiFilterChip(
              label: 'Все',
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
    );
  }

  Widget _emojiFilterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF2A79FF).withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: active
              ? Border.all(
                  color: const Color(0xFF2A79FF).withValues(alpha: 0.6),
                  width: 1,
                )
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: label.length > 3 ? 13 : 18,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: active ? 1.0 : 0.85),
          ),
        ),
      ),
    );
  }

  // ============ ВКЛАДКА «ЭМОДЗИ» ============

  Widget _emojiTab() {
    return Column(
      children: [
        // Анимированные эмодзи (GIPHY stickers).
        if (_animEmojisLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: SizedBox(
              height: 64,
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_animEmojis.isNotEmpty) ...[
          _gifSectionHeader(Icons.auto_awesome_rounded, 'АНИМИРОВАННЫЕ'),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _animEmojis.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final item = _animEmojis[i];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onPickGif(item),
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: CachedNetworkImage(
                          imageUrl: item.url,
                          fit: BoxFit.contain,
                          placeholder: (_, _) => const SizedBox.shrink(),
                          errorWidget: (_, _, _) => const SizedBox.shrink(),
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
        // Обычные unicode-эмодзи.
        Expanded(
          child: widget.onEmojiTapped == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Эмодзи в текст недоступны для этого окна.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                )
              : EmojiPicker(
                  onEmojiSelected: (cat, emoji) {
                    widget.onEmojiTapped?.call(emoji.emoji);
                    HapticFeedback.selectionClick();
                  },
                  config: Config(
                    height: 280,
                    emojiViewConfig: EmojiViewConfig(
                      backgroundColor: Colors.transparent,
                      columns: 8,
                      emojiSizeMax: 28,
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
                ),
        ),
      ],
    );
  }
}

class _PackIconButton extends StatelessWidget {
  const _PackIconButton({
    required this.packId,
    required this.name,
    required this.active,
    required this.onTap,
    required this.stream,
    this.onLongPress,
  });

  final String packId;
  final String name;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Stream<List<StickerItemRow>> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StickerItemRow>>(
      stream: stream,
      builder: (context, snap) {
        final items = snap.data ?? const [];
        final thumbUrl = items.isNotEmpty ? items.first.downloadUrl : null;
        return Tooltip(
          message: name,
          child: GestureDetector(
            onTap: onTap,
            onLongPress: onLongPress,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 40,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: thumbUrl != null
                        ? CachedNetworkImage(
                            imageUrl: thumbUrl,
                            fit: BoxFit.contain,
                            placeholder: (_, _) => const SizedBox.shrink(),
                            errorWidget: (_, _, _) => Icon(
                              Icons.layers_rounded,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 22,
                            ),
                          )
                        : Icon(
                            Icons.layers_rounded,
                            color: Colors.white.withValues(alpha: 0.5),
                            size: 22,
                          ),
                  ),
                  if (active)
                    Positioned(
                      bottom: 2,
                      child: Container(
                        width: 16,
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A79FF),
                          borderRadius: BorderRadius.circular(2),
                        ),
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

class _PackAddButton extends StatelessWidget {
  const _PackAddButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 40,
        height: 48,
        child: Center(
          child: Icon(
            Icons.add_rounded,
            color: Colors.white.withValues(alpha: 0.55),
            size: 22,
          ),
        ),
      ),
    );
  }
}
