import 'dart:io' show Platform;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:lighchat_firebase/src/firebase_callable_http.dart';

class CreateGameLobbyResult {
  const CreateGameLobbyResult({required this.gameId});
  final String gameId;
}

class GamesCallables {
  GamesCallables({String region = 'us-central1'})
      : _functions = FirebaseFunctions.instanceFor(
          app: Firebase.app(),
          region: region,
        );

  final FirebaseFunctions _functions;

  Future<CreateGameLobbyResult> createDurakLobby({
    required String conversationId,
    required Map<String, dynamic> settings,
  }) async {
    final data = <String, dynamic>{
      'conversationId': conversationId,
      'gameKey': 'durak',
      'settings': settings,
    };

    if (Platform.isIOS) {
      final raw = await callFirebaseCallableHttp(
        name: 'createGameLobby',
        region: 'us-central1',
        data: data,
        timeout: const Duration(seconds: 20),
      );
      final m = raw is Map ? raw : const <Object?, Object?>{};
      final gameId = (m['gameId'] ?? '').toString().trim();
      return CreateGameLobbyResult(gameId: gameId);
    }

    final callable = _functions.httpsCallable(
      'createGameLobby',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
    );
    final res = await callable.call<dynamic>(data);
    final raw = res.data;
    final m = raw is Map ? raw : const <Object?, Object?>{};
    final gameId = (m['gameId'] ?? '').toString().trim();
    return CreateGameLobbyResult(gameId: gameId);
  }

  Future<void> joinLobby({required String gameId}) async {
    final data = <String, dynamic>{'gameId': gameId};
    if (Platform.isIOS) {
      await callFirebaseCallableHttp(
        name: 'joinGameLobby',
        region: 'us-central1',
        data: data,
        timeout: const Duration(seconds: 20),
      );
      return;
    }
    final callable = _functions.httpsCallable(
      'joinGameLobby',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
    );
    await callable.call<dynamic>(data);
  }

  Future<void> startDurak({required String gameId}) async {
    final data = <String, dynamic>{'gameId': gameId};
    if (Platform.isIOS) {
      await callFirebaseCallableHttp(
        name: 'startDurakGame',
        region: 'us-central1',
        data: data,
        timeout: const Duration(seconds: 20),
      );
      return;
    }
    final callable = _functions.httpsCallable(
      'startDurakGame',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
    );
    await callable.call<dynamic>(data);
  }

  Future<void> makeDurakMove({
    required String gameId,
    required String clientMoveId,
    required String actionType,
    Map<String, dynamic>? payload,
  }) async {
    final data = <String, dynamic>{
      'gameId': gameId,
      'clientMoveId': clientMoveId,
      'actionType': actionType,
      'payload': payload,
    };
    if (Platform.isIOS) {
      await callFirebaseCallableHttp(
        name: 'makeDurakMove',
        region: 'us-central1',
        data: data,
        timeout: const Duration(seconds: 20),
      );
      return;
    }
    final callable = _functions.httpsCallable(
      'makeDurakMove',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
    );
    await callable.call<dynamic>(data);
  }
}

