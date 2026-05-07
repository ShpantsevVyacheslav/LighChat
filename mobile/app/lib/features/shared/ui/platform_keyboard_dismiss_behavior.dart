import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/widgets.dart';

/// Android: избегаем `onDrag` из-за регрессии, при которой клавиатура
/// может сворачиваться во время ввода в `TextField`.
ScrollViewKeyboardDismissBehavior platformScrollKeyboardDismissBehavior() {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return ScrollViewKeyboardDismissBehavior.manual;
  }
  return ScrollViewKeyboardDismissBehavior.onDrag;
}
