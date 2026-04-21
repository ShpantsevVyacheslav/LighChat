/// UI-level adapter над `tryAutoEnableE2eeNewDirectChatMobile` из
/// `lighchat_firebase`.
///
/// Зачем отдельный файл:
///  - держит политику чтения флагов (`platformSettings/main.e2eeDefaultForNewDirectChats`,
///    `users/{uid}.privacySettings.e2eeForNewDirectChats`) в одном месте;
///  - вызывающий UI-код после `createOrOpenDirectChat` просто делает
///    `await tryAutoEnableE2eeForMobileDm(...)` — и забывает про детали.
///
/// Ошибки никогда не всплывают наружу: при невозможности включить E2EE
/// (у собеседника нет ключа, таймаут Firestore и т.п.) — просто пишем в лог
/// и возвращаем false. Это паритет `tryAutoEnableE2eeNewDirectChat` на web,
/// который тоже молча `console.warn` и продолжает.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';

/// Читает настройки (платформа + пользователь) и если хоть одна требует
/// включения E2EE для новых DM — включает.
///
/// Возвращает `true`, если E2EE был включён в этом вызове. Никогда не бросает.
Future<bool> tryAutoEnableE2eeForMobileDm({
  required FirebaseFirestore firestore,
  required String conversationId,
  required String currentUserId,
}) async {
  try {
    final platformSnap = await firestore
        .collection('platformSettings')
        .doc('main')
        .get();
    final platformWants =
        platformSnap.data()?['e2eeDefaultForNewDirectChats'] == true;

    final userSnap =
        await firestore.collection('users').doc(currentUserId).get();
    final rawPrivacy = userSnap.data()?['privacySettings'];
    final userWants = rawPrivacy is Map
        ? rawPrivacy['e2eeForNewDirectChats'] == true
        : false;

    if (!platformWants && !userWants) return false;

    final identity = await getOrCreateMobileDeviceIdentity();
    return await tryAutoEnableE2eeNewDirectChatMobile(
      firestore: firestore,
      conversationId: conversationId,
      currentUserId: currentUserId,
      identity: identity,
      options: AutoEnableE2eeOptions(
        userWants: userWants,
        platformWants: platformWants,
      ),
    );
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[e2ee] auto-enable skipped: $e\n$st');
    }
    return false;
  }
}
