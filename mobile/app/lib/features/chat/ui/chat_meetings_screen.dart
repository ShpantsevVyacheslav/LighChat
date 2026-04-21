import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../data/bottom_nav_icon_settings.dart';
import 'chat_bottom_nav.dart';
import 'chat_shell_backdrop.dart';

/// «Видеовстречи» — экран создания конференции и истории встреч.
///
/// UI-реализация дизайн-макета. Сама бизнес-логика создания встречи
/// (Firestore `meetings/{id}` + WebRTC) подключается отдельным модулем:
/// сейчас кнопка «Создать встречу» показывает плейсхолдер, данные формы
/// уже типизированы и готовы к пробросу в будущий `MeetingsRepository`.
///
/// Наложения слоёв с нижней навигацией исключены конструкцией `Column`
/// (скролл занимает только оставшееся место над `ChatBottomNav`).
class ChatMeetingsScreen extends ConsumerStatefulWidget {
  const ChatMeetingsScreen({super.key});

  @override
  ConsumerState<ChatMeetingsScreen> createState() =>
      _ChatMeetingsScreenState();
}

class _ChatMeetingsScreenState extends ConsumerState<ChatMeetingsScreen> {
  final TextEditingController _title = TextEditingController();
  _MeetingDuration _duration = _MeetingDuration.none;
  bool _isPrivate = true;
  bool _waitingRoom = false;

  @override
  void initState() {
    super.initState();
    // Кнопка «Создать встречу» зависит от наличия названия — перерисовываем.
    _title.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _title.removeListener(_onTitleChanged);
    _title.dispose();
    super.dispose();
  }

  void _onTitleChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final firebaseReady = ref.watch(firebaseReadyProvider);
    final userAsync = ref.watch(authUserProvider);

    if (!firebaseReady) {
      return const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Firebase is not configured yet.'),
        ),
      );
    }

    return userAsync.when(
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/auth');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userDoc =
            ref.watch(userChatSettingsDocProvider(user.uid)).asData?.value ??
            const <String, dynamic>{};
        final chatSettings = Map<String, dynamic>.from(
          userDoc['chatSettings'] as Map? ?? const <String, dynamic>{},
        );
        final bottomNavAppearance =
            (chatSettings['bottomNavAppearance'] as String?) ?? 'colorful';
        final bottomNavIconNames = parseBottomNavIconNames(
          chatSettings['bottomNavIconNames'],
        );
        final bottomNavGlobalStyle = BottomNavIconVisualStyle.fromJson(
          chatSettings['bottomNavIconGlobalStyle'],
        );
        final bottomNavIconStyles = parseBottomNavIconStyles(
          chatSettings['bottomNavIconStyles'],
        );

        final rawName = (user.displayName ?? '').trim();
        final selfName = rawName.isNotEmpty ? rawName : 'Профиль';
        final selfAvatar = user.photoURL;

        final scheme = Theme.of(context).colorScheme;
        final dark = scheme.brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const ChatShellBackdrop(),
              Column(
                children: [
                  Expanded(child: _buildBody(context)),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: (dark ? Colors.black : scheme.surfaceContainerLow)
                          .withValues(alpha: dark ? 0.62 : 0.78),
                      border: Border(
                        top: BorderSide(
                          color: (dark ? Colors.white : scheme.onSurface)
                              .withValues(alpha: dark ? 0.08 : 0.12),
                        ),
                      ),
                    ),
                    child: ChatBottomNav(
                      activeTab: ChatBottomNavTab.meetings,
                      onChatsTap: () => context.go('/chats'),
                      onContactsTap: () => context.go('/contacts'),
                      onCallsTap: () => context.go('/calls'),
                      onMeetingsTap: () => context.go('/meetings'),
                      onProfileTap: () => context.push('/account'),
                      avatarUrl: selfAvatar,
                      userTitle: selfName,
                      bottomNavAppearance: bottomNavAppearance,
                      bottomNavIconNames: bottomNavIconNames,
                      bottomNavIconGlobalStyle: bottomNavGlobalStyle,
                      bottomNavIconStyles: bottomNavIconStyles,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Auth: $e'))),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context),
            const SizedBox(height: 22),
            _sectionLabel(context, 'Новая встреча'),
            const SizedBox(height: 10),
            _formCard(context),
            const SizedBox(height: 12),
            _infoCard(
              context,
              icon: Icons.visibility_rounded,
              iconBg: const Color(0xFF1D4ED8),
              iconTint: const Color(0xFF60A5FA),
              title: 'Зал ожидания',
              description:
                  'В режиме зала ожидания вы полностью контролируете список '
                  'участников. Пока вы не нажмёте «Принять», гость будет '
                  'видеть экран ожидания.',
            ),
            const SizedBox(height: 12),
            _infoCard(
              context,
              icon: Icons.image_rounded,
              iconBg: const Color(0xFF6D28D9),
              iconTint: const Color(0xFFC4B5FD),
              title: 'Виртуальные фоны',
              description:
                  'Загружайте фоны и размывайте задний план при желании. '
                  'Изображение из галереи. Также доступна загрузка '
                  'собственных фонов.',
            ),
            const SizedBox(height: 16),
            _createButton(context),
            const SizedBox(height: 24),
            _historyHeader(context),
            const SizedBox(height: 10),
            _historyEmptyCard(context),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.videocam_rounded,
              color: const Color(0xFF3B82F6),
              size: 26,
            ),
            const SizedBox(width: 10),
            Text(
              'Видеовстречи',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: fg,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Text(
            'Создавайте конференции и управляйте доступом участников',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: fg.withValues(alpha: dark ? 0.58 : 0.62),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: fg.withValues(alpha: 0.92),
      ),
    );
  }

  Widget _formCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    final fieldFill = fg.withValues(alpha: dark ? 0.06 : 0.04);
    final fieldBorder = fg.withValues(alpha: dark ? 0.10 : 0.08);

    return _glass(
      context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fieldLabel(context, 'Название встречи'),
            const SizedBox(height: 6),
            TextField(
              controller: _title,
              style: TextStyle(color: fg, fontSize: 15),
              cursorColor: scheme.primary,
              decoration: _fieldDecoration(
                context,
                hint: 'Напр. Обсуждение логистики',
                fill: fieldFill,
                border: fieldBorder,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel(context, 'Длительность'),
                      const SizedBox(height: 6),
                      _durationDropdown(context, fieldFill, fieldBorder),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel(context, 'Тип доступа'),
                      const SizedBox(height: 6),
                      _accessToggle(context, fieldFill, fieldBorder),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _waitingRoomCheckbox(context),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: fg.withValues(alpha: 0.78),
      ),
    );
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String hint,
    required Color fill,
    required Color border,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: fg.withValues(alpha: 0.36),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: fill,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: scheme.primary.withValues(alpha: 0.65),
        ),
      ),
    );
  }

  Widget _durationDropdown(
    BuildContext context,
    Color fill,
    Color border,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_MeetingDuration>(
          value: _duration,
          isExpanded: true,
          isDense: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: fg.withValues(alpha: 0.6),
          ),
          dropdownColor: dark
              ? const Color(0xFF0E1420)
              : scheme.surfaceContainer,
          style: TextStyle(color: fg, fontSize: 15),
          hint: Text(
            'Без ограничения',
            style: TextStyle(
              color: fg.withValues(alpha: 0.36),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          items: _MeetingDuration.values.map((d) {
            return DropdownMenuItem<_MeetingDuration>(
              value: d,
              child: Text(d.label),
            );
          }).toList(growable: false),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _duration = v);
          },
        ),
      ),
    );
  }

  Widget _accessToggle(
    BuildContext context,
    Color fill,
    Color border,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _isPrivate = !_isPrivate),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _isPrivate ? 'Закрытая' : 'Открытая',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Transform.scale(
              scale: 0.85,
              child: Switch.adaptive(
                value: _isPrivate,
                onChanged: (v) => setState(() => _isPrivate = v),
                activeTrackColor: scheme.primary.withValues(alpha: 0.65),
                activeThumbColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _waitingRoomCheckbox(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _waitingRoom = !_waitingRoom),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: _waitingRoom,
                onChanged: (v) => setState(() => _waitingRoom = v ?? false),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                side: BorderSide(
                  color: fg.withValues(alpha: 0.35),
                  width: 1.4,
                ),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Добавить комнату ожидания',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: fg.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Только хозяин комнаты может дать разрешение на '
                    'подключение и блокировать',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: fg.withValues(alpha: 0.55),
                      height: 1.3,
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

  Widget _infoCard(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconTint,
    required String title,
    required String description,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    return _glass(
      context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: iconBg.withValues(alpha: 0.22),
                border: Border.all(color: iconBg.withValues(alpha: 0.28)),
              ),
              child: Icon(icon, size: 22, color: iconTint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: fg.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: fg.withValues(alpha: 0.58),
                      height: 1.35,
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

  Widget _createButton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = _title.text.trim().isNotEmpty;
    return SizedBox(
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? _onCreateMeeting : _hintTitleRequired,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: enabled
                    ? const [Color(0xFF2563EB), Color(0xFF3B82F6)]
                    : [
                        scheme.primary.withValues(alpha: 0.35),
                        scheme.primary.withValues(alpha: 0.25),
                      ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add_rounded, color: Colors.white, size: 22),
                SizedBox(width: 6),
                Text(
                  'Создать встречу',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _hintTitleRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Укажите название встречи')),
    );
  }

  void _onCreateMeeting() {
    // Плейсхолдер: реальная интеграция с Firestore-сущностью Meeting + WebRTC
    // будет подключена через отдельный MeetingsRepository (вне рамок
    // текущей задачи по дизайну).
    final parts = <String>['«${_title.text.trim()}»'];
    parts.add(_isPrivate ? 'закрытая' : 'открытая');
    if (_duration != _MeetingDuration.none) parts.add(_duration.label);
    if (_waitingRoom) parts.add('с залом ожидания');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Создание встречи ${parts.join(' · ')} пока недоступно'),
      ),
    );
  }

  Widget _historyHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 18,
          color: fg.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 8),
        Text(
          'Ваша история',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: fg.withValues(alpha: 0.92),
          ),
        ),
      ],
    );
  }

  Widget _historyEmptyCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    return _glass(
      context,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: fg.withValues(alpha: 0.06),
                border: Border.all(color: fg.withValues(alpha: 0.08)),
              ),
              child: Icon(
                Icons.event_rounded,
                size: 28,
                color: fg.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'История встреч пуста',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: fg.withValues(alpha: 0.58),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glass(BuildContext context, {required Widget child}) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: (dark ? Colors.white : Colors.white).withValues(
              alpha: dark ? 0.04 : 0.55,
            ),
            border: Border.all(
              color: (dark ? Colors.white : Colors.black).withValues(
                alpha: dark ? 0.08 : 0.06,
              ),
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: child,
        ),
      ),
    );
  }
}

enum _MeetingDuration { none, m15, m30, m60, m90 }

extension _MeetingDurationLabel on _MeetingDuration {
  String get label {
    switch (this) {
      case _MeetingDuration.none:
        return 'Без ограничения';
      case _MeetingDuration.m15:
        return '15 минут';
      case _MeetingDuration.m30:
        return '30 минут';
      case _MeetingDuration.m60:
        return '1 час';
      case _MeetingDuration.m90:
        return '1,5 часа';
    }
  }
}
