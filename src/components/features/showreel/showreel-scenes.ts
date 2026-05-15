import type { ComponentType } from 'react';
import { MockEncryption } from '../illustrations/encryption';
import { MockSecretChats } from '../illustrations/secret-chats';
import { MockDisappearing } from '../illustrations/disappearing-messages';
import { MockScheduled } from '../illustrations/scheduled-messages';
import { MockGames } from '../illustrations/games';
import { MockMeetings } from '../illustrations/meetings';
import { MockCalls } from '../illustrations/calls';
import { MockFoldersThreads } from '../illustrations/folders-threads';
import { MockLiveLocation } from '../illustrations/live-location';
import { MockMultiDevice } from '../illustrations/multi-device';
import { MockStickersMedia } from '../illustrations/stickers-media';
import { MockPrivacy } from '../illustrations/privacy';
import { MockHero } from '../illustrations/hero';
import { MockAiSmartCompose } from '../illustrations/ai-smart-compose';
import { MockNavigatorPicker } from '../illustrations/navigator-picker';

/**
 * Сцена showreel: один мокап + воспроизводимый озвученный текст +
 * подпись поверх. Авто-переключение по `durationMs`.
 *
 * Тексты — две локали (ru/en) минимум; остальные локали при отсутствии
 * фолбэкают на `en`. Это не словарь приложения — это закадровый текст.
 */
export type ShowreelScene = {
  id: string;
  /** Главный визуал сцены (используем существующие живые мокапы). */
  Mock: ComponentType<{ className?: string; compact?: boolean }>;
  /** Длительность кадра в миллисекундах. */
  durationMs: number;
  /** Заголовок поверх сцены. */
  title: Record<'ru' | 'en', string>;
  /** Подзаголовок — он же субтитр и текст для TTS. */
  voiceover: Record<'ru' | 'en', string>;
  /** Цвет акцента — синхронизирован с features-data.ts. */
  accent: 'primary' | 'coral' | 'emerald' | 'violet' | 'amber';
};

/**
 * 16 сцен, в сумме ~178 секунд (≈ 2 минуты 58 секунд). Под лимит 3 минуты.
 * Тайминги учитывают, что комфортная TTS-скорость для русского ≈ 150 wpm.
 */
export const SHOWREEL_SCENES: ReadonlyArray<ShowreelScene> = [
  {
    id: 'intro',
    Mock: MockHero,
    durationMs: 8000,
    accent: 'primary',
    title: {
      ru: 'Знакомьтесь с LighChat',
      en: 'Meet LighChat',
    },
    voiceover: {
      ru: 'Это LighChat — мессенджер, который объединяет переписку, звонки, видеовстречи, игры и AI прямо на вашем устройстве.',
      en: 'Meet LighChat — a messenger that brings chat, calls, video meetings, games, and AI together right on your device.',
    },
  },
  {
    id: 'encryption',
    Mock: MockEncryption,
    durationMs: 14000,
    accent: 'emerald',
    title: {
      ru: 'Сквозное шифрование',
      en: 'End-to-end encryption',
    },
    voiceover: {
      ru: 'Включите сквозное шифрование — и сообщения видите только вы и собеседник. Сервер LighChat физически не может их прочитать. Сравните отпечатки ключей, чтобы убедиться: посередине нет третьего.',
      en: 'Turn on end-to-end encryption and only you and the recipient can read the messages. LighChat servers physically cannot decrypt them. Compare the key fingerprints to make sure no one is in the middle.',
    },
  },
  {
    id: 'secret-chats',
    Mock: MockSecretChats,
    durationMs: 14000,
    accent: 'violet',
    title: {
      ru: 'Секретные чаты',
      en: 'Secret chats',
    },
    voiceover: {
      ru: 'Секретные чаты живут по своим правилам. Сообщения исчезают по таймеру, пересылка запрещена, медиа открывается один раз. На чат можно поставить отдельный пароль или Face ID.',
      en: 'Secret chats play by stricter rules. Messages disappear on a timer, forwarding is blocked, media opens once, and the chat itself can be locked behind a separate password or Face ID.',
    },
  },
  {
    id: 'disappearing',
    Mock: MockDisappearing,
    durationMs: 12000,
    accent: 'coral',
    title: {
      ru: 'Исчезающие сообщения',
      en: 'Disappearing messages',
    },
    voiceover: {
      ru: 'Установите таймер — час, день, неделя или месяц — и сообщения исчезнут сами у всех участников. Никаких следов, никаких архивов.',
      en: 'Pick a timer — an hour, a day, a week or a month — and messages quietly vanish for everyone. No traces, no archives.',
    },
  },
  {
    id: 'scheduled',
    Mock: MockScheduled,
    durationMs: 12000,
    accent: 'primary',
    title: {
      ru: 'Отложенные сообщения',
      en: 'Scheduled messages',
    },
    voiceover: {
      ru: 'Напишите сейчас — отправится в нужное время. Сервер LighChat сам доставит сообщение, даже если телефон выключен.',
      en: 'Write now, deliver later. The LighChat server sends the message at the exact moment you picked — even when your phone is off.',
    },
  },
  {
    id: 'games',
    Mock: MockGames,
    durationMs: 12000,
    accent: 'amber',
    title: {
      ru: 'Игры в чате',
      en: 'Games in chat',
    },
    voiceover: {
      ru: 'Играйте в Дурака прямо в чате. Реальное время, красивые карты, без отдельного приложения. Зовите друзей — и партия начнётся за секунды.',
      en: 'Play Durak right inside the chat. Real-time matches, beautiful cards, no extra app needed. Invite friends and the deal begins in seconds.',
    },
  },
  {
    id: 'meetings',
    Mock: MockMeetings,
    durationMs: 14000,
    accent: 'primary',
    title: {
      ru: 'Видеовстречи',
      en: 'Video meetings',
    },
    voiceover: {
      ru: 'Полноценные видеоконференции с участниками, чатом, опросами и заявками на вход. Гости подключаются по ссылке без аккаунта, демонстрация экрана работает из коробки.',
      en: 'Full video conferences with participants, chat, polls and join requests. Guests join by link without an account; screen sharing works out of the box.',
    },
  },
  {
    id: 'calls',
    Mock: MockCalls,
    durationMs: 14000,
    accent: 'emerald',
    title: {
      ru: 'Звонки и видео-кружки',
      en: 'Calls and video circles',
    },
    voiceover: {
      ru: 'Стабильные 1:1 звонки на WebRTC. Или запишите короткий видео-кружок прямо в ленте чата — лицо, эмоция, голос за пару секунд.',
      en: 'Stable 1:1 WebRTC calls. Or drop a short video circle right in the chat feed — face, emotion, voice in a couple of seconds.',
    },
  },
  {
    id: 'folders',
    Mock: MockFoldersThreads,
    durationMs: 12000,
    accent: 'violet',
    title: {
      ru: 'Папки и треды',
      en: 'Folders and threads',
    },
    voiceover: {
      ru: 'Папки и треды. Раскладывайте чаты по полочкам, открывайте обсуждения веткой — сотни диалогов без хаоса.',
      en: 'Folders and threads. Sort chats into shelves and spin discussions into threads — hundreds of conversations without chaos.',
    },
  },
  {
    id: 'live-location',
    Mock: MockLiveLocation,
    durationMs: 12000,
    accent: 'coral',
    title: {
      ru: 'Прямая геолокация',
      en: 'Live location',
    },
    voiceover: {
      ru: 'Покажите, где вы сейчас. Собеседник видит вас в реальном времени, пока вы делитесь, и баннер всегда напоминает выключить трансляцию.',
      en: 'Share where you are right now. The other side sees you in real time, and a banner always reminds you to stop sharing.',
    },
  },
  {
    id: 'multi-device',
    Mock: MockMultiDevice,
    durationMs: 12000,
    accent: 'primary',
    title: {
      ru: 'Несколько устройств',
      en: 'Multiple devices',
    },
    voiceover: {
      ru: 'Подключайте телефон, планшет, веб и десктоп через QR. Резервная копия ключей с паролем переживёт даже потерю всех устройств.',
      en: 'Connect phone, tablet, web and desktop via QR pairing. A password-protected key backup survives even losing every old device.',
    },
  },
  {
    id: 'stickers',
    Mock: MockStickersMedia,
    durationMs: 10000,
    accent: 'amber',
    title: {
      ru: 'Стикеры и медиа',
      en: 'Stickers and media',
    },
    voiceover: {
      ru: 'Стикеры, GIF, опросы, встроенные редакторы фото и видео. Эмоции и медиа — без переключения приложений.',
      en: 'Stickers, GIFs, polls and built-in photo and video editors. Emotion and media — without switching apps.',
    },
  },
  {
    id: 'privacy',
    Mock: MockPrivacy,
    durationMs: 10000,
    accent: 'primary',
    title: {
      ru: 'Тонкая приватность',
      en: 'Fine-grained privacy',
    },
    voiceover: {
      ru: 'Каждая мелочь — отдельный переключатель. Решайте сами, что показывать другим: статус, последний визит, прочтение, дату рождения.',
      en: 'Every detail is its own toggle. You decide what others see: online status, last seen, read receipts, date of birth.',
    },
  },
  {
    id: 'ai-smart-compose',
    Mock: MockAiSmartCompose,
    durationMs: 14000,
    accent: 'violet',
    title: {
      ru: 'AI Smart Compose',
      en: 'AI Smart Compose',
    },
    voiceover: {
      ru: 'AI прямо на устройстве. Sparkle-иконка над инпутом перепишет ваше сообщение в одиннадцати стилях — от дружелюбного до делового. Всё на Apple Intelligence: ни одно слово не уходит в облако.',
      en: 'AI right on your device. The sparkle icon above the input rewrites your message in eleven styles — from friendly to formal. All powered by Apple Intelligence; not a single word leaves your phone.',
    },
  },
  {
    id: 'navigator-calendar',
    Mock: MockNavigatorPicker,
    durationMs: 12000,
    accent: 'emerald',
    title: {
      ru: 'Карты, такси и календарь',
      en: 'Maps, taxi and calendar',
    },
    voiceover: {
      ru: 'Локация открывается в Яндекс.Картах, Google Maps или вызывает такси одним тапом. Время и место — сразу в системный календарь.',
      en: 'Locations open in Yandex Maps, Google Maps, or hail a taxi in one tap. Time and place — straight into the system calendar.',
    },
  },
  {
    id: 'outro',
    Mock: MockHero,
    durationMs: 6000,
    accent: 'primary',
    title: {
      ru: 'Это лишь начало',
      en: 'This is just the start',
    },
    voiceover: {
      ru: 'Это лишь начало. Откройте LighChat — и узнайте остальное сами.',
      en: 'This is just the start. Open LighChat and discover the rest yourself.',
    },
  },
] as const;

export const SHOWREEL_TOTAL_MS = SHOWREEL_SCENES.reduce(
  (acc, s) => acc + s.durationMs,
  0,
);
