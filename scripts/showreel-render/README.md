# LighChat Showreel Renderer

Генерирует MP4-видео тура по фичам приложения с озвучкой.

## Что это
3-минутный showreel из 16 сцен с TTS-озвучкой (ElevenLabs API), который
рендерится из standalone HTML+CSS через Playwright и собирается в MP4
через ffmpeg.

## Зависимости
- Node 18+ (нужен глобальный `fetch`)
- ffmpeg в PATH (`brew install ffmpeg`)
- ElevenLabs аккаунт + API-ключ
  ([Settings → API Keys](https://elevenlabs.io/app/settings/api-keys))
  - Free tier: 10 000 символов/мес. Наш showreel ~2 300 символов на язык,
    укладывается с запасом на 2 ре-рендера.

## Настройка ключа

```bash
cd scripts/showreel-render
cp .env.example .env.local
# Открыть .env.local и подставить свой ELEVENLABS_API_KEY
```

`.env.local` в git не попадает (см. `.gitignore`). Если ключа нет,
скрипт падает с понятной ошибкой при старте.

## Использование

```bash
cd scripts/showreel-render
npm install                 # ~200 MB Chromium для Playwright
npx playwright install chromium
npm run render:ru           # → public/showreel/showreel-ru.mp4
npm run render:en           # → public/showreel/showreel-en.mp4
```

Каждый рендер занимает ~3.5 минуты (TTS API + headless playback + ffmpeg
транскодинг). Retry с экспоненциальной задержкой включён на случай
сетевых блипов.

## Что получается
- Размер: ~14–18 MB на язык, FullHD 1920×1080, h264 + AAC
- Длительность: ~3 минуты
- Озвучка: ElevenLabs **Sarah** (`EXAVITQu4vr4xnSDxMaL`, multilingual_v2)
  для RU и **Alice** (`Xb7hH8MSUJpSbSDYk0k2`, multilingual_v2) для EN.
  Голоса выбраны как близкие к Apple-tour-нарратору: спокойный,
  профессиональный, тёплый.

## Куда подключить
После рендера выложите MP4 в Firebase Storage (например
`gs://lighchat-prod.appspot.com/public/showreel/{ru,en}.mp4`), возьмите
public URL и пропишите в env:

```
NEXT_PUBLIC_SHOWREEL_URL_RU=https://...
NEXT_PUBLIC_SHOWREEL_URL_EN=https://...
```

Плеер `<FeaturesShowreel>` сам подхватит — если URL есть, играет
нативное `<video>`; если нет, fallback на live scripted-плеер с
Web Speech API.

## Кастомизация
- Сцены и тайминги — в `voiceover.json` (`text` + `durationMs`) и
  `showreel-standalone.html` (`SCENES` массив).
- Голоса — в `voiceover.json` → `elevenlabs.voiceId`. Список доступных
  в вашем аккаунте: `GET https://api.elevenlabs.io/v1/voices`. Free
  tier позволяет вызывать только voices из `My Voices`, не из
  публичной Voice Library.
- Параметры голоса (stability, similarity_boost, style, speaker_boost) —
  там же.
- Разрешение — флаги `--width=1280 --height=720` у `render.mjs`.

## Известные ограничения
- ElevenLabs free tier не пускает к голосам из Voice Library — только к
  уже добавленным в `My Voices`. Если получаете HTTP 402 — перейдите в
  https://elevenlabs.io/app/voice-library, добавьте нужный голос
  кнопкой `Add`.
- MP4 файлы НЕ коммитятся в git (см. `public/showreel/.gitignore`) —
  слишком крупные. Складывайте в Firebase Storage / R2 / другой CDN.
- macOS не обязательна. Скрипт работает на любой системе с Node 18+
  и ffmpeg.
