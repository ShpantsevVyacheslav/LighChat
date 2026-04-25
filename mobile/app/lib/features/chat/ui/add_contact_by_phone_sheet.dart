import 'dart:async' show unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  static Future<String?> show(
    BuildContext context, {
    required String ownerId,
    required UserProfile viewer,
    required UserContactsRepository contactsRepo,
    required Future<void> Function() onSyncDeviceContacts,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
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

class _AddContactByPhoneSheetState
    extends ConsumerState<AddContactByPhoneSheet> {
  final TextEditingController _nationalPhone = TextEditingController();
  final TextEditingController _countrySearch = TextEditingController();
  bool _busy = false;
  String? _error;
  List<String> _matchedIds = const <String>[];
  bool _checkedConsent = false;
  bool _hasDeviceConsent = false;
  late _PhoneCountry _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = _detectDefaultCountry();
    unawaited(_loadConsentOnce());
  }

  @override
  void dispose() {
    _nationalPhone.dispose();
    _countrySearch.dispose();
    super.dispose();
  }

  _PhoneCountry _detectDefaultCountry() {
    final byPhone = _detectByPhone(widget.viewer.phone);
    if (byPhone != null) return byPhone;

    final localeCode = WidgetsBinding
        .instance
        .platformDispatcher
        .locale
        .countryCode
        ?.trim()
        .toUpperCase();
    if (localeCode != null && localeCode.isNotEmpty) {
      final byLocale = _phoneCountries.firstWhere(
        (c) => c.isoCode == localeCode,
        orElse: () => _phoneCountries.first,
      );
      return byLocale;
    }
    return _phoneCountries.first;
  }

  _PhoneCountry? _detectByPhone(String? phone) {
    final raw = (phone ?? '').trim();
    if (raw.isEmpty) return null;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    final sorted = [..._phoneCountries]
      ..sort((a, b) => b.dialDigits.length.compareTo(a.dialDigits.length));
    for (final c in sorted) {
      if (digits.startsWith(c.dialDigits)) return c;
    }
    return null;
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

  String _extractNationalPhoneDigits(String input) {
    final digitsOnly = input.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) return '';
    if (digitsOnly.length > _selectedCountry.maxNationalDigits) {
      return digitsOnly.substring(
        digitsOnly.length - _selectedCountry.maxNationalDigits,
      );
    }
    return digitsOnly;
  }

  String _buildE164Phone() {
    final national = _extractNationalPhoneDigits(_nationalPhone.text);
    return '${_selectedCountry.dialCode}$national';
  }

  Future<void> _search() async {
    if (_busy) return;
    final key = registrationPhoneKey(_buildE164Phone());
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
      final ids = await widget.contactsRepo
          .resolveUserIdsByRegistrationLookupKeys([key]);
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

  Future<void> _selectContact(UserProfile peer) async {
    if (_busy) return;
    if (!canStartDirectChat(widget.viewer, peer)) {
      setState(() => _error = 'Нельзя добавить этого пользователя');
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(peer.id);
  }

  Future<void> _pickPhoneCountry() async {
    final selected = await showModalBottomSheet<_PhoneCountry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF050611),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        _countrySearch.text = '';
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                final query = _countrySearch.text.trim().toLowerCase();
                final items = query.isEmpty
                    ? _phoneCountries
                    : _phoneCountries
                          .where((c) {
                            final q = query;
                            return c.name.toLowerCase().contains(q) ||
                                c.dialCode.contains(q) ||
                                c.isoCode.toLowerCase().contains(q);
                          })
                          .toList(growable: false);

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _countrySearch,
                        onChanged: (_) => setModalState(() {}),
                        style: const TextStyle(fontSize: 18),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search, size: 24),
                          hintText: 'Поиск страны или кода',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final country = items[index];
                            final selected = country == _selectedCountry;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              minLeadingWidth: 34,
                              leading: Text(
                                country.flag,
                                style: const TextStyle(fontSize: 22),
                              ),
                              title: Text(
                                country.name,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  country.dialCode,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withValues(alpha: 0.72),
                                  ),
                                ),
                              ),
                              trailing: selected
                                  ? const Icon(
                                      Icons.check,
                                      color: Color(0xFF2A79FF),
                                      size: 24,
                                    )
                                  : null,
                              onTap: () => Navigator.of(context).pop(country),
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

    if (selected == null || !mounted) return;
    setState(() {
      _selectedCountry = selected;
      final nationalDigits = _extractNationalPhoneDigits(_nationalPhone.text);
      _nationalPhone.text = _PhoneMaskFormatter.formatDigits(
        nationalDigits,
        phoneHint: _selectedCountry.phoneHint,
      );
      _nationalPhone.selection = TextSelection.collapsed(
        offset: _nationalPhone.text.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fg = Colors.white.withValues(alpha: 0.94);
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;

    final profilesRepo = ref.watch(userProfilesRepositoryProvider);
    final profilesAsync = profilesRepo == null || _matchedIds.isEmpty
        ? const AsyncValue<Map<String, UserProfile>>.data(
            <String, UserProfile>{},
          )
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
                const SizedBox(height: 4),
                Text(
                  'По номеру телефона',
                  style: TextStyle(
                    color: fg.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _busy
                          ? null
                          : () => unawaited(_pickPhoneCountry()),
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: dark ? 0.08 : 0.10,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedCountry.flag,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _selectedCountry.dialCode,
                              style: TextStyle(
                                color: fg,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.expand_more_rounded,
                              color: fg.withValues(alpha: 0.8),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _nationalPhone,
                        enabled: !_busy,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => unawaited(_search()),
                        inputFormatters: <TextInputFormatter>[
                          _PhoneMaskFormatter(
                            phoneHint: _selectedCountry.phoneHint,
                            maxNationalDigits:
                                _selectedCountry.maxNationalDigits,
                          ),
                        ],
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: _selectedCountry.phoneHint,
                          hintStyle: TextStyle(
                            color: fg.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w600,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(
                            alpha: dark ? 0.08 : 0.10,
                          ),
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
                            borderSide: const BorderSide(
                              color: Color(0xFF2A79FF),
                            ),
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
                            : const Icon(
                                Icons.search_rounded,
                                color: Colors.white,
                              ),
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
                      if (profiles.isEmpty) return const SizedBox.shrink();
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
                          final title = p.name.trim().isNotEmpty
                              ? p.name.trim()
                              : 'Пользователь';
                          final subtitle = (p.username ?? '').trim().isEmpty
                              ? null
                              : (p.username!.startsWith('@')
                                    ? p.username!
                                    : '@${p.username!}');
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            onTap: _busy
                                ? null
                                : () => unawaited(_selectContact(p)),
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
                              onPressed: _busy
                                  ? null
                                  : () => unawaited(_selectContact(p)),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2A79FF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Выбрать'),
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
                        onPressed: _busy
                            ? null
                            : () => Navigator.of(context).pop(),
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

class _PhoneCountry {
  const _PhoneCountry({
    required this.isoCode,
    required this.name,
    required this.flag,
    required this.dialCode,
    required this.phoneHint,
    required this.maxNationalDigits,
  });

  final String isoCode;
  final String name;
  final String flag;
  final String dialCode;
  final String phoneHint;
  final int maxNationalDigits;

  String get dialDigits => dialCode.replaceAll(RegExp(r'\D'), '');
}

const List<_PhoneCountry> _phoneCountries = [
  _PhoneCountry(
    isoCode: 'RU',
    name: 'Россия',
    flag: '🇷🇺',
    dialCode: '+7',
    phoneHint: '(999)123-45-67',
    maxNationalDigits: 10,
  ),
  _PhoneCountry(
    isoCode: 'KZ',
    name: 'Казахстан',
    flag: '🇰🇿',
    dialCode: '+7',
    phoneHint: '(777)123-45-67',
    maxNationalDigits: 10,
  ),
  _PhoneCountry(
    isoCode: 'BY',
    name: 'Беларусь',
    flag: '🇧🇾',
    dialCode: '+375',
    phoneHint: '29 123 45 67',
    maxNationalDigits: 9,
  ),
  _PhoneCountry(
    isoCode: 'UA',
    name: 'Украина',
    flag: '🇺🇦',
    dialCode: '+380',
    phoneHint: '50 123 45 67',
    maxNationalDigits: 9,
  ),
  _PhoneCountry(
    isoCode: 'UZ',
    name: 'Узбекистан',
    flag: '🇺🇿',
    dialCode: '+998',
    phoneHint: '90 123 45 67',
    maxNationalDigits: 9,
  ),
  _PhoneCountry(
    isoCode: 'KG',
    name: 'Кыргызстан',
    flag: '🇰🇬',
    dialCode: '+996',
    phoneHint: '555 123 456',
    maxNationalDigits: 9,
  ),
  _PhoneCountry(
    isoCode: 'US',
    name: 'США',
    flag: '🇺🇸',
    dialCode: '+1',
    phoneHint: '(555)123-4567',
    maxNationalDigits: 10,
  ),
  _PhoneCountry(
    isoCode: 'GB',
    name: 'Великобритания',
    flag: '🇬🇧',
    dialCode: '+44',
    phoneHint: '7400 123456',
    maxNationalDigits: 10,
  ),
  _PhoneCountry(
    isoCode: 'DE',
    name: 'Германия',
    flag: '🇩🇪',
    dialCode: '+49',
    phoneHint: '1512 3456789',
    maxNationalDigits: 11,
  ),
  _PhoneCountry(
    isoCode: 'FR',
    name: 'Франция',
    flag: '🇫🇷',
    dialCode: '+33',
    phoneHint: '6 12 34 56 78',
    maxNationalDigits: 9,
  ),
];

class _PhoneMaskFormatter extends TextInputFormatter {
  const _PhoneMaskFormatter({
    required this.phoneHint,
    required this.maxNationalDigits,
  });

  final String phoneHint;
  final int maxNationalDigits;

  static bool _isDigit(String ch) => RegExp(r'\d').hasMatch(ch);

  static String formatDigits(String digits, {required String phoneHint}) {
    if (digits.isEmpty) return '';
    final cleaned = digits.replaceAll(RegExp(r'\D'), '');
    final out = StringBuffer();
    var di = 0;
    for (var i = 0; i < phoneHint.length; i++) {
      final ch = phoneHint[i];
      if (_isDigit(ch)) {
        if (di >= cleaned.length) break;
        out.write(cleaned[di]);
        di++;
      } else {
        if (di == 0) continue;
        out.write(ch);
      }
    }
    if (di < cleaned.length) {
      out.write(cleaned.substring(di));
    }
    return out.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = rawDigits.length > maxNationalDigits
        ? rawDigits.substring(0, maxNationalDigits)
        : rawDigits;
    final nextText = formatDigits(limited, phoneHint: phoneHint);
    return TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
      composing: TextRange.empty,
    );
  }
}
