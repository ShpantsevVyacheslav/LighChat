import 'package:flutter/widgets.dart';

import '../ui/feature_mocks.dart';

/// Сцена showreel в Flutter — параллель web `ShowreelScene`. Каждой сцене
/// соответствует один из mock-виджетов из `feature_mocks.dart`.
class ShowreelScene {
  const ShowreelScene({
    required this.id,
    required this.builder,
    required this.durationMs,
    required this.titleRu,
    required this.titleEn,
    required this.voiceoverRu,
    required this.voiceoverEn,
  });

  final String id;
  final WidgetBuilder builder;
  final int durationMs;
  final String titleRu;
  final String titleEn;
  final String voiceoverRu;
  final String voiceoverEn;

  String title(Locale locale) => locale.languageCode == 'en' ? titleEn : titleRu;
  String voiceover(Locale locale) =>
      locale.languageCode == 'en' ? voiceoverEn : voiceoverRu;
  String ttsLang(Locale locale) =>
      locale.languageCode == 'en' ? 'en-US' : 'ru-RU';
}

/// 16 сцен, ~178 секунд суммарно — то же расписание что и на web,
/// чтобы тур звучал и выглядел одинаково на обеих платформах.
final List<ShowreelScene> kShowreelScenes = [
  ShowreelScene(
    id: 'intro',
    builder: (_) => const MockEncryption(),
    durationMs: 8000,
    titleRu: 'Знакомьтесь с LighChat',
    titleEn: 'Meet LighChat',
    voiceoverRu:
        'Это LighChat — мессенджер, который объединяет переписку, звонки, видеовстречи, игры и AI прямо на вашем устройстве.',
    voiceoverEn:
        'Meet LighChat — a messenger that brings chat, calls, video meetings, games, and AI together right on your device.',
  ),
  ShowreelScene(
    id: 'encryption',
    builder: (_) => const MockEncryption(),
    durationMs: 14000,
    titleRu: 'Сквозное шифрование',
    titleEn: 'End-to-end encryption',
    voiceoverRu:
        'Включите сквозное шифрование — и сообщения видите только вы и собеседник. Сервер LighChat физически не может их прочитать. Сравните отпечатки ключей, чтобы убедиться: посередине нет третьего.',
    voiceoverEn:
        'Turn on end-to-end encryption and only you and the recipient can read the messages. LighChat servers physically cannot decrypt them. Compare the key fingerprints to make sure no one is in the middle.',
  ),
  ShowreelScene(
    id: 'secret-chats',
    builder: (_) => const MockSecretChats(),
    durationMs: 14000,
    titleRu: 'Секретные чаты',
    titleEn: 'Secret chats',
    voiceoverRu:
        'Секретные чаты живут по своим правилам. Сообщения исчезают по таймеру, пересылка запрещена, медиа открывается один раз. На чат можно поставить отдельный пароль или Face ID.',
    voiceoverEn:
        'Secret chats play by stricter rules. Messages disappear on a timer, forwarding is blocked, media opens once, and the chat itself can be locked behind a separate password or Face ID.',
  ),
  ShowreelScene(
    id: 'disappearing',
    builder: (_) => const MockDisappearing(),
    durationMs: 12000,
    titleRu: 'Исчезающие сообщения',
    titleEn: 'Disappearing messages',
    voiceoverRu:
        'Установите таймер — час, день, неделя или месяц — и сообщения исчезнут сами у всех участников. Никаких следов, никаких архивов.',
    voiceoverEn:
        'Pick a timer — an hour, a day, a week or a month — and messages quietly vanish for everyone. No traces, no archives.',
  ),
  ShowreelScene(
    id: 'scheduled',
    builder: (_) => const MockScheduled(),
    durationMs: 12000,
    titleRu: 'Отложенные сообщения',
    titleEn: 'Scheduled messages',
    voiceoverRu:
        'Напишите сейчас — отправится в нужное время. Сервер LighChat сам доставит сообщение, даже если телефон выключен.',
    voiceoverEn:
        'Write now, deliver later. The LighChat server sends the message at the exact moment you picked — even when your phone is off.',
  ),
  ShowreelScene(
    id: 'games',
    builder: (_) => const MockGames(),
    durationMs: 12000,
    titleRu: 'Игры в чате',
    titleEn: 'Games in chat',
    voiceoverRu:
        'Играйте в Дурака прямо в чате. Реальное время, красивые карты, без отдельного приложения. Зовите друзей — и партия начнётся за секунды.',
    voiceoverEn:
        'Play Durak right inside the chat. Real-time matches, beautiful cards, no extra app needed. Invite friends and the deal begins in seconds.',
  ),
  ShowreelScene(
    id: 'meetings',
    builder: (_) => const MockMeetings(),
    durationMs: 14000,
    titleRu: 'Видеовстречи',
    titleEn: 'Video meetings',
    voiceoverRu:
        'Полноценные видеоконференции с участниками, чатом, опросами и заявками на вход. Гости подключаются по ссылке без аккаунта, демонстрация экрана работает из коробки.',
    voiceoverEn:
        'Full video conferences with participants, chat, polls and join requests. Guests join by link without an account; screen sharing works out of the box.',
  ),
  ShowreelScene(
    id: 'calls',
    builder: (_) => const MockCalls(),
    durationMs: 14000,
    titleRu: 'Звонки и видео-кружки',
    titleEn: 'Calls and video circles',
    voiceoverRu:
        'Стабильные 1:1 звонки на WebRTC. Или запишите короткий видео-кружок прямо в ленте чата — лицо, эмоция, голос за пару секунд.',
    voiceoverEn:
        'Stable 1:1 WebRTC calls. Or drop a short video circle right in the chat feed — face, emotion, voice in a couple of seconds.',
  ),
  ShowreelScene(
    id: 'folders',
    builder: (_) => const MockFoldersThreads(),
    durationMs: 12000,
    titleRu: 'Папки и треды',
    titleEn: 'Folders and threads',
    voiceoverRu:
        'Папки и треды. Раскладывайте чаты по полочкам, открывайте обсуждения веткой — сотни диалогов без хаоса.',
    voiceoverEn:
        'Folders and threads. Sort chats into shelves and spin discussions into threads — hundreds of conversations without chaos.',
  ),
  ShowreelScene(
    id: 'live-location',
    builder: (_) => const MockLiveLocation(),
    durationMs: 12000,
    titleRu: 'Прямая геолокация',
    titleEn: 'Live location',
    voiceoverRu:
        'Покажите, где вы сейчас. Собеседник видит вас в реальном времени, пока вы делитесь, и баннер всегда напоминает выключить трансляцию.',
    voiceoverEn:
        'Share where you are right now. The other side sees you in real time, and a banner always reminds you to stop sharing.',
  ),
  ShowreelScene(
    id: 'multi-device',
    builder: (_) => const MockMultiDevice(),
    durationMs: 12000,
    titleRu: 'Несколько устройств',
    titleEn: 'Multiple devices',
    voiceoverRu:
        'Подключайте телефон, планшет, веб и десктоп через QR. Резервная копия ключей с паролем переживёт даже потерю всех устройств.',
    voiceoverEn:
        'Connect phone, tablet, web and desktop via QR pairing. A password-protected key backup survives even losing every old device.',
  ),
  ShowreelScene(
    id: 'stickers',
    builder: (_) => const MockStickersMedia(),
    durationMs: 10000,
    titleRu: 'Стикеры и медиа',
    titleEn: 'Stickers and media',
    voiceoverRu:
        'Стикеры, GIF, опросы, встроенные редакторы фото и видео. Эмоции и медиа — без переключения приложений.',
    voiceoverEn:
        'Stickers, GIFs, polls and built-in photo and video editors. Emotion and media — without switching apps.',
  ),
  ShowreelScene(
    id: 'privacy',
    builder: (_) => const MockPrivacy(),
    durationMs: 10000,
    titleRu: 'Тонкая приватность',
    titleEn: 'Fine-grained privacy',
    voiceoverRu:
        'Каждая мелочь — отдельный переключатель. Решайте сами, что показывать другим: статус, последний визит, прочтение, дату рождения.',
    voiceoverEn:
        'Every detail is its own toggle. You decide what others see: online status, last seen, read receipts, date of birth.',
  ),
  ShowreelScene(
    id: 'ai-smart-compose',
    // На mobile отдельного `MockAiSmartCompose` сейчас нет — пока показываем
    // disappearing-чат как нейтральный фон. Заменим в отдельном PR.
    builder: (_) => const MockDisappearing(),
    durationMs: 14000,
    titleRu: 'AI Smart Compose',
    titleEn: 'AI Smart Compose',
    voiceoverRu:
        'AI прямо на устройстве. Sparkle-иконка над инпутом перепишет ваше сообщение в одиннадцати стилях — от дружелюбного до делового. Всё на Apple Intelligence: ни одно слово не уходит в облако.',
    voiceoverEn:
        'AI right on your device. The sparkle icon above the input rewrites your message in eleven styles — from friendly to formal. All powered by Apple Intelligence; not a single word leaves your phone.',
  ),
  ShowreelScene(
    id: 'navigator-calendar',
    builder: (_) => const MockLiveLocation(),
    durationMs: 12000,
    titleRu: 'Карты, такси и календарь',
    titleEn: 'Maps, taxi and calendar',
    voiceoverRu:
        'Локация открывается в Яндекс.Картах, Google Maps или вызывает такси одним тапом. Время и место — сразу в системный календарь.',
    voiceoverEn:
        'Locations open in Yandex Maps, Google Maps, or hail a taxi in one tap. Time and place — straight into the system calendar.',
  ),
  ShowreelScene(
    id: 'outro',
    builder: (_) => const MockEncryption(),
    durationMs: 6000,
    titleRu: 'Это лишь начало',
    titleEn: 'This is just the start',
    voiceoverRu:
        'Это лишь начало. Откройте LighChat — и узнайте остальное сами.',
    voiceoverEn:
        'This is just the start. Open LighChat and discover the rest yourself.',
  ),
];

int showreelTotalMs() =>
    kShowreelScenes.fold<int>(0, (a, s) => a + s.durationMs);
