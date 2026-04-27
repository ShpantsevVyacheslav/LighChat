import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';

import 'package:lighchat_mobile/app_providers.dart';
import '../../../l10n/app_localizations.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  bool _busy = false;
  String? _error;
  bool _obscurePassword = true;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool get _emailGlow => _emailFocus.hasFocus || _email.text.trim().isNotEmpty;
  bool get _passwordGlow =>
      _passwordFocus.hasFocus || _password.text.trim().isNotEmpty;

  void _bindListeners() {
    _email.addListener(_rebuild);
    _password.addListener(_rebuild);
    _emailFocus.addListener(_rebuild);
    _passwordFocus.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _bindListeners();
  }

  @override
  void dispose() {
    _email.removeListener(_rebuild);
    _password.removeListener(_rebuild);
    _emailFocus.removeListener(_rebuild);
    _passwordFocus.removeListener(_rebuild);
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final repo = ref.read(authRepositoryProvider);
    if (repo == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repo.signInWithEmailPassword(
        email: _email.text,
        password: _password.text,
      );
      widget.onDone();
    } catch (e) {
      setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      final l10n = AppLocalizations.of(context);
      setState(
        () => _error =
            l10n?.auth_login_error_enter_email_for_reset ??
            'Введите email для восстановления пароля',
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyAuthError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final enabled = !_busy;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n?.auth_login_email_label ?? 'Email',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: (dark ? Colors.white : scheme.onSurface).withValues(
                alpha: 0.78,
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: _emailGlow
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2A79FF).withValues(alpha: 0.35),
                        blurRadius: 22,
                        spreadRadius: 0,
                      ),
                    ]
                  : const [],
            ),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutBack,
              scale: _emailFocus.hasFocus ? 1.008 : 1,
              child: TextField(
                controller: _email,
                focusNode: _emailFocus,
                textCapitalization: TextCapitalization.none,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(
                  color: dark ? Colors.white : scheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'email',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: (dark ? Colors.white : scheme.onSurface).withValues(
                      alpha: 0.44,
                    ),
                  ),
                  prefixIcon: Icon(
                    Icons.mail_outline_rounded,
                    color: (dark ? Colors.white : scheme.onSurface).withValues(
                      alpha: 0.56,
                    ),
                  ),
                  filled: true,
                  fillColor: dark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.76),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.13)
                          : Colors.black.withValues(alpha: 0.10),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.13)
                          : Colors.black.withValues(alpha: 0.10),
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(22)),
                    borderSide: BorderSide(
                      color: Color(0xFF2A79FF),
                      width: 1.4,
                    ),
                  ),
                ),
                enabled: enabled,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.auth_login_password_label ?? 'Пароль',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: (dark ? Colors.white : scheme.onSurface).withValues(
                alpha: 0.78,
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: _passwordGlow
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2A79FF).withValues(alpha: 0.24),
                        blurRadius: 18,
                        spreadRadius: 0,
                      ),
                    ]
                  : const [],
            ),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutBack,
              scale: _passwordFocus.hasFocus ? 1.008 : 1,
              child: TextField(
                controller: _password,
                focusNode: _passwordFocus,
                textCapitalization: TextCapitalization.none,
                obscureText: _obscurePassword,
                style: TextStyle(
                  color: dark ? Colors.white : scheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: l10n?.auth_login_password_hint ?? 'Пароль',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: (dark ? Colors.white : scheme.onSurface).withValues(
                      alpha: 0.44,
                    ),
                  ),
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                    color: (dark ? Colors.white : scheme.onSurface).withValues(
                      alpha: 0.56,
                    ),
                  ),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? (l10n?.profile_password_tooltip_show ??
                            'Показать пароль')
                        : (l10n?.profile_password_tooltip_hide ?? 'Скрыть'),
                    onPressed: enabled
                        ? () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          )
                        : null,
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: (dark ? Colors.white : scheme.onSurface).withValues(
                        alpha: 0.56,
                      ),
                    ),
                  ),
                  filled: true,
                  fillColor: dark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.76),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.13)
                          : Colors.black.withValues(alpha: 0.10),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.13)
                          : Colors.black.withValues(alpha: 0.10),
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(22)),
                    borderSide: BorderSide(
                      color: Color(0xFF2A79FF),
                      width: 1.4,
                    ),
                  ),
                ),
                enabled: enabled,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: enabled ? _forgotPassword : null,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF38A3FF),
              ),
              child: Text(
                l10n?.auth_login_forgot_password ?? 'Забыли пароль?',
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (_error != null)
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: enabled
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
              height: 56,
              child: TextButton(
                onPressed: enabled ? _submit : null,
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
                        l10n?.auth_login_sign_in ?? 'Войти',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
