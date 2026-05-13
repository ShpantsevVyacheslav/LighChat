import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lighchat_mobile/app_providers.dart';
import 'package:lighchat_mobile/brand_colors.dart';
import 'package:lighchat_mobile/features/birthdays/data/birthday_greeting_templates.dart';
import 'package:lighchat_mobile/features/birthdays/data/birthday_message_sender.dart';
import 'package:lighchat_mobile/features/birthdays/data/birthday_reminder_scheduler.dart';
import 'package:lighchat_mobile/features/birthdays/data/contact_birthday.dart';
import 'package:lighchat_mobile/features/birthdays/data/contact_birthdays_provider.dart';
import 'package:lighchat_mobile/features/birthdays/data/birthday_date_utils.dart';
import 'package:lighchat_mobile/features/birthdays/ui/widgets/birthday_cake_sheet.dart';
import 'package:lighchat_mobile/features/birthdays/ui/widgets/confetti_overlay.dart';
import 'package:lighchat_mobile/features/chat/data/user_profile.dart';
import 'package:lighchat_mobile/features/chat/ui/chat_avatar.dart';
import 'package:lighchat_mobile/l10n/app_localizations.dart';

class BirthdayCelebrationScreen extends ConsumerStatefulWidget {
  const BirthdayCelebrationScreen({super.key});

  @override
  ConsumerState<BirthdayCelebrationScreen> createState() =>
      _BirthdayCelebrationScreenState();
}

class _BirthdayCelebrationScreenState
    extends ConsumerState<BirthdayCelebrationScreen> {
  int _index = 0;
  bool _templatesExpanded = false;
  bool _busy = false;

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<UserProfile?> _ensureSelf() async {
    final user = ref.read(authUserProvider).value;
    if (user == null) return null;
    final repo = ref.read(userProfilesRepositoryProvider);
    if (repo == null) return null;
    final map = await repo.getUsersByIdsOnce(<String>[user.uid]);
    return map[user.uid];
  }

  Future<void> _sendText(ContactBirthday b, String text) async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final me = await _ensureSelf();
      if (!mounted) return;
      if (me == null) {
        _showSnack(l10n.birthday_error_self);
        return;
      }
      final sender = ref.read(birthdayMessageSenderProvider);
      final res = await sender.sendText(
        currentUserId: me.id,
        self: me,
        contactUserId: b.userId,
        contactProfile: b.profile,
        contactDisplayName: b.displayName,
        text: text,
      );
      if (!mounted) return;
      if (res.conversationId == null) {
        _showSnack(l10n.birthday_error_send);
        return;
      }
      if (res.needsManualSend) {
        // E2EE-чат / иной отказ rule — текст сохранён как draft, открываем
        // чат, чтобы юзер дотап-отправил его через основной композер.
        HapticFeedback.lightImpact();
        context.push('/chats/${res.conversationId}');
        return;
      }
      HapticFeedback.lightImpact();
      _showSnack(l10n.birthday_toast_sent);
    } catch (_) {
      if (!mounted) return;
      _showSnack(l10n.birthday_error_send);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onCake(ContactBirthday b) async {
    final l10n = AppLocalizations.of(context)!;
    final wish = await BirthdayCakeSheet.show(
      context,
      contactName: b.displayName,
    );
    if (wish == null || !mounted) return;
    final composed = l10n.birthday_cake_message(b.displayName, wish);
    await _sendText(b, composed);
  }

  Future<void> _onConfetti(ContactBirthday b) async {
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.mediumImpact();
    await _sendText(b, l10n.birthday_confetti_message(b.displayName));
  }

  Future<void> _onSerpentine(ContactBirthday b) async {
    HapticFeedback.lightImpact();
    await _sendText(b, '🎁🎉🎊🎈');
  }

  Future<void> _onAudio(ContactBirthday b) async {
    final l10n = AppLocalizations.of(context)!;
    final me = await _ensureSelf();
    if (!mounted) return;
    if (me == null) {
      _showSnack(l10n.birthday_error_self);
      return;
    }
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
    try {
      final convId = await repo.createOrOpenDirectChat(
        currentUserId: me.id,
        otherUserId: b.userId,
        currentUserInfo: (
          name: me.name,
          avatar: me.avatar,
          avatarThumb: me.avatarThumb,
        ),
        otherUserInfo: (
          name: b.profile?.name ?? b.displayName,
          avatar: b.profile?.avatar,
          avatarThumb: b.profile?.avatarThumb,
        ),
      );
      if (!mounted) return;
      context.push('/chats/$convId?startVoiceRecord=1');
    } catch (_) {
      if (!mounted) return;
      _showSnack(l10n.birthday_error_send);
    }
  }

  Future<void> _onRemindNextYear(ContactBirthday b) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await BirthdayReminderScheduler.scheduleDayBefore(
      contactUserId: b.userId,
      birthDate: b.birthDate,
      title: l10n.birthday_reminder_notif_title,
      body: l10n.birthday_reminder_notif_body(b.displayName),
    );
    if (!mounted) return;
    _showSnack(ok
        ? l10n.birthday_reminder_set(b.displayName)
        : l10n.birthday_error_reminder);
  }

  Future<void> _onOpenChat(ContactBirthday b) async {
    final l10n = AppLocalizations.of(context)!;
    final me = await _ensureSelf();
    if (!mounted) return;
    if (me == null) {
      _showSnack(l10n.birthday_error_self);
      return;
    }
    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) return;
    try {
      final convId = await repo.createOrOpenDirectChat(
        currentUserId: me.id,
        otherUserId: b.userId,
        currentUserInfo: (
          name: me.name,
          avatar: me.avatar,
          avatarThumb: me.avatarThumb,
        ),
        otherUserInfo: (
          name: b.profile?.name ?? b.displayName,
          avatar: b.profile?.avatar,
          avatarThumb: b.profile?.avatarThumb,
        ),
      );
      if (!mounted) return;
      context.push('/chats/$convId');
    } catch (_) {
      if (!mounted) return;
      _showSnack(l10n.birthday_error_send);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final authAsync = ref.watch(authUserProvider);
    final user = authAsync.value;

    final birthdays = user == null
        ? const <ContactBirthday>[]
        : ref.watch(todayBirthdaysProvider(user.uid));

    if (birthdays.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.birthday_screen_title_today)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.birthday_empty,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      );
    }

    final safeIndex = _index.clamp(0, birthdays.length - 1);
    final current = birthdays[safeIndex];
    final age = ageInYear(current.birthDate, DateTime.now());

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: ConfettiOverlay(
              particleCount: 18,
              intensity: 0.7,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Hero(
                      tag: 'birthday-avatar-${current.userId}',
                      child: SizedBox(
                        width: 132,
                        height: 132,
                        child: ChatAvatar(
                          title: current.displayName,
                          radius: 66,
                          avatarUrl:
                              current.avatarUrl ?? current.avatarThumb,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _AnimatedTitle(name: current.displayName),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      age != null
                          ? '${l10n.birthday_screen_title_today} · ${l10n.birthday_screen_age(age)}'
                          : l10n.birthday_screen_title_today,
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (birthdays.length > 1) ...[
                    const SizedBox(height: 14),
                    _Pager(
                      total: birthdays.length,
                      index: safeIndex,
                      onChanged: (i) => setState(() => _index = i),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _SectionDivider(label: l10n.birthday_section_actions),
                  const SizedBox(height: 14),
                  _StaggerIn(
                    delay: const Duration(milliseconds: 60),
                    child: _TemplateCard(
                      contact: current,
                      expanded: _templatesExpanded,
                      onToggle: () => setState(
                          () => _templatesExpanded = !_templatesExpanded),
                      onSend: (t) => _sendText(current, t),
                      busy: _busy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _StaggerIn(
                    delay: const Duration(milliseconds: 120),
                    child: Row(
                      children: [
                        Expanded(
                          child: _IconActionCard(
                            emoji: '🎂',
                            label: l10n.birthday_action_cake,
                            onTap:
                                _busy ? null : () => _onCake(current),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _IconActionCard(
                            emoji: '🎊',
                            label: l10n.birthday_action_confetti,
                            onTap:
                                _busy ? null : () => _onConfetti(current),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _IconActionCard(
                            emoji: '🎁',
                            label: l10n.birthday_action_serpentine,
                            onTap:
                                _busy ? null : () => _onSerpentine(current),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _StaggerIn(
                    delay: const Duration(milliseconds: 180),
                    child: _RowActionCard(
                      icon: Icons.mic_rounded,
                      label: l10n.birthday_action_voice,
                      onTap: _busy ? null : () => _onAudio(current),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _StaggerIn(
                    delay: const Duration(milliseconds: 240),
                    child: _RowActionCard(
                      icon: Icons.notifications_active_rounded,
                      label: l10n.birthday_action_remind_next_year,
                      onTap: _busy
                          ? null
                          : () => _onRemindNextYear(current),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _StaggerIn(
                    delay: const Duration(milliseconds: 300),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: kBrandOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: _busy ? null : () => _onOpenChat(current),
                        icon: const Icon(Icons.edit_rounded),
                        label: Text(l10n.birthday_action_open_chat),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedTitle extends StatefulWidget {
  const _AnimatedTitle({required this.name});

  final String name;

  @override
  State<_AnimatedTitle> createState() => _AnimatedTitleState();
}

class _AnimatedTitleState extends State<_AnimatedTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.rotate(
              angle: (t - 0.5) * 0.18,
              child: const Text('🎂', style: TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Transform.rotate(
              angle: -(t - 0.5) * 0.18,
              child: const Text('🎂', style: TextStyle(fontSize: 26)),
            ),
          ],
        );
      },
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({
    required this.total,
    required this.index,
    required this.onChanged,
  });

  final int total;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: index == 0 ? null : () => onChanged(index - 1),
        ),
        for (var i = 0; i < total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 14 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index
                  ? kBrandOrange
                  : scheme.onSurface.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed:
              index == total - 1 ? null : () => onChanged(index + 1),
        ),
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: scheme.onSurface.withValues(alpha: 0.12),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.6),
              letterSpacing: 0.4,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: scheme.onSurface.withValues(alpha: 0.12),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.contact,
    required this.expanded,
    required this.onToggle,
    required this.onSend,
    required this.busy,
  });

  final ContactBirthday contact;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<String> onSend;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final templates = birthdayGreetingTemplates(l10n, contact.displayName);

    return _CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: kBrandOrange.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('💬',
                        style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.birthday_action_template,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          templates.first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                scheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: expanded
                ? Column(
                    children: [
                      Divider(
                        color: scheme.onSurface.withValues(alpha: 0.08),
                        height: 1,
                      ),
                      for (final t in templates)
                        InkWell(
                          onTap: busy ? null : () => onSend(t),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    t,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.92),
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.send_rounded,
                                    size: 18,
                                    color: kBrandOrange
                                        .withValues(alpha: 0.9)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _IconActionCard extends StatelessWidget {
  const _IconActionCard({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _CardBox(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowActionCard extends StatelessWidget {
  const _RowActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _CardBox(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kBrandOrange.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: kBrandOrange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: scheme.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardBox extends StatelessWidget {
  const _CardBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: child,
      ),
    );
  }
}

class _StaggerIn extends StatelessWidget {
  const _StaggerIn({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: Future.delayed(delay, () => true),
      builder: (context, snap) {
        final ready = snap.data == true;
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          opacity: ready ? 1 : 0,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            offset: ready ? Offset.zero : const Offset(0, 0.06),
            child: child,
          ),
        );
      },
    );
  }
}
