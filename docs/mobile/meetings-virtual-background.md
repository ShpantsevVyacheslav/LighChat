# Виртуальный фон в mobile-митингах

Фичалка подключается **клиент-локально**: не влияет на wire-протокол и не требует
изменений в Firestore/Functions. Web-аналог уже работает через MediaPipe
Selfie-Segmentation + Canvas (`src/lib/webrtc/virtual-background.ts`).

Этот документ описывает:

1. Что и где должен делать мобильный клиент, чтобы выдать приемлемый FPS/CPU.
2. Какой интерфейс экспозит Dart-слой, чтобы UI и `MeetingWebRtc` не зависели
   от native-реализации.
3. Критерии оптимизации и принятия (acceptance).

## Архитектура

```
[Camera (AVCapture/CameraX)]
     ↓ raw frames (YUV_420)
[Selfie-Segmentation (Google ML Kit)]
     ↓ mask (CPU/GPU tensor)
[GPU compositor (Metal / OpenGL / SKSL)]
     ↓ RGBA frame с наложенным фоном/блюром
[flutter_webrtc CustomVideoCapturer]
     ↓ WebRTC wire
```

Native часть (iOS Swift + Android Kotlin) **обязательна**: перехват raw-кадров
нельзя сделать со стороны Dart без копирования в Flutter-heap, что убьёт FPS.

## Dart-интерфейс (СДЕЛАНО)

Готовые модули:

* `mobile/app/lib/features/meetings/data/virtual_background_controller.dart` —
  `VirtualBackgroundMode`, абстрактный `VirtualBackgroundController`,
  `NoopVirtualBackgroundController` (default, UI-кнопка скрыта, zero regression).
* `mobile/app/lib/features/meetings/data/virtual_background_platform.dart` —
  `MethodChannelVirtualBackgroundController` поверх канала
  `lighchat/virtual_background` (методы `setMode`, `dispose`).
* `virtualBackgroundControllerProvider` в `meeting_providers.dart` выбирает
  реализацию по compile-flag `--dart-define=LIGHCHAT_VIRTUAL_BG_NATIVE=true`.
* UI-кнопка в `meeting_controls.dart` показывается только если
  `controller.isPlatformBacked == true`.
* Подписка/цикл режимов в `meeting_room_screen.dart::_cycleVirtualBackground`.
* Unit-тесты `test/features/meetings/virtual_background_controller_test.dart`:
  state-машина, идемпотентность, обратная распаковка native-ошибки.

Контракт (финальный, native-код может подключаться без правок Dart/UI):

```dart
enum VirtualBackgroundMode { none, blur, image }

abstract class VirtualBackgroundController {
  VirtualBackgroundMode get currentMode;
  String? get currentImageAssetPath;
  Stream<VirtualBackgroundModeUpdate> get modeStream;
  bool get isPlatformBacked;
  Future<void> setMode(VirtualBackgroundMode mode, {String? imageAssetPath});
  Future<void> dispose();
}
```

## Native-бриджи (СКЕЛЕТ)

* Android: `android/app/src/main/kotlin/.../MainActivity.kt` — обработчик
  канала `lighchat/virtual_background`, принимает `setMode/dispose`, логирует,
  хранит состояние, **pixel-pipeline помечен TODO**.
* iOS: `ios/Runner/AppDelegate.swift::LighChatVirtualBackgroundBridge` —
  аналогично, `NSLog` + хранение состояния, **pipeline помечен TODO**.

## Что остаётся (native-PR, отдельно)

**iOS Swift**:

1. Создать `RTCVideoCapturer`-subclass (замена дефолтной
   `RTCCameraVideoCapturer`) либо обернуть исходящий `CMSampleBuffer` через
   `RTCVideoSource.capturer(_:didCapture:)`.
2. Применить ML Kit Selfie-Segmentation или Vision `VNGeneratePersonSegmentation`
   к текущему `CVPixelBuffer` (256×256 downsample, см. §«Оптимизации»).
3. Metal compute shader: blur или alpha-composite с кешированным
   `MTLTexture` фона.
4. Проброс готового `CVPixelBuffer` обратно в WebRTC.
5. Thermal throttling (`NSProcessInfo.thermalState`) + автопонижение в `.none`.

**Android Kotlin**:

1. Создать свой `VideoCapturer` (`CameraXCapturer` или обернуть дефолтный
   libwebrtc `Camera2Capturer`) и подключить `org.webrtc.VideoProcessor` через
   `VideoSource.setVideoProcessor(processor)`.
2. ML Kit Selfie-Segmentation `FAST` profile, 256×256 downsample.
3. GLES3 compositor: blur / image-composite.
4. Возврат `VideoFrame` в WebRTC capturer.
5. Thermal: Android `PowerManager.getCurrentThermalStatus()` (API 29+).

Интеграционная точка в Dart/UI после native-работы: **нет** — достаточно
запустить сборку с флагом `--dart-define=LIGHCHAT_VIRTUAL_BG_NATIVE=true`.

## Оптимизации

Критичные для FPS мобильного устройства (среднее железо — Snapdragon 730, A12):

1. **Downsample перед сегментацией**: mask считаем на 256×256 или 320×240 (не
   на полном кадре), потом масштабируем mask обратно через bilinear. ML Kit
   Selfie-Segmentation официально поддерживает 256×256 — профиль `FAST`.
2. **Adaptive FPS**: держим target 24 fps; если `frameCallback` отстаёт на
   >40 мс — пропускаем обработку кадра и отдаём исходный в WebRTC.
3. **Battery / Thermal throttling**: `ThermalManager` (Android API 29+) и
   `NSProcessInfo.thermalState` (iOS) — при `Warning`/`Serious` снижаем
   target fps до 15 и отключаем blur (оставляем только `.none`/`.image`).
4. **GPU композиция**: blur и alpha-composite — шейдерами (Metal-compute /
   GLES3), не через CoreImage/Canvas. Это даёт x3–x5 к CPU.
5. **Zero-copy**: на iOS `CVPixelBuffer` из `AVCaptureSession` кладём в
   `MTLTexture` напрямую через `CVMetalTextureCache`, на Android —
   `ImageReader` + `SurfaceTexture`, без промежуточных `ByteBuffer`.
6. **Асcеты для `image`**: фоновые картинки декодируем **один раз** при
   `setMode(.image, path)` в `MTLTexture`/`GL_TEXTURE_2D`, потом повторно
   используем — не читаем файл на каждый кадр.
7. **Кеш сегментации**: `mask` применяем к двум последовательным кадрам
   (motion-compensated) при падении FPS; это скрадывает отставание без
   визуального артефакта.

## Критерии приёмки

| Устройство          | Target FPS | CPU  | Energy (iOS) |
| ------------------- | ---------- | ---- | ------------ |
| iPhone 12           | ≥24        | ≤35% | Low/Medium   |
| Pixel 6             | ≥24        | ≤40% | —            |
| Snapdragon 730 (A52)| ≥18        | ≤55% | —            |

Дополнительно:

* нет заметного lag между движением головы и маской (<80 мс на flagship);
* при thermal Warning → авто-fallback в `.none`, уведомление UI-тостом;
* гостевой режим должен работать с отключённым фоном (по умолчанию `.none`),
  чтобы анонимная сессия не тратила батарею без согласия.

## Совместимость с web

Web уже использует MediaPipe — формат/алгоритм сегментации **не** совпадает с
ML Kit, но это не важно: фон рендерится локально, по сети уходит готовый
композит-видеотрек. Wire-формат (`MeetingSignalDoc`/`MeetingParticipant`) не
меняется.

## Статус

Готово (этот коммит):

* Dart-интерфейс `VirtualBackgroundController` + `NoopVirtualBackgroundController`.
* MethodChannel-реализация (`MethodChannelVirtualBackgroundController`).
* Провайдер + compile-flag `LIGHCHAT_VIRTUAL_BG_NATIVE`.
* UI-кнопка в `MeetingControls` (видима только при platform-backed).
* Цикл режимов в `MeetingRoomScreen._cycleVirtualBackground`.
* Native-бриджи iOS/Android (обработка `setMode/dispose`, логирование).
* Unit-тесты контроллера (7 кейсов, все зелёные).

Оставшиеся задачи (отдельные native-PR):

* iOS Swift: `CMSampleBuffer` → ML Kit / Vision segmentation → Metal compositor
  → `RTCVideoSource` (см. §«Что остаётся»).
* Android Kotlin: `VideoProcessor` → ML Kit → GLES3 compositor → libwebrtc
  `VideoSource` (см. §«Что остаётся»).
* Device-matrix benchmark в `integration_test/meetings_perf_test.dart`.
* Thermal-fallback на `.none` + toast.
