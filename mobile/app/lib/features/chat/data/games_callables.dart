// ignore_for_file: implementation_imports

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
  const CreateTournamentGameResult({
    required this.tournamentId,
    required this.gameId,
  });
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
    int? totalGames,
  }) async {
    final data = <String, dynamic>{
      'conversationId': conversationId,
      'title': title,
      'totalGames': ?totalGames,
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

  Future<CreateGameLobbyResult> createDurakRematch({
    required String gameId,
  }) async {
    final data = <String, dynamic>{'gameId': gameId};
    if (Platform.isIOS) {
      final raw = await callFirebaseCallableHttp(
        name: 'createDurakRematch',
        region: 'us-central1',
        data: data,
        timeout: const Duration(seconds: 20),
      );
      final m = raw is Map ? raw : const <Object?, Object?>{};
      final nextGameId = (m['gameId'] ?? '').toString().trim();
      return CreateGameLobbyResult(gameId: nextGameId);
    }
    final callable = _functions.httpsCallable(
      'createDurakRematch',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
    );
    final res = await callable.call<dynamic>(data);
    final raw = res.data;
    final m = raw is Map ? raw : const <Object?, Object?>{};
    final nextGameId = (m['gameId'] ?? '').toString().trim();
    return CreateGameLobbyResult(gameId: nextGameId);
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

String friendlyGamesCallableError(Object error) {
  String code = '';
  String message = error.toString();
  int? statusCode;

  if (error is FirebaseFunctionsException) {
    code = error.code;
    message = error.message ?? error.details?.toString() ?? error.toString();
  } else if (error is FirebaseCallableHttpException) {
    code = error.code;
    message = error.message;
    statusCode = error.statusCode;
  }

  final marker = _extractRuleMarker(message);
  switch (marker) {
    case 'DEFENSE_DOES_NOT_BEAT':
      return 'Эта карта не бьет атакующую';
    case 'ONLY_ATTACKER_CAN_ATTACK_FIRST':
      return 'Первым ходит атакующий игрок';
    case 'DEFENDER_CANNOT_ATTACK':
      return 'Отбивающийся сейчас не подкидывает';
    case 'NOT_ALLOWED_TO_THROWIN':
      return 'Вы не можете подкинуть в этом раунде';
    case 'THROWIN_NOT_YOUR_TURN':
      return 'Сейчас подкидывает другой игрок';
    case 'RANK_NOT_ALLOWED':
      return 'Подкинуть можно только карту того же ранга';
    case 'CANNOT_THROW_IN':
      return 'Больше карт подкинуть нельзя';
    case 'CARD_NOT_IN_HAND':
      return 'Этой карты уже нет в руке';
    case 'ALREADY_DEFENDED':
      return 'Эта карта уже отбита';
    case 'BAD_ATTACK_INDEX':
      return 'Выберите атакующую карту для защиты';
    case 'ONLY_DEFENDER_CAN_DEFEND':
      return 'Сейчас отбивается другой игрок';
    case 'DEFENDER_ALREADY_TAKING':
      return 'Отбивающийся уже берет карты';
    case 'GAME_NOT_ACTIVE':
      return 'Партия уже не активна';
    case 'NOT_IN_LOBBY':
      return 'Лобби уже стартовало';
    case 'GAME_ALREADY_ACTIVE':
      return 'Партия уже началась';
    case 'ACTIVE_GAME_ALREADY_EXISTS':
      return 'В этом чате уже есть активная партия';
    case 'ROUND_RESOLUTION_PENDING':
      return 'Сначала завершите спорный ход';
    case 'REMATCH_FAILED_RETRY':
      return 'Не удалось подготовить реванш. Попробуйте еще раз';
  }

  if (code == 'unauthenticated') return 'Нужно войти в аккаунт';
  if (code == 'permission-denied') return 'Это действие вам недоступно';
  if (code == 'invalid-argument') return 'Некорректный ход';
  if (code == 'failed-precondition') return 'Ход сейчас недоступен';
  if (code == 'network' || code == 'timeout') return message;
  if (statusCode != null && statusCode >= 500) {
    return 'Не удалось выполнить ход. Попробуйте еще раз';
  }
  return message;
}

String _extractRuleMarker(String message) {
  final upper = message.toUpperCase();
  const markers = [
    'DEFENSE_DOES_NOT_BEAT',
    'ONLY_ATTACKER_CAN_ATTACK_FIRST',
    'DEFENDER_CANNOT_ATTACK',
    'NOT_ALLOWED_TO_THROWIN',
    'THROWIN_NOT_YOUR_TURN',
    'RANK_NOT_ALLOWED',
    'CANNOT_THROW_IN',
    'CARD_NOT_IN_HAND',
    'ALREADY_DEFENDED',
    'BAD_ATTACK_INDEX',
    'ONLY_DEFENDER_CAN_DEFEND',
    'DEFENDER_ALREADY_TAKING',
    'GAME_NOT_ACTIVE',
    'NOT_IN_LOBBY',
    'GAME_ALREADY_ACTIVE',
    'ACTIVE_GAME_ALREADY_EXISTS',
    'ROUND_RESOLUTION_PENDING',
    'REMATCH_FAILED_RETRY',
  ];
  for (final marker in markers) {
    if (upper.contains(marker)) return marker;
  }
  return '';
}
