import 'dart:async' show unawaited;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../data/contact_display_name.dart';
import '../data/user_profile.dart';

class ChatContactEditScreen extends ConsumerStatefulWidget {
  const ChatContactEditScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<ChatContactEditScreen> createState() =>
      _ChatContactEditScreenState();
}

class _ChatContactEditScreenState extends ConsumerState<ChatContactEditScreen> {
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  bool _seeded = false;
  bool _saving = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  Future<void> _save({required String ownerId}) async {
    if (_saving) return;
    final first = _firstName.text.trim();
    final last = _lastName.text.trim();
    if (first.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите имя контакта.')));
      return;
    }
    final repo = ref.read(userContactsRepositoryProvider);
    if (repo == null) return;
    setState(() => _saving = true);
    try {
      await repo.upsertContactProfile(
        ownerId: ownerId,
        contactUserId: widget.userId,
        firstName: first,
        lastName: last,
      );
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/contacts/user/${Uri.encodeComponent(widget.userId)}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось сохранить контакт: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authUserProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF05070C),
      body: SafeArea(
        child: authAsync.when(
          data: (authUser) {
            if (authUser == null) return const SizedBox.shrink();
            final ownerId = authUser.uid;
            final contactsAsync = ref.watch(userContactsIndexProvider(ownerId));
            final profilesRepo = ref.watch(userProfilesRepositoryProvider);
            final profileStream = profilesRepo?.watchUsersByIds([
              widget.userId,
            ]);
            return StreamBuilder<Map<String, UserProfile>>(
              stream: profileStream,
              builder: (context, snap) {
                final profile = snap.data?[widget.userId];
                final contactProfiles =
                    contactsAsync.value?.contactProfiles ?? const {};
                final local = contactProfiles[widget.userId];
                final fallback = (profile?.name ?? '').trim();
                if (!_seeded && (local != null || fallback.isNotEmpty)) {
                  final localFirst = (local?.firstName ?? '').trim();
                  final localLast = (local?.lastName ?? '').trim();
                  if (localFirst.isNotEmpty || localLast.isNotEmpty) {
                    _firstName.text = localFirst;
                    _lastName.text = localLast;
                  } else {
                    final split = splitNameForContactForm(
                      (local?.displayName ?? '').trim().isNotEmpty
                          ? (local?.displayName ?? '').trim()
                          : fallback,
                    );
                    _firstName.text = split.firstName;
                    _lastName.text = split.lastName;
                  }
                  _seeded = true;
                }

                final displayName = resolveContactDisplayName(
                  contactProfiles: contactProfiles,
                  contactUserId: widget.userId,
                  fallbackName: fallback.isNotEmpty ? fallback : 'Пользователь',
                );

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: _saving
                                ? null
                                : () {
                                    if (context.canPop()) {
                                      context.pop();
                                    } else {
                                      context.go(
                                        '/contacts/user/${Uri.encodeComponent(widget.userId)}',
                                      );
                                    }
                                  },
                            child: const Text('Отмена'),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _saving
                                ? null
                                : () => unawaited(_save(ownerId: ownerId)),
                            child: _saving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Готово'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                        children: [
                          Center(
                            child: CircleAvatar(
                              radius: 42,
                              foregroundImage:
                                  (profile?.avatarThumb ?? profile?.avatar) ==
                                      null
                                  ? null
                                  : NetworkImage(
                                      (profile?.avatarThumb ??
                                          profile?.avatar)!,
                                    ),
                              child: Text(
                                displayName.isNotEmpty
                                    ? displayName.substring(0, 1)
                                    : '?',
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _firstName,
                                  enabled: !_saving,
                                  textCapitalization: TextCapitalization.sentences,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Имя',
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 14,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                                TextField(
                                  controller: _lastName,
                                  enabled: !_saving,
                                  textCapitalization: TextCapitalization.sentences,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Фамилия',
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 14,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Это имя видно только вам: в чатах, поиске и списке контактов.',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => Center(
            child: Text(
              'Ошибка: $e',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}
