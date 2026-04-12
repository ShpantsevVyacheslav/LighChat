import 'package:flutter/material.dart';

ShapeBorder chatGlassPopupMenuShape() => RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
    );

/// Тёмное меню как у шапки/стекла: светлый текст на тёмном фоне (не дефолтный M3 light menu).
Widget chatDarkPopupMenuScope(BuildContext context, Widget child) {
  final base = Theme.of(context);
  final itemStyle = TextStyle(
    color: Colors.white.withValues(alpha: 0.96),
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );
  return Theme(
    data: base.copyWith(
      popupMenuTheme: PopupMenuThemeData(
        shape: chatGlassPopupMenuShape(),
        color: Colors.black.withValues(alpha: 0.42),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.40),
        elevation: 14,
        textStyle: itemStyle,
      ),
      colorScheme: base.colorScheme.copyWith(
        onSurface: Colors.white.withValues(alpha: 0.96),
      ),
    ),
    child: child,
  );
}

TextStyle chatPopupMenuItemTextStyle() => TextStyle(
      color: Colors.white.withValues(alpha: 0.96),
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );
