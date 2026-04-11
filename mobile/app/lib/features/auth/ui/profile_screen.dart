import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';

import 'package:lighchat_mobile/app_providers.dart';

import 'auth_styles.dart';
import 'auth_validators.dart';
import 'avatar_picker_cropper.dart';
import 'phone_ru_format.dart';
import '../../shared/ui/app_back_button.dart';

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
  String? _error;
  AvatarResult? _avatar;
  _ProfileSnapshot? _initial;

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

  String _str(Object? raw) {
    if (raw == null) return '';
    if (raw is String) return raw.trim();
    if (raw is num || raw is bool) return raw.toString().trim();
    return '';
  }

  Future<void> _bootstrapScreen() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

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
      _dob.text = _str(data['dateOfBirth']);
      _bio.text = _str(data['bio']);
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
    final errors = <String?>[
      validateName(_name.text),
      validateUsername(_username.text),
      validatePhone11(_phone.text),
      validateEmail(_email.text),
      validateDateOfBirth(_dob.text),
      validateBio(_bio.text),
    ].whereType<String>().toList();
    return errors.isEmpty ? null : errors.first;
  }

  void _reset() {
    final s = _initial;
    if (s == null) return;
    setState(() {
      _name.text = s.name;
      _username.text = s.username;
      _phone.text = s.phone;
      _email.text = s.email;
      _dob.text = s.dateOfBirth;
      _bio.text = s.bio;
      _avatar = null;
      _error = null;
    });
  }

  Future<void> _save() async {
    final svc = ref.read(registrationServiceProvider);
    final u = FirebaseAuth.instance.currentUser;
    if (svc == null || u == null) return;

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Профиль сохранен')));
    } catch (e) {
      if (e is RegistrationConflict) {
        setState(() => _error = e.message);
      } else {
        setState(() => _error = friendlyAuthError(e));
      }
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
            title: const Text('Мой профиль'),
          ),
          body: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AvatarPickerCropper(
                        enabled: enabled,
                        onChanged: (v) => _avatar = v,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _name,
                        decoration: authGlassInputDecoration(
                          context,
                          label: 'ФИО',
                        ),
                        enabled: enabled,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _username,
                        decoration: authGlassInputDecoration(
                          context,
                          label: 'Логин',
                        ),
                        enabled: enabled,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: authGlassInputDecoration(
                          context,
                          label: 'Email',
                        ),
                        enabled: enabled,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [PhoneRuMaskFormatter()],
                              decoration: authGlassInputDecoration(
                                context,
                                label: 'Телефон',
                              ),
                              enabled: enabled,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _dob,
                              decoration: authGlassInputDecoration(
                                context,
                                label: 'Дата рождения',
                              ),
                              enabled: enabled,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _bio,
                        maxLines: 4,
                        decoration: authGlassInputDecoration(
                          context,
                          label: 'О себе',
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: enabled ? _reset : null,
                              child: const Text('Отмена'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              style: authPrimaryButtonStyle(context),
                              onPressed: enabled ? _save : null,
                              child: _busy
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Сохранить'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
