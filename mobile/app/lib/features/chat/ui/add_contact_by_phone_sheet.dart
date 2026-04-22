import 'dart:async' show unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../data/device_contact_lookup_keys.dart';
import '../data/user_chat_policy.dart';
import '../data/user_contacts_repository.dart';
import '../data/user_profile.dart';
import 'chat_avatar.dart';

class AddContactByPhoneSheet extends ConsumerStatefulWidget {
  const AddContactByPhoneSheet({
    super.key,
    required this.ownerId,
    required this.viewer,
    required this.contactsRepo,
    required this.onSyncDeviceContacts,
  });

  final String ownerId;
  final UserProfile viewer;
  final UserContactsRepository contactsRepo;
  final Future<void> Function() onSyncDeviceContacts;

  static Future<void> show(
    BuildContext context, {
    required String ownerId,
    required UserProfile viewer,
    required UserContactsRepository contactsRepo,
    required Future<void> Function() onSyncDeviceContacts,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      // Клавиатуру учитываем внутри [AddContactByPhoneSheet.build] — здесь
      // [MediaQuery.viewInsets] при первом кадре часто 0 и не «поднимает» форму.
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: AddContactByPhoneSheet(
          ownerId: ownerId,
          viewer: viewer,
          contactsRepo: contactsRepo,
          onSyncDeviceContacts: onSyncDeviceContacts,
        ),
      ),
    );
  }

  @override
  ConsumerState<AddContactByPhoneSheet> createState() =>
      _AddContactByPhoneSheetState();
}

class _AddContactByPhoneSheetState extends ConsumerState<AddContactByPhoneSheet> {
  final TextEditingController _phone = TextEditingController();
  bool _busy = false;
  String? _error;
  List<String> _matchedIds = const <String>[];
  bool _checkedConsent = false;
  bool _hasDeviceConsent = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadConsentOnce());
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _loadConsentOnce() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('userContacts')
          .doc(widget.ownerId)
          .get();
      final raw = snap.data()?['deviceSyncConsentAt'];
      final ok = raw is String && raw.trim().isNotEmpty;
      if (!mounted) return;
      setState(() {
        _checkedConsent = true;
        _hasDeviceConsent = ok;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checkedConsent = true;
        _hasDeviceConsent = false;
      });
    }
  }

  Future<void> _search() async {
    if (_busy) return;
    final key = registrationPhoneKey(_phone.text);
    if (key == null) {
      setState(() {
        _matchedIds = const <String>[];
        _error = 'Введите номер телефона';
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _matchedIds = const <String>[];
    });
    try {
      final ids = await widget.contactsRepo.resolveUserIdsByRegistrationLookupKeys([key]);
      final filtered = ids
          .where((x) => x.isNotEmpty && x != widget.ownerId)
          .toList(growable: false);
      if (!mounted) return;
      setState(() => _matchedIds = filtered);
      if (filtered.isEmpty) {
        setState(() => _error = 'Пользователь не найден');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Не удалось выполнить поиск: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addContact(UserProfile peer) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!canStartDirectChat(widget.viewer, peer)) {
        setState(() => _error = 'Нельзя добавить этого пользователя');
        return;
      }
      await widget.contactsRepo.addContactId(widget.ownerId, peer.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Контакт добавлен')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Не удалось добавить контакт: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = Colors.white.withValues(alpha: 0.94);
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;

    final profilesRepo = ref.watch(userProfilesRepositoryProvider);
    final profilesAsync = profilesRepo == null || _matchedIds.isEmpty
        ? const AsyncValue<Map<String, UserProfile>>.data(<String, UserProfile>{})
        : ref.watch(
            StreamProvider.autoDispose<Map<String, UserProfile>>((ref) {
              return profilesRepo.watchUsersByIds(_matchedIds);
            }),
          );

    return AnimatedPadding(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardBottom + 12),
      child: Material(
        color: Colors.black.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Добавить контакт',
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _phone,
                        enabled: !_busy,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => unawaited(_search()),
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Номер телефона',
                          hintStyle: TextStyle(
                            color: fg.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w600,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: dark ? 0.08 : 0.10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF2A79FF)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 44,
                      width: 44,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: const Color(0xFF2A79FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _busy ? null : () => unawaited(_search()),
                        child: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search_rounded, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Colors.redAccent.shade100,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (_checkedConsent && !_hasDeviceConsent) ...[
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () async {
                            await widget.onSyncDeviceContacts();
                            if (!mounted) return;
                            setState(() => _hasDeviceConsent = true);
                          },
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text('Синхронизировать контакты'),
                  ),
                  const SizedBox(height: 10),
                ],
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: profilesAsync.when(
                    data: (map) {
                      final profiles = _matchedIds
                          .map((id) => map[id])
                          .whereType<UserProfile>()
                          .where((p) => (p.deletedAt ?? '').trim().isEmpty)
                          .toList(growable: false);
                      if (profiles.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        itemCount: profiles.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                        itemBuilder: (context, i) {
                          final p = profiles[i];
                          final title = p.name.trim().isNotEmpty ? p.name.trim() : 'Пользователь';
                          final subtitle = (p.username ?? '').trim().isEmpty
                              ? null
                              : (p.username!.startsWith('@') ? p.username! : '@${p.username!}');
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ChatAvatar(
                              title: title,
                              radius: 22,
                              avatarUrl: p.avatarThumb ?? p.avatar,
                            ),
                            title: Text(
                              title,
                              style: TextStyle(
                                color: fg,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: subtitle == null
                                ? null
                                : Text(
                                    subtitle,
                                    style: TextStyle(
                                      color: fg.withValues(alpha: 0.65),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                            trailing: FilledButton(
                              onPressed: _busy ? null : () => unawaited(_addContact(p)),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2A79FF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Добавить'),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => Text(
                      'Ошибка: $e',
                      style: TextStyle(
                        color: Colors.redAccent.shade100,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy ? null : () => Navigator.of(context).pop(),
                        child: const Text('Закрыть'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

