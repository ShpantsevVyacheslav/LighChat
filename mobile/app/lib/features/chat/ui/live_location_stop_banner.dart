import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../../../l10n/app_localizations.dart';
import '../data/live_location_utils.dart';

/// Полоса «идёт трансляция» + остановка (паритет `LiveLocationStopBanner.tsx`).
class LiveLocationStopBanner extends StatelessWidget {
  const LiveLocationStopBanner({super.key});

  Future<void> _stop(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update(
        <String, Object?>{'liveLocationShare': FieldValue.delete()},
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, Object?>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data == null) return const SizedBox.shrink();
        final data = snap.data!.data();
        final live = UserLiveLocationShare.fromJson(data?['liveLocationShare']);
        if (!isLiveShareVisible(live)) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF064E3B).withValues(alpha: 0.92),
              border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: const Color(0xFF6EE7B7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.live_location_sharing,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _stop(user.uid),
                    icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                    label: Text(
                      AppLocalizations.of(context)!.live_location_stop,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
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
