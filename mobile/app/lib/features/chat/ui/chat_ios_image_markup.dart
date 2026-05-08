import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

const MethodChannel _kIosImageMarkupChannel = MethodChannel(
  'lighchat/image_markup',
);

Future<XFile?> openIosNativeImageMarkup(XFile file) async {
  if (!Platform.isIOS) return null;
  final path = file.path.trim();
  if (path.isEmpty) return null;
  final source = File(path);
  if (!await source.exists()) return null;
  try {
    final editedPath = await _kIosImageMarkupChannel.invokeMethod<String>(
      'editImage',
      <String, Object?>{'path': path},
    );
    if (editedPath == null || editedPath.trim().isEmpty) return null;
    final output = File(editedPath.trim());
    if (!await output.exists()) return null;
    final mime = file.mimeType ?? 'image/jpeg';
    return XFile(output.path, mimeType: mime);
  } catch (_) {
    return null;
  }
}
