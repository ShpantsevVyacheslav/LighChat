import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'meeting_models.dart';

/// WebRTC-сигналинг через Firestore. Формат контрактов — §3 wire-protocol.
///
/// Принцип: получатель **удаляет** документ после применения, чтобы коллекция
/// не росла. Инициатор (меньший uid в паре) создаёт offer, инициатива на restart
/// — тоже на нём (см. `meeting_webrtc.dart`).
class MeetingSignaling {
  MeetingSignaling(this._firestore, this.meetingId, this.selfUid);

  final FirebaseFirestore _firestore;
  final String meetingId;
  final String selfUid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('meetings/$meetingId/signals');

  /// Поток сигналов, адресованных текущему пользователю.
  /// ВАЖНО: фильтр `to == selfUid` должен совпадать с правилом Firestore
  /// (`from == auth.uid || to == auth.uid`), иначе list-query упадёт по permissions.
  Stream<List<_SignalDocWithRef>> watchIncoming() {
    return _col.where('to', isEqualTo: selfUid).snapshots().map((snap) {
      final list = <_SignalDocWithRef>[];
      for (final change in snap.docChanges) {
        // Обрабатываем только 'added' — 'removed'/'modified' нас не интересуют
        // (мы сами удаляем документы после применения).
        if (change.type != DocumentChangeType.added) continue;
        final doc = change.doc;
        final parsed = MeetingSignalDoc.fromFirestore(doc.id, doc.data());
        if (parsed != null) list.add(_SignalDocWithRef(parsed, doc.reference));
      }
      return list;
    });
  }

  /// Отправить signal. `data` — payload, уже в wire-формате (§3 протокола).
  Future<void> send({
    required String to,
    required String type,
    required Map<String, dynamic> data,
  }) {
    return _col.add(<String, Object?>{
      'from': selfUid,
      'to': to,
      'type': type,
      'data': data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(DocumentReference<Map<String, dynamic>> ref) async {
    try {
      await ref.delete();
    } catch (_) {
      // Уже удалён — ок.
    }
  }
}

class _SignalDocWithRef {
  _SignalDocWithRef(this.doc, this.ref);
  final MeetingSignalDoc doc;
  final DocumentReference<Map<String, dynamic>> ref;
}

/// Экспортируем приватный класс наружу через typedef — оставляем API закрытым,
/// но доступным потребителю (WebRTC-контроллеру).
typedef IncomingSignal = _SignalDocWithRef;
