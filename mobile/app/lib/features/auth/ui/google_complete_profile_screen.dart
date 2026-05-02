import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';

import 'package:lighchat_mobile/app_providers.dart';

import '../../../l10n/app_localizations.dart';

import '../registration_profile_gate.dart'
    show
        RegistrationProfileStatus,
        getFirestoreRegistrationProfileStatusWithDeadline,
        kFirestoreRegistrationGetTimeout;
import 'auth_validators.dart';
import 'auth_brand_header.dart';
import 'avatar_picker_cropper.dart';
import 'auth_styles.dart';
import 'phone_ru_format.dart';
import '../../shared/ui/app_back_button.dart';

class GoogleCompleteProfileScreen extends ConsumerStatefulWidget {
  const GoogleCompleteProfileScreen({super.key});

  @override
  ConsumerState<GoogleCompleteProfileScreen> createState() =>
      _GoogleCompleteProfileScreenState();
}

class _GoogleCompleteProfileScreenState
    extends ConsumerState<GoogleCompleteProfileScreen> {
  bool _busy = false;
  String? _error;
  AvatarResult? _avatar;

  final _name = TextEditingController();
  final _username = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _dob = TextEditingController();
  final _bio = TextEditingController();

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
    super.dispose();
  }

  /// Уже полный профиль на сервере — уходим (паритет с web, без «вечной» анкеты из кэша).
  Future<void> _bootstrapScreen() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    final status = await getFirestoreRegistrationProfileStatusWithDeadline(u);
    if (status == RegistrationProfileStatus.complete) {
      if (mounted) context.go('/chats');
      return;
    }
    await _hydrateFromFirestore(u);
  }

  Future<void> _hydrateFromFirestore(User u) async {
    _email.text = u.email ?? _email.text;
    _name.text = (u.displayName ?? _name.text).trim();
    if (_username.text.isEmpty && u.email != null) {
      _username.text = u.email!.split('@').first;
    }

    final DocumentSnapshot<Map<String, dynamic>> snap;
    try {
      snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(u.uid)
          .get()
          .timeout(kFirestoreRegistrationGetTimeout);
    } on TimeoutException {
      return;
    }
    final data = snap.data();
    if (data == null) return;
    if (mounted) {
      setState(() {
        _name.text = (data['name'] as String?) ?? _name.text;
        _username.text = (data['username'] as String?) ?? _username.text;
        _phone.text = formatPhoneRuForDisplay(
          (data['phone'] as String?) ?? _phone.text,
        );
        _email.text = (data['email'] as String?) ?? _email.text;
        _dob.text = (data['dateOfBirth'] as String?) ?? _dob.text;
        _bio.text = (data['bio'] as String?) ?? _bio.text;
      });
    }
  }

  String? _validateAll() {
    final l10n = AppLocalizations.of(context)!;
    final e = <String?>[
      validateName(_name.text, l10n),
      validateUsername(_username.text, l10n),
      validatePhone11(_phone.text, l10n),
      validateEmail(_email.text, l10n),
      validateDateOfBirth(_dob.text, l10n),
      validateBio(_bio.text, l10n),
    ].whereType<String>().toList();
    return e.isEmpty ? null : e.first;
  }

  Future<void> _submit() async {
    final svc = ref.read(registrationServiceProvider);
    if (svc == null) return;
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

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
      await svc.completeGoogleProfile(
        uid: u.uid,
        data: GoogleProfileCompletionData(
          name: _name.text,
          username: _username.text,
          phone: normalizePhoneRuToE164(_phone.text),
          email: _email.text,
          dateOfBirth: _dob.text.trim().isEmpty ? null : _dob.text.trim(),
          bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
          avatarFullJpeg: _avatar?.fullJpeg,
          avatarThumbPng: _avatar?.thumbPng,
        ),
      );
      if (!mounted) return;
      ref.invalidate(registrationProfileCompleteProvider(u.uid));
      ref.invalidate(registrationProfileStatusProvider(u.uid));
      context.go('/chats');
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

  Future<void> _backToAuth() async {
    final repo = ref.read(authRepositoryProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (repo != null) {
        await repo.signOut();
      } else {
        await FirebaseAuth.instance.signOut();
      }
      if (!mounted) return;
      context.go('/auth');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseReady = ref.watch(firebaseReadyProvider);
    final enabled = firebaseReady && !_busy;
    return FutureBuilder<void>(
      future: _bootstrap,
      builder: (context, snapshot) {
        return Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(fallbackLocation: '/chats'),
            title: const Text('Завершите регистрацию'),
          ),
          body: SafeArea(
            child: snapshot.connectionState != ConnectionState.done
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: AuthBrandHeader()),
                        const SizedBox(height: 12),
                        const Text(
                          'После входа через Google нужно заполнить профиль, как в веб-версии.',
                        ),
                        const SizedBox(height: 12),
                        AvatarPickerCropper(
                          enabled: enabled,
                          onChanged: (v) => _avatar = v,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: authGlassInputDecoration(
                            context,
                            label: 'Имя',
                          ),
                          enabled: enabled,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _username,
                          textCapitalization: TextCapitalization.none,
                          decoration: authGlassInputDecoration(
                            context,
                            label: 'Логин (@username)',
                          ),
                          enabled: enabled,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phone,
                          textCapitalization: TextCapitalization.none,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [PhoneRuMaskFormatter()],
                          decoration: authGlassInputDecoration(
                            context,
                            label: 'Телефон (11 цифр)',
                          ),
                          enabled: enabled,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _email,
                          textCapitalization: TextCapitalization.none,
                          keyboardType: TextInputType.emailAddress,
                          decoration: authGlassInputDecoration(
                            context,
                            label: 'Email',
                            hint: 'you@example.com',
                          ),
                          enabled: enabled,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _dob,
                          textCapitalization: TextCapitalization.none,
                          decoration: authGlassInputDecoration(
                            context,
                            label: 'Дата рождения (YYYY-MM-DD, опционально)',
                          ),
                          enabled: enabled,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _bio,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: authGlassInputDecoration(
                            context,
                            label: 'О себе (до 200 символов, опционально)',
                          ),
                          enabled: enabled,
                        ),
                        const SizedBox(height: 12),
                        if (_error != null)
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: enabled ? _submit : null,
                          style: authPrimaryButtonStyle(context),
                          child: _busy
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Сохранить и продолжить'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: enabled ? _backToAuth : null,
                          child: const Text('Вернуться к авторизации'),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}
