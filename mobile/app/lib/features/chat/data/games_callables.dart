import 'dart:io' show Platform;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:lighchat_firebase/src/firebase_callable_http.dart';

class CreateGameLobbyResult {
  const CreateGameLobbyResult({required this.gameId});
  final String gameId;
}

class CreateTournamentResult {
  const CreateTournamentResult({required this.tournamentId});
  final String tournamentId;
}

class CreateTournamentGameResult {
  const CreateTournamentGameResult({required this.tournamentId, required this.gameId});
  final String tournamentId;
  final String gameId;
}

class GamesCallables {
  GamesCallables({String region = 'us-central1'})
      : _functions = FirebaseFunctions.instanceFor(
          app: Firebase.app(),
          region: region,
        );

  final FirebaseFunctions _functions;

  Future<CreateTournamentResult> createDurakTournament({
    required String conversationId,
    String? title,
  }) async {
    final data = <String, dynamic>{
      'conversationId': conversationId,
      'title': title,
    };

    if (Platform.isIOS) {
      final raw = await callFirebaseCallableHttp(
        name: 'createDurakTournament',
        region: 'us-central1',
        data: data,
        timeout: const Duration(seconds: 20),
      );
      final m = raw is Map ? raw : const <Object?, Object?>{};
      final tournamentId = (m['tournamentId'] ?? '').toString().trim();
      return CreateTournamentResult(tournamentId: tournamentId);
    }

    final callable = _functions.httpsCallable(
      'createDurakTournament',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
    );
    final res = await callable.call<dynamic>(data);
    final raw = res.data;
    final m = raw is Map ? raw : const <Object?, Object?>{};
    final tournamentId = (m['tournamentId'] ?? '').toString().trim();
    return CreateTournamentResult(tournamentId: tournamentId);
  }

  Future<CreateTournamentGameResult> createTournamentDurakLobby({
    required String tournamentId,
    required Map<String, dynamic> settings,
  }) async {
    final data = <String, dynamic>{
      'tournamentId': tournamentId,
      'settings': settings,
    };

    if (Platform.isIOS) {
      final raw = await callFirebaseCallableHttp(
        name: 'createTournamentGameLobby',
        region: 'us-central1',
        data: data,
        timeout: const Duration(seconds: 20),
      );
      final m = raw is Map ? raw : const <Object?, Object?>{};
      final gameId = (m['gameId'] ?? '').toString().trim();
      final tid = (m['tournamentId'] ?? tournamentId).toString().trim();
      return CreateTournamentGameResult(tournamentId: tid, gameId: gameId);
    }

    final callable = _functions.httpsCallable(
      'createTournamentGameLobby',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
    );
    final res = await callable.call<dynamic>(data);
    final raw = res.data;
    final m = raw is Map ? raw : const <Object?, Object?>{};
    final gameId = (m['gameId'] ?? '').toString().trim();
    final tid = (m['tournamentId'] ?? tournamentId).toString().trim();
    return CreateTournamentGameResult(tournamentId: tid, gameId: gameId);
  }

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

  Future<void> cancelLobby({required String gameId}) async {
    final data = <String, dynamic>{'gameId': gameId};
    if (Platform.isIOS) {
      await callFirebaseCallableHttp(
        name: 'cancelGameLobby',
        region: 'us-central1',
        data: data,
        timeout: const Duration(seconds: 20),
      );
      return;
    }
    final callable = _functions.httpsCallable(
      'cancelGameLobby',
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

