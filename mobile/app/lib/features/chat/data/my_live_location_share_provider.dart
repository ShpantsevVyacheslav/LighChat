import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lighchat_models/lighchat_models.dart';

/// Bug I: один поток `users/{currentUid}.liveLocationShare` для всего
/// приложения. chat_list_item читает его через `ref.watch` и
/// показывает индикатор только в той строке, где
/// `liveLocationShare.conversationId == conversation.id`. Так мы
/// держим одну Firestore-подписку на все N строк списка, а не N×.
final myLiveLocationShareProvider = StreamProvider<UserLiveLocationShare?>(
  (ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream<UserLiveLocationShare?>.value(null);
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      return UserLiveLocationShare.fromJson(data['liveLocationShare']);
    });
  },
);
