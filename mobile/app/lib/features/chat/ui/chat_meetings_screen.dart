import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lighchat_mobile/app_providers.dart';
import 'package:lighchat_mobile/features/meetings/data/meeting_models.dart';
import 'package:lighchat_mobile/features/meetings/data/meeting_providers.dart';

import '../../../l10n/app_localizations.dart';
import '../../../platform/native_nav_bar/native_nav_bar_facade.dart';
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
  ConsumerState<ChatMeetingsScreen> createState() => _ChatMeetingsScreenState();
}

class _ChatMeetingsScreenState extends ConsumerState<ChatMeetingsScreen> {
  final TextEditingController _title = TextEditingController();
  _MeetingDuration _duration = _MeetingDuration.none;
  bool _isPrivate = true;
  bool _creating = false;

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

  String? _asNonEmptyString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final firebaseReady = ref.watch(firebaseReadyProvider);
    final userAsync = ref.watch(authUserProvider);
    final l10n = AppLocalizations.of(context)!;

    if (!firebaseReady) {
      return Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Text(l10n.chat_list_firebase_not_configured),
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

        final selfName =
            _asNonEmptyString(userDoc['name']) ??
            _asNonEmptyString(user.displayName) ??
            l10n.profile_title;
        final selfAvatar =
            _asNonEmptyString(userDoc['avatarThumb']) ??
            _asNonEmptyString(userDoc['avatar']) ??
            _asNonEmptyString(user.photoURL);

        final scheme = Theme.of(context).colorScheme;
        final dark = scheme.brightness == Brightness.dark;

        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.transparent,
          body: Stack(
            fit: StackFit.expand,
            children: [
              const ChatShellBackdrop(),
              Column(
                children: [
                  Expanded(child: _buildBody(context, user.uid)),
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
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text(l10n.chat_auth_error(e.toString())))),
    );
  }

  Widget _buildBody(BuildContext context, String uid) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      top: true,
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          // 16pt базовый + место под native tab-bar overlay (≈77pt
          // на iOS), чтобы последняя секция проскролливалась ВЫШЕ
          // bar'а.
          16 + NativeNavBarFacade.instance.bottomBarOverlayPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context),
            const SizedBox(height: 22),
            _sectionLabel(context, l10n.chat_meetings_section_new),
            const SizedBox(height: 10),
            _formCard(context),
            const SizedBox(height: 12),
            _infoCard(
              context,
              icon: Icons.visibility_rounded,
              iconBg: const Color(0xFF1D4ED8),
              iconTint: const Color(0xFF60A5FA),
              title: l10n.chat_meetings_waiting_room_title,
              description: l10n.chat_meetings_waiting_room_desc,
            ),
            const SizedBox(height: 12),
            _infoCard(
              context,
              icon: Icons.image_rounded,
              iconBg: const Color(0xFF6D28D9),
              iconTint: const Color(0xFFC4B5FD),
              title: l10n.chat_meetings_backgrounds_title,
              description: l10n.chat_meetings_backgrounds_desc,
            ),
            const SizedBox(height: 16),
            _createButton(context),
            const SizedBox(height: 24),
            _historyHeader(context),
            const SizedBox(height: 10),
            _historySection(context, uid),
          ],
        ),
      ),
    );
  }

  Widget _historySection(BuildContext context, String uid) {
    final meetingsAsync = ref.watch(meetingHistoryProvider(uid));
    return meetingsAsync.when(
      skipLoadingOnReload: true,
      loading: () => _historyLoadingCard(context),
      error: (e, _) => _historyErrorCard(context, e),
      data: (list) {
        if (list.isEmpty) return _historyEmptyCard(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final m in list) ...[
              _MeetingHistoryRow(
                meeting: m,
                onTap: () => context.push('/meetings/${m.id}'),
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }

  Widget _historyLoadingCard(BuildContext context) {
    return _glass(
      context,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _historyErrorCard(BuildContext context, Object err) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return _glass(
      context,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          l10n.chat_meetings_history_error(err.toString()),
          style: TextStyle(color: scheme.error, fontSize: 13),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
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
              l10n.chat_meetings_title,
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
            l10n.chat_meetings_subtitle,
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
    final l10n = AppLocalizations.of(context)!;
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
            _fieldLabel(context, l10n.chat_meetings_field_title_label),
            const SizedBox(height: 6),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: fg, fontSize: 15),
              cursorColor: scheme.primary,
              decoration: _fieldDecoration(
                context,
                hint: l10n.chat_meetings_field_title_hint,
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
                      _fieldLabel(context, l10n.chat_meetings_field_duration_label),
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
                      _fieldLabel(context, l10n.chat_meetings_field_access_label),
                      const SizedBox(height: 6),
                      _accessToggle(context, fieldFill, fieldBorder),
                    ],
                  ),
                ),
              ],
            ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.65)),
      ),
    );
  }

  Widget _durationDropdown(BuildContext context, Color fill, Color border) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
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
            l10n.chat_meetings_duration_unlimited,
            style: TextStyle(
              color: fg.withValues(alpha: 0.36),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          items: _MeetingDuration.values
              .map((d) {
                return DropdownMenuItem<_MeetingDuration>(
                  value: d,
                  child: Text(d.label(l10n)),
                );
              })
              .toList(growable: false),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _duration = v);
          },
        ),
      ),
    );
  }

  Widget _accessToggle(BuildContext context, Color fill, Color border) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
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
                _isPrivate
                    ? l10n.chat_meetings_access_private
                    : l10n.chat_meetings_access_public,
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
    final l10n = AppLocalizations.of(context)!;
    final enabled = _title.text.trim().isNotEmpty && !_creating;
    return SizedBox(
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _creating
              ? null
              : (enabled ? _onCreateMeeting : _hintTitleRequired),
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
              children: _creating
                  ? const [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ]
                  : [
                      const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.chat_meetings_create_button,
                        style: const TextStyle(
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
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.chat_meetings_snackbar_enter_title)));
  }

  Future<void> _onCreateMeeting() async {
    if (_creating) return;
    final l10n = AppLocalizations.of(context)!;
    final user = ref.read(authUserProvider).asData?.value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chat_meetings_snackbar_auth_required)),
      );
      return;
    }
    final name = _title.text.trim();
    if (name.isEmpty) {
      _hintTitleRequired();
      return;
    }
    setState(() => _creating = true);
    try {
      final repo = ref.read(meetingRepositoryProvider);
      final meetingId = await repo.createMeeting(
        hostId: user.uid,
        name: name,
        isPrivate: _isPrivate,
        duration: _duration.asDuration(),
      );
      if (!mounted) return;
      context.push('/meetings/$meetingId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(l10n.chat_meetings_error_create_failed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Widget _historyHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
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
          l10n.chat_meetings_history_title,
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
    final l10n = AppLocalizations.of(context)!;
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
              l10n.chat_meetings_history_empty,
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

/// Карточка в истории встреч. Web показывает похожие карточки на
/// `/dashboard/meetings`, но здесь используем компактный list-вариант.
class _MeetingHistoryRow extends StatelessWidget {
  const _MeetingHistoryRow({required this.meeting, required this.onTap});

  final MeetingDoc meeting;
  final VoidCallback onTap;

  String _subtitle(AppLocalizations l10n) {
    final d = meeting.createdAt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final date = '${two(d.day)}.${two(d.month)}.${d.year}';
    final time = '${two(d.hour)}:${two(d.minute)}';
    final parts = <String>[
      date,
      time,
      if (meeting.status == 'active')
        l10n.chat_meetings_status_live
      else if (meeting.status == 'ended')
        l10n.chat_meetings_status_finished,
      if (meeting.isPrivate) l10n.chat_meetings_badge_private,
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final dark = scheme.brightness == Brightness.dark;
    final fg = dark ? Colors.white : scheme.onSurface;
    final active = meeting.status == 'active';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: fg.withValues(alpha: dark ? 0.04 : 0.04),
            border: Border.all(color: fg.withValues(alpha: dark ? 0.08 : 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color:
                      (active
                              ? const Color(0xFF10B981)
                              : const Color(0xFF3B82F6))
                          .withValues(alpha: 0.20),
                ),
                child: Icon(
                  active ? Icons.sensors_rounded : Icons.videocam_rounded,
                  size: 22,
                  color: active
                      ? const Color(0xFF10B981)
                      : const Color(0xFF60A5FA),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meeting.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: fg.withValues(alpha: 0.96),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(l10n),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: fg.withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: fg.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _MeetingDuration { none, m15, m30, m60, m90 }

extension _MeetingDurationLabel on _MeetingDuration {
  String label(AppLocalizations l10n) {
    switch (this) {
      case _MeetingDuration.none:
        return l10n.chat_meetings_duration_unlimited;
      case _MeetingDuration.m15:
        return l10n.chat_meetings_duration_15m;
      case _MeetingDuration.m30:
        return l10n.chat_meetings_duration_30m;
      case _MeetingDuration.m60:
        return l10n.chat_meetings_duration_1h;
      case _MeetingDuration.m90:
        return l10n.chat_meetings_duration_90m;
    }
  }

  Duration? asDuration() {
    switch (this) {
      case _MeetingDuration.none:
        return null;
      case _MeetingDuration.m15:
        return const Duration(minutes: 15);
      case _MeetingDuration.m30:
        return const Duration(minutes: 30);
      case _MeetingDuration.m60:
        return const Duration(hours: 1);
      case _MeetingDuration.m90:
        return const Duration(minutes: 90);
    }
  }
}
