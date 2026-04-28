import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

String _trimOrEmpty(Object? v) => (v is String) ? v.trim() : '';

({String a, String b})? _parseDmConversationId(String conversationId) {
  // Format: dm_<lenA>:<uidA>_<lenB>:<uidB>
  // Example:
  // dm_28:5edHR..._28:Uyhf...
  try {
    final raw = conversationId.trim();
    if (!raw.startsWith('dm_')) return null;
    final rest = raw.substring(3);
    final parts = rest.split('_');
    if (parts.length != 2) return null;
    String parsePart(String p) {
      final idx = p.indexOf(':');
      if (idx <= 0) return '';
      final len = int.tryParse(p.substring(0, idx)) ?? -1;
      final uid = p.substring(idx + 1);
      if (len <= 0) return '';
      // If malformed, still return uid; len is used only as a sanity check.
      if (uid.isEmpty) return '';
      return uid;
    }

    final a = parsePart(parts[0]);
    final b = parsePart(parts[1]);
    if (a.isEmpty || b.isEmpty) return null;
    return (a: a, b: b);
  } catch (_) {
    return null;
  }
}

String _jwtPayloadField(String token, String field) {
  try {
    final parts = token.split('.');
    if (parts.length < 2) return '';
    final payload = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(payload));
    final m = jsonDecode(decoded);
    if (m is Map && m[field] != null) return '${m[field]}';
    return '';
  } catch (_) {
    return '';
  }
}

/// Diagnostic logger for "permission-denied on chat open" cases.
///
/// Purpose: emit enough context to distinguish:
/// - wrong Firebase project (old build uses different plist/options),
/// - request.auth == null / stale token,
/// - token-sub mismatch (unexpected auth state).
Future<void> logChatOpenDiagnostics({
  required String stage,
  required String conversationId,
  Object? error,
  StackTrace? stackTrace,
  Logger? logger,
}) async {
  final log = logger ?? Logger();

  String projectId = '';
  String appId = '';
  try {
    final app = Firebase.app();
    projectId = app.options.projectId;
    appId = app.options.appId;
  } catch (_) {}

  final u = fb_auth.FirebaseAuth.instance.currentUser;
  final uid = u?.uid ?? '';
  String tokenSub = '';
  String tokenAud = '';
  String tokenExp = '';
  try {
    final tok = await u?.getIdToken(false);
    if (tok != null && tok.isNotEmpty) {
      tokenSub = _jwtPayloadField(tok, 'sub');
      tokenAud = _jwtPayloadField(tok, 'aud');
      tokenExp = _jwtPayloadField(tok, 'exp');
    }
  } catch (_) {}

  // Self-read probe: if this is denied too, the app is likely unauthenticated
  // from Firestore's perspective or pointing to another project.
  String selfUserChatsRead = 'skipped';
  if (uid.isNotEmpty) {
    try {
      await FirebaseFirestore.instance.collection('userChats').doc(uid).get();
      selfUserChatsRead = 'ok';
    } on FirebaseException catch (e) {
      selfUserChatsRead = 'firebase:${e.code}';
    } catch (_) {
      selfUserChatsRead = 'error';
    }
  }

  // Chat probes: determine whether the denial is due to membership index
  // or DM-hidden (outgoingBlocks marker).
  String convRead = 'skipped';
  String secretEnabled = 'unknown';
  String secretAccess = 'skipped';
  String memberDoc = 'skipped';
  String otherUid = '';
  String otherBlocksMe = 'skipped';
  String meBlocksOther = 'skipped';

  if (uid.isNotEmpty && conversationId.trim().isNotEmpty) {
    try {
      final convSnap = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .get();
      convRead = 'ok';
      final data = convSnap.data();
      if (data != null) {
        final sc = data['secretChat'];
        if (sc is Map) {
          final enabled = sc['enabled'];
          secretEnabled = enabled == true ? 'true' : 'false';
        } else {
          secretEnabled = 'absent';
        }
      }
    } on FirebaseException catch (e) {
      convRead = 'firebase:${e.code}';
    } catch (_) {
      convRead = 'error';
    }

    try {
      final m = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('members')
          .doc(uid)
          .get();
      memberDoc = m.exists ? 'exists' : 'missing';
    } on FirebaseException catch (e) {
      memberDoc = 'firebase:${e.code}';
    } catch (_) {
      memberDoc = 'error';
    }

    try {
      final a = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('secretAccess')
          .doc(uid)
          .get();
      secretAccess = a.exists ? 'exists' : 'missing';
    } on FirebaseException catch (e) {
      secretAccess = 'firebase:${e.code}';
    } catch (_) {
      secretAccess = 'error';
    }

    final pair = _parseDmConversationId(conversationId);
    if (pair != null) {
      otherUid = pair.a == uid ? pair.b : (pair.b == uid ? pair.a : '');
    }

    if (otherUid.isNotEmpty) {
      try {
        final d = await FirebaseFirestore.instance
            .collection('users')
            .doc(otherUid)
            .collection('outgoingBlocks')
            .doc(uid)
            .get();
        otherBlocksMe = d.exists ? 'exists' : 'missing';
      } on FirebaseException catch (e) {
        otherBlocksMe = 'firebase:${e.code}';
      } catch (_) {
        otherBlocksMe = 'error';
      }

      try {
        final d = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('outgoingBlocks')
            .doc(otherUid)
            .get();
        meBlocksOther = d.exists ? 'exists' : 'missing';
      } on FirebaseException catch (e) {
        meBlocksOther = 'firebase:${e.code}';
      } catch (_) {
        meBlocksOther = 'error';
      }
    }
  }

  log.w(
    'chat-open diagnostics stage=$stage conv=$conversationId '
    'projectId=$projectId appId=$appId uid=$uid tokenSub=$tokenSub '
    'tokenAud=$tokenAud tokenExp=$tokenExp selfUserChatsRead=$selfUserChatsRead '
    'convRead=$convRead secretEnabled=$secretEnabled secretAccess=$secretAccess memberDoc=$memberDoc otherUid=$otherUid '
    'otherBlocksMe=$otherBlocksMe meBlocksOther=$meBlocksOther',
    error: error,
    stackTrace: stackTrace,
  );

  // Ensure the message is visible in Xcode even if the `logger` backend
  // is filtered/disabled.
  // ignore: avoid_print
  print(
    'chat-open diagnostics stage=$stage conv=$conversationId '
    'projectId=$projectId appId=$appId uid=$uid tokenSub=$tokenSub '
    'tokenAud=$tokenAud tokenExp=$tokenExp selfUserChatsRead=$selfUserChatsRead '
    'convRead=$convRead secretEnabled=$secretEnabled secretAccess=$secretAccess memberDoc=$memberDoc otherUid=$otherUid '
    'otherBlocksMe=$otherBlocksMe meBlocksOther=$meBlocksOther '
    'error=${error.runtimeType}:${error ?? ''}',
  );
}

