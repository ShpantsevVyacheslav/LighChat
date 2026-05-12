# Native navigation bar (UIKit / AppKit overlay)

## Что и зачем

Раньше навигация в mobile-приложении была полностью на Flutter-виджетах
(`ChatBottomNav`, `ChatHeader`, Material `AppBar`). Теперь на iOS и macOS
эти бары рисуются настоящими `UINavigationBar` / `UITabBar` /
`NSToolbar` через overlay поверх `FlutterViewController.view`. Цель —
получить нативный UX, scroll-edge effects и **Liquid Glass** на iOS 26+ /
macOS 26+ без переезда всей навигации в native-стек.

**Архитектура — overlay**, не host: GoRouter и весь Flutter-stack
остаются владельцем навигации. Native bar — это `UIView` (iOS) /
`NSToolbar` (macOS) поверх Flutter-канваса, конфигурируемый через
MethodChannel. На Android / Windows / Linux / Web — Material-фолбэк.

## Поддержка платформ

| Платформа | Native bar | Liquid Glass | Фолбэк |
|---|---|---|---|
| iOS 26+ | ✅ UINavigationBar + UITabBar | ✅ | — |
| iOS 15–25 | ✅ UINavigationBar + UITabBar | ❌ opaque background | — |
| macOS 26+ | ✅ NSToolbar | ✅ | — |
| macOS 11–25 | ✅ NSToolbar | ❌ | — |
| Android | ❌ | — | `AppBar` + `BottomNavigationBar` |
| Windows / Linux / Web | ❌ | — | `AppBar` + `BottomNavigationBar` |

iOS deployment target **остаётся iOS 15** — Liquid Glass подключается
через runtime-чек `@available(iOS 26.0, *)`. На старых OS бар выглядит
как стандартный непрозрачный UIKit.

## Контракт MethodChannel

Канал: `lighchat/native_nav`. Реализации:
- iOS: `mobile/app/ios/Runner/NavBarOverlay/NavBarBridge.swift` →
  `NavBarOverlayHost`
- macOS: `mobile/app/macos/Runner/NavBarOverlay/NavBarBridge.swift` →
  `NavBarToolbarHost`
- Flutter: `mobile/app/lib/platform/native_nav_bar/native_nav_bar_facade.dart`

### Методы (Flutter → native)

| Метод | Аргументы | Что делает |
|---|---|---|
| `setTopBar` | `NavBarTopConfig.toMap()` | Конфигурация верхней панели (title/leading/trailing/style/visibility) |
| `setBottomBar` | `NavBarBottomConfig.toMap()` | Конфигурация таб-бара (items/selectedId/visibility); macOS — no-op |
| `setSearchMode` | `NavBarSearchConfig.toMap()` | Переключение в режим поиска. На iOS — UISearchBar в `titleView` |
| `setSelectionMode` | `NavBarSelectionConfig.toMap()` | Режим выбора сообщений (counter + forward/delete actions) |
| `setScrollOffset` | `{contentOffset: double}` | Зарезервировано для scroll-edge tuning |

Все параметры см. в [nav_bar_config.dart](../../mobile/app/lib/platform/native_nav_bar/nav_bar_config.dart).
Иконки передаются как **SF Symbol** имена (`phone.fill`, `video.fill`,
`magnifyingglass`, `bubble.left.and.bubble.right` и т.д.). Для
Material-фолбэка маппинг SF Symbol → `IconData` лежит в
`native_nav_scaffold.dart::_materialIconFromSymbol`.

### События (native → Flutter)

EventChannel: `lighchat/native_nav/events`. Payload:
`{ type: String, payload: Map }`. Типы — см. `NavBarEvent` иерархия:

| Type | Payload | Когда |
|---|---|---|
| `leadingTap` | `{id}` | Кнопка слева (обычно `back`) |
| `actionTap` | `{id}` | Trailing action (search/call/video/threads/...) |
| `tabChange` | `{id}` | Пользователь переключил таб |
| `searchChange` | `{value}` | Изменился текст в UISearchBar |
| `searchSubmit` | `{value}` | Нажат Return в UISearchBar |
| `searchCancel` | `{}` | Кнопка Cancel в UISearchBar |

## Как мигрировать экран

### Простой экран (один title + back)

Заменить `Scaffold(appBar: AppBar(title: Text(...)))` на
`NativeNavScaffold`:

```dart
import 'package:lighchat_mobile/platform/native_nav_bar/nav_bar_config.dart';
import 'package:lighchat_mobile/platform/native_nav_bar/native_nav_scaffold.dart';

NativeNavScaffold(
  top: NavBarTopConfig(
    title: NavBarTitle(title: l10n.settings_language_title),
  ),
  onBack: () => Navigator.of(context).pop(),
  body: ListView(...),
);
```

На iOS/macOS бар нарисует UIKit/AppKit; на Android — обычный `AppBar`.

### Экран с trailing actions

```dart
NativeNavScaffold(
  top: NavBarTopConfig(
    title: NavBarTitle(title: l10n.archived_chats_title),
    trailing: [
      NavBarAction(
        id: 'clear',
        icon: const NavBarIcon('trash'),
        title: l10n.archived_clear_all,
      ),
    ],
  ),
  onAction: (id) {
    if (id == 'clear') _clearAll();
  },
  onBack: () => context.pop(),
  body: ...,
);
```

### Экран с собственной шапкой (ChatHeader / ChatBottomNav)

Эти виджеты сами детектят `NativeNavBarFacade.instance.isSupported` и:
- На iOS/macOS — пушат config в фасад и возвращают `SizedBox.shrink()`
- На Android — рисуют свой Flutter-виджет

То есть `chat_screen.dart` не меняется.

## Layout и safe area

`NavBarOverlayHost.attach(to:)` (iOS) добавляет `UINavigationBar` сверху
и `UITabBar` снизу как subview `FlutterViewController.view`, и
обновляет `additionalSafeAreaInsets` так, чтобы Flutter автоматически
получал правильные `MediaQuery.padding`. Flutter-контент не должен
вручную учитывать высоту bar.

На macOS `NavBarToolbarHost.attach(to:)` подключает `NSToolbar` к
основному `NSWindow` и выставляет `titlebarAppearsTransparent = true`.

## Liquid Glass

Изоляция от SDK: см. `mobile/app/ios/Runner/NavBarOverlay/LiquidGlassAppearance.swift`.
Метод `enableGlassEffectIfAvailable(on:)` пытается активировать новый
background-эффект через KVC — компилится на iOS 15 SDK, работает на
iOS 26+ устройствах. На старых OS — `configureWithDefaultBackground()`.

## Тестирование

- **iPhone 16 Pro / iOS 26**: убедиться, что nav bar и tab bar отрисованы
  с Liquid Glass; контент Flutter прокручивается под прозрачным баром.
- **iPhone 13 / iOS 18**: nav bar и tab bar отрисованы обычным
  непрозрачным UIKit; функциональность та же.
- **Android**: `ChatBottomNav` рисует свою pill-анимацию,
  `ChatHeader` — старый кастомный header. Никаких регрессий.
- **macOS desktop**: workspace-layout (`/workspace/*`) не затронут. На
  mobile-layout (если используется) — виден NSToolbar.

## Известные ограничения

- На iOS кастомные иконки таб-бара из Firestore (`bottomNavIconNames` /
  `bottomNavIconStyles`) пока маппятся в фиксированный набор SF Symbols.
  Полная поддержка пользовательских иконок (загрузка из ассетов) — отдельная задача.
- Pill-drag анимация ChatBottomNav теряется на iOS/macOS (заменена
  стандартной UIKit tab-switch анимацией). Это сознательный trade-off.
- macOS NSToolbar пока не поддерживает selection-mode (счётчик
  выделенных сообщений отображается, но без анимации перехода).

## Файлы

### Flutter
- `mobile/app/lib/platform/native_nav_bar/nav_bar_config.dart` — модели
- `mobile/app/lib/platform/native_nav_bar/native_nav_bar_facade.dart` — фасад
- `mobile/app/lib/platform/native_nav_bar/native_nav_scaffold.dart` — виджет

### iOS
- `mobile/app/ios/Runner/NavBarOverlay/NavBarOverlayHost.swift`
- `mobile/app/ios/Runner/NavBarOverlay/NavBarBridge.swift`
- `mobile/app/ios/Runner/NavBarOverlay/LiquidGlassAppearance.swift`
- `mobile/app/ios/Runner/AppDelegate.swift` — регистрация bridge
- `mobile/app/ios/Runner/SceneDelegate.swift` — attach overlay host

### macOS
- `mobile/app/macos/Runner/NavBarOverlay/NavBarToolbarHost.swift`
- `mobile/app/macos/Runner/NavBarOverlay/NavBarBridge.swift`
- `mobile/app/macos/Runner/MainFlutterWindow.swift` — регистрация bridge
