import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../../../l10n/app_localizations.dart';
import '../../chat/data/new_chat_user_search.dart' show ruEnSubstringMatch;
import 'auth_validators.dart';
import 'avatar_picker_cropper.dart';

class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  bool _busy = false;
  String? _error;
  bool _acceptedPolicy = false;
  bool _showValidation = false;
  _PhoneCountry _selectedCountry = _phoneCountries.first;
  late final TapGestureRecognizer _privacyPolicyTap;
  late final TapGestureRecognizer _termsTap;

  final _name = TextEditingController();
  final _username = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _dob = TextEditingController(); // yyyy-mm-dd
  final _bio = TextEditingController();
  final _nameFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _dobFocus = FocusNode();
  final _bioFocus = FocusNode();
  final _countrySearch = TextEditingController();
  final _nameKey = GlobalKey();
  final _usernameKey = GlobalKey();
  final _phoneKey = GlobalKey();
  final _emailKey = GlobalKey();
  final _passwordKey = GlobalKey();
  final _confirmKey = GlobalKey();
  final _dobKey = GlobalKey();
  final _bioKey = GlobalKey();

  AvatarResult? _avatar;

  @override
  void initState() {
    super.initState();
    _privacyPolicyTap = TapGestureRecognizer()
      ..onTap = () => _openLegalUrl('https://lighchat.app/privacy');
    _termsTap = TapGestureRecognizer()
      ..onTap = () => _openLegalUrl('https://lighchat.app/terms');
    _bindFocusAutoScroll(_nameFocus, _nameKey);
    _bindFocusAutoScroll(_usernameFocus, _usernameKey);
    _bindFocusAutoScroll(_phoneFocus, _phoneKey);
    _bindFocusAutoScroll(_emailFocus, _emailKey);
    _bindFocusAutoScroll(_passwordFocus, _passwordKey);
    _bindFocusAutoScroll(_confirmFocus, _confirmKey);
    _bindFocusAutoScroll(_dobFocus, _dobKey);
    _bindFocusAutoScroll(_bioFocus, _bioKey);
  }

  void _bindFocusAutoScroll(FocusNode node, GlobalKey key) {
    node.addListener(() {
      if (!node.hasFocus) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = key.currentContext;
        if (ctx == null) return;
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: 0.08,
        );
      });
    });
  }

  @override
  void dispose() {
    _privacyPolicyTap.dispose();
    _termsTap.dispose();
    _name.dispose();
    _username.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _dob.dispose();
    _bio.dispose();
    _nameFocus.dispose();
    _usernameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _dobFocus.dispose();
    _bioFocus.dispose();
    _countrySearch.dispose();
    super.dispose();
  }

  String? get _nameError => !_showValidation
      ? null
      : (_name.text.trim().isEmpty
            ? AppLocalizations.of(context)!.register_error_enter_name
            : validateName(_name.text));
  String? get _usernameError => !_showValidation
      ? null
      : (_username.text.trim().isEmpty
            ? AppLocalizations.of(context)!.register_error_enter_username
            : validateUsername(_username.text));
  String? get _phoneError => !_showValidation
      ? null
      : (_phone.text.trim().isEmpty
            ? AppLocalizations.of(context)!.register_error_enter_phone
            : _validatePhoneForCountry(_phone.text));
  String? get _emailError => !_showValidation
      ? null
      : (_email.text.trim().isEmpty
            ? AppLocalizations.of(context)!.register_error_enter_email
            : validateEmail(_email.text));
  String? get _passwordError => !_showValidation
      ? null
      : (_password.text.trim().isEmpty
            ? AppLocalizations.of(context)!.register_error_enter_password
            : validatePassword(_password.text));
  String? get _confirmError => !_showValidation
      ? null
      : (_confirm.text.trim().isEmpty
            ? AppLocalizations.of(context)!.register_error_repeat_password
            : validateConfirmPassword(_password.text, _confirm.text));
  String? get _dobError {
    if (!_showValidation) return null;
    final dobIso = _toIsoDate(_dob.text);
    if (_dob.text.trim().isNotEmpty && dobIso == null) {
      return AppLocalizations.of(context)!.register_error_dob_format;
    }
    return validateDateOfBirth(dobIso ?? '');
  }

  String? get _bioError => !_showValidation ? null : validateBio(_bio.text);

  String? _validateAll() {
    final e = <String?>[
      _nameError,
      _usernameError,
      _phoneError,
      _emailError,
      _passwordError,
      _confirmError,
      _dobError,
      _bioError,
      (_showValidation && !_acceptedPolicy)
          ? AppLocalizations.of(context)!.register_error_accept_privacy_policy
          : null,
    ].whereType<String>().toList();
    return e.isEmpty ? null : e.first;
  }

  bool get _canSubmit =>
      !_busy &&
      _acceptedPolicy &&
      _name.text.trim().isNotEmpty &&
      _username.text.trim().isNotEmpty &&
      _phone.text.trim().isNotEmpty &&
      _email.text.trim().isNotEmpty &&
      _password.text.trim().isNotEmpty &&
      _confirm.text.trim().isNotEmpty;

  Future<void> _submit() async {
    final svc = ref.read(registrationServiceProvider);
    if (svc == null) return;

    setState(() => _showValidation = true);
    final msg = _validateAll();
    if (msg != null) {
      setState(() => _error = msg);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await svc.register(
        RegistrationData(
          name: _name.text,
          username: _username.text,
          phone: _buildE164Phone(_phone.text),
          email: _email.text,
          password: _password.text,
          dateOfBirth: _toIsoDate(_dob.text),
          bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
          avatarFullJpeg: _avatar?.fullJpeg,
          avatarThumbPng: _avatar?.thumbPng,
        ),
      );
      widget.onDone();
    } catch (e) {
      if (e is RegistrationConflict) {
        setState(() => _error = e.message);
      } else {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openLegalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.auth_register_error_open_link),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final enabled = !_busy;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _AvatarSection(
            enabled: enabled,
            value: _avatar,
            onChanged: (v) => setState(() => _avatar = v),
          ),
          const SizedBox(height: 18),
          _LabeledInput(
            key: _nameKey,
            label: l10n.register_label_name,
            required: true,
            focusNode: _nameFocus,
            enabled: enabled,
            errorText: _nameError,
            child: TextField(
              controller: _name,
              focusNode: _nameFocus,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: _registerInputDecoration(
                context,
                hint: l10n.register_hint_name,
                hasError: _nameError != null,
              ),
              enabled: enabled,
            ),
          ),
          const SizedBox(height: 14),
          _LabeledInput(
            key: _usernameKey,
            label: l10n.register_label_username,
            required: true,
            focusNode: _usernameFocus,
            enabled: enabled,
            errorText: _usernameError,
            child: TextField(
              controller: _username,
              focusNode: _usernameFocus,
              textCapitalization: TextCapitalization.none,
              onChanged: (_) => setState(() {}),
              decoration: _registerInputDecoration(
                context,
                hint: l10n.register_hint_username,
                hasError: _usernameError != null,
              ),
              enabled: enabled,
            ),
          ),
          const SizedBox(height: 14),
          _LabeledInput(
            key: _phoneKey,
            label: l10n.register_label_phone,
            required: true,
            focusNode: _phoneFocus,
            enabled: enabled,
            errorText: _phoneError,
            child: Column(
              children: [
                GestureDetector(
                  onTap: enabled ? _pickPhoneCountry : null,
                  child: AbsorbPointer(
                    child: DropdownButtonFormField<_PhoneCountry>(
                      isExpanded: true,
                      initialValue: _selectedCountry,
                      decoration: _registerInputDecoration(
                        context,
                        hint: l10n.register_hint_choose_country,
                        hasError: _phoneError != null,
                      ),
                      items: [
                        DropdownMenuItem<_PhoneCountry>(
                          value: _selectedCountry,
                          child: Text(
                            '${_selectedCountry.flag} ${_selectedCountry.name} (${_selectedCountry.dialCode})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      onChanged: (_) {},
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phone,
                  focusNode: _phoneFocus,
                  textCapitalization: TextCapitalization.none,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    _PhoneMaskFormatter(
                      phoneHint: _selectedCountry.phoneHint,
                      maxDigits: _selectedCountry.maxNationalDigits,
                    ),
                  ],
                  decoration: _registerInputDecoration(
                    context,
                    hint: _selectedCountry.phoneHint,
                    prefix: '${_selectedCountry.dialCode} ',
                    hasError: _phoneError != null,
                  ),
                  enabled: enabled,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _LabeledInput(
            key: _emailKey,
            label: l10n.register_label_email,
            required: true,
            focusNode: _emailFocus,
            enabled: enabled,
            errorText: _emailError,
            child: TextField(
              controller: _email,
              focusNode: _emailFocus,
              textCapitalization: TextCapitalization.none,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.emailAddress,
              decoration: _registerInputDecoration(
                context,
                hint: l10n.register_hint_email,
                hasError: _emailError != null,
              ),
              enabled: enabled,
            ),
          ),
          const SizedBox(height: 14),
          _LabeledInput(
            key: _passwordKey,
            label: l10n.register_label_password,
            required: true,
            focusNode: _passwordFocus,
            enabled: enabled,
            errorText: _passwordError,
            child: TextField(
              controller: _password,
              focusNode: _passwordFocus,
              textCapitalization: TextCapitalization.none,
              onChanged: (_) => setState(() {}),
              obscureText: true,
              decoration: _registerInputDecoration(
                context,
                hint: l10n.register_hint_password,
                hasError: _passwordError != null,
              ),
              enabled: enabled,
            ),
          ),
          const SizedBox(height: 14),
          _LabeledInput(
            key: _confirmKey,
            label: l10n.register_label_confirm_password,
            focusNode: _confirmFocus,
            enabled: enabled,
            errorText: _confirmError,
            child: TextField(
              controller: _confirm,
              focusNode: _confirmFocus,
              textCapitalization: TextCapitalization.none,
              onChanged: (_) => setState(() {}),
              obscureText: true,
              decoration: _registerInputDecoration(
                context,
                hint: l10n.register_hint_confirm_password,
                hasError: _confirmError != null,
              ),
              enabled: enabled,
            ),
          ),
          const SizedBox(height: 14),
          _LabeledInput(
            key: _dobKey,
            label: l10n.register_label_dob,
            focusNode: _dobFocus,
            enabled: enabled,
            errorText: _dobError,
            child: TextField(
              controller: _dob,
              focusNode: _dobFocus,
              textCapitalization: TextCapitalization.none,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.number,
              inputFormatters: [DateDdMmYyyyFormatter()],
              decoration: _registerInputDecoration(
                context,
                hint: l10n.register_hint_dob,
                hasError: _dobError != null,
                suffixIcon: IconButton(
                  onPressed: enabled ? _pickBirthDate : null,
                  icon: Icon(
                    Icons.calendar_month_outlined,
                    color: (dark ? Colors.white : scheme.onSurface).withValues(
                      alpha: 0.72,
                    ),
                  ),
                ),
              ),
              enabled: enabled,
            ),
          ),
          const SizedBox(height: 14),
          _LabeledInput(
            key: _bioKey,
            label: l10n.register_label_bio,
            focusNode: _bioFocus,
            enabled: enabled,
            errorText: _bioError,
            child: TextField(
              controller: _bio,
              focusNode: _bioFocus,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              maxLines: 4,
              decoration: _registerInputDecoration(
                context,
                hint: l10n.register_hint_bio,
                minHeight: 122,
                hasError: _bioError != null,
              ),
              enabled: enabled,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _acceptedPolicy,
                    onChanged: enabled
                        ? (v) => setState(() => _acceptedPolicy = v ?? false)
                        : null,
                    side: BorderSide(
                      color: (dark ? Colors.white : scheme.onSurface)
                          .withValues(alpha: 0.38),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      height: 1.35,
                      fontSize: 11.5,
                      color: (dark ? Colors.white : scheme.onSurface)
                          .withValues(alpha: 0.64),
                    ),
                    children: [
                      TextSpan(text: l10n.register_privacy_prefix),
                      TextSpan(
                        text: l10n.register_privacy_link_text,
                        recognizer: _privacyPolicyTap,
                        style: const TextStyle(
                          color: Color(0xFF38A3FF),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(text: l10n.register_privacy_and),
                      TextSpan(
                        text: l10n.register_terms_link_text,
                        recognizer: _termsTap,
                        style: const TextStyle(
                          color: Color(0xFF38A3FF),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_showValidation && !_acceptedPolicy)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l10n.register_privacy_required,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 18),
          if (_error != null)
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: _canSubmit
                    ? const [
                        Color(0xFF2E86FF),
                        Color(0xFF5F90FF),
                        Color(0xFF9A18FF),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.18),
                        Colors.white.withValues(alpha: 0.18),
                      ],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: SizedBox(
              height: 62,
              child: TextButton(
                onPressed: _canSubmit ? _submit : null,
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  foregroundColor: Colors.white,
                ),
                child: _busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.register_button_create_account,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  InputDecoration _registerInputDecoration(
    BuildContext context, {
    String? hint,
    double? minHeight,
    String? prefix,
    Widget? suffixIcon,
    bool hasError = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fillColor = dark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.76);

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: (dark ? Colors.white : scheme.onSurface).withValues(alpha: 0.34),
        fontSize: 13,
      ),
      prefixText: prefix,
      prefixStyle: TextStyle(
        color: (dark ? Colors.white : scheme.onSurface).withValues(alpha: 0.72),
        fontSize: 13,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor,
      isDense: true,
      constraints: minHeight == null
          ? null
          : BoxConstraints(minHeight: minHeight),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: minHeight == null ? 14 : 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: hasError
              ? const Color(0xFFFF5A5F)
              : (dark ? Colors.white : Colors.black).withValues(alpha: 0.17),
          width: 1.1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: hasError
              ? const Color(0xFFFF5A5F)
              : (dark ? Colors.white : Colors.black).withValues(alpha: 0.17),
          width: 1.1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        borderSide: BorderSide(
          color: hasError ? const Color(0xFFFF5A5F) : const Color(0xFF2A79FF),
          width: 1.3,
        ),
      ),
    );
  }

  String _extractNationalPhoneDigits(String input) {
    final digitsOnly = input.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) return '';

    // Normalize: drop leading zeros.
    // If the user pastes a full E.164, it includes dial-code digits at the front.
    // Keeping only the last `maxNationalDigits` isolates the national part
    // for both validation and E.164 building.
    var cleaned = digitsOnly.replaceFirst(RegExp(r'^0+'), '');
    if (cleaned.length > _selectedCountry.maxNationalDigits) {
      cleaned = cleaned.substring(
        cleaned.length - _selectedCountry.maxNationalDigits,
      );
    }

    return cleaned;
  }

  String? _validatePhoneForCountry(String input) {
    final nationalDigits = _extractNationalPhoneDigits(input);
    if (nationalDigits.length < _selectedCountry.minNationalDigits ||
        nationalDigits.length > _selectedCountry.maxNationalDigits) {
      return AppLocalizations.of(context)!.register_error_invalid_phone;
    }
    return null;
  }

  String _buildE164Phone(String input) {
    final nationalDigits = _extractNationalPhoneDigits(input);
    final codeDigits = _selectedCountry.dialCode.replaceAll('+', '');
    return '+$codeDigits$nationalDigits';
  }

  Future<void> _pickPhoneCountry() async {
    final l10n = AppLocalizations.of(context)!;
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
                    : _phoneCountries.where((c) {
                        final q = query;
                        return ruEnSubstringMatch(c.name, q) ||
                            c.dialCode.contains(q);
                      }).toList();

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
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => setModalState(() {}),
                        style: const TextStyle(fontSize: 18),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search, size: 24),
                          hintText: l10n.register_country_search_hint,
                          hintStyle: const TextStyle(fontSize: 18),
                          contentPadding: const EdgeInsets.symmetric(
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
                              onTap: () {
                                Navigator.of(context).pop(country);
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

    if (selected == null) return;
    setState(() {
      _selectedCountry = selected;
      final nationalDigits = _extractNationalPhoneDigits(_phone.text);
      _phone.text = _PhoneMaskFormatter.formatDigits(
        nationalDigits,
        phoneHint: _selectedCountry.phoneHint,
      );
      _phone.selection = TextSelection.collapsed(offset: _phone.text.length);
    });
  }

  String? _toIsoDate(String value) {
    final v = value.trim();
    if (v.isEmpty) return null;
    final match = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(v);
    if (match == null) return null;
    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) return null;
    final dt = DateTime.tryParse(
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
    );
    if (dt == null || dt.day != day || dt.month != month || dt.year != year) {
      return null;
    }
    return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickBirthDate() async {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final initial = _toIsoDate(_dob.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial == null
          ? DateTime(now.year - 18)
          : DateTime.parse(initial),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: l10n.register_date_picker_help,
      cancelText: l10n.register_date_picker_cancel,
      confirmText: l10n.register_date_picker_confirm,
    );
    if (picked == null) return;
    final dd = picked.day.toString().padLeft(2, '0');
    final mm = picked.month.toString().padLeft(2, '0');
    final yyyy = picked.year.toString().padLeft(4, '0');
    setState(() => _dob.text = '$dd.$mm.$yyyy');
  }
}

class _PhoneCountry {
  const _PhoneCountry({
    required this.name,
    required this.flag,
    required this.dialCode,
    this.phoneHint = '123456789',
    this.minNationalDigits = 6,
    this.maxNationalDigits = 14,
  });

  final String name;
  final String flag;
  final String dialCode;
  final String phoneHint;
  final int minNationalDigits;
  final int maxNationalDigits;
}

const List<_PhoneCountry> _phoneCountries = [
  _PhoneCountry(
    name: 'Россия',
    flag: '🇷🇺',
    dialCode: '+7',
    phoneHint: '(999)123-45-67',
    minNationalDigits: 10,
    maxNationalDigits: 10,
  ),
  _PhoneCountry(
    name: 'Казахстан',
    flag: '🇰🇿',
    dialCode: '+7',
    phoneHint: '(777)123-45-67',
    minNationalDigits: 10,
    maxNationalDigits: 10,
  ),
  _PhoneCountry(
    name: 'Беларусь',
    flag: '🇧🇾',
    dialCode: '+375',
    phoneHint: '29 123 45 67',
    minNationalDigits: 9,
    maxNationalDigits: 9,
  ),
  _PhoneCountry(
    name: 'Узбекистан',
    flag: '🇺🇿',
    dialCode: '+998',
    phoneHint: '90 123 45 67',
    minNationalDigits: 9,
    maxNationalDigits: 9,
  ),
  _PhoneCountry(
    name: 'Кыргызстан',
    flag: '🇰🇬',
    dialCode: '+996',
    phoneHint: '555 123 456',
    minNationalDigits: 9,
    maxNationalDigits: 9,
  ),
  _PhoneCountry(name: 'Украина', flag: '🇺🇦', dialCode: '+380'),
  _PhoneCountry(name: 'Армения', flag: '🇦🇲', dialCode: '+374'),
  _PhoneCountry(name: 'Азербайджан', flag: '🇦🇿', dialCode: '+994'),
  _PhoneCountry(name: 'Грузия', flag: '🇬🇪', dialCode: '+995'),
  _PhoneCountry(name: 'Молдова', flag: '🇲🇩', dialCode: '+373'),
  _PhoneCountry(name: 'Таджикистан', flag: '🇹🇯', dialCode: '+992'),
  _PhoneCountry(name: 'Туркменистан', flag: '🇹🇲', dialCode: '+993'),
  _PhoneCountry(name: 'США', flag: '🇺🇸', dialCode: '+1'),
  _PhoneCountry(name: 'Канада', flag: '🇨🇦', dialCode: '+1'),
  _PhoneCountry(name: 'Мексика', flag: '🇲🇽', dialCode: '+52'),
  _PhoneCountry(name: 'Бразилия', flag: '🇧🇷', dialCode: '+55'),
  _PhoneCountry(name: 'Аргентина', flag: '🇦🇷', dialCode: '+54'),
  _PhoneCountry(name: 'Чили', flag: '🇨🇱', dialCode: '+56'),
  _PhoneCountry(name: 'Колумбия', flag: '🇨🇴', dialCode: '+57'),
  _PhoneCountry(name: 'Перу', flag: '🇵🇪', dialCode: '+51'),
  _PhoneCountry(name: 'Венесуэла', flag: '🇻🇪', dialCode: '+58'),
  _PhoneCountry(name: 'Уругвай', flag: '🇺🇾', dialCode: '+598'),
  _PhoneCountry(name: 'Парагвай', flag: '🇵🇾', dialCode: '+595'),
  _PhoneCountry(name: 'Боливия', flag: '🇧🇴', dialCode: '+591'),
  _PhoneCountry(name: 'Эквадор', flag: '🇪🇨', dialCode: '+593'),
  _PhoneCountry(name: 'Гватемала', flag: '🇬🇹', dialCode: '+502'),
  _PhoneCountry(name: 'Коста-Рика', flag: '🇨🇷', dialCode: '+506'),
  _PhoneCountry(name: 'Панама', flag: '🇵🇦', dialCode: '+507'),
  _PhoneCountry(name: 'Доминиканская Республика', flag: '🇩🇴', dialCode: '+1'),
  _PhoneCountry(name: 'Ямайка', flag: '🇯🇲', dialCode: '+1'),
  _PhoneCountry(name: 'Германия', flag: '🇩🇪', dialCode: '+49'),
  _PhoneCountry(name: 'Франция', flag: '🇫🇷', dialCode: '+33'),
  _PhoneCountry(name: 'Испания', flag: '🇪🇸', dialCode: '+34'),
  _PhoneCountry(name: 'Италия', flag: '🇮🇹', dialCode: '+39'),
  _PhoneCountry(name: 'Великобритания', flag: '🇬🇧', dialCode: '+44'),
  _PhoneCountry(name: 'Нидерланды', flag: '🇳🇱', dialCode: '+31'),
  _PhoneCountry(name: 'Бельгия', flag: '🇧🇪', dialCode: '+32'),
  _PhoneCountry(name: 'Швейцария', flag: '🇨🇭', dialCode: '+41'),
  _PhoneCountry(name: 'Австрия', flag: '🇦🇹', dialCode: '+43'),
  _PhoneCountry(name: 'Польша', flag: '🇵🇱', dialCode: '+48'),
  _PhoneCountry(name: 'Чехия', flag: '🇨🇿', dialCode: '+420'),
  _PhoneCountry(name: 'Словакия', flag: '🇸🇰', dialCode: '+421'),
  _PhoneCountry(name: 'Венгрия', flag: '🇭🇺', dialCode: '+36'),
  _PhoneCountry(name: 'Румыния', flag: '🇷🇴', dialCode: '+40'),
  _PhoneCountry(name: 'Болгария', flag: '🇧🇬', dialCode: '+359'),
  _PhoneCountry(name: 'Сербия', flag: '🇷🇸', dialCode: '+381'),
  _PhoneCountry(name: 'Хорватия', flag: '🇭🇷', dialCode: '+385'),
  _PhoneCountry(name: 'Словения', flag: '🇸🇮', dialCode: '+386'),
  _PhoneCountry(name: 'Босния и Герцеговина', flag: '🇧🇦', dialCode: '+387'),
  _PhoneCountry(name: 'Черногория', flag: '🇲🇪', dialCode: '+382'),
  _PhoneCountry(name: 'Северная Македония', flag: '🇲🇰', dialCode: '+389'),
  _PhoneCountry(name: 'Албания', flag: '🇦🇱', dialCode: '+355'),
  _PhoneCountry(name: 'Греция', flag: '🇬🇷', dialCode: '+30'),
  _PhoneCountry(name: 'Португалия', flag: '🇵🇹', dialCode: '+351'),
  _PhoneCountry(name: 'Швеция', flag: '🇸🇪', dialCode: '+46'),
  _PhoneCountry(name: 'Норвегия', flag: '🇳🇴', dialCode: '+47'),
  _PhoneCountry(name: 'Финляндия', flag: '🇫🇮', dialCode: '+358'),
  _PhoneCountry(name: 'Дания', flag: '🇩🇰', dialCode: '+45'),
  _PhoneCountry(name: 'Исландия', flag: '🇮🇸', dialCode: '+354'),
  _PhoneCountry(name: 'Ирландия', flag: '🇮🇪', dialCode: '+353'),
  _PhoneCountry(name: 'Люксембург', flag: '🇱🇺', dialCode: '+352'),
  _PhoneCountry(name: 'Латвия', flag: '🇱🇻', dialCode: '+371'),
  _PhoneCountry(name: 'Литва', flag: '🇱🇹', dialCode: '+370'),
  _PhoneCountry(name: 'Эстония', flag: '🇪🇪', dialCode: '+372'),
  _PhoneCountry(name: 'Кипр', flag: '🇨🇾', dialCode: '+357'),
  _PhoneCountry(name: 'Мальта', flag: '🇲🇹', dialCode: '+356'),
  _PhoneCountry(name: 'Турция', flag: '🇹🇷', dialCode: '+90'),
  _PhoneCountry(name: 'Израиль', flag: '🇮🇱', dialCode: '+972'),
  _PhoneCountry(name: 'ОАЭ', flag: '🇦🇪', dialCode: '+971'),
  _PhoneCountry(name: 'Саудовская Аравия', flag: '🇸🇦', dialCode: '+966'),
  _PhoneCountry(name: 'Катар', flag: '🇶🇦', dialCode: '+974'),
  _PhoneCountry(name: 'Кувейт', flag: '🇰🇼', dialCode: '+965'),
  _PhoneCountry(name: 'Бахрейн', flag: '🇧🇭', dialCode: '+973'),
  _PhoneCountry(name: 'Оман', flag: '🇴🇲', dialCode: '+968'),
  _PhoneCountry(name: 'Иордания', flag: '🇯🇴', dialCode: '+962'),
  _PhoneCountry(name: 'Ливан', flag: '🇱🇧', dialCode: '+961'),
  _PhoneCountry(name: 'Ирак', flag: '🇮🇶', dialCode: '+964'),
  _PhoneCountry(name: 'Иран', flag: '🇮🇷', dialCode: '+98'),
  _PhoneCountry(name: 'Египет', flag: '🇪🇬', dialCode: '+20'),
  _PhoneCountry(name: 'Марокко', flag: '🇲🇦', dialCode: '+212'),
  _PhoneCountry(name: 'Алжир', flag: '🇩🇿', dialCode: '+213'),
  _PhoneCountry(name: 'Тунис', flag: '🇹🇳', dialCode: '+216'),
  _PhoneCountry(name: 'Ливия', flag: '🇱🇾', dialCode: '+218'),
  _PhoneCountry(name: 'ЮАР', flag: '🇿🇦', dialCode: '+27'),
  _PhoneCountry(name: 'Нигерия', flag: '🇳🇬', dialCode: '+234'),
  _PhoneCountry(name: 'Кения', flag: '🇰🇪', dialCode: '+254'),
  _PhoneCountry(name: 'Эфиопия', flag: '🇪🇹', dialCode: '+251'),
  _PhoneCountry(name: 'Гана', flag: '🇬🇭', dialCode: '+233'),
  _PhoneCountry(name: 'Танзания', flag: '🇹🇿', dialCode: '+255'),
  _PhoneCountry(name: 'Уганда', flag: '🇺🇬', dialCode: '+256'),
  _PhoneCountry(name: 'Камерун', flag: '🇨🇲', dialCode: '+237'),
  _PhoneCountry(name: 'Ангола', flag: '🇦🇴', dialCode: '+244'),
  _PhoneCountry(name: 'Сенегал', flag: '🇸🇳', dialCode: '+221'),
  _PhoneCountry(name: 'Кот-д’Ивуар', flag: '🇨🇮', dialCode: '+225'),
  _PhoneCountry(name: 'Замбия', flag: '🇿🇲', dialCode: '+260'),
  _PhoneCountry(name: 'Зимбабве', flag: '🇿🇼', dialCode: '+263'),
  _PhoneCountry(name: 'Мозамбик', flag: '🇲🇿', dialCode: '+258'),
  _PhoneCountry(name: 'Намибия', flag: '🇳🇦', dialCode: '+264'),
  _PhoneCountry(name: 'Индия', flag: '🇮🇳', dialCode: '+91'),
  _PhoneCountry(name: 'Пакистан', flag: '🇵🇰', dialCode: '+92'),
  _PhoneCountry(name: 'Бангладеш', flag: '🇧🇩', dialCode: '+880'),
  _PhoneCountry(name: 'Шри-Ланка', flag: '🇱🇰', dialCode: '+94'),
  _PhoneCountry(name: 'Непал', flag: '🇳🇵', dialCode: '+977'),
  _PhoneCountry(name: 'Китай', flag: '🇨🇳', dialCode: '+86'),
  _PhoneCountry(name: 'Япония', flag: '🇯🇵', dialCode: '+81'),
  _PhoneCountry(name: 'Южная Корея', flag: '🇰🇷', dialCode: '+82'),
  _PhoneCountry(name: 'Тайвань', flag: '🇹🇼', dialCode: '+886'),
  _PhoneCountry(name: 'Гонконг', flag: '🇭🇰', dialCode: '+852'),
  _PhoneCountry(name: 'Макао', flag: '🇲🇴', dialCode: '+853'),
  _PhoneCountry(name: 'Сингапур', flag: '🇸🇬', dialCode: '+65'),
  _PhoneCountry(name: 'Малайзия', flag: '🇲🇾', dialCode: '+60'),
  _PhoneCountry(name: 'Таиланд', flag: '🇹🇭', dialCode: '+66'),
  _PhoneCountry(name: 'Вьетнам', flag: '🇻🇳', dialCode: '+84'),
  _PhoneCountry(name: 'Индонезия', flag: '🇮🇩', dialCode: '+62'),
  _PhoneCountry(name: 'Филиппины', flag: '🇵🇭', dialCode: '+63'),
  _PhoneCountry(name: 'Камбоджа', flag: '🇰🇭', dialCode: '+855'),
  _PhoneCountry(name: 'Лаос', flag: '🇱🇦', dialCode: '+856'),
  _PhoneCountry(name: 'Мьянма', flag: '🇲🇲', dialCode: '+95'),
  _PhoneCountry(name: 'Монголия', flag: '🇲🇳', dialCode: '+976'),
  _PhoneCountry(name: 'Австралия', flag: '🇦🇺', dialCode: '+61'),
  _PhoneCountry(name: 'Новая Зеландия', flag: '🇳🇿', dialCode: '+64'),
  _PhoneCountry(name: 'Папуа — Новая Гвинея', flag: '🇵🇬', dialCode: '+675'),
  _PhoneCountry(name: 'Фиджи', flag: '🇫🇯', dialCode: '+679'),
  _PhoneCountry(name: 'Самоа', flag: '🇼🇸', dialCode: '+685'),
  _PhoneCountry(name: 'Тонга', flag: '🇹🇴', dialCode: '+676'),
  _PhoneCountry(name: 'Афганистан', flag: '🇦🇫', dialCode: '+93'),
  _PhoneCountry(name: 'Йемен', flag: '🇾🇪', dialCode: '+967'),
  _PhoneCountry(name: 'Сирия', flag: '🇸🇾', dialCode: '+963'),
  _PhoneCountry(name: 'Палестина', flag: '🇵🇸', dialCode: '+970'),
];

class _PhoneMaskFormatter extends TextInputFormatter {
  const _PhoneMaskFormatter({required this.phoneHint, required this.maxDigits});

  final String phoneHint;
  final int maxDigits;

  static int _templateDigitSlots(String template) {
    // In this codebase `phoneHint` uses digits as placeholders.
    return RegExp(r'\d').allMatches(template).length;
  }

  static String formatDigits(
    String nationalDigits, {
    required String phoneHint,
  }) {
    if (nationalDigits.isEmpty) return '';

    final digits = nationalDigits;
    final b = StringBuffer();
    var di = 0;

    // Insert digits into every digit char in `phoneHint`, leaving all other
    // chars (spaces, brackets, dashes) as-is.
    for (var i = 0; i < phoneHint.length; i++) {
      final ch = phoneHint[i];
      final unit = ch.codeUnitAt(0);
      final isAsciiDigit = unit >= 48 && unit <= 57;

      if (isAsciiDigit) {
        if (di >= digits.length) break;
        b.write(digits[di++]);
        continue;
      }

      // Only add separators while we still have digits to place.
      if (di < digits.length) b.write(ch);
    }

    return b.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final slots = _templateDigitSlots(phoneHint);
    final effectiveMaxDigits = (maxDigits < slots) ? maxDigits : slots;

    // Удаляем лидирующие нули, затем берем только первые `effectiveMaxDigits`
    // цифр. Таким образом новые цифры сверх лимита просто игнорируются.
    final cleaned = digitsOnly.replaceFirst(RegExp(r'^0+'), '');
    final clipped = cleaned.length > effectiveMaxDigits
        ? cleaned.substring(0, effectiveMaxDigits)
        : cleaned;

    final formatted = formatDigits(clipped, phoneHint: phoneHint);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
      composing: TextRange.empty,
    );
  }
}

class DateDdMmYyyyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final clipped = digits.length > 8 ? digits.substring(0, 8) : digits;
    final b = StringBuffer();
    for (var i = 0; i < clipped.length; i++) {
      if (i == 2 || i == 4) b.write('.');
      b.write(clipped[i]);
    }
    final text = b.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
    );
  }
}

class _LabeledInput extends StatelessWidget {
  const _LabeledInput({
    super.key,
    required this.label,
    required this.child,
    required this.focusNode,
    required this.enabled,
    this.errorText,
    this.required = false,
  });

  final String label;
  final bool required;
  final Widget child;
  final FocusNode focusNode;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: (dark ? Colors.white : scheme.onSurface).withValues(
                    alpha: enabled ? 0.76 : 0.46,
                  ),
                ),
              ),
              if (required)
                const TextSpan(
                  text: '*',
                  style: TextStyle(
                    color: Color(0xFFFF5252),
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ListenableBuilder(
          listenable: focusNode,
          builder: (context, _) {
            final glow = focusNode.hasFocus && errorText == null;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: glow
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFF2A79FF,
                          ).withValues(alpha: 0.25),
                          blurRadius: 20,
                        ),
                      ]
                    : const [],
              ),
              child: child,
            );
          },
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(
              errorText!,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    required this.enabled,
    required this.value,
    required this.onChanged,
  });

  final bool enabled;
  final AvatarResult? value;
  final ValueChanged<AvatarResult?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Column(
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: AvatarPickerCropper(
                  enabled: enabled,
                  compact: true,
                  value: value,
                  onChanged: onChanged,
                ),
              ),
              Positioned(
                right: -2,
                bottom: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E69FF),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (dark ? Colors.black : Colors.white),
                      width: 2,
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.photo_camera_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.register_pick_avatar_title,
          style: TextStyle(
            fontSize: 14,
            color: (dark ? Colors.white : scheme.onSurface).withValues(
              alpha: 0.62,
            ),
          ),
        ),
      ],
    );
  }
}
