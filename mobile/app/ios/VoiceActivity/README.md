# Voice Live Activity — Widget Extension setup

Эта папка содержит исходники для Live Activity «Сейчас играет голосовое» в Dynamic Island / Lock Screen (iOS 16.1+).

## Что уже сделано в репо (готово к использованию):

- `Runner/Speech/VoiceActivityAttributes.swift` — Codable-структура состояния (общая для main app и widget). Уже в Runner target; виджет добавит её как второй target membership.
- `VoiceActivity/VoiceActivityWidget.swift` — SwiftUI-вьюшки Live Activity (Lock Screen banner + Dynamic Island в трёх режимах). Только widget target.
- `VoiceActivityBridge.swift` (в `Runner/Speech/`) — `MethodChannel('lighchat/live_activity')` для старта / апдейта / завершения активности из Flutter.
- `LiveActivityController.dart` — Dart-обёртка над каналом.
- `_VoiceJustAudioBar` уже вызывает старт/апдейт/конец автоматически при play/pause/dispose.
- В `Info.plist` главного приложения добавлен `NSSupportsLiveActivities = true`.

## Что нужно сделать вручную (3 клика, ~5 минут):

ActivityKit требует отдельный **Widget Extension target** — это нельзя добавить чисто через `project.pbxproj`-патч без поломки. Поэтому один разовый шаг:

### 1. Добавить Widget Extension target

1. Открой `mobile/app/ios/Runner.xcworkspace` в Xcode.
2. **File → New → Target…**
3. Выбери **Widget Extension** → **Next**.
4. Заполни:
   - **Product Name:** `VoiceActivity`
   - **Bundle Identifier:** `<твой главный bundle id>.VoiceActivity` (Xcode подставит автоматически).
   - **Language:** Swift
   - **Include Live Activity:** ✅ (важно!)
   - **Project:** Runner
   - **Embed in Application:** Runner
5. **Finish** → Activate scheme `VoiceActivity`? Не активируй (Cancel).
6. Xcode создаст папку `VoiceActivity/` с шаблоном — **удали все автогенерированные `.swift` файлы внутри неё**, кроме `Info.plist` и `Assets.xcassets`.
7. **Drag-and-drop** в эту папку файл `VoiceActivityWidget.swift` (он уже лежит здесь в репо) — Xcode предложит «Copy items if needed» → **не копируй**, оставь reference. Поставь Target Membership = **VoiceActivity**.
8. Файл `Runner/Speech/VoiceActivityAttributes.swift` уже скомпилирован в Runner. Открой его в Xcode (File Inspector справа), в секции **Target Membership** поставь галочку ещё и на **VoiceActivity**. Так одна и та же `ActivityAttributes`-структура попадёт в оба target-а.

### 2. Минимальный iOS target Widget Extension

В настройках target `VoiceActivity`:
- **Deployment Target:** iOS 16.1+ (минимум для ActivityKit).

### 3. Сборка

`flutter build ios` (или `flutter run`) — Xcode соберёт оба target-а, и Live Activity появится при следующем воспроизведении голосового сообщения.

## Проверка

1. Запустить приложение на физическом iPhone (Live Activity не работает в симуляторе).
2. Открыть чат, нажать play на голосовом сообщении.
3. Свайпнуть домой / заблокировать → в Dynamic Island / Lock Screen появится плашка «Сейчас играет голосовое от <Имя>» с прогрессом.
4. Тап → возврат в приложение.

## Если что-то пошло не так

- **«Live Activity не появляется»:** проверить что `NSSupportsLiveActivities = true` в Info.plist главного приложения + что юзер не отключил Live Activities для приложения в Settings → LighChat.
- **Build error «Cannot find type 'VoiceActivityAttributes'»:** не поставил Target Membership = **Runner** для `VoiceActivityAttributes.swift` (см. шаг 1.8).
- **Симулятор:** Live Activities только на физическом устройстве с iOS 16.1+.

## Зачем это нельзя автоматизировать

Widget Extension target требует:
- Отдельный bundle id с правильной структурой
- Embedded в main app target через Embed Foundation Extensions phase
- Свой `Info.plist` с особыми ключами (`NSExtension` block)
- Свой `entitlements` (для shared data) — не нужен для нашего случая
- Build settings, signing, schemes

Всё это Xcode умеет сделать одним кликом «New Target», но из bash/dart — это сотни строк сложного `.pbxproj`-патча, который очень легко сломать. Поэтому код готов на 100%, шаг в Xcode остаётся вручную.
