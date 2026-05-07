import 'dart:async' show unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as flutter_contacts;
import 'package:permission_handler/permission_handler.dart'
    show openAppSettings;

import 'package:lighchat_mobile/app_providers.dart';

import '../../../l10n/app_localizations.dart';
import '../../auth/data/phone_country_names.dart';
import '../data/add_contact_profile_providers.dart';
import '../data/device_contact_lookup_keys.dart';
import '../data/profile_qr_link.dart';
import '../data/new_chat_user_search.dart' show ruEnSubstringMatch;
import '../data/user_chat_policy.dart';
import '../data/user_contacts_repository.dart';
import '../data/user_profile.dart';
import 'add_contact_phone_mask_formatter.dart';
import 'chat_avatar.dart';
import '../../shared/ui/platform_keyboard_dismiss_behavior.dart';

class AddContactByPhoneSheet extends ConsumerStatefulWidget {
  const AddContactByPhoneSheet({
    super.key,
    required this.ownerId,
    required this.viewer,
    required this.contactsRepo,
    required this.existingContactIds,
    required this.onSyncDeviceContacts,
  });

  final String ownerId;
  final UserProfile viewer;
  final UserContactsRepository contactsRepo;
  final Set<String> existingContactIds;
  final Future<bool> Function() onSyncDeviceContacts;

  static Future<String?> show(
    BuildContext context, {
    required String ownerId,
    required UserProfile viewer,
    required UserContactsRepository contactsRepo,
    required Set<String> existingContactIds,
    required Future<bool> Function() onSyncDeviceContacts,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AddContactByPhoneSheet(
        ownerId: ownerId,
        viewer: viewer,
        contactsRepo: contactsRepo,
        existingContactIds: existingContactIds,
        onSyncDeviceContacts: onSyncDeviceContacts,
      ),
    );
  }

  @override
  ConsumerState<AddContactByPhoneSheet> createState() =>
      _AddContactByPhoneSheetState();
}

class _AddContactByPhoneSheetState extends ConsumerState<AddContactByPhoneSheet>
    with WidgetsBindingObserver {
  final TextEditingController _nationalPhone = TextEditingController();
  final TextEditingController _countrySearch = TextEditingController();
  bool _busy = false;
  bool _syncBusy = false;
  bool _errorIsSoft = false;
  String? _error;
  String? _info;
  bool _checkedConsent = false;
  bool _hasDeviceConsent = false;

  /// Разрешение ОС на чтение контактов (permission_handler), не путать с согласием в Firestore.
  bool _contactsOsGranted = false;
  bool _isApplyingPhoneMask = false;
  List<String> _matchedIds = const <String>[];
  late _PhoneCountry _selectedCountry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedCountry = _detectDefaultCountry();
    unawaited(_loadConsentOnce());
    unawaited(_refreshOsContactsPermission());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nationalPhone.dispose();
    _countrySearch.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshOsContactsPermission());
    }
  }

  Future<void> _refreshOsContactsPermission() async {
    final st = await flutter_contacts.FlutterContacts.permissions.request(
      flutter_contacts.PermissionType.read,
    );
    if (!mounted) return;
    setState(() {
      _contactsOsGranted =
          st == flutter_contacts.PermissionStatus.granted ||
          st == flutter_contacts.PermissionStatus.limited;
    });
  }

  /// Тумблер отражает «синхронизация включена» (основной UX), но при этом
  /// учитывает реальное разрешение ОС.
  bool get _syncSwitchOn => _hasDeviceConsent && _contactsOsGranted;

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
      await _refreshOsContactsPermission();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checkedConsent = true;
        _hasDeviceConsent = false;
      });
      await _refreshOsContactsPermission();
    }
  }

  void _setError(String message, {bool soft = false}) {
    setState(() {
      _error = message;
      _errorIsSoft = soft;
      _info = null;
    });
  }

  void _setInfo(String message) {
    setState(() {
      _info = message;
      _error = null;
      _errorIsSoft = false;
    });
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

  void _clearResultsKeepMessage() {
    setState(() {
      _matchedIds = const <String>[];
      _info = null;
      _error = null;
      _errorIsSoft = false;
    });
  }

  void _handlePhoneChanged(String value) {
    if (_isApplyingPhoneMask) return;
    _clearResultsKeepMessage();

    final looksLikeInternational = value.contains('+');
    if (!looksLikeInternational) return;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;

    final sorted = [..._phoneCountries]
      ..sort((a, b) => b.dialDigits.length.compareTo(a.dialDigits.length));
    final matched = sorted.where((c) => digits.startsWith(c.dialDigits));
    if (matched.isEmpty) return;
    final country = matched.first;
    final nationalDigits = digits.substring(country.dialDigits.length);
    final masked = AddContactNationalPhoneMaskFormatter.formatDigits(
      nationalDigits,
      phoneHint: country.phoneHint,
    );
    setState(() {
      _selectedCountry = country;
      _isApplyingPhoneMask = true;
      _nationalPhone.text = masked;
      _nationalPhone.selection = TextSelection.collapsed(offset: masked.length);
      _isApplyingPhoneMask = false;
    });
  }

  Future<void> _toggleSyncWithPhone(bool next) async {
    if (_syncBusy || _busy) return;
    if (!next) {
      setState(() => _hasDeviceConsent = false);
      try {
        await widget.contactsRepo.saveDeviceContactsConsent(
          ownerId: widget.ownerId,
          granted: false,
        );
      } catch (_) {
        // Ignore network issues here: local toggle state is still explicit.
      }
      if (mounted) {
        _setInfo(AppLocalizations.of(context)!.add_contact_sync_off);
      }
      await _refreshOsContactsPermission();
      return;
    }

    final st = await flutter_contacts.FlutterContacts.permissions.request(
      flutter_contacts.PermissionType.read,
    );
    if (!mounted) return;
    if (st != flutter_contacts.PermissionStatus.granted &&
        st != flutter_contacts.PermissionStatus.limited) {
      await openAppSettings();
      _setError(
        AppLocalizations.of(context)!.add_contact_enable_system_access,
        soft: true,
      );
      await _refreshOsContactsPermission();
      return;
    }
    await _refreshOsContactsPermission();

    if (_hasDeviceConsent && _contactsOsGranted) {
      return;
    }

    setState(() => _syncBusy = true);
    var ok = false;
    try {
      ok = await widget.onSyncDeviceContacts();
    } finally {
      if (mounted) {
        setState(() {
          _syncBusy = false;
          _hasDeviceConsent = ok;
        });
        await _refreshOsContactsPermission();
        if (ok) {
          _setInfo(AppLocalizations.of(context)!.add_contact_sync_on);
        } else {
          _setError(
            AppLocalizations.of(context)!.add_contact_sync_failed,
            soft: true,
          );
        }
      }
    }
  }

  Future<void> _searchByPhone() async {
    if (_busy) return;
    final key = registrationPhoneKey(_buildE164Phone());
    if (key == null) {
      _setError(AppLocalizations.of(context)!.add_contact_invalid_phone);
      return;
    }
    setState(() {
      _busy = true;
      _matchedIds = const <String>[];
      _error = null;
      _errorIsSoft = false;
      _info = null;
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
        _setError(
          AppLocalizations.of(context)!.add_contact_not_found_by_phone,
          soft: true,
        );
      } else {
        _setInfo(AppLocalizations.of(context)!.add_contact_found);
      }
    } catch (e) {
      if (!mounted) return;
      _setError(
        AppLocalizations.of(context)!.add_contact_search_error(e.toString()),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _searchByQrPayload(String payload) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final target = extractProfileTargetFromQrPayload(payload);
    final userId = target.userId?.trim() ?? '';
    final username = target.username?.trim() ?? '';
    if (userId.isEmpty && username.isEmpty) {
      _setError(l10n.add_contact_qr_no_profile, soft: true);
      return;
    }
    if (userId.isNotEmpty && userId == widget.ownerId) {
      _setError(l10n.add_contact_own_profile, soft: true);
      return;
    }

    setState(() {
      _busy = true;
      _matchedIds = const <String>[];
      _error = null;
      _errorIsSoft = false;
      _info = null;
    });

    try {
      String? resolvedUserId = userId.isEmpty ? null : userId;
      if ((resolvedUserId == null || resolvedUserId.isEmpty) &&
          username.isNotEmpty) {
        try {
          resolvedUserId = await widget.contactsRepo.resolveUserIdByUsername(
            username,
          );
        } catch (_) {
          resolvedUserId = null;
        }
      }
      if (resolvedUserId == null || resolvedUserId.isEmpty) {
        _setError(l10n.add_contact_qr_not_found, soft: true);
        return;
      }
      if (resolvedUserId == widget.ownerId) {
        _setError(l10n.add_contact_own_profile, soft: true);
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(resolvedUserId)
          .get();
      if (!mounted) return;
      if (!doc.exists) {
        _setError(l10n.add_contact_qr_not_found, soft: true);
        return;
      }
      final resolvedUserIdSafe = resolvedUserId;
      setState(() => _matchedIds = <String>[resolvedUserIdSafe]);
      _setInfo(l10n.add_contact_qr_found);
    } catch (e) {
      if (!mounted) return;
      _setError(
        AppLocalizations.of(context)!.add_contact_qr_error(e.toString()),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openQrScanner() async {
    if (_busy) return;
    final payload = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ContactQrScannerSheet(),
    );
    if (!mounted || payload == null || payload.trim().isEmpty) return;
    await _searchByQrPayload(payload);
  }

  Future<void> _addContact(UserProfile peer) async {
    if (_busy) return;
    if (!canStartDirectChat(widget.viewer, peer)) {
      _setError(AppLocalizations.of(context)!.add_contact_not_allowed);
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.contactsRepo.addContactId(widget.ownerId, peer.id);
      if (!mounted) return;
      Navigator.of(context).pop(peer.id);
    } catch (e) {
      if (!mounted) return;
      _setError(
        AppLocalizations.of(context)!.add_contact_save_error(e.toString()),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openExistingContact(UserProfile peer) async {
    if (_busy) return;
    if (!mounted) return;
    Navigator.of(context).pop(peer.id);
  }

  Future<void> _pickPhoneCountry() async {
    final selected = await showModalBottomSheet<_PhoneCountry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF11131A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        _countrySearch.text = '';
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.78,
          minChildSize: 0.42,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                final query = _countrySearch.text.trim().toLowerCase();
                final items = query.isEmpty
                    ? _phoneCountries
                    : _phoneCountries
                          .where((c) {
                            final q = query;
                            return ruEnSubstringMatch(
                                  c.localizedName(
                                    Localizations.localeOf(
                                      context,
                                    ).languageCode,
                                  ),
                                  q,
                                ) ||
                                c.dialCode.contains(q) ||
                                ruEnSubstringMatch(c.isoCode, q);
                          })
                          .toList(growable: false);

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _countrySearch,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => setModalState(() {}),
                        style: const TextStyle(fontSize: 18),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search, size: 24),
                          hintText: AppLocalizations.of(
                            context,
                          )!.add_contact_country_search,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF2A79FF),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                                vertical: 6,
                              ),
                              minLeadingWidth: 34,
                              leading: Text(
                                country.flag,
                                style: const TextStyle(fontSize: 22),
                              ),
                              title: Text(
                                country.localizedName(
                                  Localizations.localeOf(context).languageCode,
                                ),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                country.dialCode,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white.withValues(alpha: 0.72),
                                ),
                              ),
                              trailing: selected
                                  ? const Icon(
                                      Icons.check_rounded,
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
      _nationalPhone.text = AddContactNationalPhoneMaskFormatter.formatDigits(
        nationalDigits,
        phoneHint: _selectedCountry.phoneHint,
      );
      _nationalPhone.selection = TextSelection.collapsed(
        offset: _nationalPhone.text.length,
      );
      _matchedIds = const <String>[];
      _info = null;
      _error = null;
      _errorIsSoft = false;
    });
  }

  Widget _buildTopActions() {
    return Row(
      children: [
        _RoundHeaderAction(
          icon: Icons.close_rounded,
          onTap: _busy ? null : () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.add_contact_title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 34 / 2,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
        ),
        _RoundHeaderAction(
          icon: Icons.check_rounded,
          onTap: _busy ? null : () => unawaited(_searchByPhone()),
        ),
      ],
    );
  }

  Widget _buildPhoneBlock() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.065),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            onTap: (_busy || _syncBusy)
                ? null
                : () => unawaited(_pickPhoneCountry()),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Row(
                children: [
                  Text(
                    _selectedCountry.flag,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedCountry.localizedName(
                        Localizations.localeOf(context).languageCode,
                      ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.94),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.62),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: Row(
              children: [
                Text(
                  _selectedCountry.dialCode,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 28 / 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _nationalPhone,
                    enabled: !_busy,
                    textCapitalization: TextCapitalization.none,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.search,
                    onChanged: _handlePhoneChanged,
                    onSubmitted: (_) => unawaited(_searchByPhone()),
                    inputFormatters: <TextInputFormatter>[
                      AddContactNationalPhoneMaskFormatter(
                        phoneHint: _selectedCountry.phoneHint,
                        maxNationalDigits: _selectedCountry.maxNationalDigits,
                      ),
                    ],
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.94),
                      fontSize: 28 / 2,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: _selectedCountry.phoneHint,
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.34),
                        fontSize: 28 / 2,
                        fontWeight: FontWeight.w500,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncRow() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.065),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.add_contact_sync_phone,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 30 / 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_syncBusy)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            else
              Switch.adaptive(
                value: _syncSwitchOn,
                onChanged: (_busy || !_checkedConsent)
                    ? null
                    : (v) => unawaited(_toggleSyncWithPhone(v)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrActionRow() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: (_busy || _syncBusy) ? null : () => unawaited(_openQrScanner()),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.065),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(
              Icons.qr_code_scanner_rounded,
              size: 24,
              color: Colors.blue.shade300,
            ),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context)!.add_contact_qr_button,
              style: TextStyle(
                color: Colors.blue.shade300,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLine() {
    final message = _error ?? _info;
    if (message == null || message.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final isError = _error != null && !_errorIsSoft;
    final isSoftError = _error != null && _errorIsSoft;
    final color = isError
        ? Colors.redAccent.shade100
        : isSoftError
        ? Colors.orange.shade200
        : Colors.greenAccent.shade100;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        message,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSearchResult() {
    if (_matchedIds.isEmpty) {
      return const SizedBox.shrink();
    }
    if (ref.watch(userProfilesRepositoryProvider) == null) {
      return _ResultPlaceholderCard(
        text: AppLocalizations.of(context)!.add_contact_results_unavailable,
        warning: true,
      );
    }
    final idsKey = addContactMatchedProfilesProviderKey(_matchedIds);
    final profilesAsync = ref.watch(
      addContactMatchedProfilesStreamProvider(idsKey),
    );

    return profilesAsync.when(
      loading: () => const _ResultLoadingCard(),
      error: (e, _) => _ResultPlaceholderCard(
        text: AppLocalizations.of(
          context,
        )!.add_contact_profile_load_error(e.toString()),
        warning: true,
      ),
      data: (map) {
        final profiles = _matchedIds
            .map((id) => map[id])
            .whereType<UserProfile>()
            .where((p) => (p.deletedAt ?? '').trim().isEmpty)
            .toList(growable: false);
        if (profiles.isEmpty) {
          return _ResultPlaceholderCard(
            text: AppLocalizations.of(context)!.add_contact_profile_not_found,
            warning: true,
          );
        }
        return Column(
          children: profiles
              .map((profile) {
                final title = profile.name.trim().isNotEmpty
                    ? profile.name.trim()
                    : AppLocalizations.of(context)!.group_members_user_fallback;
                final username = (profile.username ?? '').trim();
                final subtitle = username.isEmpty
                    ? null
                    : (username.startsWith('@') ? username : '@$username');
                final alreadyAdded = widget.existingContactIds.contains(
                  profile.id,
                );
                final allowed = canStartDirectChat(widget.viewer, profile);
                final l10n = AppLocalizations.of(context)!;
                final badgeText = alreadyAdded
                    ? l10n.add_contact_badge_already_added
                    : (allowed
                          ? l10n.add_contact_badge_new
                          : l10n.add_contact_badge_unavailable);
                final badgeColor = alreadyAdded
                    ? const Color(0xFF2E87FF)
                    : (allowed
                          ? const Color(0xFF36C26C)
                          : const Color(0xFF8A8E99));

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.white.withValues(alpha: 0.07),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  context.push(
                                    '/contacts/user/${Uri.encodeComponent(profile.id)}',
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    children: [
                                      ChatAvatar(
                                        title: title,
                                        radius: 24,
                                        avatarUrl:
                                            profile.avatarThumb ??
                                            profile.avatar,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.95,
                                                ),
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            if (subtitle != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                subtitle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.68),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: badgeColor.withValues(alpha: 0.18),
                              border: Border.all(
                                color: badgeColor.withValues(alpha: 0.44),
                              ),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: alreadyAdded
                            ? OutlinedButton(
                                onPressed: _busy
                                    ? null
                                    : () => unawaited(
                                        _openExistingContact(profile),
                                      ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(46),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.24),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.add_contact_open_contact,
                                ),
                              )
                            : FilledButton(
                                onPressed: (!_busy && allowed)
                                    ? () => unawaited(_addContact(profile))
                                    : null,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(46),
                                  backgroundColor: const Color(0xFF2A79FF),
                                  disabledBackgroundColor: Colors.white
                                      .withValues(alpha: 0.08),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  allowed
                                      ? AppLocalizations.of(
                                          context,
                                        )!.add_contact_add_to_contacts
                                      : AppLocalizations.of(
                                          context,
                                        )!.add_contact_add_unavailable,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardBottom),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFF12141C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            16 + MediaQuery.paddingOf(context).bottom,
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: platformScrollKeyboardDismissBehavior(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopActions(),
                const SizedBox(height: 18),
                _buildPhoneBlock(),
                const SizedBox(height: 12),
                _buildSyncRow(),
                const SizedBox(height: 10),
                _buildQrActionRow(),
                const SizedBox(height: 10),
                _buildStatusLine(),
                if (_busy) ...[
                  const SizedBox(height: 12),
                  const _ResultLoadingCard(),
                ],
                const SizedBox(height: 8),
                _buildSearchResult(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundHeaderAction extends StatelessWidget {
  const _RoundHeaderAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.11),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: Colors.white, size: 27),
        ),
      ),
    );
  }
}

class _ResultLoadingCard extends StatelessWidget {
  const _ResultLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.065),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.add_contact_searching,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultPlaceholderCard extends StatelessWidget {
  const _ResultPlaceholderCard({required this.text, this.warning = false});

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning ? Colors.orange.shade200 : Colors.white70;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _ContactQrScannerSheet extends StatefulWidget {
  const _ContactQrScannerSheet();

  @override
  State<_ContactQrScannerSheet> createState() => _ContactQrScannerSheetState();
}

class _ContactQrScannerSheetState extends State<_ContactQrScannerSheet> {
  final MobileScannerController _controller = MobileScannerController(
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool _handled = false;
  bool _torchEnabled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    if (!mounted) return;
    setState(() => _torchEnabled = !_torchEnabled);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value == null || value.isEmpty) continue;
      _handled = true;
      Navigator.of(context).pop(value);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF101218),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.add_contact_scan_qr_title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.96),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: AppLocalizations.of(
                    context,
                  )!.add_contact_flash_tooltip,
                  onPressed: _toggleTorch,
                  icon: Icon(
                    _torchEnabled
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                  ),
                  color: Colors.white.withValues(alpha: 0.88),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 360,
                child: MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.add_contact_scan_qr_hint,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.common_cancel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneCountry {
  const _PhoneCountry({
    required this.isoCode,
    required this.flag,
    required this.dialCode,
    required this.phoneHint,
    required this.maxNationalDigits,
  });

  final String isoCode;
  final String flag;
  final String dialCode;
  final String phoneHint;
  final int maxNationalDigits;

  String localizedName(String langCode) =>
      localizedCountryName(isoCode, langCode);

  String get dialDigits => dialCode.replaceAll(RegExp(r'\D'), '');
}

const List<_PhoneCountry> _phoneCountries = [
  _PhoneCountry(
    isoCode: 'RU',
    flag: '🇷🇺',
    dialCode: '+7',
    phoneHint: '(999)123-45-67',
    maxNationalDigits: 10,
  ),
  _PhoneCountry(
    isoCode: 'KZ',
    flag: '🇰🇿',
    dialCode: '+7',
    phoneHint: '(777)123-45-67',
    maxNationalDigits: 10,
  ),
  _PhoneCountry(
    isoCode: 'BY',
    flag: '🇧🇾',
    dialCode: '+375',
    phoneHint: '29 123 45 67',
    maxNationalDigits: 9,
  ),
  _PhoneCountry(
    isoCode: 'UA',
    flag: '🇺🇦',
    dialCode: '+380',
    phoneHint: '50 123 45 67',
    maxNationalDigits: 9,
  ),
  _PhoneCountry(
    isoCode: 'UZ',
    flag: '🇺🇿',
    dialCode: '+998',
    phoneHint: '90 123 45 67',
    maxNationalDigits: 9,
  ),
  _PhoneCountry(
    isoCode: 'KG',
    flag: '🇰🇬',
    dialCode: '+996',
    phoneHint: '555 123 456',
    maxNationalDigits: 9,
  ),
  _PhoneCountry(
    isoCode: 'US',
    flag: '🇺🇸',
    dialCode: '+1',
    phoneHint: '(555)123-4567',
    maxNationalDigits: 10,
  ),
  _PhoneCountry(
    isoCode: 'GB',
    flag: '🇬🇧',
    dialCode: '+44',
    phoneHint: '7400 123456',
    maxNationalDigits: 10,
  ),
  _PhoneCountry(
    isoCode: 'DE',
    flag: '🇩🇪',
    dialCode: '+49',
    phoneHint: '1512 3456789',
    maxNationalDigits: 11,
  ),
  _PhoneCountry(
    isoCode: 'FR',
    flag: '🇫🇷',
    dialCode: '+33',
    phoneHint: '6 12 34 56 78',
    maxNationalDigits: 9,
  ),
];
