/// Экран "Резервное копирование и передача ключа" (E2EE v2 Phase 6).
///
/// Объединяет два recovery-пути:
///  1. Password backup — зашифрованный приватник в
///     `users/{uid}/e2eeBackups/{deviceId}`. Полностью self-contained, не
///     требует дополнительных устройств.
///  2. QR-pairing (ссылка-строка) — показывает протокольный payload или
///     позволяет вручную вставить payload, полученный с другого устройства.
///     Полноценный QR-сканер/рендер будет отдельным деливери (нужен пакет
///     `qr_flutter` + `mobile_scanner`, добавление которых требует явного
///     согласования). Сейчас UX — «скопировать/вставить строку», протокол
///     остаётся тем же.
///
/// Паритет с web `src/lib/e2ee/v2/password-backup.ts` и `pairing-qr.ts` —
/// формат Firestore-документов совпадает бит-в-бит, поэтому backup,
/// созданный на web, читается на мобайле и наоборот.
library;

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:lighchat_mobile/app_providers.dart';

import '../../auth/ui/auth_glass.dart';
import '../../shared/ui/app_back_button.dart';
import '../../../l10n/app_localizations.dart';

class E2eeRecoveryScreen extends ConsumerStatefulWidget {
  const E2eeRecoveryScreen({super.key});

  @override
  ConsumerState<E2eeRecoveryScreen> createState() => _E2eeRecoveryScreenState();
}

class _E2eeRecoveryScreenState extends ConsumerState<E2eeRecoveryScreen> {
  MobileDeviceIdentityV2? _identity;
  bool _hasBackup = false;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final user = await ref.read(authUserProvider.future);
    if (user == null) return;
    try {
      final identity = await getOrCreateMobileDeviceIdentity();
      final has = await hasAnyMobilePasswordBackup(
        firestore: FirebaseFirestore.instance,
        userId: user.uid,
      );
      if (!mounted) return;
      setState(() {
        _identity = identity;
        _hasBackup = has;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  Future<String?> _promptPassword({
    required String title,
    required String confirmLabel,
    bool requireConfirmation = false,
  }) async {
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(title),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: c1,
                  obscureText: true,
                  textCapitalization: TextCapitalization.none,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l10n?.e2ee_password_label ?? 'Пароль',
                  ),
                  validator: (v) {
                    if ((v ?? '').length < e2eeBackupMinPasswordLength) {
                      return l10n?.e2ee_password_min_length(
                            e2eeBackupMinPasswordLength,
                          ) ??
                          'Минимум $e2eeBackupMinPasswordLength символов';
                    }
                    return null;
                  },
                ),
                if (requireConfirmation) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: c2,
                    obscureText: true,
                    textCapitalization: TextCapitalization.none,
                    decoration: InputDecoration(
                      labelText: l10n?.e2ee_password_confirm_label ??
                          'Повторите пароль',
                    ),
                    validator: (v) {
                      if (v != c1.text) {
                        return l10n?.e2ee_password_mismatch ??
                            'Пароли не совпадают';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(l10n?.common_cancel ?? 'Отмена'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  Navigator.of(ctx).pop(c1.text);
                }
              },
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result;
  }

  Future<void> _onCreateBackup() async {
    final user = await ref.read(authUserProvider.future);
    if (user == null) return;
    final identity = _identity;
    if (identity == null) return;
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final pwd = await _promptPassword(
      title: l10n?.e2ee_backup_create_title ?? 'Создать backup ключа',
      confirmLabel: l10n?.common_save ?? 'Сохранить',
      requireConfirmation: true,
    );
    if (pwd == null || pwd.isEmpty) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final pkcs8 = await identity.keyPair.exportPkcs8Private();
      await createMobilePasswordBackup(
        firestore: FirebaseFirestore.instance,
        userId: user.uid,
        backupId: identity.deviceId,
        password: pwd,
        privateKeyPkcs8: pkcs8,
      );
      if (!mounted) return;
      setState(() => _hasBackup = true);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n?.e2ee_backup_create_error(e) ?? 'Не удалось создать backup: $e',
          ),
        ),
      );
    }
  }

  Future<void> _onRestoreBackup() async {
    final user = await ref.read(authUserProvider.future);
    if (user == null) return;
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final pwd = await _promptPassword(
      title: l10n?.e2ee_backup_restore_title ?? 'Восстановить по паролю',
      confirmLabel: l10n?.e2ee_backup_restore_action ?? 'Восстановить',
    );
    if (pwd == null || pwd.isEmpty) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final restored = await restoreMobilePasswordBackup(
        firestore: FirebaseFirestore.instance,
        userId: user.uid,
        password: pwd,
      );
      // Перезаписываем приватник в secure-storage. Сразу после этого
      // `getOrCreateMobileDeviceIdentity` вернёт восстановленный ключ.
      await _replaceStoredIdentity(
        backupId: restored.backupId,
        privateKeyPkcs8: restored.privateKeyPkcs8,
      );
      if (!mounted) return;
      // Rebootstrap — подтягиваем новую identity.
      await _bootstrap();
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final msg = e.toString();
      final user = msg.contains('E2EE_BACKUP_WRONG_PASSWORD')
          ? (l10n?.e2ee_backup_wrong_password ?? 'Неверный пароль')
          : msg.contains('E2EE_BACKUP_NOT_FOUND')
              ? (l10n?.e2ee_backup_not_found ?? 'Backup не найден')
              : (l10n?.e2ee_backup_restore_error(e) ??
                  'Не удалось восстановить: $e');
      messenger.showSnackBar(SnackBar(content: Text(user)));
    }
  }

  /// Перезаписывает identity в secure-storage на ту, что была в backup.
  /// Важно: deviceId берём из backup (это deviceId устройства, которое backup
  /// создало) — так же на web, это поддерживает ротацию мульти-девайсов.
  Future<void> _replaceStoredIdentity({
    required String backupId,
    required Uint8List privateKeyPkcs8,
  }) async {
    final kp = await importPkcs8P256(pkcs8: privateKeyPkcs8);
    final pubSpki = await kp.exportSpkiPublic();
    // Напрямую через FlutterSecureStorage нельзя — ключи хранятся внутри
    // package `lighchat_firebase`. Делаем clear + свежая запись через
    // публичный API: clear → перезаписать вручную через тот же secure-storage.
    // Чтобы не раскрывать ключи наружу, добавляем функцию в `device_identity`.
    await replaceMobileDeviceIdentityFromBackup(
      deviceId: backupId,
      privateKeyPkcs8: privateKeyPkcs8,
      publicKeySpki: pubSpki,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                leading: const AppBackButton(fallbackLocation: '/settings/privacy'),
                title: Text(l10n?.e2ee_recovery_title ?? 'E2EE — резервирование'),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_loadError != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n?.e2ee_recovery_error_generic(_loadError!) ??
                            'Ошибка: $_loadError',
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 12),
                    _Card(
                      title: l10n?.e2ee_backup_password_card_title ??
                          'Backup паролем',
                      description: l10n?.e2ee_backup_password_card_description ??
                          'Создайте зашифрованный backup приватного ключа. '
                              'Если потеряете все устройства, сможете восстановить '
                              'его на новом, зная только пароль. '
                              'Пароль нельзя восстановить — записывайте надёжно.',
                      children: [
                        FilledButton.icon(
                          onPressed: _onCreateBackup,
                          icon: const Icon(Icons.lock_outline_rounded),
                          label: Text(
                            _hasBackup
                                ? (l10n?.e2ee_backup_overwrite ??
                                    'Перезаписать backup')
                                : (l10n?.e2ee_backup_create ?? 'Создать backup'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_hasBackup)
                          OutlinedButton.icon(
                            onPressed: _onRestoreBackup,
                            icon: const Icon(Icons.restore_rounded),
                            label: Text(
                              l10n?.e2ee_backup_restore ??
                                  'Восстановить из backup',
                            ),
                          ),
                        if (!_hasBackup)
                          OutlinedButton.icon(
                            onPressed: _onRestoreBackup,
                            icon: const Icon(Icons.restore_rounded),
                            label: Text(
                              l10n?.e2ee_backup_already_have ??
                                  'У меня уже есть backup',
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Card(
                      title: l10n?.e2ee_qr_transfer_title ??
                          'Передача ключа по QR',
                      description: l10n?.e2ee_qr_transfer_description ??
                          'На новом устройстве показываем QR, на старом сканируем камерой. '
                              'Сверяете 6-значный код — приватный ключ переносится безопасно.',
                      children: [
                        FilledButton.icon(
                          onPressed: () => context.push('/settings/e2ee-qr-pairing'),
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          label: Text(
                            l10n?.e2ee_qr_transfer_open ??
                                'Открыть QR-pairing',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.description,
    required this.children,
  });

  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

