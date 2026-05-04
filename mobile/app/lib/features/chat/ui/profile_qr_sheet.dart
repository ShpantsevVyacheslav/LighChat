import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../data/profile_qr_link.dart';
import 'chat_avatar.dart';

class ProfileQrSheet extends StatelessWidget {
  const ProfileQrSheet({
    super.key,
    required this.userId,
    required this.name,
    required this.username,
    this.avatarUrl,
    this.profileQrLink,
  });

  final String userId;
  final String name;
  final String username;
  final String? avatarUrl;
  final String? profileQrLink;

  static Future<void> show(
    BuildContext context, {
    required String userId,
    required String name,
    required String username,
    String? avatarUrl,
    String? profileQrLink,
  }) async {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ProfileQrSheet(
        userId: userId,
        name: name,
        username: username,
        avatarUrl: avatarUrl,
        profileQrLink: profileQrLink,
      ),
    );
  }

  String _resolvedPayload() {
    final explicit = (profileQrLink ?? '').trim();
    if (explicit.isNotEmpty) return explicit;
    return buildProfileQrPayload(userId: userId, username: username);
  }

  Future<void> _shareQr(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final payload = _resolvedPayload();
    if (payload.isEmpty) return;
    Rect? origin;
    final ro = context.findRenderObject();
    if (ro is RenderBox && ro.hasSize) {
      final p = ro.localToGlobal(Offset.zero);
      origin = p & ro.size;
    }
    final cleanUsername = username.trim().replaceFirst(RegExp(r'^@'), '');
    final label = cleanUsername.isEmpty ? name.trim() : '@$cleanUsername';
    final text = <String>[l10n.profile_qr_share_title, label, payload].join('\n');
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: l10n.profile_qr_share_subject,
        sharePositionOrigin: origin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final payload = _resolvedPayload();
    final cleanUsername = username.trim().replaceFirst(RegExp(r'^@'), '');
    final displayUsername = cleanUsername.isEmpty ? 'user' : cleanUsername;
    final displayName = name.trim().isEmpty ? l10n.profile_title : name.trim();

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        color: Color(0xFF12141C),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          20 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.profile_qr_title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.profile_qr_tooltip_close,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: 320,
              constraints: const BoxConstraints(maxWidth: 360),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(
                  children: [
                    ChatAvatar(
                      title: displayName,
                      avatarUrl: avatarUrl,
                      radius: 36,
                    ),
                    const SizedBox(height: 14),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F000000),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: 220,
                        height: 220,
                        child: payload.isEmpty
                            ? const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Color(0xFF2A79FF),
                                ),
                              )
                            : QrImageView(
                                data: payload,
                                version: QrVersions.auto,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Color(0xFF1B2743),
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Color(0xFF1F2954),
                                ),
                                embeddedImage: const AssetImage(
                                  'assets/lighchat_mark.png',
                                ),
                                embeddedImageStyle: const QrEmbeddedImageStyle(
                                  size: Size(40, 40),
                                ),
                                gapless: true,
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '@${displayUsername.toUpperCase()}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF1C2440),
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF2E86FF),
                      Color(0xFF5F90FF),
                      Color(0xFF9A18FF),
                    ],
                  ),
                ),
                child: TextButton.icon(
                  onPressed: payload.isEmpty
                      ? null
                      : () => unawaited(_shareQr(context)),
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.share_outlined),
                  label: Text(
                    AppLocalizations.of(context)!.profile_qr_share,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
