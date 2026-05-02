import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';
import '../../../l10n/app_localizations.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../../chat/ui/chat_cached_network_image.dart';
import '../../chat/ui/user_avatar_fullscreen_viewer.dart';
import '../data/account_callables.dart';
import '../data/profile_update_service.dart';
import 'auth_validators.dart';
import 'auth_glass.dart';
import 'avatar_picker_cropper.dart';
import 'phone_ru_format.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileSnapshot {
  const _ProfileSnapshot({
    required this.name,
    required this.username,
    required this.phone,
    required this.email,
    required this.dateOfBirth,
    required this.bio,
  });

  final String name;
  final String username;
  final String phone;
  final String email;
  final String dateOfBirth;
  final String bio;
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _busy = false;
  bool _editing = false;
  bool _showPasswordSection = false;
  String? _error;
  AvatarResult? _avatar;
  bool _canChangePassword = false;

  /// Круглое превью в списках (как `avatarThumb` на вебе).
  String? _initialAvatarThumbUrl;

  /// Полноразмерное фото для полноэкранного просмотра (`avatar`).
  String? _initialAvatarFullUrl;
  _ProfileSnapshot? _initial;

  final _name = TextEditingController();
  final _username = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _dob = TextEditingController();
  final _bio = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;

  late final Future<void> _bootstrap;

  @override
  void initState() {
    super.initState();
    _bootstrap = _bootstrapScreen();
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _phone.dispose();
    _email.dispose();
    _dob.dispose();
    _bio.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  String _str(Object? raw) {
    if (raw == null) return '';
    if (raw is String) return raw.trim();
    if (raw is num || raw is bool) return raw.toString().trim();
    return '';
  }

  String _formatDateForDisplay(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    final iso = DateTime.tryParse(value);
    if (iso != null) {
      final d = iso.toLocal();
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      final yyyy = d.year.toString();
      return '$dd.$mm.$yyyy';
    }
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (m != null) {
      return '${m.group(3)}.${m.group(2)}.${m.group(1)}';
    }
    return value;
  }

  String _normalizeDateForSave(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    final ru = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(value);
    if (ru != null) {
      return '${ru.group(3)}-${ru.group(2)}-${ru.group(1)}';
    }
    return value;
  }

  String? _validateDateForProfile(String value) {
    final normalized = _normalizeDateForSave(value);
    if (normalized.isEmpty) return null;
    return validateDateOfBirth(normalized, AppLocalizations.of(context)!);
  }

  Future<void> _bootstrapScreen() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

    _canChangePassword = u.providerData.any((p) => p.providerId == 'password');
    _email.text = u.email?.trim() ?? '';
    _name.text = u.displayName?.trim() ?? '';
    if (_username.text.isEmpty && u.email != null) {
      _username.text = u.email!.split('@').first;
    }

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(u.uid)
        .get()
        .timeout(const Duration(seconds: 12));

    final data = snap.data();
    if (data != null) {
      _name.text = _str(data['name']).isNotEmpty
          ? _str(data['name'])
          : _name.text;
      _username.text = _str(data['username']).isNotEmpty
          ? _str(data['username'])
          : _username.text;
      _phone.text = formatPhoneRuForDisplay(_str(data['phone']));
      _email.text = _str(data['email']).isNotEmpty
          ? _str(data['email'])
          : _email.text;
      _dob.text = _formatDateForDisplay(_str(data['dateOfBirth']));
      _bio.text = _str(data['bio']);
      final full = _str(data['avatar']);
      final thumb = _str(data['avatarThumb']);
      _initialAvatarFullUrl = full.isNotEmpty ? full : null;
      _initialAvatarThumbUrl = thumb.isNotEmpty ? thumb : null;
    }

    _initial = _ProfileSnapshot(
      name: _name.text,
      username: _username.text,
      phone: _phone.text,
      email: _email.text,
      dateOfBirth: _dob.text,
      bio: _bio.text,
    );
  }

  String? _validateAll() {
    final l10n = AppLocalizations.of(context)!;
    final errors = <String?>[
      validateName(_name.text, l10n),
      validateUsername(_username.text, l10n),
      validatePhone11(_phone.text, l10n),
      validateEmail(_email.text, l10n),
      _validateDateForProfile(_dob.text),
      validateBio(_bio.text, l10n),
    ].whereType<String>().toList();
    return errors.isEmpty ? null : errors.first;
  }

  String? _validatePasswordIfChanging() {
    if (!_showPasswordSection) return null;
    final a = _newPassword.text;
    final b = _confirmPassword.text;
    if (a.isEmpty && b.isEmpty) return null;
    if (a.isEmpty || b.isEmpty) {
      return AppLocalizations.of(context)!.profile_password_error_fill_both;
    }
    final l10nPw = AppLocalizations.of(context)!;
    final e = validatePassword(a, l10nPw);
    if (e != null) return e;
    return validateConfirmPassword(a, b, l10nPw);
  }

  void _resetToInitial() {
    final s = _initial;
    if (s == null) return;
    setState(() {
      _editing = false;
      _showPasswordSection = false;
      _name.text = s.name;
      _username.text = s.username;
      _phone.text = s.phone;
      _email.text = s.email;
      _dob.text = s.dateOfBirth;
      _bio.text = s.bio;
      _avatar = null;
      _newPassword.clear();
      _confirmPassword.clear();
      _obscureNew = true;
      _obscureConfirm = true;
      _error = null;
    });
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _save() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

    final pwdErr = _validatePasswordIfChanging();
    if (pwdErr != null) {
      setState(() => _error = pwdErr);
      return;
    }

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
      final changePwd =
          _showPasswordSection &&
          _newPassword.text.isNotEmpty &&
          _confirmPassword.text.isNotEmpty;
      if (changePwd && _canChangePassword) {
        await u.updatePassword(_newPassword.text.trim());
      }

      final initial = _initial;
      if (initial == null) return;
      final normalizedDob = _normalizeDateForSave(_dob.text).trim();
      await updateUserProfile(
        uid: u.uid,
        data: ProfileUpdateData(
          name: _name.text,
          username: _username.text,
          phoneE164: normalizePhoneRuToE164(_phone.text),
          email: _email.text,
          dateOfBirth: normalizedDob.isEmpty ? null : normalizedDob,
          bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
          avatarFullJpeg: _avatar?.fullJpeg,
          avatarThumbPng: _avatar?.thumbPng,
        ),
        initial: ProfileUpdateData(
          name: initial.name,
          username: initial.username,
          phoneE164: normalizePhoneRuToE164(initial.phone),
          email: initial.email,
          dateOfBirth: _normalizeDateForSave(initial.dateOfBirth).trim().isEmpty
              ? null
              : _normalizeDateForSave(initial.dateOfBirth).trim(),
          bio: initial.bio.trim().isEmpty ? null : initial.bio.trim(),
          avatarFullJpeg: null,
          avatarThumbPng: null,
        ),
      );

      if (!mounted) return;
      _initial = _ProfileSnapshot(
        name: _name.text,
        username: _username.text,
        phone: _phone.text,
        email: _email.text,
        dateOfBirth: _dob.text,
        bio: _bio.text,
      );
      ref.invalidate(authUserProvider);
      ref.invalidate(registrationProfileStatusProvider(u.uid));
      final fresh = await FirebaseFirestore.instance
          .collection('users')
          .doc(u.uid)
          .get()
          .timeout(const Duration(seconds: 12));
      final d = fresh.data();
      final fullAfter = d != null ? _str(d['avatar']) : '';
      final thumbAfter = d != null ? _str(d['avatarThumb']) : '';
      if (!mounted) return;
      setState(() {
        _editing = false;
        _showPasswordSection = false;
        _newPassword.clear();
        _confirmPassword.clear();
        _avatar = null;
        _initialAvatarFullUrl = fullAfter.isNotEmpty ? fullAfter : null;
        _initialAvatarThumbUrl = thumbAfter.isNotEmpty ? thumbAfter : null;
      });
      FocusManager.instance.primaryFocus?.unfocus();
    } catch (e) {
      if (!mounted) return;
      if (e is RegistrationConflict) {
        setState(() => _error = e.message);
      } else {
        setState(() => _error = friendlyAuthError(e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profile_delete_account_confirm_title),
        content: Text(l10n.profile_delete_account_confirm_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.profile_delete_account_confirm_action),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AccountCallables().deleteAccount();
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      context.go('/auth');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = l10n.profile_delete_account_error(e.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? get _avatarUrlForSmallCircle {
    final t = _initialAvatarThumbUrl;
    if (t != null && t.isNotEmpty) return t;
    final f = _initialAvatarFullUrl;
    if (f != null && f.isNotEmpty) return f;
    return null;
  }

  void _openAvatarFullscreen() {
    final pending = _avatar;
    final fullUrl = _initialAvatarFullUrl?.trim();
    final thumbUrl = _initialAvatarThumbUrl?.trim();

    Uint8List? bytes;
    String? url;
    if (pending != null) {
      bytes = pending.fullJpeg.isNotEmpty
          ? pending.fullJpeg
          : pending.previewBytes;
    } else {
      url = (fullUrl != null && fullUrl.isNotEmpty)
          ? fullUrl
          : (thumbUrl != null && thumbUrl.isNotEmpty ? thumbUrl : null);
    }

    if (bytes == null && (url == null || url.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.profile_no_photo_to_view),
        ),
      );
      return;
    }
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (ctx) => UserAvatarFullscreenViewer(
            imageBytes: bytes,
            imageUrl: bytes != null ? null : url,
          ),
        ),
      ),
    );
  }

  Widget _buildCenteredAvatar(ThemeData theme, bool enabled) {
    const double side = 132;
    if (_editing) {
      return SizedBox(
        width: side,
        height: side,
        child: AvatarPickerCropper(
          enabled: enabled,
          compact: true,
          value: _avatar,
          initialImageUrl: _avatarUrlForSmallCircle,
          onChanged: (v) => setState(() => _avatar = v),
        ),
      );
    }
    return GestureDetector(
      onTap: _openAvatarFullscreen,
      child: SizedBox(
        width: side,
        height: side,
        child: ClipOval(
          child: ColoredBox(
            color: Colors.white.withValues(alpha: 0.06),
            child: _avatar != null
                ? Image.memory(
                    _avatar!.previewBytes,
                    fit: BoxFit.cover,
                    width: side,
                    height: side,
                  )
                : (_avatarUrlForSmallCircle != null &&
                      _avatarUrlForSmallCircle!.isNotEmpty)
                ? ChatCachedNetworkImage(
                    url: _avatarUrlForSmallCircle!,
                    fit: BoxFit.cover,
                    width: side,
                    height: side,
                    showProgressIndicator: false,
                  )
                : Icon(
                    Icons.person_outline_rounded,
                    size: 72,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final firebaseReady = ref.watch(firebaseReadyProvider);
    final enabled = firebaseReady && !_busy;
    final scheme = Theme.of(context).colorScheme;
    final titleColor = Colors.white.withValues(alpha: 0.95);
    final fieldLabelColor = Colors.white.withValues(alpha: 0.82);

    return FutureBuilder<void>(
      future: _bootstrap,
      builder: (context, snapshot) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            leadingWidth: 68,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Material(
                color: Colors.white.withValues(alpha: 0.08),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    if (context.canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      context.go('/account');
                    }
                  },
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 30,
                      color: Color(0xFFEAF2FF),
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              l10n.profile_title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            actions: [
              if (!_editing)
                IconButton(
                  tooltip: l10n.profile_edit_tooltip,
                  icon: const Icon(Icons.edit_outlined),
                  color: const Color(0xFFEAF2FF),
                  onPressed: () => setState(() => _editing = true),
                ),
            ],
          ),
          body: AuthBackground(
            child: snapshot.connectionState != ConnectionState.done
                ? const SafeArea(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
                      16,
                      28 + MediaQuery.paddingOf(context).bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: _buildCenteredAvatar(
                            Theme.of(context),
                            enabled,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _FieldLabel(
                          text: l10n.profile_full_name_label,
                          color: fieldLabelColor,
                        ),
                        const SizedBox(height: 10),
                        _ProfileInput(
                          controller: _name,
                          enabled: !_busy,
                          readOnly: !_editing,
                          hintText: l10n.profile_full_name_hint,
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 22),
                        _FieldLabel(
                          text: l10n.profile_username_label,
                          color: fieldLabelColor,
                        ),
                        const SizedBox(height: 10),
                        _ProfileInput(
                          controller: _username,
                          enabled: !_busy,
                          readOnly: !_editing,
                          hintText: l10n.profile_placeholder_username,
                          textCapitalization: TextCapitalization.none,
                        ),
                        const SizedBox(height: 22),
                        _FieldLabel(
                          text: l10n.profile_email_label,
                          color: fieldLabelColor,
                        ),
                        const SizedBox(height: 10),
                        _ProfileInput(
                          controller: _email,
                          enabled: !_busy,
                          readOnly: !_editing,
                          keyboardType: TextInputType.emailAddress,
                          hintText: l10n.profile_placeholder_email,
                          textCapitalization: TextCapitalization.none,
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FieldLabel(
                                    text: l10n.profile_phone_label,
                                    color: fieldLabelColor,
                                  ),
                                  const SizedBox(height: 10),
                                  _ProfileInput(
                                    controller: _phone,
                                    enabled: !_busy,
                                    readOnly: !_editing,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [PhoneRuMaskFormatter()],
                                    hintText: l10n.profile_placeholder_phone,
                                    textCapitalization: TextCapitalization.none,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FieldLabel(
                                    text: l10n.profile_birthdate_label,
                                    color: fieldLabelColor,
                                  ),
                                  const SizedBox(height: 10),
                                  _ProfileInput(
                                    controller: _dob,
                                    enabled: !_busy,
                                    readOnly: !_editing,
                                    hintText: l10n.profile_placeholder_birthdate,
                                    textCapitalization: TextCapitalization.none,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _FieldLabel(
                          text: l10n.profile_about_label,
                          color: fieldLabelColor,
                        ),
                        const SizedBox(height: 10),
                        _ProfileInput(
                          controller: _bio,
                          enabled: !_busy,
                          readOnly: !_editing,
                          hintText: l10n.profile_about_hint,
                          maxLines: 4,
                        ),
                        if (!_editing) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 54,
                            child: OutlinedButton(
                              onPressed: enabled ? _deleteAccount : null,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: scheme.error.withValues(alpha: 0.55),
                                ),
                                backgroundColor: scheme.error.withValues(
                                  alpha: 0.08,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!
                                    .profile_delete_account,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: scheme.error.withValues(alpha: 0.95),
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (_editing) ...[
                          const SizedBox(height: 22),
                          if (_canChangePassword) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: enabled
                                    ? () => setState(
                                          () => _showPasswordSection =
                                              !_showPasswordSection,
                                        )
                                    : null,
                                child: Text(
                                  _showPasswordSection
                                      ? l10n.profile_password_toggle_hide
                                      : l10n.profile_password_toggle_show,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4DA2FF),
                                  ),
                                ),
                              ),
                            ),
                            if (_showPasswordSection) ...[
                              const SizedBox(height: 8),
                              _FieldLabel(
                                text: l10n.profile_password_new_label,
                                color: fieldLabelColor,
                              ),
                              const SizedBox(height: 8),
                              _PasswordField(
                                controller: _newPassword,
                                enabled: enabled,
                                obscure: _obscureNew,
                                onToggleObscure: () => setState(
                                  () => _obscureNew = !_obscureNew,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _FieldLabel(
                                text: l10n.profile_password_confirm_label,
                                color: fieldLabelColor,
                              ),
                              const SizedBox(height: 8),
                              _PasswordField(
                                controller: _confirmPassword,
                                enabled: enabled,
                                obscure: _obscureConfirm,
                                onToggleObscure: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                              ),
                            ],
                          ] else ...[
                            if (_showPasswordSection)
                              const SizedBox.shrink(),
                          ],
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: TextStyle(
                              fontSize: 14,
                              color: scheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (_editing) ...[
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 54,
                                  child: OutlinedButton(
                                    onPressed: enabled ? _resetToInitial : null,
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.16,
                                        ),
                                      ),
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.04,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.common_cancel,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: titleColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: SizedBox(
                                  height: 54,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: enabled
                                          ? const LinearGradient(
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                              colors: [
                                                Color(0xFF2E86FF),
                                                Color(0xFF5F90FF),
                                                Color(0xFF9A18FF),
                                              ],
                                            )
                                          : LinearGradient(
                                              colors: [
                                                Colors.white.withValues(
                                                  alpha: 0.18,
                                                ),
                                                Colors.white.withValues(
                                                  alpha: 0.18,
                                                ),
                                              ],
                                            ),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: TextButton(
                                      onPressed: enabled ? _save : null,
                                      style: TextButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: _busy
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              l10n.common_save,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ),
        );
      },
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.enabled,
    required this.obscure,
    required this.onToggleObscure,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool obscure;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: controller,
      enabled: enabled,
      textCapitalization: TextCapitalization.none,
      obscureText: obscure,
      style: TextStyle(
        fontSize: 16,
        height: 1.25,
        color: Colors.white.withValues(alpha: 0.95),
      ),
      decoration: InputDecoration(
        hintText: l10n.profile_placeholder_password_dots,
        hintStyle: TextStyle(
          fontSize: 16,
          color: Colors.white.withValues(alpha: 0.34),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: const Color(0xFF4DA2FF).withValues(alpha: 0.8),
            width: 1.2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        suffixIcon: IconButton(
          tooltip: obscure
              ? AppLocalizations.of(context)!.profile_password_tooltip_show
              : AppLocalizations.of(context)!.profile_password_tooltip_hide,
          onPressed: enabled ? onToggleObscure : null,
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: color),
    );
  }
}

class _ProfileInput extends StatelessWidget {
  const _ProfileInput({
    required this.controller,
    required this.enabled,
    required this.readOnly,
    this.hintText,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.sentences,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool readOnly;
  final String? hintText;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      style: TextStyle(
        fontSize: 16,
        height: 1.25,
        color: Colors.white.withValues(alpha: 0.95),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 16,
          color: Colors.white.withValues(alpha: 0.34),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: const Color(0xFF4DA2FF).withValues(alpha: 0.8),
            width: 1.2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 14 : 16,
        ),
      ),
    );
  }
}
