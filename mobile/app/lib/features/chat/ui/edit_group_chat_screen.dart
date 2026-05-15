import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'package:lighchat_mobile/app_providers.dart';

import 'chat_shell_backdrop.dart';
import 'group_chat_avatar_button.dart';
import 'profile_subpage_header.dart';
import '../../shared/ui/platform_keyboard_dismiss_behavior.dart';
import '../../../l10n/app_localizations.dart';

class EditGroupChatScreen extends ConsumerStatefulWidget {
  const EditGroupChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<EditGroupChatScreen> createState() =>
      _EditGroupChatScreenState();
}

class _EditGroupChatScreenState extends ConsumerState<EditGroupChatScreen> {
  static const _hPad = 18.0;

  final _name = TextEditingController();
  final _description = TextEditingController();

  Uint8List? _groupPhotoJpeg;
  bool _busy = false;
  String? _error;
  bool _initialized = false;

  // Privacy settings
  bool _forwardingAllowed = true;
  bool _screenshotsAllowed = true;
  bool _copyAllowed = true;
  bool _saveMediaAllowed = true;
  bool _shareMediaAllowed = true;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _closeScreen() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/chats');
    }
  }

  Widget _fieldLabel(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad, 0, _hPad, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface.withValues(alpha: 0.72),
        ),
      ),
    );
  }

  Widget _filledInput({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputAction action = TextInputAction.next,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fill = dark
        ? Colors.white.withValues(alpha: 0.09)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.85);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: fill,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: maxLines > 1 ? 12 : 4,
      ),
      child: TextField(
        controller: controller,
        onChanged: (_) => setState(() {}),
        maxLines: maxLines,
        textInputAction: action,
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(fontSize: 15, color: scheme.onSurface),
        cursorColor: scheme.primary,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 15,
            color: scheme.onSurface.withValues(alpha: 0.42),
          ),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _privacySwitch({
    required BuildContext context,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Цвета и форма — те же, что у [NotificationSettingsSwitchRow] в
          // экране «Уведомления»: единый язык для toggle'ов настроек.
          Switch.adaptive(
            value: value,
            onChanged: _busy ? null : onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF2F86FF),
            inactiveThumbColor: (dark ? Colors.white : scheme.surface)
                .withValues(alpha: dark ? 0.9 : 1),
            inactiveTrackColor: (dark ? Colors.white : scheme.onSurface)
                .withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ChatProfileSubpageHeader(
      title: l10n.edit_group_title,
      onBack: _closeScreen,
    );
  }

  Widget _bottomActions(BuildContext context, {required VoidCallback onSave}) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final barColor = dark
        ? const Color(0xFF04070C).withValues(alpha: 0.94)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.98);

    return DecoratedBox(
      decoration: BoxDecoration(color: barColor),
      child: Padding(
        padding: EdgeInsets.fromLTRB(_hPad, 12, _hPad, 12 + bottomInset),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _busy ? null : _closeScreen,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    foregroundColor: scheme.onSurface.withValues(alpha: 0.92),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.edit_group_cancel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: DecoratedBox(
                  // Тот же gradient, что у кнопки «Сохранить» в
                  // [profile_screen.dart] — единый visual-язык для primary
                  // CTA в edit-формах (профиль / группа).
                  decoration: BoxDecoration(
                    gradient: _busy
                        ? LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.18),
                              Colors.white.withValues(alpha: 0.18),
                            ],
                          )
                        : const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFF2E86FF),
                              Color(0xFF5F90FF),
                              Color(0xFF9A18FF),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextButton(
                    onPressed: _busy ? null : onSave,
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      foregroundColor: Colors.white,
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.edit_group_save,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit({required String uid}) async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(
        () => _error = AppLocalizations.of(
          context,
        )!.edit_group_error_name_required,
      );
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final updates = <String, dynamic>{
        'name': name,
        'description': _description.text.trim(),
        'forwardingAllowed': _forwardingAllowed,
        'screenshotsAllowed': _screenshotsAllowed,
        'copyAllowed': _copyAllowed,
        'saveMediaAllowed': _saveMediaAllowed,
        'shareMediaAllowed': _shareMediaAllowed,
      };

      // Upload avatar if changed
      if (_groupPhotoJpeg != null) {
        final storage = FirebaseStorage.instance;
        final photoRef = storage.ref().child(
          'group-avatars/${widget.conversationId}/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await photoRef.putData(_groupPhotoJpeg!);
        final downloadUrl = await photoRef.getDownloadURL();
        updates['photoUrl'] = downloadUrl;
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .update(updates);

      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.edit_group_success),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.edit_group_error_save_failed,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _initializeFields(Conversation conv) {
    if (_initialized) return;
    _name.text = conv.name ?? '';
    _description.text = conv.description ?? '';
    // Initialize privacy settings with defaults or existing values
    _forwardingAllowed = conv.forwardingAllowed ?? true;
    _screenshotsAllowed = conv.screenshotsAllowed ?? true;
    _copyAllowed = conv.copyAllowed ?? true;
    _saveMediaAllowed = conv.saveMediaAllowed ?? true;
    _shareMediaAllowed = conv.shareMediaAllowed ?? true;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authUserProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const ChatShellBackdrop(),
            SafeArea(
              child: userAsync.when(
                data: (u) {
                  if (u == null) {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => context.go('/auth'),
                    );
                    return const Center(child: CircularProgressIndicator());
                  }

                  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('conversations')
                        .doc(widget.conversationId)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snap.hasData || snap.data?.data() == null) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!.edit_group_error_not_found,
                          ),
                        );
                      }

                      final conv = Conversation.fromJson(
                        snap.data!.data() ?? const <String, dynamic>{},
                      );

                      // Инициализируем поля при первой загрузке
                      _initializeFields(conv);

                      // Проверяем, является ли пользователь администратором
                      final isAdmin =
                          conv.createdByUserId == u.uid ||
                          conv.adminIds.contains(u.uid);

                      if (!isAdmin) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!.edit_group_error_permission_denied,
                          ),
                        );
                      }

                      final l10n = AppLocalizations.of(context)!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _header(context),
                          Expanded(
                            child: ListView(
                              keyboardDismissBehavior:
                                  platformScrollKeyboardDismissBehavior(),
                              padding: const EdgeInsets.only(bottom: 16),
                              children: [
                                const SizedBox(height: 16),
                                Tooltip(
                                  message: l10n.edit_group_pick_photo_tooltip,
                                  child: GroupChatAvatarButton(
                                    enabled: !_busy,
                                    diameter: 112,
                                    placeholderIcon:
                                        Icons.people_outline_rounded,
                                    existingPhotoUrl: conv.photoUrl,
                                    showCaptionRow: false,
                                    onChanged: (v) =>
                                        setState(() => _groupPhotoJpeg = v),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                _fieldLabel(
                                  context,
                                  l10n.edit_group_name_label,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: _hPad,
                                  ),
                                  child: _filledInput(
                                    context: context,
                                    controller: _name,
                                    hint: l10n.edit_group_name_hint,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _fieldLabel(
                                  context,
                                  l10n.edit_group_description_label,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: _hPad,
                                  ),
                                  child: _filledInput(
                                    context: context,
                                    controller: _description,
                                    hint: l10n.edit_group_description_hint,
                                    maxLines: 3,
                                    action: TextInputAction.done,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _fieldLabel(
                                  context,
                                  l10n.edit_group_privacy_section,
                                ),
                                _privacySwitch(
                                  context: context,
                                  title: l10n.edit_group_privacy_forwarding,
                                  description:
                                      l10n.edit_group_privacy_forwarding_desc,
                                  value: _forwardingAllowed,
                                  onChanged: (v) =>
                                      setState(() => _forwardingAllowed = v),
                                ),
                                _privacySwitch(
                                  context: context,
                                  title: l10n.edit_group_privacy_screenshots,
                                  description:
                                      l10n.edit_group_privacy_screenshots_desc,
                                  value: _screenshotsAllowed,
                                  onChanged: (v) =>
                                      setState(() => _screenshotsAllowed = v),
                                ),
                                _privacySwitch(
                                  context: context,
                                  title: l10n.edit_group_privacy_copy,
                                  description:
                                      l10n.edit_group_privacy_copy_desc,
                                  value: _copyAllowed,
                                  onChanged: (v) =>
                                      setState(() => _copyAllowed = v),
                                ),
                                _privacySwitch(
                                  context: context,
                                  title: l10n.edit_group_privacy_save_media,
                                  description:
                                      l10n.edit_group_privacy_save_media_desc,
                                  value: _saveMediaAllowed,
                                  onChanged: (v) =>
                                      setState(() => _saveMediaAllowed = v),
                                ),
                                _privacySwitch(
                                  context: context,
                                  title: l10n.edit_group_privacy_share_media,
                                  description:
                                      l10n.edit_group_privacy_share_media_desc,
                                  value: _shareMediaAllowed,
                                  onChanged: (v) =>
                                      setState(() => _shareMediaAllowed = v),
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: _hPad,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.red.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        _error!,
                                        style: TextStyle(
                                          color: Colors.red.shade400,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          _bottomActions(
                            context,
                            onSave: () => _submit(uid: u.uid),
                          ),
                        ],
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(AppLocalizations.of(context)!.generic_error(err.toString())),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
