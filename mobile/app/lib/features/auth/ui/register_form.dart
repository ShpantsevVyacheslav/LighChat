import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';

import 'package:lighchat_mobile/app_providers.dart';

import 'auth_validators.dart';
import 'avatar_picker_cropper.dart';
import 'auth_styles.dart';
import 'phone_ru_format.dart';

class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  bool _busy = false;
  String? _error;

  final _name = TextEditingController();
  final _username = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _dob = TextEditingController(); // yyyy-mm-dd
  final _bio = TextEditingController();

  AvatarResult? _avatar;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _dob.dispose();
    _bio.dispose();
    super.dispose();
  }

  String? _validateAll() {
    final e = <String?>[
      validateName(_name.text),
      validateUsername(_username.text),
      validatePhone11(_phone.text),
      validateEmail(_email.text),
      validatePassword(_password.text),
      validateConfirmPassword(_password.text, _confirm.text),
      validateDateOfBirth(_dob.text),
      validateBio(_bio.text),
    ].whereType<String>().toList();
    return e.isEmpty ? null : e.first;
  }

  Future<void> _submit() async {
    final svc = ref.read(registrationServiceProvider);
    if (svc == null) return;

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
          phone: normalizePhoneRuToE164(_phone.text),
          email: _email.text,
          password: _password.text,
          dateOfBirth: _dob.text.trim().isEmpty ? null : _dob.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final enabled = !_busy;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AvatarPickerCropper(enabled: enabled, onChanged: (v) => _avatar = v),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: authGlassInputDecoration(context, label: 'Имя'),
            enabled: enabled,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _username,
            decoration: authGlassInputDecoration(
              context,
              label: 'Логин (@username)',
            ),
            enabled: enabled,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
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
            controller: _password,
            obscureText: true,
            decoration: authGlassInputDecoration(
              context,
              label: 'Пароль',
              hint: '••••••••',
            ),
            enabled: enabled,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirm,
            obscureText: true,
            decoration: authGlassInputDecoration(
              context,
              label: 'Повтор пароля',
              hint: '••••••••',
            ),
            enabled: enabled,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dob,
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
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 8),
          FilledButton(
            style: authPrimaryButtonStyle(context),
            onPressed: enabled ? _submit : null,
            child: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Создать аккаунт'),
          ),
        ],
      ),
    );
  }
}
