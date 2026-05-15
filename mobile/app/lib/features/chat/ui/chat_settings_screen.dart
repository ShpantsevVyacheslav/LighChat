import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../../auth/ui/auth_glass.dart';
import '../data/bottom_nav_icon_settings.dart';
import '../data/animated_wallpapers.dart';
import '../data/builtin_wallpapers.dart';
import 'animated_wallpaper_layer.dart';
import '../data/emoji_burst_animation_profile.dart';
import '../data/new_chat_user_search.dart' show ruEnSubstringMatch;
import '../../../l10n/app_localizations.dart';

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
    required this.autoTranslateIncoming,
    required this.bottomNavAppearance,
    required this.bottomNavIconNames,
    required this.bottomNavIconGlobalStyle,
    required this.bottomNavIconStyles,
    required this.bubbleColor,
    required this.incomingBubbleColor,
    required this.chatWallpaper,
    required this.customBackgrounds,
    required this.emojiBurstAnimationProfile,
  });

  String fontSize;
  String bubbleRadius;
  bool showTimestamps;
  bool autoTranslateIncoming;
  String bottomNavAppearance;
  Map<String, String> bottomNavIconNames;
  BottomNavIconVisualStyle bottomNavIconGlobalStyle;
  Map<String, BottomNavIconVisualStyle> bottomNavIconStyles;
  String? bubbleColor;
  String? incomingBubbleColor;
  String? chatWallpaper;
  List<String> customBackgrounds;
  String emojiBurstAnimationProfile;
}

const Map<String, Object?> _defaultChatSettings = <String, Object?>{
  'fontSize': 'medium',
  'bubbleColor': null,
  'incomingBubbleColor': null,
  'chatWallpaper': null,
  'bubbleRadius': 'rounded',
  'showTimestamps': true,
  'autoTranslateIncoming': false,
  'emojiBurstAnimationProfile': chatEmojiBurstAnimationProfileBalanced,
  'bottomNavAppearance': 'colorful',
  'bottomNavIconNames': <String, String>{},
  'bottomNavIconGlobalStyle': <String, Object?>{},
  'bottomNavIconStyles': <String, Object?>{},
};

List<({String? value, String label, Color fallback})>
_outgoingBubbleColors(AppLocalizations l10n) =>
    <({String? value, String label, Color fallback})>[
      (value: null, label: l10n.chat_settings_color_default, fallback: Color(0xFF637FE1)),
      (value: '#CF82DD', label: l10n.chat_settings_color_lilac, fallback: Color(0xFFCF82DD)),
      (value: '#ED6897', label: l10n.chat_settings_color_pink, fallback: Color(0xFFED6897)),
      (value: '#47D973', label: l10n.chat_settings_color_green, fallback: Color(0xFF47D973)),
      (value: '#FC6A6A', label: l10n.chat_settings_color_coral, fallback: Color(0xFFFC6A6A)),
      (value: '#8CCCCC', label: l10n.chat_settings_color_mint, fallback: Color(0xFF8CCCCC)),
      (value: '#53A2E6', label: l10n.chat_settings_color_sky, fallback: Color(0xFF53A2E6)),
    ];

List<({String? value, String label, Color fallback})>
_incomingBubbleColors(AppLocalizations l10n) =>
    <({String? value, String label, Color fallback})>[
      (value: null, label: l10n.chat_settings_color_default, fallback: Color(0xFF53A2E6)),
      (value: '#7650A8', label: l10n.chat_settings_color_purple, fallback: Color(0xFF7650A8)),
      (value: '#EE5572', label: l10n.chat_settings_color_crimson, fallback: Color(0xFFEE5572)),
      (value: '#42DCC8', label: l10n.chat_settings_color_tiffany, fallback: Color(0xFF42DCC8)),
      (value: '#F1DC40', label: l10n.chat_settings_color_yellow, fallback: Color(0xFFF1DC40)),
      (value: '#DFC0CF', label: l10n.chat_settings_color_powder, fallback: Color(0xFFDFC0CF)),
      (value: '#1BD0DD', label: l10n.chat_settings_color_turquoise, fallback: Color(0xFF1BD0DD)),
    ];

List<({String? value, String label})>
_wallpaperPresets(AppLocalizations l10n) =>
    <({String? value, String label})>[
      (
        value: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        label: l10n.chat_settings_color_purple,
      ),
      (
        value: 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)',
        label: l10n.chat_settings_color_pink,
      ),
      (
        value: 'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)',
        label: l10n.chat_settings_color_blue,
      ),
      (
        value: 'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)',
        label: l10n.chat_settings_color_green,
      ),
      (value: 'linear-gradient(135deg, #fa709a 0%, #fee140 100%)', label: l10n.chat_settings_color_sunset),
      (value: 'linear-gradient(135deg, #C6E8EB 0%, #E9D0DE 100%)', label: l10n.chat_settings_color_tender),
      (value: 'linear-gradient(135deg, #D9F904 0%, #6CEB00 100%)', label: l10n.chat_settings_color_lime),
      (value: 'linear-gradient(135deg, #151619 0%, #23242A 100%)', label: l10n.chat_settings_color_graphite),
      (value: null, label: l10n.chat_settings_color_no_bg),
    ];

const List<Color> _iconStyleColorSwatches = <Color>[
  Color(0xFFFFFFFF),
  Color(0xFF2F86FF),
  Color(0xFF7A5CF8),
  Color(0xFF00C2FF),
  Color(0xFF34D399),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFF111827),
];

const double _kHeaderTitleSize = 16;
const double _kSectionTitleSize = 19;
const double _kBlockTitleSize = 18;
const double _kBodyTextSize = 14;
const double _kMutedTextSize = 13;

class _ChatSettingsScreenState extends ConsumerState<ChatSettingsScreen> {
  _EditableChatSettings? _state;
  bool _loading = true;
  bool _uploading = false;
  bool _globalIconStyleExpanded = false;
  String? _iconStyleExpandedHref;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _previewKey = GlobalKey();
  /// Маркер раздела «Эмодзи эффекты» — после него настройки больше
  /// не влияют на превью, поэтому sticky-превью «отлипает».
  final GlobalKey _emojiSectionKey = GlobalKey();
  bool _hidePreview = false;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_handleScrollForPreviewVisibility);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScrollForPreviewVisibility);
    _scrollController.dispose();
    super.dispose();
  }

  /// Вызывается на каждый scroll-tick — переключает `_hidePreview`,
  /// когда раздел «Эмодзи эффекты» дошёл до верха viewport. С этого
  /// момента превью больше не нужно (последующие настройки на него
  /// не влияют), и его место отдаётся под содержимое.
  ///
  /// Гистерезис ±18px — чтобы исключить дрожание sticky-флага вокруг
  /// порога при медленном скролле.
  void _handleScrollForPreviewVisibility() {
    if (!_scrollController.hasClients) return;
    final ctx = _emojiSectionKey.currentContext;
    if (ctx == null) return;
    final ro = ctx.findRenderObject();
    if (ro is! RenderBox) return;
    final viewport = RenderAbstractViewport.maybeOf(ro);
    if (viewport == null) return;
    final revealOffset = viewport.getOffsetToReveal(ro, 0.0).offset;
    final offset = _scrollController.offset;
    final shouldHide = _hidePreview
        ? offset >= revealOffset - 18
        : offset >= revealOffset + 18;
    if (shouldHide != _hidePreview) {
      setState(() => _hidePreview = shouldHide);
    }
  }

  /// Применить выбор обоев + сохранить + проскроллить к превью. Общая
  /// точка вызова из главного grid и из bottom-sheet picker'а.
  void _selectWallpaper(_EditableChatSettings s, String? value) {
    setState(() => s.chatWallpaper = value);
    _savePatch(<String, Object?>{'chatWallpaper': value});
    _scrollToPreview();
  }

  /// Полный список обоев в bottom-sheet'е: компактное sticky-превью
  /// сверху (обновляется при тапе на плитку без закрытия sheet),
  /// затем список фирменных обоев, градиентов-пресетов, пользовательских
  /// картинок и кнопка добавления.
  Future<void> _openWallpapersPicker(
    _EditableChatSettings s, {
    required Color incomingBubbleColor,
    required Color outgoingBubbleColor,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) {
            return StatefulBuilder(
              builder: (sbCtx, setSheetState) {
                final builtinAll = kBuiltinWallpapers;
                final presets = _wallpaperPresets(l10n);
                final customCount = s.customBackgrounds.length;
                final total =
                    builtinAll.length + presets.length + customCount + 1;
                // При тапе на плитку — применяем настройку, обновляем
                // и main-экран, и sheet (для перерисовки превью).
                // Sheet НЕ закрывается, чтобы пользователь мог
                // пробовать варианты не возвращаясь на главный экран.
                void applyAndStay(String? value) {
                  _selectWallpaper(s, value);
                  setSheetState(() {});
                }

                return Container(
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFF0D121A)
                        : scheme.surfaceContainerLow,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 6),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: (dark ? Colors.white : scheme.onSurface)
                              .withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Text(
                          l10n.chat_settings_chat_background,
                          style: TextStyle(
                            fontSize: _kSectionTitleSize,
                            fontWeight: FontWeight.w700,
                            color: dark
                                ? Colors.white.withValues(alpha: 0.92)
                                : scheme.onSurface,
                          ),
                        ),
                      ),
                      // Sticky-превью внутри sheet — по аналогии с
                      // главным экраном, но компактнее (260px).
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: _ChatPreviewCard(
                          overrideHeight: 260,
                          wallpaperDecoration: _wallpaperDecoration(
                            context,
                            s.chatWallpaper,
                          ),
                          animatedWallpaper: resolveAnimatedWallpaper(
                            s.chatWallpaper,
                          ),
                          incomingBubbleColor: incomingBubbleColor,
                          outgoingBubbleColor: outgoingBubbleColor,
                          bubbleRadius: s.bubbleRadius,
                          showTimestamps: s.showTimestamps,
                          messageFontSize:
                              _previewMessageFont(s.fontSize),
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          controller: scrollController,
                          padding: EdgeInsets.fromLTRB(
                            16,
                            4,
                            16,
                            16 + MediaQuery.paddingOf(context).bottom,
                          ),
                          itemCount: total,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 1.04,
                              ),
                          itemBuilder: (context, index) {
                            if (index < builtinAll.length) {
                              final wp = builtinAll[index];
                              final value = wp.value;
                              return _WallpaperTile(
                                selected: s.chatWallpaper == value,
                                decoration:
                                    _wallpaperDecoration(context, value),
                                onTap: () => applyAndStay(value),
                              );
                            }
                            if (index < builtinAll.length + presets.length) {
                              final preset =
                                  presets[index - builtinAll.length];
                              final value = preset.value;
                              return _WallpaperTile(
                                selected: s.chatWallpaper == value,
                                decoration:
                                    _wallpaperDecoration(context, value),
                                onTap: () => applyAndStay(value),
                              );
                            }
                            if (index <
                                builtinAll.length +
                                    presets.length +
                                    customCount) {
                              final url = s.customBackgrounds[index -
                                  builtinAll.length -
                                  presets.length];
                              return _WallpaperTile(
                                selected: s.chatWallpaper == url,
                                decoration:
                                    _wallpaperDecoration(context, url),
                                onTap: () => applyAndStay(url),
                                onDelete: () =>
                                    _confirmRemoveCustomWallpaper(url),
                              );
                            }
                            return _AddWallpaperTile(
                              uploading: _uploading,
                              onTap: _uploading
                                  ? null
                                  : () {
                                      Navigator.of(sheetContext).pop();
                                      _pickAndUploadWallpaper();
                                    },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Автоскролл к карточке превью — вызывается после изменения настройки,
  /// которая влияет на отображаемый превью (фон, цвета пузырьков, шрифт,
  /// форма, отметка времени), чтобы пользователь сразу видел эффект.
  /// Превью теперь sticky — пока scroll выше раздела «Эмодзи эффекты»,
  /// превью всегда видно сверху, и автоскролл при изменении настроек
  /// не нужен (раньше он давал визуальный «прыжок» при каждом тапе).
  /// Возвращаемся к 0 только если превью уже отлипло
  /// (`_hidePreview == true`) — то есть пользователь скроллил в раздел
  /// «Дополнительно» / «Показать время» / «Авто-перевод», а оттуда
  /// меняет настройку, влияющую на превью.
  void _scrollToPreview() {
    if (!_hidePreview) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
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
      autoTranslateIncoming:
          (chat['autoTranslateIncoming'] as bool?) ?? false,
      emojiBurstAnimationProfile: normalizeChatEmojiBurstAnimationProfile(
        chat['emojiBurstAnimationProfile'] as String?,
      ),
      bottomNavAppearance:
          (chat['bottomNavAppearance'] as String?) ?? 'colorful',
      bottomNavIconNames: parseBottomNavIconNames(chat['bottomNavIconNames']),
      bottomNavIconGlobalStyle: BottomNavIconVisualStyle.fromJson(
        chat['bottomNavIconGlobalStyle'],
      ),
      bottomNavIconStyles: parseBottomNavIconStyles(
        chat['bottomNavIconStyles'],
      ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.settings_chats_error_cannot_save(e.toString()),
          ),
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.settings_chats_error_wallpaper_load(e.toString()),
          ),
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.settings_chats_error_wallpaper_delete(e.toString()),
          ),
        ),
      );
    }
  }

  Future<void> _confirmRemoveCustomWallpaper(String url) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.settings_chats_wallpaper_delete_confirm_title),
          content: Text(l10n.settings_chats_wallpaper_delete_confirm_body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.common_cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.common_delete),
            ),
          ],
        );
      },
    );
    if (ok == true) {
      await _removeCustomWallpaper(url);
    }
  }

  Color _colorFromHex(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    final c = hex.replaceAll('#', '');
    if (c.length != 6) return fallback;
    return Color(int.parse('FF$c', radix: 16));
  }

  Gradient? _wallpaperGradient(String? value) {
    switch (value) {
      case 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        );
      case 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
        );
      case 'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
        );
      case 'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
        );
      case 'linear-gradient(135deg, #fa709a 0%, #fee140 100%)':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFA709A), Color(0xFFFEE140)],
        );
      case 'linear-gradient(135deg, #C6E8EB 0%, #E9D0DE 100%)':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC6E8EB), Color(0xFFE9D0DE)],
        );
      case 'linear-gradient(135deg, #D9F904 0%, #6CEB00 100%)':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD9F904), Color(0xFF6CEB00)],
        );
      case 'linear-gradient(135deg, #151619 0%, #23242A 100%)':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF151619), Color(0xFF23242A)],
        );
      default:
        return null;
    }
  }

  BoxDecoration _wallpaperDecoration(BuildContext context, String? value) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    if (value == null || value.isEmpty) {
      return BoxDecoration(
        color: (dark ? Colors.white : scheme.surfaceContainerHigh).withValues(
          alpha: dark ? 0.06 : 0.9,
        ),
        borderRadius: BorderRadius.circular(20),
      );
    }
    if (value.startsWith('http')) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(image: NetworkImage(value), fit: BoxFit.cover),
      );
    }
    final builtin = resolveBuiltinWallpaper(value);
    if (builtin != null) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: builtin.previewGradient,
        image: DecorationImage(
          image: AssetImage(builtin.assetFor(Theme.of(context).brightness)),
          fit: BoxFit.cover,
        ),
      );
    }
    final animated = resolveAnimatedWallpaper(value);
    if (animated != null) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: animated.previewGradient,
        image: DecorationImage(
          image: AssetImage(animated.assetFor(Theme.of(context).brightness)),
          fit: BoxFit.cover,
        ),
      );
    }
    final gradient = _wallpaperGradient(value);
    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: gradient,
      color: gradient == null
          ? (dark ? Colors.white : scheme.surfaceContainerHigh).withValues(
              alpha: dark ? 0.06 : 0.9,
            )
          : null,
    );
  }

  double _previewMessageFont(String fontSize) {
    switch (fontSize) {
      case 'small':
        return 12;
      case 'large':
        return 16;
      default:
        return 14;
    }
  }

  Map<String, Object?> _iconStyleMapToJson(
    Map<String, BottomNavIconVisualStyle> value,
  ) {
    final out = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key.trim().isEmpty || entry.value.isEmpty) continue;
      out[entry.key] = entry.value.toJson();
    }
    return out;
  }

  Future<void> _saveBottomNavIconNames(_EditableChatSettings s) async {
    await _savePatch(<String, Object?>{
      'bottomNavIconNames': Map<String, String>.from(s.bottomNavIconNames),
    });
  }

  Future<void> _saveBottomNavGlobalStyle(_EditableChatSettings s) async {
    await _savePatch(<String, Object?>{
      'bottomNavIconGlobalStyle': s.bottomNavIconGlobalStyle.toJson(),
    });
  }

  Future<void> _saveBottomNavIconStyles(_EditableChatSettings s) async {
    await _savePatch(<String, Object?>{
      'bottomNavIconStyles': _iconStyleMapToJson(s.bottomNavIconStyles),
    });
  }

  Future<void> _setBottomNavIconName(
    _EditableChatSettings s, {
    required String href,
    required String iconName,
  }) async {
    final next = Map<String, String>.from(s.bottomNavIconNames)
      ..[href] = iconName;
    setState(() => s.bottomNavIconNames = next);
    await _saveBottomNavIconNames(s);
  }

  Future<void> _resetBottomNavIconOverride(
    _EditableChatSettings s, {
    required String href,
  }) async {
    final nextNames = Map<String, String>.from(s.bottomNavIconNames)
      ..remove(href);
    final nextStyles = Map<String, BottomNavIconVisualStyle>.from(
      s.bottomNavIconStyles,
    )..remove(href);
    setState(() {
      s.bottomNavIconNames = nextNames;
      s.bottomNavIconStyles = nextStyles;
      if (_iconStyleExpandedHref == href) {
        _iconStyleExpandedHref = null;
      }
    });
    await _savePatch(<String, Object?>{
      'bottomNavIconNames': nextNames,
      'bottomNavIconStyles': _iconStyleMapToJson(nextStyles),
    });
  }

  Future<void> _resetBottomNavGlobalStyle(_EditableChatSettings s) async {
    setState(
      () => s.bottomNavIconGlobalStyle = const BottomNavIconVisualStyle(),
    );
    await _saveBottomNavGlobalStyle(s);
  }

  Future<void> _updateBottomNavGlobalStyle(
    _EditableChatSettings s,
    BottomNavIconVisualStyle Function(BottomNavIconVisualStyle current) apply,
  ) async {
    final next = apply(s.bottomNavIconGlobalStyle);
    setState(() => s.bottomNavIconGlobalStyle = next);
    await _saveBottomNavGlobalStyle(s);
  }

  Future<void> _updateBottomNavIconStyle(
    _EditableChatSettings s, {
    required String href,
    required BottomNavIconVisualStyle Function(BottomNavIconVisualStyle current)
    apply,
  }) async {
    final all = Map<String, BottomNavIconVisualStyle>.from(
      s.bottomNavIconStyles,
    );
    final current = all[href] ?? const BottomNavIconVisualStyle();
    final next = apply(current);
    if (next.isEmpty) {
      all.remove(href);
    } else {
      all[href] = next;
    }
    setState(() => s.bottomNavIconStyles = all);
    await _saveBottomNavIconStyles(s);
  }

  Future<void> _openBottomNavIconPicker(
    _EditableChatSettings s, {
    required BottomNavMenuItemDefinition item,
  }) async {
    var query = '';
    final baseDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: baseDark ? 0.62 : 0.32),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final scheme = Theme.of(context).colorScheme;
            final dark = scheme.brightness == Brightness.dark;
            final fg = dark ? Colors.white : scheme.onSurface;
            final q = query.trim().toLowerCase();
            final filtered = q.isEmpty
                ? bottomNavIconLibrary
                : bottomNavIconLibrary
                      .where((entry) {
                        if (entry.name.contains(q)) return true;
                        if (ruEnSubstringMatch(entry.label, q)) return true;
                        return entry.searchKeywords.any(
                          (k) => ruEnSubstringMatch(k, q),
                        );
                      })
                      .toList(growable: false);
            final current = resolveBottomNavIconName(
              item.href,
              s.bottomNavIconNames,
            );
            return Dialog(
              backgroundColor: dark
                  ? const Color(0xFF0C1018)
                  : scheme.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(
                  color: fg.withValues(alpha: dark ? 0.18 : 0.12),
                ),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 560,
                  maxHeight: 690,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.chat_settings_icon_picker_title(localizedBottomNavLabel(item.href, l10n)),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: fg.withValues(alpha: dark ? 0.96 : 0.9),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close_rounded,
                              color: fg.withValues(alpha: dark ? 0.86 : 0.76),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: TextField(
                        onChanged: (v) => setLocalState(() => query = v),
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: l10n.chat_settings_search_hint,
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor:
                              (dark
                                      ? Colors.white
                                      : scheme.surfaceContainerHigh)
                                  .withValues(alpha: dark ? 0.04 : 0.86),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: fg.withValues(alpha: dark ? 0.18 : 0.12),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: fg.withValues(alpha: dark ? 0.18 : 0.12),
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                            borderSide: BorderSide(color: Color(0xFF2F86FF)),
                          ),
                        ),
                        style: TextStyle(color: fg.withValues(alpha: 0.95)),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: fg.withValues(alpha: dark ? 0.25 : 0.12),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                l10n.common_nothing_found,
                                style: TextStyle(
                                  color: fg.withValues(
                                    alpha: dark ? 0.62 : 0.56,
                                  ),
                                ),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                12,
                                14,
                                12,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 7,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final icon = filtered[index];
                                final selected = icon.name == current;
                                return InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () async {
                                    Navigator.of(context).pop();
                                    await _setBottomNavIconName(
                                      s,
                                      href: item.href,
                                      iconName: icon.name,
                                    );
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 140),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: selected
                                          ? const Color(0xFF2F86FF)
                                          : (dark
                                                    ? Colors.white
                                                    : scheme
                                                          .surfaceContainerHigh)
                                                .withValues(
                                                  alpha: dark ? 0.06 : 0.86,
                                                ),
                                      border: Border.all(
                                        color: selected
                                            ? const Color(0xFF5B9EFF)
                                            : fg.withValues(
                                                alpha: dark ? 0.1 : 0.12,
                                              ),
                                      ),
                                    ),
                                    child: Icon(
                                      icon.icon,
                                      color: selected
                                          ? Colors.white
                                          : fg.withValues(
                                              alpha: dark ? 0.95 : 0.82,
                                            ),
                                      size: 24,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    Divider(
                      height: 1,
                      color: fg.withValues(alpha: dark ? 0.25 : 0.12),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 46),
                            side: BorderSide(
                              color: fg.withValues(alpha: dark ? 0.18 : 0.12),
                            ),
                          ),
                          child: Text(l10n.common_cancel),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _hexEquals(String? a, String? b) {
    final aa = a?.trim().toUpperCase();
    final bb = b?.trim().toUpperCase();
    if (aa == null || aa.isEmpty || bb == null || bb.isEmpty) return false;
    return aa == bb;
  }

  /// Только значения `#RRGGBB` для ряда кружков (не `none` и не мусор из старых данных).
  String? _hexSwatchSelection(String? raw) {
    final t = raw?.trim();
    if (t == null || t.isEmpty || !t.startsWith('#')) return null;
    return t;
  }

  Widget _buildColorSwatches({
    required String? selectedHex,
    required ValueChanged<String> onSelect,
    required VoidCallback onReset,
    required String resetLabel,
    Widget? betweenSwatchesAndReset,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _iconStyleColorSwatches
              .map((color) {
                final hex = colorToHex(color);
                final selected = _hexEquals(selectedHex, hex);
                return InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onSelect(hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(
                        color: selected
                            ? (dark
                                  ? Colors.white
                                  : scheme.surfaceContainerLowest)
                            : fg.withValues(alpha: dark ? 0.26 : 0.2),
                        width: selected ? 2 : 1.2,
                      ),
                    ),
                    child: selected
                        ? Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: dark ? Colors.white : scheme.onPrimary,
                          )
                        : null,
                  ),
                );
              })
              .toList(growable: false),
        ),
        if (betweenSwatchesAndReset != null) ...[
          const SizedBox(height: 6),
          betweenSwatchesAndReset,
        ],
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: onReset,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 36),
            side: BorderSide(color: fg.withValues(alpha: dark ? 0.18 : 0.12)),
          ),
          child: Text(resetLabel),
        ),
      ],
    );
  }

  Widget _buildBottomNavStyleEditor({
    required BottomNavIconVisualStyle currentStyle,
    required BottomNavIconVisualStyle effectiveStyle,
    required ValueChanged<BottomNavIconVisualStyle> onStyleChanged,
    required bool isGlobalEditor,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    final iconColor = currentStyle.iconColor ?? effectiveStyle.iconColor;
    final tileBackground =
        currentStyle.tileBackground ?? effectiveStyle.tileBackground;
    final iconSize = (currentStyle.size ?? effectiveStyle.size ?? 22)
        .clamp(16.0, 34.0)
        .toDouble();
    final stroke = (currentStyle.strokeWidth ?? effectiveStyle.strokeWidth ?? 2)
        .clamp(1.0, 3.0)
        .toDouble();

    BottomNavIconVisualStyle apply({
      String? iconColor,
      String? tileBackground,
      double? size,
      double? strokeWidth,
      bool resetIconColor = false,
      bool resetTileBackground = false,
      bool resetSize = false,
      bool resetStrokeWidth = false,
    }) {
      return currentStyle.copyWith(
        iconColor: resetIconColor
            ? null
            : (iconColor ?? currentStyle.iconColor),
        tileBackground: resetTileBackground
            ? null
            : (tileBackground ?? currentStyle.tileBackground),
        size: resetSize ? null : (size ?? currentStyle.size),
        strokeWidth: resetStrokeWidth
            ? null
            : (strokeWidth ?? currentStyle.strokeWidth),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: (dark ? Colors.white : scheme.surfaceContainerHigh).withValues(
          alpha: dark ? 0.03 : 0.84,
        ),
        border: Border.all(color: fg.withValues(alpha: dark ? 0.12 : 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.chat_settings_icon_color,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: fg.withValues(alpha: dark ? 0.86 : 0.82),
            ),
          ),
          const SizedBox(height: 8),
          _buildColorSwatches(
            selectedHex: _hexSwatchSelection(iconColor),
            onSelect: (hex) => onStyleChanged(apply(iconColor: hex)),
            onReset: () => onStyleChanged(apply(resetIconColor: true)),
            resetLabel: l10n.chat_settings_color_default,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                l10n.chat_settings_icon_size,
                style: TextStyle(
                  fontSize: 14,
                  color: fg.withValues(alpha: dark ? 0.8 : 0.76),
                ),
              ),
              const Spacer(),
              Text(
                iconSize.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 13,
                  color: fg.withValues(alpha: dark ? 0.7 : 0.66),
                ),
              ),
            ],
          ),
          Slider(
            min: 16,
            max: 34,
            divisions: 18,
            value: iconSize,
            onChanged: (v) => onStyleChanged(apply(size: v)),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => onStyleChanged(apply(resetSize: true)),
              child: Text(l10n.chat_settings_reset_size),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                l10n.chat_settings_stroke_width,
                style: TextStyle(
                  fontSize: 14,
                  color: fg.withValues(alpha: dark ? 0.8 : 0.76),
                ),
              ),
              const Spacer(),
              Text(
                stroke.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 13,
                  color: fg.withValues(alpha: dark ? 0.7 : 0.66),
                ),
              ),
            ],
          ),
          Slider(
            min: 1,
            max: 3,
            divisions: 8,
            value: stroke,
            onChanged: (v) => onStyleChanged(apply(strokeWidth: v)),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => onStyleChanged(apply(resetStrokeWidth: true)),
              child: Text(l10n.chat_settings_reset_stroke),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.chat_settings_tile_background,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: fg.withValues(alpha: dark ? 0.86 : 0.82),
            ),
          ),
          const SizedBox(height: 8),
          _buildColorSwatches(
            selectedHex: _hexSwatchSelection(tileBackground),
            onSelect: (hex) => onStyleChanged(apply(tileBackground: hex)),
            onReset: () => onStyleChanged(apply(resetTileBackground: true)),
            resetLabel: isGlobalEditor
                ? l10n.chat_settings_default_gradient
                : l10n.chat_settings_inherit_global,
            betweenSwatchesAndReset: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => onStyleChanged(apply(tileBackground: 'none')),
                child: Text(
                  bottomNavTileBackgroundIsNone(
                        currentStyle.tileBackground ??
                            effectiveStyle.tileBackground,
                      )
                      ? l10n.chat_settings_no_bg_on
                      : l10n.chat_settings_no_bg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavIconsSection(_EditableChatSettings s) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final textMain = (dark ? Colors.white : scheme.onSurface).withValues(
      alpha: dark ? 0.92 : 0.9,
    );
    final textSecondary = (dark ? Colors.white : scheme.onSurface).withValues(
      alpha: dark ? 0.62 : 0.62,
    );
    final appearance = s.bottomNavAppearance;

    final globalPreview = mergeBottomNavIconVisualStyles(
      const BottomNavIconVisualStyle(),
      s.bottomNavIconGlobalStyle,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.chat_settings_bottom_nav_icons,
          style: TextStyle(
            fontSize: _kBlockTitleSize,
            fontWeight: FontWeight.w600,
            color: textMain,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.chat_settings_bottom_nav_description,
          style: TextStyle(fontSize: _kMutedTextSize, color: textSecondary),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SegmentButton(
                label: l10n.chat_settings_colorful,
                active: appearance != 'minimal',
                onTap: () {
                  setState(() => s.bottomNavAppearance = 'colorful');
                  _savePatch(<String, Object?>{
                    'bottomNavAppearance': 'colorful',
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SegmentButton(
                label: l10n.chat_settings_minimalism,
                active: appearance == 'minimal',
                onTap: () {
                  setState(() => s.bottomNavAppearance = 'minimal');
                  _savePatch(<String, Object?>{
                    'bottomNavAppearance': 'minimal',
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: (dark ? const Color(0xFF101B3A) : scheme.surfaceContainerLow)
                .withValues(alpha: dark ? 0.46 : 0.9),
            border: Border.all(
              color: (dark ? const Color(0xFF2F86FF) : scheme.primary)
                  .withValues(alpha: dark ? 0.52 : 0.34),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  children: [
                    _BottomNavIconTilePreview(
                      iconName: 'sparkles',
                      href: '/global',
                      appearance: appearance,
                      style: globalPreview,
                      fallbackIcon: Icons.auto_awesome_outlined,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.chat_settings_for_all_icons,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textMain,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.chat_settings_bottom_nav_global_description,
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!s.bottomNavIconGlobalStyle.isEmpty)
                      IconButton(
                        tooltip: l10n.chat_settings_reset,
                        onPressed: () =>
                            unawaited(_resetBottomNavGlobalStyle(s)),
                        icon: const Icon(Icons.undo_rounded, size: 20),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => setState(
                        () => _globalIconStyleExpanded =
                            !_globalIconStyleExpanded,
                      ),
                      icon: const Icon(Icons.palette_outlined, size: 17),
                      label: Text(
                        _globalIconStyleExpanded ? l10n.chat_settings_hide : l10n.chat_settings_customize,
                      ),
                    ),
                  ],
                ),
              ),
              if (_globalIconStyleExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: _buildBottomNavStyleEditor(
                    currentStyle: s.bottomNavIconGlobalStyle,
                    effectiveStyle: s.bottomNavIconGlobalStyle,
                    isGlobalEditor: true,
                    onStyleChanged: (next) =>
                        unawaited(_updateBottomNavGlobalStyle(s, (_) => next)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...bottomNavMenuItems.map((item) {
          final resolvedName = resolveBottomNavIconName(
            item.href,
            s.bottomNavIconNames,
          );
          final localStyle =
              s.bottomNavIconStyles[item.href] ??
              const BottomNavIconVisualStyle();
          final effectiveStyle = mergeBottomNavIconVisualStyles(
            s.bottomNavIconGlobalStyle,
            localStyle,
          );
          final isExpanded = _iconStyleExpandedHref == item.href;
          final hasOverride =
              s.bottomNavIconNames.containsKey(item.href) ||
              s.bottomNavIconStyles[item.href]?.isEmpty == false;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: (dark ? Colors.white : scheme.surfaceContainerLow)
                  .withValues(alpha: dark ? 0.05 : 0.88),
              border: Border.all(
                color: (dark ? Colors.white : scheme.onSurface).withValues(
                  alpha: dark ? 0.12 : 0.1,
                ),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Row(
                    children: [
                      _BottomNavIconTilePreview(
                        iconName: resolvedName,
                        href: item.href,
                        appearance: appearance,
                        style: effectiveStyle,
                        fallbackIcon: item.fallbackIcon,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizedBottomNavLabel(item.href, l10n),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textMain,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              resolvedName,
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasOverride)
                        IconButton(
                          tooltip: l10n.chat_settings_reset_item,
                          onPressed: () => unawaited(
                            _resetBottomNavIconOverride(s, href: item.href),
                          ),
                          icon: const Icon(Icons.undo_rounded, size: 20),
                        ),
                      IconButton(
                        tooltip: l10n.chat_settings_style,
                        onPressed: () => setState(
                          () => _iconStyleExpandedHref = isExpanded
                              ? null
                              : item.href,
                        ),
                        icon: const Icon(Icons.palette_outlined, size: 20),
                      ),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _openBottomNavIconPicker(s, item: item),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text(l10n.chat_settings_select),
                      ),
                    ],
                  ),
                ),
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: _buildBottomNavStyleEditor(
                      currentStyle: localStyle,
                      effectiveStyle: effectiveStyle,
                      isGlobalEditor: false,
                      onStyleChanged: (next) => unawaited(
                        _updateBottomNavIconStyle(
                          s,
                          href: item.href,
                          apply: (_) => next,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Future<void> _resetSettings() async {
    final repo = ref.read(chatSettingsRepositoryProvider);
    final user = FirebaseAuth.instance.currentUser;
    if (repo == null || user == null) return;
    await repo.setChatSettings(user.uid, _defaultChatSettings);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = _state;
    if (_loading || s == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final textMain = (dark ? Colors.white : scheme.onSurface).withValues(
      alpha: dark ? 0.94 : 0.92,
    );
    final textSecondary = (dark ? Colors.white : scheme.onSurface).withValues(
      alpha: dark ? 0.62 : 0.62,
    );
    final sectionBlue = dark ? const Color(0xFF4DA2FF) : scheme.primary;

    final outgoingColor = _colorFromHex(s.bubbleColor, const Color(0xFF637FE1));
    final incomingColor = _colorFromHex(
      s.incomingBubbleColor,
      const Color(0xFF33404A),
    );

    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Material(
                      color: (dark ? Colors.white : scheme.surface).withValues(
                        alpha: dark ? 0.08 : 0.74,
                      ),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/account');
                          }
                        },
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.chevron_left_rounded,
                            size: 28,
                            color: textMain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: sectionBlue,
                      size: 27,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context)!.settings_chats_title,
                      style: TextStyle(
                        fontSize: _kHeaderTitleSize,
                        fontWeight: FontWeight.w700,
                        color: textMain,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                // Sticky-превью: карточка чат-превью закреплена сверху
                // через `SliverPersistentHeader(pinned: true)`. Все
                // настройки, влияющие на внешний вид (обои, цвета,
                // шрифт, форма пузырьков, отметки времени), при
                // изменении сразу видны без необходимости скроллить
                // обратно к превью.
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverPersistentHeader(
                      // pinned: после раздела «Эмодзи эффекты» (т.е. когда
                      // _hidePreview == true) слой превью схлопывается
                      // в высоту 0 и перестаёт быть прикреплённым —
                      // освобождает место под последующие настройки.
                      pinned: !_hidePreview,
                      delegate: _PreviewHeaderDelegate(
                        height: _hidePreview ? 0 : 374,
                        background: dark
                            ? const Color(0xFF04070C)
                            : scheme.surface,
                        child: KeyedSubtree(
                          key: _previewKey,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!
                                      .settings_chats_preview,
                                  style: TextStyle(
                                    fontSize: _kSectionTitleSize,
                                    fontWeight: FontWeight.w700,
                                    color: sectionBlue,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _ChatPreviewCard(
                                  wallpaperDecoration: _wallpaperDecoration(
                                    context,
                                    s.chatWallpaper,
                                  ),
                                  animatedWallpaper: resolveAnimatedWallpaper(
                                    s.chatWallpaper,
                                  ),
                                  incomingBubbleColor: incomingColor,
                                  outgoingBubbleColor: outgoingColor,
                                  bubbleRadius: s.bubbleRadius,
                                  showTimestamps: s.showTimestamps,
                                  messageFontSize:
                                      _previewMessageFont(s.fontSize),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        4,
                        16,
                        24 + MediaQuery.paddingOf(context).bottom,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 4),
                      // Обои чата — единый раздел: сначала фирменные
                      // (kBuiltinWallpapers), затем классические градиенты-
                      // пресеты, затем пользовательские изображения и кнопка
                      // загрузки. Сетка 4×N для компактности.
                      Text(
                        l10n.chat_settings_chat_background,
                        style: TextStyle(
                          fontSize: _kBlockTitleSize,
                          fontWeight: FontWeight.w600,
                          color: textMain,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // На главной — первые 10 фирменных обоев + все
                      // загруженные пользователем + кнопка добавить +
                      // (если фирменных >10) кнопка «Показать все», которая
                      // открывает полноэкранный picker с полным списком,
                      // включая классические градиенты-пресеты.
                      //
                      // Если выбранный фон — builtin за пределами топ-10,
                      // он поднимается в начало списка, чтобы оставаться
                      // видимым после возврата из picker'а.
                      Builder(
                        builder: (context) {
                          final current = s.chatWallpaper;
                          final selectedBuiltinIdx = current == null
                              ? -1
                              : kBuiltinWallpapers.indexWhere(
                                  (w) => w.value == current,
                                );
                          final builtinAll = selectedBuiltinIdx > 0
                              ? <BuiltinWallpaper>[
                                  kBuiltinWallpapers[selectedBuiltinIdx],
                                  for (var i = 0;
                                      i < kBuiltinWallpapers.length;
                                      i++)
                                    if (i != selectedBuiltinIdx)
                                      kBuiltinWallpapers[i],
                                ]
                              : kBuiltinWallpapers;
                          const builtinPreviewCount = 10;
                          final builtinShown =
                              builtinAll.length <= builtinPreviewCount
                                  ? builtinAll.length
                                  : builtinPreviewCount;
                          final hasMore =
                              builtinAll.length > builtinPreviewCount ||
                              _wallpaperPresets(l10n).isNotEmpty;
                          final customCount = s.customBackgrounds.length;
                          final itemCount =
                              builtinShown + customCount + 1 +
                              (hasMore ? 1 : 0);
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: itemCount,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 1.04,
                                ),
                            itemBuilder: (context, index) {
                              if (index < builtinShown) {
                                final wp = builtinAll[index];
                                final value = wp.value;
                                final selected = s.chatWallpaper == value;
                                return _WallpaperTile(
                                  selected: selected,
                                  decoration: _wallpaperDecoration(
                                    context,
                                    value,
                                  ),
                                  onTap: () => _selectWallpaper(s, value),
                                );
                              }
                              if (index < builtinShown + customCount) {
                                final url = s.customBackgrounds[
                                    index - builtinShown];
                                final selected = s.chatWallpaper == url;
                                return _WallpaperTile(
                                  selected: selected,
                                  decoration: _wallpaperDecoration(
                                    context,
                                    url,
                                  ),
                                  onTap: () => _selectWallpaper(s, url),
                                  onDelete: () =>
                                      _confirmRemoveCustomWallpaper(url),
                                );
                              }
                              if (index == builtinShown + customCount) {
                                return _AddWallpaperTile(
                                  uploading: _uploading,
                                  onTap: _uploading
                                      ? null
                                      : _pickAndUploadWallpaper,
                                );
                              }
                              return _ShowMoreWallpapersTile(
                                onTap: () => _openWallpapersPicker(
                                  s,
                                  incomingBubbleColor: incomingColor,
                                  outgoingBubbleColor: outgoingColor,
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.chat_settings_background_hint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: _kBodyTextSize,
                          color: textSecondary,
                        ),
                      ),
                      // Анимированные обои — отдельная секция. Над плиткой
                      // значок «▶» подсказывает, что это движение, а не
                      // статика. Анимация одноразовая (играется один раз
                      // при открытии чата) и не отвлекает от переписки.
                      const SizedBox(height: 20),
                      Text(
                        l10n.chat_settings_animated_wallpapers_heading,
                        style: TextStyle(
                          fontSize: _kBlockTitleSize,
                          fontWeight: FontWeight.w600,
                          color: textMain,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.chat_settings_animated_wallpapers_hint,
                        style: TextStyle(
                          fontSize: _kMutedTextSize,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: kAnimatedWallpapers.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1.04,
                            ),
                        itemBuilder: (context, index) {
                          final wp = kAnimatedWallpapers[index];
                          final value = wp.value;
                          return _AnimatedWallpaperTile(
                            selected: s.chatWallpaper == value,
                            decoration: _wallpaperDecoration(context, value),
                            onTap: () => _selectWallpaper(s, value),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.chat_settings_outgoing_messages,
                        style: TextStyle(
                          fontSize: _kBlockTitleSize,
                          fontWeight: FontWeight.w600,
                          color: textMain,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ColorPaletteRow(
                        options: _outgoingBubbleColors(l10n),
                        selectedValue: s.bubbleColor,
                        resolveColor: (value, fallback) =>
                            _colorFromHex(value, fallback),
                        onSelect: (value) {
                          setState(() => s.bubbleColor = value);
                          _savePatch(<String, Object?>{'bubbleColor': value});
                          _scrollToPreview();
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.chat_settings_incoming_messages,
                        style: TextStyle(
                          fontSize: _kBlockTitleSize,
                          fontWeight: FontWeight.w600,
                          color: textMain,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ColorPaletteRow(
                        options: _incomingBubbleColors(l10n),
                        selectedValue: s.incomingBubbleColor,
                        resolveColor: (value, fallback) =>
                            _colorFromHex(value, fallback),
                        onSelect: (value) {
                          setState(() => s.incomingBubbleColor = value);
                          _savePatch(<String, Object?>{
                            'incomingBubbleColor': value,
                          });
                          _scrollToPreview();
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.chat_settings_font_size,
                        style: TextStyle(
                          fontSize: _kBlockTitleSize,
                          fontWeight: FontWeight.w600,
                          color: textMain,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _SegmentButton(
                              label: l10n.chat_settings_font_small,
                              active: s.fontSize == 'small',
                              onTap: () {
                                setState(() => s.fontSize = 'small');
                                _savePatch(<String, Object?>{
                                  'fontSize': 'small',
                                });
                                _scrollToPreview();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SegmentButton(
                              label: l10n.chat_settings_font_medium,
                              active: s.fontSize == 'medium',
                              onTap: () {
                                setState(() => s.fontSize = 'medium');
                                _savePatch(<String, Object?>{
                                  'fontSize': 'medium',
                                });
                                _scrollToPreview();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SegmentButton(
                              label: l10n.chat_settings_font_large,
                              active: s.fontSize == 'large',
                              onTap: () {
                                setState(() => s.fontSize = 'large');
                                _savePatch(<String, Object?>{
                                  'fontSize': 'large',
                                });
                                _scrollToPreview();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.chat_settings_bubble_shape,
                        style: TextStyle(
                          fontSize: _kBlockTitleSize,
                          fontWeight: FontWeight.w600,
                          color: textMain,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _BubbleShapeCard(
                              title: l10n.chat_settings_bubble_rounded,
                              selected: s.bubbleRadius == 'rounded',
                              rounded: true,
                              onTap: () {
                                setState(() => s.bubbleRadius = 'rounded');
                                _savePatch(<String, Object?>{
                                  'bubbleRadius': 'rounded',
                                });
                                _scrollToPreview();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _BubbleShapeCard(
                              title: l10n.chat_settings_bubble_square,
                              selected: s.bubbleRadius == 'square',
                              rounded: false,
                              onTap: () {
                                setState(() => s.bubbleRadius = 'square');
                                _savePatch(<String, Object?>{
                                  'bubbleRadius': 'square',
                                });
                                _scrollToPreview();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        key: _emojiSectionKey,
                        l10n.chat_settings_emoji_effects,
                        style: TextStyle(
                          fontSize: _kBlockTitleSize,
                          fontWeight: FontWeight.w600,
                          color: textMain,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.chat_settings_emoji_description,
                        style: TextStyle(
                          fontSize: _kMutedTextSize,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _SegmentButton(
                              label: l10n.animation_quality_lite,
                              fontSize: 14,
                              active:
                                  s.emojiBurstAnimationProfile ==
                                  chatEmojiBurstAnimationProfileLite,
                              onTap: () {
                                setState(
                                  () => s.emojiBurstAnimationProfile =
                                      chatEmojiBurstAnimationProfileLite,
                                );
                                _savePatch(<String, Object?>{
                                  'emojiBurstAnimationProfile':
                                      chatEmojiBurstAnimationProfileLite,
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SegmentButton(
                              label: l10n.animation_quality_balanced,
                              fontSize: 14,
                              active:
                                  s.emojiBurstAnimationProfile ==
                                  chatEmojiBurstAnimationProfileBalanced,
                              onTap: () {
                                setState(
                                  () => s.emojiBurstAnimationProfile =
                                      chatEmojiBurstAnimationProfileBalanced,
                                );
                                _savePatch(<String, Object?>{
                                  'emojiBurstAnimationProfile':
                                      chatEmojiBurstAnimationProfileBalanced,
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SegmentButton(
                              label: l10n.animation_quality_cinematic,
                              fontSize: 14,
                              active:
                                  s.emojiBurstAnimationProfile ==
                                  chatEmojiBurstAnimationProfileCinematic,
                              onTap: () {
                                setState(
                                  () => s.emojiBurstAnimationProfile =
                                      chatEmojiBurstAnimationProfileCinematic,
                                );
                                _savePatch(<String, Object?>{
                                  'emojiBurstAnimationProfile':
                                      chatEmojiBurstAnimationProfileCinematic,
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        switch (s.emojiBurstAnimationProfile) {
                          chatEmojiBurstAnimationProfileLite =>
                            'Lite: минимум нагрузки и максимально плавно на слабых устройствах.',
                          chatEmojiBurstAnimationProfileCinematic =>
                            'Cinematic: максимум частиц и глубины для вау-эффекта.',
                          _ =>
                            'Balanced: автоматический компромисс между производительностью и выразительностью.',
                        },
                        style: TextStyle(
                          fontSize: _kBodyTextSize,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _buildBottomNavIconsSection(s),
                      const SizedBox(height: 22),
                      Text(
                        l10n.chat_settings_additional,
                        style: TextStyle(
                          fontSize: _kSectionTitleSize,
                          fontWeight: FontWeight.w700,
                          color: sectionBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // «Показать время» — стиль toggle-row без отдельной
                      // карточки (тот же шаблон, что у «Авто-перевод» ниже).
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.chat_settings_show_time,
                                    style: TextStyle(
                                      fontSize: _kBlockTitleSize,
                                      fontWeight: FontWeight.w600,
                                      color: textMain,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.chat_settings_show_time_hint,
                                    style: TextStyle(
                                      fontSize: _kBodyTextSize,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: s.showTimestamps,
                              onChanged: (value) {
                                setState(() => s.showTimestamps = value);
                                _savePatch(<String, Object?>{
                                  'showTimestamps': value,
                                });
                                _scrollToPreview();
                              },
                              activeThumbColor: Colors.white,
                              activeTrackColor: sectionBlue,
                            ),
                          ],
                        ),
                      ),
                      // Auto-translate incoming messages: ML Kit on-device,
                      // язык назначения = язык UI пользователя.
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.chat_settings_auto_translate,
                                    style: TextStyle(
                                      fontSize: _kBlockTitleSize,
                                      fontWeight: FontWeight.w600,
                                      color: textMain,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.chat_settings_auto_translate_hint,
                                    style: TextStyle(
                                      fontSize: _kBodyTextSize,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: s.autoTranslateIncoming,
                              onChanged: (value) {
                                setState(
                                  () => s.autoTranslateIncoming = value,
                                );
                                _savePatch(<String, Object?>{
                                  'autoTranslateIncoming': value,
                                });
                              },
                              activeThumbColor: Colors.white,
                              activeTrackColor: sectionBlue,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: _resetSettings,
                          style: OutlinedButton.styleFrom(
                            backgroundColor:
                                (dark
                                        ? Colors.white
                                        : scheme.surfaceContainerHigh)
                                    .withValues(alpha: dark ? 0.04 : 0.88),
                            side: BorderSide(
                              color: (dark ? Colors.white : scheme.onSurface)
                                  .withValues(alpha: dark ? 0.16 : 0.12),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: Icon(
                            Icons.sync_rounded,
                            size: 18,
                            color: (dark ? Colors.white : scheme.onSurface)
                                .withValues(alpha: dark ? 0.82 : 0.68),
                          ),
                          label: Text(
                            l10n.chat_settings_reset_all,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: (dark ? Colors.white : scheme.onSurface)
                                  .withValues(alpha: dark ? 0.74 : 0.72),
                            ),
                          ),
                        ),
                      ),
                            ],
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sliver-делегат для sticky-превью в `CustomScrollView`. Превью имеет
/// фиксированную высоту, не сжимается, остаётся приклеенным сверху при
/// скролле остального контента.
class _PreviewHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PreviewHeaderDelegate({
    required this.child,
    required this.height,
    required this.background,
  });

  final Widget child;
  final double height;
  final Color background;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Когда высота == 0 (превью «отлипло» — после раздела эмодзи), не
    // рендерим child вообще, чтобы не было overflow и invisible
    // занимаемого места painter'ом анимации.
    return Container(
      color: background,
      height: height,
      child: height <= 0
          ? null
          : ClipRect(child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: 0,
              maxHeight: height,
              child: child,
            )),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _PreviewHeaderDelegate old) =>
      old.height != height ||
      old.background != background ||
      old.child != child;
}

class _ChatPreviewCard extends StatelessWidget {
  const _ChatPreviewCard({
    required this.wallpaperDecoration,
    required this.animatedWallpaper,
    required this.incomingBubbleColor,
    required this.outgoingBubbleColor,
    required this.bubbleRadius,
    required this.showTimestamps,
    required this.messageFontSize,
    this.overrideHeight,
  });

  final BoxDecoration wallpaperDecoration;
  /// Если выбран `animated:<slug>` — поверх preview-фона рисуется живой
  /// painter через [AnimatedWallpaperLayer], такой же как в реальном
  /// чате. Так пользователь сразу видит анимацию в карточке настроек.
  final AnimatedWallpaper? animatedWallpaper;
  final Color incomingBubbleColor;
  final Color outgoingBubbleColor;
  final String bubbleRadius;
  final bool showTimestamps;
  final double messageFontSize;
  /// Опциональная высота карточки. По умолчанию 320 (основной экран
  /// настроек), внутри bottom-sheet picker'а используется 220-240 для
  /// компактности.
  final double? overrideHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    final isSquare = bubbleRadius == 'square';
    final metaColor = fg.withValues(alpha: dark ? 0.48 : 0.56);
    // Высота 320 — компромисс: вертикальный wallpaper (1440×2880, 1:2)
    // показывается почти целиком при `BoxFit.cover`, но не занимает
    // больше половины экрана (важно потому, что превью теперь sticky —
    // см. `CustomScrollView` ниже).
    return Container(
      height: overrideHeight ?? 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: fg.withValues(alpha: dark ? 0.15 : 0.12)),
        color: dark ? const Color(0xFF0D121A) : scheme.surfaceContainerLow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(width: double.infinity, decoration: wallpaperDecoration),
            if (animatedWallpaper != null)
              AnimatedWallpaperLayer(
                key: ValueKey('preview-${animatedWallpaper!.slug}'),
                wallpaper: animatedWallpaper!,
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (dark ? Colors.black : scheme.surface).withValues(
                      alpha: dark ? 0.22 : 0.06,
                    ),
                    (dark ? Colors.black : scheme.surface).withValues(
                      alpha: dark ? 0.30 : 0.14,
                    ),
                    (dark ? Colors.black : scheme.surface).withValues(
                      alpha: dark ? 0.42 : 0.22,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 206),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: incomingBubbleColor,
                        borderRadius: BorderRadius.circular(isSquare ? 9 : 20),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.chat_settings_preview_incoming,
                        style: TextStyle(
                          fontSize: messageFontSize,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                  ),
                  if (showTimestamps)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        '11:58',
                        style: TextStyle(fontSize: 12, color: metaColor),
                      ),
                    ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 220),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: outgoingBubbleColor,
                        borderRadius: BorderRadius.circular(isSquare ? 9 : 20),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.chat_settings_preview_outgoing,
                        style: TextStyle(
                          fontSize: messageFontSize,
                          color: Colors.white.withValues(alpha: 0.96),
                        ),
                      ),
                    ),
                  ),
                  if (showTimestamps)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, right: 4),
                        child: Text(
                          '12:00',
                          style: TextStyle(fontSize: 12, color: metaColor),
                        ),
                      ),
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

class _ColorPaletteRow extends StatelessWidget {
  const _ColorPaletteRow({
    required this.options,
    required this.selectedValue,
    required this.resolveColor,
    required this.onSelect,
  });

  final List<({String? value, String label, Color fallback})> options;
  final String? selectedValue;
  final Color Function(String? value, Color fallback) resolveColor;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options
          .map(
            (opt) => Expanded(
              child: Center(
                child: _ColorDot(
                  color: resolveColor(opt.value, opt.fallback),
                  selected: selectedValue == opt.value,
                  onTap: () => onSelect(opt.value),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected
                ? (dark ? Colors.white : scheme.surfaceContainerLowest)
                      .withValues(alpha: dark ? 0.92 : 1)
                : fg.withValues(alpha: dark ? 0.16 : 0.16),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: selected
            ? Icon(
                Icons.check_rounded,
                color: dark ? Colors.white : scheme.onPrimary,
                size: 17,
              )
            : null,
      ),
    );
  }
}

class _BottomNavIconTilePreview extends StatelessWidget {
  const _BottomNavIconTilePreview({
    required this.iconName,
    required this.href,
    required this.appearance,
    required this.style,
    required this.fallbackIcon,
  });

  final String iconName;
  final String href;
  final String appearance;
  final BottomNavIconVisualStyle style;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    final iconData = iconDataForBottomNavName(iconName, fallbackIcon);
    final customIconColor = parseColorFromHex(style.iconColor);
    final noTile = bottomNavTileBackgroundIsNone(style.tileBackground);
    final customTile = noTile ? null : parseColorFromHex(style.tileBackground);
    final iconColor =
        customIconColor ??
        (appearance == 'minimal'
            ? fg.withValues(alpha: dark ? 0.86 : 0.82)
            : (dark ? Colors.white : fg.withValues(alpha: 0.94)));
    final iconSize = (style.size ?? 22).clamp(16, 34).toDouble();
    final stroke = (style.strokeWidth ?? 2).clamp(1, 3).toDouble();
    final iconWeight = 200 + ((stroke - 1) / 2 * 500);
    final defaultGradient = defaultBottomNavTileGradient(href);
    final tileGradient =
        !noTile && customTile == null && appearance != 'minimal'
        ? defaultGradient
        : null;
    final tileColor = noTile
        ? Colors.transparent
        : (customTile ??
              (appearance == 'minimal'
                  ? Colors.transparent
                  : (dark ? Colors.white : scheme.surfaceContainerHighest)
                        .withValues(alpha: dark ? 0.08 : 0.86)));
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: tileGradient == null ? tileColor : null,
        gradient: tileGradient,
        border: Border.all(
          color: appearance == 'minimal' && customTile == null && !noTile
              ? fg.withValues(alpha: dark ? 0.16 : 0.14)
              : fg.withValues(alpha: dark ? 0.12 : 0.1),
        ),
      ),
      child: Icon(
        iconData,
        size: iconSize,
        color: iconColor,
        weight: iconWeight,
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.active,
    required this.onTap,
    this.fontSize = 16,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 56),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        backgroundColor: active
            ? const Color(0xFF2F86FF)
            : (dark ? Colors.white : scheme.surfaceContainerHigh).withValues(
                alpha: dark ? 0.06 : 0.9,
              ),
        side: BorderSide(
          color: active
              ? const Color(0xFF2F86FF)
              : fg.withValues(alpha: dark ? 0.16 : 0.12),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: active
              ? Colors.white.withValues(alpha: 0.98)
              : fg.withValues(alpha: dark ? 0.62 : 0.68),
        ),
      ),
    );
  }
}

class _BubbleShapeCard extends StatelessWidget {
  const _BubbleShapeCard({
    required this.title,
    required this.selected,
    required this.rounded,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final bool rounded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        height: 138,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: (dark ? Colors.white : scheme.surfaceContainerHigh).withValues(
            alpha: dark ? 0.06 : 0.9,
          ),
          border: Border.all(
            color: selected
                ? const Color(0xFF2F86FF)
                : fg.withValues(alpha: dark ? 0.14 : 0.1),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2F86FF),
                borderRadius: BorderRadius.circular(rounded ? 20 : 7),
              ),
              child: Text(
                AppLocalizations.of(context)!.chat_settings_preview_hello,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: fg.withValues(alpha: dark ? 0.78 : 0.74),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WallpaperTile extends StatelessWidget {
  const _WallpaperTile({
    required this.selected,
    required this.decoration,
    required this.onTap,
    this.onDelete,
  });

  final bool selected;
  final BoxDecoration decoration;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: decoration.copyWith(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF2F86FF)
                : fg.withValues(alpha: dark ? 0.12 : 0.1),
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            if (selected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: (dark ? Colors.black : scheme.surface).withValues(
                      alpha: dark ? 0.16 : 0.14,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            if (onDelete != null)
              Positioned(
                top: 5,
                right: 5,
                child: InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (dark ? Colors.black : scheme.surface).withValues(
                        alpha: dark ? 0.42 : 0.32,
                      ),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddWallpaperTile extends StatelessWidget {
  const _AddWallpaperTile({required this.uploading, required this.onTap});

  final bool uploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: (dark ? Colors.white : scheme.surfaceContainerHigh).withValues(
            alpha: dark ? 0.04 : 0.9,
          ),
          border: Border.all(
            color: fg.withValues(alpha: dark ? 0.26 : 0.12),
            width: 1.6,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Center(
          child: uploading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 32,
                      color: fg.withValues(alpha: dark ? 0.7 : 0.66),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.common_add,
                      style: TextStyle(
                        fontSize: 14,
                        color: fg.withValues(alpha: dark ? 0.64 : 0.62),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Плитка анимированного обоя с badge «▶» в правом верхнем углу — чтобы
/// пользователь видел, что это движение, а не статика.
class _AnimatedWallpaperTile extends StatelessWidget {
  const _AnimatedWallpaperTile({
    required this.selected,
    required this.decoration,
    required this.onTap,
  });

  final bool selected;
  final BoxDecoration decoration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Сам preview как у обычной плитки
          _WallpaperTile(
            selected: selected,
            decoration: decoration,
            onTap: onTap,
          ),
          // Badge «анимация» поверх — маленький круглый индикатор play
          Positioned(
            right: 6,
            top: 6,
            child: IgnorePointer(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2F86FF).withValues(alpha: 0.92),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowMoreWallpapersTile extends StatelessWidget {
  const _ShowMoreWallpapersTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: (dark ? Colors.white : scheme.surfaceContainerHigh)
              .withValues(alpha: dark ? 0.04 : 0.9),
          border: Border.all(
            color: fg.withValues(alpha: dark ? 0.26 : 0.12),
            width: 1.6,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.grid_view_rounded,
                size: 28,
                color: fg.withValues(alpha: dark ? 0.7 : 0.66),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.chat_settings_show_all_wallpapers,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.15,
                  color: fg.withValues(alpha: dark ? 0.64 : 0.62),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
