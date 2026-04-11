import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../../shared/ui/app_back_button.dart';

class ChatSettingsScreen extends ConsumerStatefulWidget {
  const ChatSettingsScreen({super.key});

  @override
  ConsumerState<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _EditableChatSettings {
  _EditableChatSettings({
    required this.fontSize,
    required this.bubbleRadius,
    required this.showTimestamps,
    required this.bottomNavAppearance,
    required this.bubbleColor,
    required this.incomingBubbleColor,
    required this.chatWallpaper,
    required this.customBackgrounds,
  });

  String fontSize;
  String bubbleRadius;
  bool showTimestamps;
  String bottomNavAppearance;
  String? bubbleColor;
  String? incomingBubbleColor;
  String? chatWallpaper;
  List<String> customBackgrounds;
}

const Map<String, Object?> _defaultChatSettings = <String, Object?>{
  'fontSize': 'medium',
  'bubbleColor': null,
  'incomingBubbleColor': null,
  'chatWallpaper': null,
  'bubbleRadius': 'rounded',
  'showTimestamps': true,
  'bottomNavAppearance': 'colorful',
};

const List<({String? value, String label})> _bubbleColors =
    <({String? value, String label})>[
      (value: null, label: 'По умолчанию'),
      (value: '#3B82F6', label: 'Синий'),
      (value: '#10B981', label: 'Зеленый'),
      (value: '#8B5CF6', label: 'Фиолетовый'),
      (value: '#F59E0B', label: 'Оранжевый'),
      (value: '#EF4444', label: 'Красный'),
      (value: '#EC4899', label: 'Розовый'),
      (value: '#06B6D4', label: 'Бирюзовый'),
    ];

const List<({String? value, String label})>
_wallpapers = <({String? value, String label})>[
  (value: null, label: 'Нет'),
  (
    value: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
    label: 'Фиолетовый',
  ),
  (
    value: 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)',
    label: 'Розовый',
  ),
  (
    value: 'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)',
    label: 'Голубой',
  ),
  (
    value: 'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)',
    label: 'Зеленый',
  ),
  (value: 'linear-gradient(135deg, #fa709a 0%, #fee140 100%)', label: 'Закат'),
  (
    value: 'linear-gradient(135deg, #a18cd1 0%, #fbc2eb 100%)',
    label: 'Лавандовый',
  ),
  (value: 'linear-gradient(135deg, #0c0c0c 0%, #1a1a2e 100%)', label: 'Ночь'),
  (value: 'linear-gradient(135deg, #d4fc79 0%, #96e6a1 100%)', label: 'Мята'),
];

class _ChatSettingsScreenState extends ConsumerState<ChatSettingsScreen> {
  _EditableChatSettings? _state;
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(chatSettingsRepositoryProvider);
    final user = FirebaseAuth.instance.currentUser;
    if (repo == null || user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final raw = await repo.loadUserDoc(user.uid);
    final chat = Map<String, dynamic>.from(
      raw['chatSettings'] as Map? ?? const <String, dynamic>{},
    );
    final custom = (raw['customBackgrounds'] as List? ?? const <Object?>[])
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList(growable: true);

    _state = _EditableChatSettings(
      fontSize: (chat['fontSize'] as String?) ?? 'medium',
      bubbleRadius: (chat['bubbleRadius'] as String?) ?? 'rounded',
      showTimestamps: (chat['showTimestamps'] as bool?) ?? true,
      bottomNavAppearance:
          (chat['bottomNavAppearance'] as String?) ?? 'colorful',
      bubbleColor: chat['bubbleColor'] as String?,
      incomingBubbleColor: chat['incomingBubbleColor'] as String?,
      chatWallpaper: chat['chatWallpaper'] as String?,
      customBackgrounds: custom,
    );

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _savePatch(Map<String, Object?> patch) async {
    final repo = ref.read(chatSettingsRepositoryProvider);
    final user = FirebaseAuth.instance.currentUser;
    if (repo == null || user == null) return;
    try {
      await repo.patchChatSettings(user.uid, patch);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось сохранить: $e')));
      await _load();
    }
  }

  Future<void> _pickAndUploadWallpaper() async {
    final repo = ref.read(chatSettingsRepositoryProvider);
    final user = FirebaseAuth.instance.currentUser;
    if (repo == null || user == null) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      final raw = await file.readAsBytes();
      final decoded = img.decodeImage(raw);
      Uint8List uploadBytes;
      if (decoded == null) {
        uploadBytes = raw;
      } else {
        final resized = img.copyResize(
          decoded,
          width: decoded.width > 1920 ? 1920 : decoded.width,
        );
        uploadBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 84));
      }

      final url = await repo.uploadWallpaper(user.uid, uploadBytes);
      await repo.addCustomBackground(user.uid, url);
      await repo.patchChatSettings(user.uid, <String, Object?>{
        'chatWallpaper': url,
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка загрузки фона: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removeCustomWallpaper(String url) async {
    final repo = ref.read(chatSettingsRepositoryProvider);
    final user = FirebaseAuth.instance.currentUser;
    final s = _state;
    if (repo == null || user == null || s == null) return;
    try {
      await repo.removeCustomBackground(
        user.uid,
        url,
        wasActive: s.chatWallpaper == url,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка удаления фона: $e')));
    }
  }

  Color _colorFromHex(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    final c = hex.replaceAll('#', '');
    if (c.length != 6) return fallback;
    return Color(int.parse('FF$c', radix: 16));
  }

  BoxDecoration _wallpaperDecoration(String? value) {
    if (value == null || value.isEmpty) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.08),
      );
    }

    if (value.startsWith('http')) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        image: DecorationImage(image: NetworkImage(value), fit: BoxFit.cover),
      );
    }

    final gradients = <String, Gradient>{
      'linear-gradient(135deg, #667eea 0%, #764ba2 100%)': const LinearGradient(
        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      ),
      'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)': const LinearGradient(
        colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
      ),
      'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)': const LinearGradient(
        colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
      ),
      'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)': const LinearGradient(
        colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
      ),
      'linear-gradient(135deg, #fa709a 0%, #fee140 100%)': const LinearGradient(
        colors: [Color(0xFFFA709A), Color(0xFFFEE140)],
      ),
      'linear-gradient(135deg, #a18cd1 0%, #fbc2eb 100%)': const LinearGradient(
        colors: [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
      ),
      'linear-gradient(135deg, #0c0c0c 0%, #1a1a2e 100%)': const LinearGradient(
        colors: [Color(0xFF0C0C0C), Color(0xFF1A1A2E)],
      ),
      'linear-gradient(135deg, #d4fc79 0%, #96e6a1 100%)': const LinearGradient(
        colors: [Color(0xFFD4FC79), Color(0xFF96E6A1)],
      ),
    };

    return BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: gradients[value],
      color: gradients[value] == null
          ? Colors.white.withValues(alpha: 0.08)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _state;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;

    if (_loading || s == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final outgoing = _colorFromHex(s.bubbleColor, scheme.primary);
    final incoming = _colorFromHex(
      s.incomingBubbleColor,
      dark ? const Color(0xFF26373D) : const Color(0xFFE2EEF2),
    );

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: '/chats'),
        title: const Text('Настройки чатов'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Внешний вид сообщений и чатов.',
              style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.66)),
            ),
            const SizedBox(height: 18),
            const Text(
              'Предпросмотр',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: _wallpaperDecoration(s.chatWallpaper),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color:
                      s.chatWallpaper != null &&
                          s.chatWallpaper!.startsWith('http')
                      ? Colors.black.withValues(alpha: 0.30)
                      : Colors.transparent,
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: incoming,
                          borderRadius: BorderRadius.circular(
                            s.bubbleRadius == 'square' ? 8 : 22,
                          ),
                        ),
                        child: Text(
                          'Привет! Как дела?',
                          style: TextStyle(
                            fontSize: s.fontSize == 'small'
                                ? 12
                                : s.fontSize == 'large'
                                ? 18
                                : 15,
                          ),
                        ),
                      ),
                    ),
                    if (s.showTimestamps)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4, top: 4),
                          child: Text(
                            '11:58',
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurface.withValues(alpha: 0.62),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: outgoing,
                          borderRadius: BorderRadius.circular(
                            s.bubbleRadius == 'square' ? 8 : 22,
                          ),
                        ),
                        child: Text(
                          'Отлично, спасибо!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: s.fontSize == 'small'
                                ? 12
                                : s.fontSize == 'large'
                                ? 18
                                : 15,
                          ),
                        ),
                      ),
                    ),
                    if (s.showTimestamps)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4, top: 4),
                          child: Text(
                            '12:00',
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurface.withValues(alpha: 0.62),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Исходящие сообщения',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _bubbleColors
                  .map(
                    (opt) => _colorDot(
                      context,
                      color: _colorFromHex(opt.value, scheme.primary),
                      selected: s.bubbleColor == opt.value,
                      onTap: () {
                        setState(() => s.bubbleColor = opt.value);
                        _savePatch(<String, Object?>{'bubbleColor': opt.value});
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 18),
            const Text(
              'Входящие сообщения',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _bubbleColors
                  .map(
                    (opt) => _colorDot(
                      context,
                      color: _colorFromHex(
                        opt.value,
                        dark
                            ? const Color(0xFF26373D)
                            : const Color(0xFFE2EEF2),
                      ),
                      selected: s.incomingBubbleColor == opt.value,
                      onTap: () {
                        setState(() => s.incomingBubbleColor = opt.value);
                        _savePatch(<String, Object?>{
                          'incomingBubbleColor': opt.value,
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 18),
            const Text(
              'Размер шрифта',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _seg(
                  context,
                  label: 'Мелкий',
                  active: s.fontSize == 'small',
                  onTap: () {
                    setState(() => s.fontSize = 'small');
                    _savePatch(<String, Object?>{'fontSize': 'small'});
                  },
                ),
                const SizedBox(width: 10),
                _seg(
                  context,
                  label: 'Средний',
                  active: s.fontSize == 'medium',
                  onTap: () {
                    setState(() => s.fontSize = 'medium');
                    _savePatch(<String, Object?>{'fontSize': 'medium'});
                  },
                ),
                const SizedBox(width: 10),
                _seg(
                  context,
                  label: 'Крупный',
                  active: s.fontSize == 'large',
                  onTap: () {
                    setState(() => s.fontSize = 'large');
                    _savePatch(<String, Object?>{'fontSize': 'large'});
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Форма пузырьков',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _selectCard(
                    context,
                    selected: s.bubbleRadius == 'rounded',
                    title: 'Скругленные',
                    subtitle: 'Плавные углы',
                    onTap: () {
                      setState(() => s.bubbleRadius = 'rounded');
                      _savePatch(<String, Object?>{'bubbleRadius': 'rounded'});
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _selectCard(
                    context,
                    selected: s.bubbleRadius == 'square',
                    title: 'Квадратные',
                    subtitle: 'Более строгий стиль',
                    onTap: () {
                      setState(() => s.bubbleRadius = 'square');
                      _savePatch(<String, Object?>{'bubbleRadius': 'square'});
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Фон чата',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _wallpapers
                  .map(
                    (wp) => GestureDetector(
                      onTap: () {
                        setState(() => s.chatWallpaper = wp.value);
                        _savePatch(<String, Object?>{
                          'chatWallpaper': wp.value,
                        });
                      },
                      child: Container(
                        width: 150,
                        height: 74,
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.only(bottom: 8),
                        decoration: _wallpaperDecoration(wp.value).copyWith(
                          border: Border.all(
                            color: s.chatWallpaper == wp.value
                                ? scheme.primary
                                : Colors.white.withValues(alpha: 0.18),
                            width: s.chatWallpaper == wp.value ? 2 : 1,
                          ),
                        ),
                        child: Text(wp.label),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 18),
            const Text(
              'Ваши фоны',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: s.customBackgrounds.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  if (index == s.customBackgrounds.length) {
                    return OutlinedButton.icon(
                      onPressed: _uploading ? null : _pickAndUploadWallpaper,
                      icon: _uploading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(_uploading ? 'Загрузка...' : 'Добавить'),
                    );
                  }

                  final url = s.customBackgrounds[index];
                  final selected = s.chatWallpaper == url;
                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() => s.chatWallpaper = url);
                          _savePatch(<String, Object?>{'chatWallpaper': url});
                        },
                        child: Container(
                          width: 140,
                          height: 88,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            image: DecorationImage(
                              image: NetworkImage(url),
                              fit: BoxFit.cover,
                            ),
                            border: Border.all(
                              color: selected
                                  ? scheme.primary
                                  : Colors.white.withValues(alpha: 0.18),
                              width: selected ? 2 : 1,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: InkWell(
                          onTap: () => _removeCustomWallpaper(url),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.56),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 16),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Показывать время'),
              subtitle: const Text('Время отправки под каждым сообщением.'),
              value: s.showTimestamps,
              onChanged: (v) {
                setState(() => s.showTimestamps = v);
                _savePatch(<String, Object?>{'showTimestamps': v});
              },
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () async {
                final repo = ref.read(chatSettingsRepositoryProvider);
                final user = FirebaseAuth.instance.currentUser;
                if (repo == null || user == null) return;
                await repo.setChatSettings(user.uid, _defaultChatSettings);
                await _load();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Сбросить настройки'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorDot(
    BuildContext context, {
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _seg(
    BuildContext context, {
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: active
              ? scheme.primary.withValues(alpha: 0.20)
              : null,
          side: BorderSide(
            color: active
                ? scheme.primary
                : Colors.white.withValues(alpha: 0.22),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _selectCard(
    BuildContext context, {
    required bool selected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withValues(alpha: dark ? 0.07 : 0.22),
          border: Border.all(
            color: selected
                ? scheme.primary
                : Colors.white.withValues(alpha: dark ? 0.12 : 0.34),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.62)),
            ),
            if (selected) ...[
              const SizedBox(height: 6),
              Text(
                'Выбрано',
                style: TextStyle(
                  color: scheme.primary,
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
