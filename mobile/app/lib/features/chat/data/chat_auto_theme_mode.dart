import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import 'app_theme_preference.dart';

const Color kDefaultAppThemeSeed = Color(0xFF7C3AED);

class AppThemeResolution {
  const AppThemeResolution({required this.mode, required this.seedColor});

  final ThemeMode mode;
  final Color seedColor;
}

Future<AppThemeResolution> resolveAppThemeResolution({
  required AppThemePreference preference,
  required String? chatWallpaper,
}) async {
  switch (preference) {
    case AppThemePreference.light:
      return const AppThemeResolution(
        mode: ThemeMode.light,
        seedColor: kDefaultAppThemeSeed,
      );
    case AppThemePreference.dark:
      return const AppThemeResolution(
        mode: ThemeMode.dark,
        seedColor: kDefaultAppThemeSeed,
      );
    case AppThemePreference.chat:
      final accent = await _resolveWallpaperAccent(chatWallpaper);
      final lum = _relativeLuminance(accent.r, accent.g, accent.b);
      return AppThemeResolution(
        mode: lum > 0.52 ? ThemeMode.light : ThemeMode.dark,
        seedColor: Color.fromARGB(0xFF, accent.r, accent.g, accent.b),
      );
  }
}

class _Rgb {
  const _Rgb(this.r, this.g, this.b);
  final int r;
  final int g;
  final int b;
}

final Map<String, _Rgb> _wallpaperAccentCache = <String, _Rgb>{};

Future<_Rgb> _resolveWallpaperAccent(String? wallpaper) async {
  final raw = wallpaper?.trim() ?? '';
  if (raw.isEmpty) return _toRgb(kDefaultAppThemeSeed);

  final cached = _wallpaperAccentCache[raw];
  if (cached != null) return cached;

  _Rgb accent;
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    accent = await _sampleImageAverageRgb(raw) ?? _toRgb(kDefaultAppThemeSeed);
  } else {
    final rgbs = _extractGradientColors(raw);
    accent = rgbs.isEmpty ? _toRgb(kDefaultAppThemeSeed) : _averageRgb(rgbs);
  }
  _wallpaperAccentCache[raw] = accent;
  return accent;
}

_Rgb _toRgb(Color color) => _Rgb(
  (color.r * 255.0).round().clamp(0, 255),
  (color.g * 255.0).round().clamp(0, 255),
  (color.b * 255.0).round().clamp(0, 255),
);

List<_Rgb> _extractGradientColors(String raw) {
  final out = <_Rgb>[];
  final rgbReg = RegExp(
    r'rgb\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*\)',
    caseSensitive: false,
  );
  for (final m in rgbReg.allMatches(raw)) {
    final r = int.tryParse(m.group(1) ?? '');
    final g = int.tryParse(m.group(2) ?? '');
    final b = int.tryParse(m.group(3) ?? '');
    if (r == null || g == null || b == null) continue;
    out.add(_Rgb(_clamp8(r), _clamp8(g), _clamp8(b)));
  }
  if (out.isNotEmpty) return out;

  final hexReg = RegExp(r'#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})\b');
  for (final m in hexReg.allMatches(raw)) {
    final parsed = _parseHexToRgb(m.group(1) ?? '');
    if (parsed != null) out.add(parsed);
  }
  return out;
}

_Rgb? _parseHexToRgb(String hexRaw) {
  final hex = hexRaw.trim();
  if (hex.length == 3) {
    final r = int.tryParse('${hex[0]}${hex[0]}', radix: 16);
    final g = int.tryParse('${hex[1]}${hex[1]}', radix: 16);
    final b = int.tryParse('${hex[2]}${hex[2]}', radix: 16);
    if (r == null || g == null || b == null) return null;
    return _Rgb(r, g, b);
  }
  if (hex.length != 6) return null;
  final v = int.tryParse(hex, radix: 16);
  if (v == null) return null;
  return _Rgb((v >> 16) & 255, (v >> 8) & 255, v & 255);
}

_Rgb _averageRgb(List<_Rgb> values) {
  var sr = 0;
  var sg = 0;
  var sb = 0;
  for (final c in values) {
    sr += c.r;
    sg += c.g;
    sb += c.b;
  }
  final n = math.max(1, values.length);
  return _Rgb((sr / n).round(), (sg / n).round(), (sb / n).round());
}

double _relativeLuminance(int r, int g, int b) {
  double channel(int v) {
    final x = v / 255.0;
    return x <= 0.03928
        ? x / 12.92
        : math.pow((x + 0.055) / 1.055, 2.4) as double;
  }

  final rl = channel(r);
  final gl = channel(g);
  final bl = channel(b);
  return 0.2126 * rl + 0.7152 * gl + 0.0722 * bl;
}

int _clamp8(int v) => v.clamp(0, 255);

Future<_Rgb?> _sampleImageAverageRgb(String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    final image = img.decodeImage(response.bodyBytes);
    if (image == null) return null;
    final resized = img.copyResize(
      image,
      width: image.width > 48 ? 48 : image.width,
      height: image.height > 48 ? 48 : image.height,
    );
    final rgba = _toRgbaBytes(resized);
    if (rgba.isEmpty) return null;
    var sr = 0;
    var sg = 0;
    var sb = 0;
    var n = 0;
    for (var i = 0; i + 3 < rgba.length; i += 4) {
      sr += rgba[i];
      sg += rgba[i + 1];
      sb += rgba[i + 2];
      n++;
    }
    if (n <= 0) return null;
    return _Rgb((sr / n).round(), (sg / n).round(), (sb / n).round());
  } catch (_) {
    return null;
  }
}

Uint8List _toRgbaBytes(img.Image image) {
  return image.getBytes(order: img.ChannelOrder.rgba);
}
