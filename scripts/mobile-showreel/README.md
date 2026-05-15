# Mobile Showreel Recorder

Гибридный pipeline записи 3-минутного showreel-а по реальным экранам
LighChat на iPhone-симуляторе.

## Архитектура

- **`scenes.json`** — манифест из 16 сцен. Каждая помечена как:
  - `manual` (10 сцен) — пользователь руками снимает реальный экран
    приложения;
  - `mock` (6 сцен) — гейм/звонок/митинг невозможно записать без
    второго участника или живой камеры, оставляем mock из
    `mobile/app/lib/features/features_tour/ui/feature_mocks.dart`;
  - `auto` — стартовый/финальный кадр без действий.
- **`record.sh`** — оркестратор. Для каждой сцены показывает
  инструкции (что показать на экране), ждёт ENTER, стартует
  `xcrun simctl io recordVideo`, останавливает через
  `scene.durationMs`. Уже снятые клипы пропускает — `--retake NN`
  заставляет переснять.
- **`stitch.mjs`** — финализация. Нормализует каждый клип в 1080×1920
  @ 30fps, конкатит, накладывает озвучку из основного web-showreel
  (`scripts/showreel-render/`), выкладывает финал в
  `public/showreel/showreel-mobile-<lang>.mp4`.
- **`clips/`** — сюда падают сырые записи из simulator (создаётся
  автоматически, в git не идёт).
- **`.work/`** — временные файлы ffmpeg (создаётся автоматически,
  в git не идёт).

## Подготовка

1. **Озвучка должна быть готова** для нужного языка. Один из двух
   путей:

   - либо уже сделали full web render `node scripts/showreel-render/render.mjs --lang=ru`
     и mp4 лежит в `public/showreel/showreel-ru.mp4` (stitcher
     извлечёт оттуда дорожку);
   - либо есть «холодный» `voiceover.m4a` в
     `scripts/showreel-render/.work/<lang>/voiceover.m4a`.

2. **Тестовый аккаунт в Firebase**. На вашем simulator должен быть
   залогинен живой LighChat-юзер с парой подготовленных чатов:
   - обычный чат (с E2EE on/off)
   - secret chat (с TTL)
   - чат, где можно нажать «Add Location» (с включёнными location
     services в Simulator → Features → Location → Custom Location)
   - папки (создайте Personal/Groups через Edit Folders)

3. **iPhone 16 Pro симулятор**:
   ```bash
   xcrun simctl boot "iPhone 16 Pro"
   open -a Simulator
   ```
   После этого один раз установите приложение и залогиньтесь.

4. **ffmpeg** в `$PATH` (`brew install ffmpeg`).

## Использование

```bash
cd scripts/mobile-showreel

# Снять все 16 сцен по очереди (с пропусками уже снятых)
./record.sh

# Перезаснять отдельную сцену
./record.sh --retake 04        # по индексу
./record.sh --retake scheduled # по id

# Снять только одну сцену
./record.sh --only 12

# После того как все clips/*.mp4 готовы:
node stitch.mjs --lang=ru   # → public/showreel/showreel-mobile-ru.mp4
node stitch.mjs --lang=en
```

## Что показывать в каждой сцене

См. поле `hint` в `scenes.json`. Кратко:

| #  | id              | kind   | что показать на экране                        |
|----|-----------------|--------|----------------------------------------------|
| 00 | intro           | auto   | ChatListScreen (приложение только открылось) |
| 01 | encryption      | manual | E2EE-чат → header → fingerprint screen       |
| 02 | secret          | manual | Secret chat → settings → TTL/Lock/NoForward  |
| 03 | disappearing    | manual | Chat → menu → 'Исчезающие сообщения'         |
| 04 | scheduled       | manual | Composer → long-press send → schedule        |
| 05 | games           | mock   | в-app showreel proигрывает scene 'games'     |
| 06 | meetings        | mock   | в-app showreel scene 'meetings'              |
| 07 | calls           | mock   | в-app showreel scene 'calls'                 |
| 08 | folders         | manual | /chats со скроллом по папкам + Thread        |
| 09 | live-location   | manual | Chat → Attach → Live Location                |
| 10 | multi-device    | manual | /settings/devices → Add → QR pairing         |
| 11 | stickers        | manual | Composer → Sticker → 3 вкладки               |
| 12 | privacy         | manual | /settings/privacy → switches                 |
| 13 | ai              | manual | Composer → Smart Compose strip → стили       |
| 14 | navigator       | manual | Локация-сообщение → NavigatorPickerSheet     |
| 15 | outro           | auto   | Фейд-аут или splash                          |

## Производительность

- Запись одного клипа: ~`durationMs/1000` сек + 1-2 сек overhead на
  ffmpeg-старт/стоп. Всего ~3.5 минуты «чистого» времени записи.
- Нормализация (`stitch.mjs`): ~1 мин на 16 клипов.
- Mux + копирование: ~10 сек.
- Итого: ~5 минут от старта `record.sh` до готового mp4 — если все
  сцены пройдены с первого раза.

## Известные ограничения

- Записывает экран simulator со всеми его глюками (плавающие
  индикаторы Xcode, status bar). Минимизируется тем, что simulator
  отдаёт чистый кадр без чрома.
- `xcrun simctl io recordVideo` пишет в исходном разрешении устройства
  (например 1206×2622 для iPhone 16 Pro). Финальный 1080×1920
  получается через ffmpeg `scale + crop` — обрезается немного по
  бокам.
- Финальные `*.mp4` не коммитим (см. `public/showreel/.gitignore`).
- Звук simulator выбрасывается — наложить можно только заранее
  сгенерированный voiceover.m4a (см. шаг «Подготовка»).
