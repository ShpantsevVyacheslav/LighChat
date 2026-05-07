import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:lighchat_models/lighchat_models.dart';
import 'package:path_provider/path_provider.dart';

import 'chat_pdf_viewer_screen.dart';
import 'link_webview_screen.dart';

const MethodChannel _kDocumentPreviewChannel = MethodChannel(
  'lighchat/document_preview',
);

Future<bool> openChatDocumentAttachment(
  BuildContext context,
  ChatAttachment attachment,
) async {
  final rawUrl = attachment.url.trim();
  final uri = Uri.tryParse(rawUrl);
  if (uri == null) return false;

  if (Platform.isAndroid && isChatPdfPreviewCandidate(attachment)) {
    if (!context.mounted) return false;
    ChatPdfViewerScreen.open(
      context,
      uri: uri,
      title: _displayName(attachment, uri),
    );
    return true;
  }

  if (Platform.isIOS && isChatDocumentPreviewCandidate(attachment)) {
    try {
      final localPath = await _resolveLocalPathForPreview(uri, attachment);
      final title = _displayName(attachment, uri);
      final opened = await _kDocumentPreviewChannel.invokeMethod<bool>(
        'openFile',
        <String, Object?>{'path': localPath, 'title': title},
      );
      if (opened == true) return true;
    } catch (_) {
      // Fall through to generic in-app open path.
    }
  }

  if (uri.isScheme('http') || uri.isScheme('https')) {
    if (!context.mounted) return false;
    LinkWebViewScreen.open(context, uri.toString());
    return true;
  }

  return false;
}

bool isChatDocumentPreviewCandidate(ChatAttachment attachment) {
  final uri = Uri.tryParse(attachment.url.trim());
  if (uri == null) return false;
  return _looksLikeDocument(attachment, uri);
}

bool isChatPdfPreviewCandidate(ChatAttachment attachment) {
  final uri = Uri.tryParse(attachment.url.trim());
  if (uri == null) return false;
  final mime = (attachment.type ?? '').toLowerCase();
  if (mime == 'application/pdf') return true;
  final fromName = attachment.name.trim().toLowerCase();
  if (fromName.endsWith('.pdf')) return true;
  if (uri.pathSegments.isNotEmpty &&
      uri.pathSegments.last.toLowerCase().endsWith('.pdf')) {
    return true;
  }
  return false;
}

bool _looksLikeDocument(ChatAttachment a, Uri uri) {
  final mime = (a.type ?? '').toLowerCase();
  if (mime == 'application/pdf' || mime.startsWith('text/')) return true;
  if (mime.contains('msword') ||
      mime.contains('officedocument') ||
      mime.contains('rtf')) {
    return true;
  }
  final name = a.name.toLowerCase();
  if (_hasKnownDocExtension(name)) return true;
  final lastSegment = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
  return _hasKnownDocExtension(lastSegment.toLowerCase());
}

bool _hasKnownDocExtension(String name) {
  return name.endsWith('.pdf') ||
      name.endsWith('.txt') ||
      name.endsWith('.rtf') ||
      name.endsWith('.doc') ||
      name.endsWith('.docx') ||
      name.endsWith('.xls') ||
      name.endsWith('.xlsx') ||
      name.endsWith('.ppt') ||
      name.endsWith('.pptx');
}

String _displayName(ChatAttachment a, Uri uri) {
  final named = a.name.trim();
  if (named.isNotEmpty) return named;
  if (uri.pathSegments.isNotEmpty && uri.pathSegments.last.trim().isNotEmpty) {
    return uri.pathSegments.last.trim();
  }
  return 'document';
}

String _extensionFromName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  final q = trimmed.indexOf('?');
  final clean = q > -1 ? trimmed.substring(0, q) : trimmed;
  final dot = clean.lastIndexOf('.');
  if (dot <= 0 || dot >= clean.length - 1) return '';
  return clean.substring(dot).toLowerCase();
}

String _preferredExtension(ChatAttachment a, Uri uri) {
  final byName = _extensionFromName(a.name);
  if (byName.isNotEmpty) return byName;
  if (uri.pathSegments.isNotEmpty) {
    final byPath = _extensionFromName(uri.pathSegments.last);
    if (byPath.isNotEmpty) return byPath;
  }
  final mime = (a.type ?? '').toLowerCase();
  if (mime == 'application/pdf') return '.pdf';
  if (mime == 'text/plain') return '.txt';
  if (mime == 'text/rtf') return '.rtf';
  if (mime == 'application/msword') return '.doc';
  if (mime ==
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document') {
    return '.docx';
  }
  if (mime == 'application/vnd.ms-excel') return '.xls';
  if (mime ==
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') {
    return '.xlsx';
  }
  if (mime == 'application/vnd.ms-powerpoint') return '.ppt';
  if (mime ==
      'application/vnd.openxmlformats-officedocument.presentationml.presentation') {
    return '.pptx';
  }
  return '.bin';
}

Future<String> _resolveLocalPathForPreview(Uri uri, ChatAttachment a) async {
  if (uri.isScheme('file')) return uri.toFilePath();
  if (!uri.isScheme('http') && !uri.isScheme('https')) {
    throw StateError('Unsupported URI scheme for preview: ${uri.scheme}');
  }

  final ext = _preferredExtension(a, uri);
  final hash = md5.convert(utf8.encode(uri.toString())).toString();
  final tmp = await getTemporaryDirectory();
  final dir = Directory('${tmp.path}/chat_document_preview');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  final file = File('${dir.path}/$hash$ext');
  if (await file.exists()) return file.path;

  final response = await http.get(uri);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException(
      'Failed to download document: HTTP ${response.statusCode}',
      uri: uri,
    );
  }
  await file.writeAsBytes(response.bodyBytes, flush: true);
  return file.path;
}
