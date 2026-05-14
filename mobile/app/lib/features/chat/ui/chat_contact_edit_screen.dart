import 'dart:async' show unawaited;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../data/contact_display_name.dart';
import '../data/user_profile.dart';
import 'chat_avatar.dart';

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
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.contact_edit_name_required)));
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
        SnackBar(content: Text(AppLocalizations.of(context)!.contact_edit_save_error(e.toString()))),
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
                  fallbackName: fallback.isNotEmpty ? fallback : AppLocalizations.of(context)!.contact_edit_user_fallback,
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
                            child: Text(AppLocalizations.of(context)!.common_cancel),
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
                                : Text(AppLocalizations.of(context)!.common_done),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                        children: [
                          Center(
                            child: ChatAvatar(
                              title: displayName,
                              radius: 42,
                              avatarUrl:
                                  profile?.avatarThumb ?? profile?.avatar,
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
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)!.contact_edit_first_name_hint,
                                    contentPadding: const EdgeInsets.symmetric(
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
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)!.contact_edit_last_name_hint,
                                    contentPadding: const EdgeInsets.symmetric(
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
                          Text(
                            AppLocalizations.of(context)!.contact_edit_description,
                            style: const TextStyle(
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
              AppLocalizations.of(context)!.contact_edit_error(e.toString()),
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}
