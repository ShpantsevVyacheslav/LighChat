import 'package:flutter/widgets.dart';

/// Provides the effective chat wallpaper value to descendants.
///
/// This keeps UI elements (composer, deleted stubs, overlays) able to pick
/// readable foreground colors even when app theme is "light" but wallpaper is dark.
class ChatWallpaperScope extends InheritedWidget {
  const ChatWallpaperScope({
    super.key,
    required this.wallpaper,
    required super.child,
  });

  final String? wallpaper;

  static String? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ChatWallpaperScope>()?.wallpaper;
  }

  @override
  bool updateShouldNotify(ChatWallpaperScope oldWidget) {
    return oldWidget.wallpaper != wallpaper;
  }
}

