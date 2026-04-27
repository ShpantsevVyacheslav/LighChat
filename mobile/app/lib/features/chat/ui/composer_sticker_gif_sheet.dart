import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../data/chat_attachment_upload.dart';
import '../data/tenor_gif_search.dart';
import '../data/tenor_proxy_config.dart';
import '../data/user_sticker_item_attachment.dart';
import '../data/user_sticker_packs_constants.dart';
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
          onPickAttachment: (a) {
            Navigator.of(ctx).pop();
            onPickAttachment(a);
          },
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
    this.directUploadConversationId,
  });

  final String userId;
  final UserStickerPacksRepository repo;
  final String? directUploadConversationId;
  final void Function(ChatAttachment attachment) onPickAttachment;

  @override
  State<_ComposerStickerGifPanel> createState() =>
      _ComposerStickerGifPanelState();
}

class _ComposerStickerGifPanelState extends State<_ComposerStickerGifPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs =
      TabController(length: 2, vsync: this);

  _StickerScope _scope = _StickerScope.my;
  String? _myPackId;
  String? _publicPackId;

  final _gifQueryController = TextEditingController();
  Timer? _tenorDebounce;
  List<TenorGifItem> _tenorItems = [];
  bool _tenorLoading = false;
  bool _tenorMissingKey = false;
  bool _deviceDirectBusy = false;

  @override
  void initState() {
    super.initState();
    _gifQueryController.addListener(_scheduleTenorSearch);
  }

  @override
  void dispose() {
    _tenorDebounce?.cancel();
    _gifQueryController.removeListener(_scheduleTenorSearch);
    _gifQueryController.dispose();
    _tabs.dispose();
    super.dispose();
  }

  void _scheduleTenorSearch() {
    _tenorDebounce?.cancel();
    _tenorDebounce = Timer(const Duration(milliseconds: 350), () async {
      final q = _gifQueryController.text;
      if (!mounted) return;
      setState(() => _tenorLoading = true);
      final r = await searchTenorGifs(q);
      if (!mounted) return;
      setState(() {
        _tenorLoading = false;
        _tenorItems = r.items;
        _tenorMissingKey = r.missingKey;
      });
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<String?> _promptNewPackName() async {
    final ctrl = TextEditingController(text: 'Мой пак');
    final id = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новый стикерпак'),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Название'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () async {
              final name = ctrl.text;
              final pid =
                  await widget.repo.createPack(widget.userId, name);
              if (ctx.mounted) Navigator.pop(ctx, pid);
            },
            child: const Text('Создать'),
          ),
        ],
      ),
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

  Future<void> _addDeviceImagesToPack(List<XFile> files) async {
    if (files.isEmpty) return;

    final packId = await _pickPackSheet();
    if (packId == null || !mounted) return;

    final res = await widget.repo.addXFilesToPack(
      userId: widget.userId,
      packId: packId,
      files: files,
    );
    if (!mounted) return;
    if (res.ok > 0) {
      _snack('Сохранено в пак: ${res.ok}');
    } else if (res.errors.contains('file_too_large')) {
      _snack(
        'Файл слишком большой (до ${kUserStickerMaxFileBytes ~/ (1024 * 1024)} МБ)',
      );
    } else {
      _snack('Не удалось сохранить');
    }
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

  Future<void> _pickFromDeviceForPack() async {
    final picker = ImagePicker();
    try {
      final list = await picker.pickMultipleMedia(imageQuality: 100);
      if (list.isEmpty || !mounted) return;
      final images = list.where((x) {
        final m = x.mimeType?.toLowerCase() ?? '';
        final n = x.name.toLowerCase();
        return m.startsWith('image/') ||
            n.endsWith('.gif') ||
            n.endsWith('.png') ||
            n.endsWith('.jpg') ||
            n.endsWith('.jpeg') ||
            n.endsWith('.webp');
      }).toList();
      if (images.isEmpty) {
        _snack('Выберите изображение или GIF');
        return;
      }
      await _addDeviceImagesToPack(images);
    } catch (e) {
      if (mounted) _snack('Не удалось выбрать файл: $e');
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
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить пак?'),
        content: Text('«$name» и все стикеры в нём будут удалены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
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
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          TabBar(
            controller: _tabs,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
            tabs: const [
              Tab(text: 'СТИКЕРЫ'),
              Tab(text: 'GIF'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
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
        child: Text(
          'Нет стикерпаков. Нажмите + чтобы создать.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
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
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: packs.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == packs.length) {
            return Center(
              child: IconButton(
                onPressed: () async {
                  final id = await _promptNewPackName();
                  if (id != null && mounted) setState(() => _myPackId = id);
                },
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            );
          }
          final p = packs[i];
          final active = p.id == effective;
          return GestureDetector(
            onLongPress: () => _confirmDeletePack(p.id, p.name),
            child: ActionChip(
              label: Text(
                p.name.length > 10 ? '${p.name.substring(0, 9)}…' : p.name,
              ),
              onPressed: () => setState(() => _myPackId = p.id),
              backgroundColor: active
                  ? Colors.teal.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.08),
            ),
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
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: packs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final p = packs[i];
          final active = p.id == effective;
          return ActionChip(
            label: Text(
              p.name.length > 10 ? '${p.name.substring(0, 9)}…' : p.name,
            ),
            onPressed: () => setState(() => _publicPackId = p.id),
            backgroundColor: active
                ? Colors.teal.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.08),
          );
        },
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
                      builder: (ctx) => AlertDialog(
                        title: const Text('Удалить стикер?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Отмена'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Удалить'),
                          ),
                        ],
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
          Text(
            'С УСТРОЙСТВА',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.85,
              color: muted,
            ),
          ),
          const SizedBox(height: 8),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: OutlinedButton.icon(
            onPressed: _scope == _StickerScope.my ? _pickFromDeviceForPack : null,
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: const Text('С УСТРОЙСТВА'),
          ),
        ),
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      children: [
        OutlinedButton.icon(
          onPressed: _pickFromDeviceForPack,
          icon: const Icon(Icons.upload_outlined, size: 18),
          label: const Text('В МОЙ ПАК'),
        ),
        const SizedBox(height: 6),
        Text(
          'GIF или картинка сохраняются в выбранный пак; отправляйте из «Стикеры».',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _gifQueryController,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Поиск GIF…',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (kTenorProxyBaseUrl.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Укажите TENOR_PROXY_BASE_URL (URL веб-приложения) для поиска Tenor.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          )
        else if (_tenorMissingKey)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Поиск Tenor недоступен без ключа на сервере. Загрузите GIF кнопкой «В мой пак».',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: _tenorLoading
              ? const Center(child: CircularProgressIndicator())
              : _tenorItems.isEmpty
                  ? Center(
                      child: Text(
                        _gifQueryController.text.trim().isEmpty
                            ? 'Введите запрос или загрузите файл'
                            : 'Ничего не найдено',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : GridView.builder(
                      itemCount: _tenorItems.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                      ),
                      itemBuilder: (context, i) {
                        final item = _tenorItems[i];
                        final att = tenorItemToSendAttachment(item);
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Material(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                onTap: () =>
                                    widget.onPickAttachment(att),
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
                                  onPressed: () => _saveRemoteToPack(att),
                                  icon: const Icon(Icons.bookmark_add_outlined),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
