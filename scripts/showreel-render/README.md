# LighChat Showreel Renderer

Генерирует MP4-видео тура по фичам приложения с озвучкой.

## Что это
3-минутный showreel из 16 сцен с TTS-озвучкой (через macOS `say`), который рендерится из standalone HTML+CSS через Playwright и собирается в MP4 через ffmpeg.

## Зависимости
- macOS (use `say` для TTS)
- Node 18+
- ffmpeg в PATH (`brew install ffmpeg`)

## Использование

```bash
cd scripts/showreel-render
npm install                 # ~200 MB Chromium для Playwright
npx playwright install chromium
npm run render:ru           # → public/showreel/showreel-ru.mp4
npm run render:en           # → public/showreel/showreel-en.mp4
```

Каждый рендер занимает ~3.5 минуты (озвучка + воспроизведение + транскодинг).

## Что получается
- Размер: ~10–20 MB на язык, FullHD 1920×1080, h264 + AAC
- Длительность: ~3 минуты
- Озвучка: macOS-голос Milena (RU) / Samantha (EN). Для премиум-голоса установите Enhanced/Premium через System Settings → Accessibility → Spoken Content → Voices

## Куда подключить
После рендера выложи MP4 в Firebase Storage (например `gs://lighchat-prod.appspot.com/public/showreel/{ru,en}.mp4`), возьми public URL и передай в `<FeaturesShowreel videoSrc={url} />` (web). Если `videoSrc` задан, плеер играет видео; иначе fallback на текущий JS-рендер шоурила.

## Кастомизация
- Сцены и таймиги — в `voiceover.json` (text + durationMs) и `showreel-standalone.html` (`SCENES` массив)
- Голоса — в `voiceover.json` (`voice`, `rate`)
- Разрешение — флаг `--width=1280 --height=720` у `render.mjs`

## Известные ограничения
- macOS-only (использует `say`). На Linux замените на `espeak-ng` или платный API.
- Голоса compact-уровня. Для естественного звука — установите Premium-голоса (бесплатно, через System Settings) или замените `say` на ElevenLabs/OpenAI/Azure API.
- MP4 файлы НЕ коммитятся в git (см. `public/showreel/.gitignore`) — слишком большие.
