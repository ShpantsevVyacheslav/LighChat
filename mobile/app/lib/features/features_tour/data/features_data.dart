import 'package:flutter/material.dart';

/// Идентификаторы тем — параллельны web-варианту (`features-data.ts`).
enum FeatureTopicId {
  encryption,
  secretChats,
  disappearingMessages,
  scheduledMessages,
  games,
  meetings,
  calls,
  foldersThreads,
  liveLocation,
  multiDevice,
  stickersMedia,
  privacy,
}

extension FeatureTopicIdSlug on FeatureTopicId {
  String get slug {
    switch (this) {
      case FeatureTopicId.encryption:
        return 'encryption';
      case FeatureTopicId.secretChats:
        return 'secret-chats';
      case FeatureTopicId.disappearingMessages:
        return 'disappearing-messages';
      case FeatureTopicId.scheduledMessages:
        return 'scheduled-messages';
      case FeatureTopicId.games:
        return 'games';
      case FeatureTopicId.meetings:
        return 'meetings';
      case FeatureTopicId.calls:
        return 'calls';
      case FeatureTopicId.foldersThreads:
        return 'folders-threads';
      case FeatureTopicId.liveLocation:
        return 'live-location';
      case FeatureTopicId.multiDevice:
        return 'multi-device';
      case FeatureTopicId.stickersMedia:
        return 'stickers-media';
      case FeatureTopicId.privacy:
        return 'privacy';
    }
  }
}

FeatureTopicId? featureTopicIdFromSlug(String slug) {
  for (final id in FeatureTopicId.values) {
    if (id.slug == slug) return id;
  }
  return null;
}

class FeatureSection {
  const FeatureSection({required this.title, required this.body, this.bullets = const []});
  final String title;
  final String body;
  final List<String> bullets;
}

class FeatureTopicContent {
  const FeatureTopicContent({
    required this.title,
    required this.tagline,
    required this.summary,
    required this.ctaLabel,
    required this.sections,
    required this.howTo,
  });
  final String title;
  final String tagline;
  final String summary;
  final String ctaLabel;
  final List<FeatureSection> sections;
  final List<String> howTo;
}

/// Тексты, которые попадают внутрь иллюстраций (имена, статусы, реплики).
class FeaturesMockText {
  const FeaturesMockText({
    required this.e2eeBadge,
    required this.peerAlice,
    required this.peerBob,
    required this.peerHello,
    required this.fingerprintMatch,
    required this.groupProject,
    required this.secretStatus,
    required this.secretMsg1,
    required this.secretMsg2,
    required this.teamDesign,
    required this.disappearingStatus,
    required this.disappearingMsg1,
    required this.disappearingMsg2,
    required this.disappearingMsg3,
    required this.disappearingMsg4,
    required this.peerMikhail,
    required this.mikhailStatus,
    required this.scheduledMsg1,
    required this.scheduledMsg2,
    required this.scheduledMsg3,
    required this.scheduledQueueTitle,
    required this.scheduledQueueDate,
    required this.gamesBadge,
    required this.gamesTrump,
    required this.gamesDeck,
    required this.gamesYou,
    required this.gamesOpponent,
    required this.gamesYourTurn,
    required this.gamesActionBeat,
    required this.gamesActionTake,
    required this.meetingDuration,
    required this.meetingSpeaking,
    required this.callsAudioTitle,
    required this.callsAudioMeta,
    required this.callsCircleTitle,
    required this.callsCircleMeta,
    required this.folderAll,
    required this.folderWork,
    required this.folderFamily,
    required this.folderStudy,
    required this.folderStarred,
    required this.folderWorkChats,
    required this.chat1Name,
    required this.chat1Last,
    required this.chat2Name,
    required this.chat2Last,
    required this.chat3Name,
    required this.chat3Last,
    required this.threadTitle,
    required this.threadReply1,
    required this.threadReply2,
    required this.liveLocationBanner,
    required this.liveLocationStop,
    required this.multiDevicePhone,
    required this.multiDeviceDesktop,
    required this.multiDevicePairing,
    required this.multiDeviceBackup,
    required this.multiDeviceBackupSub,
    required this.stickerSearchHint,
    required this.pollTitle,
    required this.pollOption1,
    required this.pollOption2,
    required this.editorLabel,
    required this.editorHint,
    required this.privacyTitle,
    required this.privacySubtitle,
    required this.privacyOnline,
    required this.privacyOnlineHint,
    required this.privacyLastSeen,
    required this.privacyLastSeenHint,
    required this.privacyReceipts,
    required this.privacyReceiptsHint,
    required this.privacyGlobalSearch,
    required this.privacyGlobalSearchHint,
    required this.privacyGroupAdd,
    required this.privacyGroupAddHint,
  });

  final String e2eeBadge;
  final String peerAlice;
  final String peerBob;
  final String peerHello;
  final String fingerprintMatch;
  final String groupProject;
  final String secretStatus;
  final String secretMsg1;
  final String secretMsg2;
  final String teamDesign;
  final String disappearingStatus;
  final String disappearingMsg1;
  final String disappearingMsg2;
  final String disappearingMsg3;
  final String disappearingMsg4;
  final String peerMikhail;
  final String mikhailStatus;
  final String scheduledMsg1;
  final String scheduledMsg2;
  final String scheduledMsg3;
  final String scheduledQueueTitle;
  final String scheduledQueueDate;
  final String gamesBadge;
  final String gamesTrump;
  final String gamesDeck;
  final String gamesYou;
  final String gamesOpponent;
  final String gamesYourTurn;
  final String gamesActionBeat;
  final String gamesActionTake;
  final String meetingDuration;
  final String meetingSpeaking;
  final String callsAudioTitle;
  final String callsAudioMeta;
  final String callsCircleTitle;
  final String callsCircleMeta;
  final String folderAll;
  final String folderWork;
  final String folderFamily;
  final String folderStudy;
  final String folderStarred;
  final String folderWorkChats;
  final String chat1Name;
  final String chat1Last;
  final String chat2Name;
  final String chat2Last;
  final String chat3Name;
  final String chat3Last;
  final String threadTitle;
  final String threadReply1;
  final String threadReply2;
  final String liveLocationBanner;
  final String liveLocationStop;
  final String multiDevicePhone;
  final String multiDeviceDesktop;
  final String multiDevicePairing;
  final String multiDeviceBackup;
  final String multiDeviceBackupSub;
  final String stickerSearchHint;
  final String pollTitle;
  final String pollOption1;
  final String pollOption2;
  final String editorLabel;
  final String editorHint;
  final String privacyTitle;
  final String privacySubtitle;
  final String privacyOnline;
  final String privacyOnlineHint;
  final String privacyLastSeen;
  final String privacyLastSeenHint;
  final String privacyReceipts;
  final String privacyReceiptsHint;
  final String privacyGlobalSearch;
  final String privacyGlobalSearchHint;
  final String privacyGroupAdd;
  final String privacyGroupAddHint;
}

class FeaturesContent {
  const FeaturesContent({
    required this.pageTitle,
    required this.pageSubtitle,
    required this.heroPrimary,
    required this.heroSecondary,
    required this.highlightTitle,
    required this.highlightSubtitle,
    required this.moreTitle,
    required this.moreSubtitle,
    required this.helpfulTitle,
    required this.howToTitle,
    required this.relatedTitle,
    required this.backToList,
    required this.fromWelcomeBadge,
    required this.welcomeTitle,
    required this.welcomeSubtitle,
    required this.welcomePrimaryCta,
    required this.welcomeSecondaryCta,
    required this.welcomeBullets,
    required this.topics,
    required this.mockText,
  });
  final String pageTitle;
  final String pageSubtitle;
  final String heroPrimary;
  final String heroSecondary;
  final String highlightTitle;
  final String highlightSubtitle;
  final String moreTitle;
  final String moreSubtitle;
  final String helpfulTitle;
  final String howToTitle;
  final String relatedTitle;
  final String backToList;
  final String fromWelcomeBadge;
  final String welcomeTitle;
  final String welcomeSubtitle;
  final String welcomePrimaryCta;
  final String welcomeSecondaryCta;
  final List<String> welcomeBullets;
  final Map<FeatureTopicId, FeatureTopicContent> topics;
  final FeaturesMockText mockText;
}

class FeatureTopicMeta {
  const FeatureTopicMeta({
    required this.id,
    required this.icon,
    required this.accent,
    required this.ctaPath,
    required this.highlight,
  });
  final FeatureTopicId id;
  final IconData icon;
  final Color accent;
  final String? ctaPath;
  final bool highlight;
}

const featureAccentEmerald = Color(0xFF34D399);
const featureAccentViolet = Color(0xFFA78BFA);
const featureAccentCoral = Color(0xFFFB7185);
const featureAccentPrimary = Color(0xFF3B82F6);
const featureAccentAmber = Color(0xFFF59E0B);

const List<FeatureTopicMeta> kFeatureTopics = [
  FeatureTopicMeta(
    id: FeatureTopicId.encryption,
    icon: Icons.lock_outline_rounded,
    accent: featureAccentEmerald,
    ctaPath: '/settings/devices',
    highlight: true,
  ),
  FeatureTopicMeta(
    id: FeatureTopicId.secretChats,
    icon: Icons.timer_outlined,
    accent: featureAccentViolet,
    ctaPath: '/chats',
    highlight: true,
  ),
  FeatureTopicMeta(
    id: FeatureTopicId.disappearingMessages,
    icon: Icons.visibility_off_outlined,
    accent: featureAccentCoral,
    ctaPath: '/chats',
    highlight: true,
  ),
  FeatureTopicMeta(
    id: FeatureTopicId.scheduledMessages,
    icon: Icons.schedule_rounded,
    accent: featureAccentPrimary,
    ctaPath: '/chats',
    highlight: true,
  ),
  FeatureTopicMeta(
    id: FeatureTopicId.games,
    icon: Icons.sports_esports_outlined,
    accent: featureAccentAmber,
    ctaPath: '/chats',
    highlight: true,
  ),
  FeatureTopicMeta(
    id: FeatureTopicId.meetings,
    icon: Icons.video_call_outlined,
    accent: featureAccentPrimary,
    ctaPath: '/meetings',
    highlight: false,
  ),
  FeatureTopicMeta(
    id: FeatureTopicId.calls,
    icon: Icons.call_outlined,
    accent: featureAccentEmerald,
    ctaPath: '/calls',
    highlight: false,
  ),
  FeatureTopicMeta(
    id: FeatureTopicId.foldersThreads,
    icon: Icons.folder_outlined,
    accent: featureAccentViolet,
    ctaPath: '/chats',
    highlight: false,
  ),
  FeatureTopicMeta(
    id: FeatureTopicId.liveLocation,
    icon: Icons.location_on_outlined,
    accent: featureAccentCoral,
    ctaPath: '/chats',
    highlight: false,
  ),
  FeatureTopicMeta(
    id: FeatureTopicId.multiDevice,
    icon: Icons.devices_other_outlined,
    accent: featureAccentPrimary,
    ctaPath: '/settings/devices',
    highlight: false,
  ),
  FeatureTopicMeta(
    id: FeatureTopicId.stickersMedia,
    icon: Icons.emoji_emotions_outlined,
    accent: featureAccentAmber,
    ctaPath: '/chats',
    highlight: false,
  ),
  FeatureTopicMeta(
    id: FeatureTopicId.privacy,
    icon: Icons.shield_outlined,
    accent: featureAccentPrimary,
    ctaPath: '/settings/privacy',
    highlight: false,
  ),
];

FeatureTopicMeta featureTopicMetaFor(FeatureTopicId id) =>
    kFeatureTopics.firstWhere((m) => m.id == id);

FeaturesContent featuresContentFor(Locale locale) {
  return locale.languageCode == 'en' ? _kEn : _kRu;
}

// ---------- RU ----------

const _kRu = FeaturesContent(
  pageTitle: 'Возможности LighChat',
  pageSubtitle:
      'Короткий тур по тому, что делает LighChat быстрее, безопаснее и удобнее обычного мессенджера. Каждая фишка — на отдельной странице, с примером и шагами.',
  heroPrimary: 'Знакомьтесь с LighChat',
  heroSecondary:
      'Сквозное шифрование на выбор, секретные чаты с самоуничтожением, отложенные сообщения, видеовстречи и даже игры — всё в одном приложении и без рекламы.',
  highlightTitle: 'Самое полезное',
  highlightSubtitle: 'Пять возможностей, ради которых пользователи остаются с LighChat.',
  moreTitle: 'Ещё интересного',
  moreSubtitle: 'Что приложение умеет помимо переписки — от папок и тредов до прямой геолокации.',
  helpfulTitle: 'Что это даёт',
  howToTitle: 'Как включить',
  relatedTitle: 'Смотрите также',
  backToList: 'К списку возможностей',
  fromWelcomeBadge: 'Знакомство',
  welcomeTitle: 'Откройте возможности LighChat',
  welcomeSubtitle:
      'За две минуты покажем, чем LighChat отличается от привычных мессенджеров: шифрование, секретные чаты, игры и встречи. К туру можно вернуться в любой момент через меню настроек.',
  welcomePrimaryCta: 'Посмотреть',
  welcomeSecondaryCta: 'Позже',
  welcomeBullets: [
    'Сквозное шифрование чатов и звонков на выбор',
    'Секретные чаты с самоуничтожением',
    'Игры и видеовстречи прямо в чате',
  ],
  topics: {
    FeatureTopicId.encryption: FeatureTopicContent(
      title: 'Сквозное шифрование',
      tagline: 'Включите — и сообщения видите только вы и собеседник.',
      summary:
          'Сквозное шифрование (E2EE) в LighChat — отдельный включаемый режим. Можно включить его глобально для всех новых чатов или только для конкретного диалога. Когда E2EE активен, сообщения и медиа шифруются прямо на вашем устройстве и расшифровываются только у получателя — серверы не видят содержимого даже технически.',
      ctaLabel: 'Перейти к устройствам',
      sections: [
        FeatureSection(
          title: 'Никто посторонний не прочитает',
          body:
              'Ключи шифрования живут только на ваших устройствах и никогда не покидают их в открытом виде. Сервер видит зашифрованный поток и метаданные доставки, но не текст, не голос, не файлы и не превью ссылок. Даже если базу когда-то скомпрометируют — переписка останется недоступной.',
        ),
        FeatureSection(
          title: 'Подтверждение собеседника',
          body:
              'Каждое устройство имеет свой отпечаток ключа — короткий код. Сравните его с собеседником лично или по другому каналу: если коды совпали, между вами нет «третьего». Это та же модель доверия, что используют Signal и WhatsApp в безопасных чатах.',
        ),
        FeatureSection(
          title: 'Включается там, где нужно',
          body: 'В Настройках можно включить E2EE для всех новых чатов разом, а в шапке любого диалога — для конкретной переписки. Когда режим активен, под защиту попадает всё содержимое чата, не только текст:',
          bullets: [
            'Текстовые сообщения и реакции',
            'Голосовые и видео-кружки',
            'Фото, видео и любые файлы',
            'Превью ссылок и стикеры',
          ],
        ),
        FeatureSection(
          title: 'Восстановление без рисков',
          body:
              'Потеряли телефон? Зашифрованную копию ключей можно положить под пароль. Восстановление возможно только с этим паролем — никто, включая нас, не сможет получить доступ к ключам без него.',
        ),
      ],
      howTo: [
        'В Настройках → Конфиденциальность включите E2EE по умолчанию для новых чатов.',
        'Чтобы включить шифрование в существующем чате — откройте шапку и пункт «Шифрование».',
        'В Настройках → Устройства сравните отпечатки ключей и включите резервную копию.',
      ],
    ),
    FeatureTopicId.secretChats: FeatureTopicContent(
      title: 'Секретные чаты',
      tagline: 'Чаты, которые исчезают и не разрешают пересылать.',
      summary:
          'Секретный чат — отдельный, более строгий режим переписки. Сообщения сами удаляются по таймеру, пересылку и копирование можно полностью запретить, фото и видео открываются один раз, а сам чат закрывается отдельным паролем или биометрией.',
      ctaLabel: 'Начать секретный чат',
      sections: [
        FeatureSection(
          title: 'Самоуничтожение по таймеру',
          body: 'Выберите, через сколько сообщения исчезают: от 5 минут до суток. Таймер отсчитывается синхронно у обеих сторон — после удаления восстановить переписку невозможно ни на одном из устройств.',
        ),
        FeatureSection(
          title: 'Жёсткие ограничения',
          body: 'Запретите пересылку, цитирование, копирование текста и сохранение медиа. Серверная политика не пропустит копию мимо правил, а попытка скриншота сопровождается уведомлением собеседнику.',
          bullets: [
            'Запрет пересылки и цитирования',
            'Запрет копирования текста',
            'Запрет сохранения медиа',
            'Одноразовый просмотр фото и видео',
          ],
        ),
        FeatureSection(
          title: 'Замок поверх шифрования',
          body: 'Поверх обычного E2EE можно поставить отдельный пароль или Face ID/Touch ID на сам чат. Даже если телефон уже разблокирован и лежит на столе, заглянуть в секретный чат не получится — нужен второй фактор именно для него.',
        ),
        FeatureSection(
          title: 'Полный контроль доступа',
          body: 'В любой момент можно мгновенно очистить переписку у обеих сторон или закрыть чат паролем. Это удобно для рабочих обсуждений, юридических вопросов и любых тем, где «слишком много» лишнее.',
        ),
      ],
      howTo: [
        'В чате нажмите шапку и откройте «Конфиденциальность».',
        'Включите режим «Секретный чат» и задайте таймер.',
        'Дополнительно включите запреты и замок.',
      ],
    ),
    FeatureTopicId.disappearingMessages: FeatureTopicContent(
      title: 'Исчезающие сообщения',
      tagline: 'Переписка не копится в архивах.',
      summary:
          'В обычном чате не обязательно держать всё навсегда. Включите таймер — и сообщения будут аккуратно исчезать у всех участников через 1 час, сутки, неделю или месяц. Идеально для рабочих обсуждений, временных тем и просто гигиены переписки.',
      ctaLabel: 'Открыть чат',
      sections: [
        FeatureSection(
          title: 'Готовые таймеры на любой случай',
          body: 'Не нужно вычислять секунды — выбирайте подходящий пресет. Время отсчитывается с момента отправки и одинаково работает в личных чатах и группах.',
          bullets: [
            '1 час — для разовых вопросов',
            '24 часа — для дневной переписки',
            '7 дней — для недельных задач',
            '30 дней — длинный буфер на месяц',
          ],
        ),
        FeatureSection(
          title: 'Чисто на всех устройствах',
          body: 'Сообщения исчезают одновременно: на телефоне, в вебе и на десктопе. Не нужно вручную чистить архив или беспокоиться, что копия осталась на «другом устройстве».',
        ),
        FeatureSection(
          title: 'Никаких остатков в облаке',
          body: 'Удалённые сообщения уходят и со стороны сервера. Из бэкапов их не достанут — это не «скрыто», а действительно удалено.',
        ),
      ],
      howTo: [
        'Откройте чат и нажмите на шапку.',
        '«Исчезающие сообщения» — выберите таймер.',
        'Все новые сообщения будут жить заданное время.',
      ],
    ),
    FeatureTopicId.scheduledMessages: FeatureTopicContent(
      title: 'Отложенные сообщения',
      tagline: 'Напишите сейчас — отправится в нужный момент.',
      summary:
          'Готовите поздравление к утру или рабочее напоминание команде на понедельник? Поставьте сообщение в очередь — отправит сервер LighChat ровно в назначенное время. Можно выключить телефон, закрыть приложение или даже разрядить батарею — сообщение всё равно уйдёт.',
      ctaLabel: 'Открыть чат',
      sections: [
        FeatureSection(
          title: 'Отправка точно в срок',
          body: 'Расписание исполняется на сервере, а не на вашем устройстве. В отличие от «локальных таймеров» в других мессенджерах, доставка не сорвётся, если телефон оказался в самолёте, метро или просто без сети.',
        ),
        FeatureSection(
          title: 'Полный контроль очереди',
          body: 'Все запланированные сообщения видны на отдельной панели. Можно изменить время или текст, отправить раньше срока или вовсе отменить отправку — пока сообщение не ушло, оно полностью под вашим контролем.',
        ),
        FeatureSection(
          title: 'Удобно для команд и личного',
          body: 'Подходит для дни рождения, напоминаний, отчётов в начале рабочего дня и любых сообщений, которые «надо не забыть отправить». Часовые пояса учитываются автоматически.',
        ),
      ],
      howTo: [
        'Введите текст сообщения как обычно.',
        'Зажмите кнопку отправки — выберите «Запланировать».',
        'Выберите дату и время.',
      ],
    ),
    FeatureTopicId.games: FeatureTopicContent(
      title: 'Игры в чате',
      tagline: 'Зовите друзей в «Дурака» прямо в переписке.',
      summary:
          'Не нужно ставить отдельное приложение и регистрироваться заново. Запустите партию в «Дурака» прямо в чате — игра идёт в реальном времени, карты выглядят по-настоящему, а ходы синхронизируются мгновенно. Простой повод собраться вечером.',
      ctaLabel: 'Открыть чат',
      sections: [
        FeatureSection(
          title: 'Реальное время и атмосфера',
          body: 'Игроки видят ходы друг друга мгновенно. Партия живёт, пока вы в чате, и ставится на паузу, если кто-то отвлёкся. Обсуждайте ходы и троллите проигравшего тут же в переписке — без переключения окон.',
        ),
        FeatureSection(
          title: 'Понятные правила и подсказки',
          body: 'Поддерживается классический «Дурак подкидной» — те же правила, что вы знаете с детства. Подсказки помогут новичку, а опытный игрок сразу узнает родной вариант.',
        ),
        FeatureSection(
          title: 'Интегрировано в чат',
          body: 'Стол игры открывается в самом сообщении, а итоги партии остаются в истории. Это не отдельное «гипер-казуальное» приложение, а часть переписки между друзьями.',
        ),
      ],
      howTo: [
        'Откройте любой чат с другом или группу.',
        'Нажмите «+» и выберите «Игра».',
        'Пригласите соперников — и сдавайте.',
      ],
    ),
    FeatureTopicId.meetings: FeatureTopicContent(
      title: 'Видеовстречи',
      tagline: 'До нескольких десятков человек на одном экране.',
      summary:
          'Полноценные видеоконференции с сеткой участников, общим чатом, опросами и заявками на вход. Подключаться можно по ссылке без аккаунта — достаточно открыть страницу в браузере. Подходит и для рабочих созвонов, и для встреч с близкими.',
      ctaLabel: 'Перейти к встречам',
      sections: [
        FeatureSection(
          title: 'Удобная сетка и активный спикер',
          body: 'Активный говорящий выделяется автоматически. Закрепите нужного участника, отключите чужой звук одним нажатием или временно выйдите из эфира — без потери места в комнате.',
        ),
        FeatureSection(
          title: 'Опросы и заявки на вход',
          body: 'Запускайте голосования прямо во время встречи: одно решение, несколько ответов или анонимный режим. Закрытая комната принимает гостей по заявке — модератор подтверждает каждого вручную.',
        ),
        FeatureSection(
          title: 'Без приложений и аккаунтов',
          body: 'Для гостей встреча открывается прямо в браузере по ссылке. Не нужно ставить отдельный клиент, регистрироваться или ждать установки обновлений.',
        ),
      ],
      howTo: [
        'Откройте раздел «Встречи».',
        'Создайте новую комнату или подключитесь по ссылке.',
        'Поделитесь ссылкой с участниками.',
      ],
    ),
    FeatureTopicId.calls: FeatureTopicContent(
      title: 'Звонки и видео-кружки',
      tagline: 'От голосового до видео-открытки за секунду.',
      summary:
          'Качественные 1:1-звонки на WebRTC и короткие видео-кружки прямо в ленте чата — для быстрых реплик, когда печатать долго, а голосового мало. Лицо, эмоция, голос — всё за пару секунд. В чате со включённым E2EE звонки и кружки тоже идут зашифрованными.',
      ctaLabel: 'История звонков',
      sections: [
        FeatureSection(
          title: 'Стабильно даже в дороге',
          body: 'Звонок аккуратно переключается между Wi-Fi и мобильной сетью, держит звук в любом тоннеле и автоматически выбирает разрешение видео под канал. Никаких «вы слышите меня?» каждые тридцать секунд.',
        ),
        FeatureSection(
          title: 'Видео-кружки',
          body: 'Запишите кружок до 60 секунд: лицо, эмоция, короткий комментарий. Получатель смотрит прямо в ленте — кружок играет автоматически, без полноэкранного режима и распаковки.',
        ),
        FeatureSection(
          title: 'Сквозное шифрование, когда включено',
          body: 'Если в чате включён E2EE, звонки и кружки идут от устройства до устройства зашифрованными — серверу не достаётся ни звук, ни картинка. Включите шифрование в шапке чата, и звонки и кружки автоматически подхватят защиту.',
        ),
      ],
      howTo: [
        'В шапке чата нажмите трубку или камеру.',
        'Для кружка: зажмите кнопку записи в строке ввода.',
        'Отпустите палец — кружок отправится мгновенно.',
      ],
    ),
    FeatureTopicId.foldersThreads: FeatureTopicContent(
      title: 'Папки и треды',
      tagline: 'Сотни чатов — без хаоса.',
      summary:
          'Раскладывайте чаты по папкам — «Работа», «Семья», «Учёба», как удобно — и переключайтесь между ними одним касанием. А внутри групповых обсуждений запускайте треды по конкретным темам, чтобы основной чат не превращался в кашу.',
      ctaLabel: 'Открыть чаты',
      sections: [
        FeatureSection(
          title: 'Сколько угодно папок',
          body: 'Создайте свои папки и тяните в них любые чаты — личные, группы, каналы. Папки синхронизируются между телефоном, вебом и десктопом, порядок сохраняется.',
        ),
        FeatureSection(
          title: 'Треды в группах',
          body: 'Ответ на сообщение можно открыть в отдельной ветке — обсуждение идёт там, а основной чат остаётся читаемым. Особенно ценно в больших командах и активных сообществах.',
        ),
        FeatureSection(
          title: 'Невидимые шумные чаты',
          body: 'Папка с «тихими» чатами не звонит уведомлениями: настройки звука и бейджей задаются на уровне папки, а не для каждого чата отдельно.',
        ),
      ],
      howTo: [
        'В списке чатов нажмите на полку папок и «Создать».',
        'Перетащите чаты в нужную папку.',
        'В группе — нажмите «Ответить в треде» под сообщением.',
      ],
    ),
    FeatureTopicId.liveLocation: FeatureTopicContent(
      title: 'Прямая трансляция геолокации',
      tagline: 'Покажите, где вы сейчас, не тыкая в карту.',
      summary:
          'Вместо обмена скриншотами карты включите прямую трансляцию геолокации — собеседник в реальном времени видит, как вы движетесь к точке встречи. Удобно для свиданий в новом районе, поездок и заботы о близких.',
      ctaLabel: 'Открыть чат',
      sections: [
        FeatureSection(
          title: 'Трансляция по таймеру',
          body: 'Выберите, сколько делиться: 15 минут, час или 8 часов. По истечении трансляция останавливается автоматически — не забудете отключить даже в спешке.',
        ),
        FeatureSection(
          title: 'Никаких сюрпризов',
          body: 'Пока трансляция идёт, в чате висит хорошо заметный красный баннер. Остановить можно одним нажатием — ровно столько шагов, сколько нужно.',
        ),
        FeatureSection(
          title: 'Бережно к батарее',
          body: 'Используются те же системные API, что у штатных приложений «Карты», поэтому фоновая трансляция почти не сажает аккумулятор и не мешает уведомлениям.',
        ),
      ],
      howTo: [
        'В чате нажмите «+» и выберите «Геопозиция».',
        'Включите «Транслировать» и задайте срок.',
        'Чтобы остановить — нажмите красный баннер сверху.',
      ],
    ),
    FeatureTopicId.multiDevice: FeatureTopicContent(
      title: 'Несколько устройств',
      tagline: 'Один аккаунт, много экранов, ничего не теряется.',
      summary:
          'Подключайте телефон, планшет, веб и десктоп к одному аккаунту. Ключи шифрования синхронизируются через QR-паринг и зашифрованную резервную копию с паролем — переписка остаётся с вами, даже если потеряли все старые устройства.',
      ctaLabel: 'Управление устройствами',
      sections: [
        FeatureSection(
          title: 'Безопасный QR-паринг',
          body: 'Чтобы подключить новое устройство, отсканируйте QR-код со старого. Ключи передаются между устройствами напрямую и никогда не лежат в открытом виде на сервере. Это занимает секунды и не требует ввода длинных паролей.',
        ),
        FeatureSection(
          title: 'Резервная копия с паролем',
          body: 'Зашифруйте копию ключей собственным паролем — и восстанавливайте чаты на любом новом устройстве, даже если потеряли все старые. Без пароля копия бесполезна никому, включая нас.',
        ),
        FeatureSection(
          title: 'Одинаковый опыт везде',
          body: 'Веб, десктоп и мобильные приложения собраны на одной платформе. История чатов, папки, темы и настройки синхронизируются между всеми устройствами без задержек.',
        ),
      ],
      howTo: [
        'На новом устройстве выберите «Войти по QR».',
        'На старом откройте Настройки → Устройства.',
        'Покажите QR-код.',
      ],
    ),
    FeatureTopicId.stickersMedia: FeatureTopicContent(
      title: 'Стикеры и медиа',
      tagline: 'Эмоции, опросы и быстрые правки картинок.',
      summary:
          'Богатые стикерпаки, GIF-поиск прямо из строки ввода, опросы в один клик и встроенные редакторы фото и видео. Всё, чтобы общаться ярче и быстрее — без переключения на сторонние приложения и без потери качества.',
      ctaLabel: 'Открыть чат',
      sections: [
        FeatureSection(
          title: 'Стикеры и GIF',
          body: 'Добавляйте свои стикерпаки и используйте паблик-каталог. GIF ищутся прямо в строке ввода без переключения приложений — а самые любимые попадают в «Недавние».',
        ),
        FeatureSection(
          title: 'Опросы и реакции',
          body: 'Запустите опрос за пару касаний: с одним или несколькими ответами, анонимно или открыто. Реакции на сообщения — для быстрого фидбэка, чтобы не засорять чат односложными ответами.',
        ),
        FeatureSection(
          title: 'Редакторы фото и видео',
          body: 'Кадрируйте, рисуйте поверх, обрезайте видео и подписывайте — встроенные инструменты работают мгновенно и не теряют качество. Не нужно отдельного приложения, чтобы перед отправкой быстро привести медиа в порядок.',
        ),
      ],
      howTo: [
        'В строке ввода нажмите смайл — стикеры и GIF.',
        'Для опроса: «+» → «Опрос».',
        'Для редактора: коснитесь фото или видео в превью.',
      ],
    ),
    FeatureTopicId.privacy: FeatureTopicContent(
      title: 'Тонкая приватность',
      tagline: 'Вы решаете, что видят другие.',
      summary:
          'Каждая важная мелочь — отдельный переключатель: статус «онлайн», время «был в сети», прочитан или нет, кто может вас найти и кто может добавить в группу. Настраивается за минуту и работает на всех устройствах.',
      ctaLabel: 'Открыть приватность',
      sections: [
        FeatureSection(
          title: 'Видимость активности',
          body: 'Прячьте «онлайн» и «был в сети» от тех, кому это не нужно. Можно отключить и отчёты о прочтении — собеседники не увидят синюю галочку, и вам тоже её показывать не будут.',
        ),
        FeatureSection(
          title: 'Кто вас найдёт',
          body: 'Глобальный поиск можно отключить — и вы будете доступны только тем, у кого ваш контакт уже сохранён. Полезно, если не хотите получать сообщения от случайных людей.',
        ),
        FeatureSection(
          title: 'Профиль для других',
          body: 'Решайте, показывать ли почту, телефон, дату рождения и био в карточке профиля. Каждое поле — отдельный переключатель, без режимов «всё или ничего».',
        ),
        FeatureSection(
          title: 'Группы по правилам',
          body: 'Выбирайте, кто может добавить вас в группу: все пользователи, только контакты или вообще никто. Это убирает 99% рекламных групп без блокировок и борьбы с автоприглашениями.',
        ),
      ],
      howTo: [
        'Откройте Настройки → Приватность.',
        'Пройдитесь по переключателям и выберите своё.',
        'Кнопка «Сбросить» вернёт значения по умолчанию.',
      ],
    ),
  },
  mockText: FeaturesMockText(
    e2eeBadge: 'Сквозное шифрование',
    peerAlice: 'Алиса',
    peerBob: 'Боб',
    peerHello: 'Привет, как дела?',
    fingerprintMatch: 'совпали',
    groupProject: 'Группа · Проект',
    secretStatus: '6 участников',
    secretMsg1: 'Файл с ценой — пришлю одним просмотром.',
    secretMsg2: 'Принял. Запрет копий включён.',
    teamDesign: 'Команда · Дизайн',
    disappearingStatus: 'в сети',
    disappearingMsg1: 'Делюсь черновиком — потом удалится.',
    disappearingMsg2: 'Ок, дам комментарии до вечера.',
    disappearingMsg3: 'Цвет хедера лучше тёмный.',
    disappearingMsg4: 'Согласен. Применю и пушну.',
    peerMikhail: 'Михаил',
    mikhailStatus: 'был сегодня в 21:40',
    scheduledMsg1: 'Не забудь напомнить про планёрку.',
    scheduledMsg2: 'Уже поставил отправку на утро.',
    scheduledMsg3: 'Доброе утро! Через 15 минут начинаем планёрку.',
    scheduledQueueTitle: 'Запланированные',
    scheduledQueueDate: 'завтра, 08:45',
    gamesBadge: 'Дурак · ваш ход',
    gamesTrump: 'Козырь',
    gamesDeck: 'Колода',
    gamesYou: 'Вы',
    gamesOpponent: 'Анна',
    gamesYourTurn: 'Ваш ход',
    gamesActionBeat: 'Бить',
    gamesActionTake: 'Взять',
    meetingDuration: 'Встреча · 24:18',
    meetingSpeaking: 'говорит',
    callsAudioTitle: 'Аудио-звонок',
    callsAudioMeta: '3:42 · качество HD',
    callsCircleTitle: 'Видео-кружок',
    callsCircleMeta: '0:42 / 1:00',
    folderAll: 'Все',
    folderWork: 'Работа',
    folderFamily: 'Семья',
    folderStudy: 'Учёба',
    folderStarred: 'Избранное',
    folderWorkChats: 'Работа · чаты',
    chat1Name: 'Команда · Дизайн',
    chat1Last: 'Юля: пушнул новый вариант',
    chat2Name: 'Маркетинг',
    chat2Last: 'Костя: отчёт готов',
    chat3Name: 'CRM-релизы',
    chat3Last: 'Алина: жду апрува',
    threadTitle: 'Тред · «Цена пакета» · 6 ответов',
    threadReply1: 'Думаю, 4990 будет в самый раз',
    threadReply2: 'Поддерживаю',
    liveLocationBanner: 'Вы делитесь геолокацией',
    liveLocationStop: 'Остановить',
    multiDevicePhone: 'Телефон',
    multiDeviceDesktop: 'Desktop',
    multiDevicePairing: 'QR-паринг',
    multiDeviceBackup: 'Резервная копия ключей',
    multiDeviceBackupSub: 'защищена паролем',
    stickerSearchHint: 'поиск стикеров и GIF',
    pollTitle: 'Куда едем в субботу?',
    pollOption1: 'В горы',
    pollOption2: 'На дачу',
    editorLabel: 'Редактор',
    editorHint: 'обрезать · подписать',
    privacyTitle: 'Приватность',
    privacySubtitle: 'Решайте, что видят другие.',
    privacyOnline: 'Статус «онлайн»',
    privacyOnlineHint: 'Видят, что вы сейчас в сети',
    privacyLastSeen: 'Был в сети',
    privacyLastSeenHint: 'Точное время последнего визита',
    privacyReceipts: 'Отчёты о прочтении',
    privacyReceiptsHint: 'Двойная галочка собеседнику',
    privacyGlobalSearch: 'Глобальный поиск',
    privacyGlobalSearchHint: 'Найти вас по имени могут все',
    privacyGroupAdd: 'Добавление в группы',
    privacyGroupAddHint: 'Только из контактов',
  ),
);

// ---------- EN ----------

const _kEn = FeaturesContent(
  pageTitle: 'LighChat features',
  pageSubtitle:
      'A short tour of what makes LighChat faster, safer and more useful than a regular messenger. Each feature has its own page with an example and steps.',
  heroPrimary: 'Meet LighChat',
  heroSecondary:
      'Opt-in end-to-end encryption, secret chats that self-destruct, scheduled messages, video meetings and even games — all in one ad-free app. Discover it all in a couple of minutes.',
  highlightTitle: 'Most useful',
  highlightSubtitle: 'Five reasons people stay with LighChat.',
  moreTitle: 'More to explore',
  moreSubtitle: 'What the app can do beyond chatting — folders, threads, live location and more.',
  helpfulTitle: 'What you get',
  howToTitle: 'How to enable',
  relatedTitle: 'See also',
  backToList: 'Back to features',
  fromWelcomeBadge: 'Tour',
  welcomeTitle: 'Discover LighChat features',
  welcomeSubtitle:
      'Two minutes to see what makes LighChat different: encryption, secret chats, games and meetings. You can come back to the tour any time from the settings menu.',
  welcomePrimaryCta: 'Take a look',
  welcomeSecondaryCta: 'Later',
  welcomeBullets: [
    'Opt-in end-to-end encryption for chats and calls',
    'Secret chats that self-destruct',
    'Games and video meetings inside chat',
  ],
  topics: {
    FeatureTopicId.encryption: FeatureTopicContent(
      title: 'End-to-end encryption',
      tagline: 'Turn it on — and only you and the recipient can read it.',
      summary:
          'End-to-end encryption (E2EE) in LighChat is an opt-in mode. Enable it globally for every new chat or just for one specific conversation. While E2EE is on, messages and media are encrypted right on your device and decrypted only on the other side — servers cannot read the content even technically.',
      ctaLabel: 'Open devices',
      sections: [
        FeatureSection(
          title: 'Nobody else reads it',
          body:
              'Encryption keys live on your devices only and never leave them in plaintext. The server sees encrypted traffic and delivery metadata, but not text, voice, files or link previews. Even if the database were ever compromised, your conversations would stay private.',
        ),
        FeatureSection(
          title: 'Verify your peer',
          body:
              'Every device has a fingerprint — a short code. Compare it with your peer in person or over a separate channel: if the codes match, there is nobody in the middle. Same trust model as Signal and WhatsApp use in their secure chats.',
        ),
        FeatureSection(
          title: 'Turn it on where you need it',
          body:
              'In Settings you can enable E2EE for every new chat at once, or turn it on for a specific conversation from its header. Once the mode is active, everything in that chat travels encrypted — not just text:',
          bullets: [
            'Text messages and reactions',
            'Voice and video circles',
            'Photos, videos and files',
            'Link previews and stickers',
          ],
        ),
        FeatureSection(
          title: 'Recovery without trade-offs',
          body:
              'Lost your phone? You can keep an encrypted backup of your keys behind a password. Recovery only works with that password — nobody, including us, can reach the keys without it.',
        ),
      ],
      howTo: [
        'In Settings → Privacy enable E2EE by default for new chats.',
        'To turn it on in an existing chat, open the chat header and pick Encryption.',
        'In Settings → Devices compare key fingerprints with your peer and enable the backup.',
      ],
    ),
    FeatureTopicId.secretChats: FeatureTopicContent(
      title: 'Secret chats',
      tagline: 'Chats that disappear and refuse to forward.',
      summary:
          'A secret chat is a stricter mode of conversation. Messages auto-delete on a timer, you can fully block forwarding and copying, photos and videos open once, and the chat itself can be locked behind a separate password or biometrics.',
      ctaLabel: 'Start a secret chat',
      sections: [
        FeatureSection(
          title: 'Self-destructing timer',
          body:
              'Pick how long messages live, from 5 minutes to a day. The timer counts down on both sides — once a message is gone, it cannot be recovered on any device.',
        ),
        FeatureSection(
          title: 'Hard restrictions',
          body:
              'Block forwarding, quoting, text copying and saving media. Server-side policy enforces every rule, and screenshot attempts notify your peer.',
          bullets: [
            'No forwarding or quoting',
            'No copying text',
            'No saving media',
            'View-once photos and videos',
          ],
        ),
        FeatureSection(
          title: 'A lock on top of encryption',
          body:
              'On top of regular E2EE, you can put a separate password or Face ID/Touch ID on the chat itself. Even an unlocked phone left on a desk will not reveal it — the second factor is required for that specific chat.',
        ),
        FeatureSection(
          title: 'Full control of access',
          body:
              'You can wipe the conversation on both sides at any moment, or lock the chat. Handy for work topics, legal matters and anything where less is more.',
        ),
      ],
      howTo: [
        'Tap the chat header and open Privacy.',
        'Turn on Secret chat and set a timer.',
        'Optionally enable restrictions and the lock.',
      ],
    ),
    FeatureTopicId.disappearingMessages: FeatureTopicContent(
      title: 'Disappearing messages',
      tagline: 'Stop hoarding old conversations.',
      summary:
          'You do not have to keep everything forever. Set a timer and messages quietly vanish for everyone after 1 hour, a day, a week or a month. Perfect for work threads, casual topics and basic conversation hygiene.',
      ctaLabel: 'Open chats',
      sections: [
        FeatureSection(
          title: 'Sensible presets',
          body: 'No need to count seconds — pick a preset. The clock starts at send time and works the same in 1:1 chats and groups.',
          bullets: [
            '1 hour for one-offs',
            '24 hours for daily threads',
            '7 days for weekly tasks',
            '30 days for a month-long buffer',
          ],
        ),
        FeatureSection(
          title: 'Clean across devices',
          body:
              'Messages disappear in sync — on phone, web and desktop. No archive cleanup, no worries about a copy left somewhere.',
        ),
        FeatureSection(
          title: 'No leftovers in the cloud',
          body:
              'Deleted messages are gone server-side too. They will not surface from a backup — this is not “hidden”, it is actually deleted.',
        ),
      ],
      howTo: [
        'Open a chat and tap the header.',
        'Disappearing messages — pick a timer.',
        'New messages will live exactly that long.',
      ],
    ),
    FeatureTopicId.scheduledMessages: FeatureTopicContent(
      title: 'Scheduled messages',
      tagline: 'Write now, send later.',
      summary:
          'Preparing a morning greeting or a Monday team reminder? Queue the message and the LighChat server will deliver it at the right moment. You can power down the device, close the app or even drain the battery — your message will still go out.',
      ctaLabel: 'Open chats',
      sections: [
        FeatureSection(
          title: 'Always on time',
          body:
              'Delivery happens on the server, not on your phone. Unlike local timers in other messengers, the send will not fail because the device is on a plane, in a tunnel or simply offline.',
        ),
        FeatureSection(
          title: 'Full control of the queue',
          body:
              'A separate panel shows every scheduled message. Edit time or text, send earlier or cancel — until it leaves, the message is fully under your control.',
        ),
        FeatureSection(
          title: 'Great for teams and life',
          body: 'Birthdays, reminders, morning standups and any “must not forget to send” messages. Time zones are handled automatically.',
        ),
      ],
      howTo: [
        'Type your message as usual.',
        'Long-press the send button → Schedule.',
        'Pick a date and time. Done.',
      ],
    ),
    FeatureTopicId.games: FeatureTopicContent(
      title: 'Games in chat',
      tagline: 'Invite friends to a card game inside the chat.',
      summary:
          'No separate app, no separate signup. Start a game of Durak right inside the chat — real-time, beautiful cards, instant moves. A simple reason to gather in the evening.',
      ctaLabel: 'Open chats',
      sections: [
        FeatureSection(
          title: 'Real time and atmosphere',
          body:
              'Players see each other’s moves instantly. The match lives while you stay in the chat and pauses when someone steps away. Trash-talk and discuss right in the same conversation, no window switching.',
        ),
        FeatureSection(
          title: 'Familiar rules with hints',
          body: 'Classic “Durak with passing on” — the rules you know from childhood. Hints help newcomers; veterans recognise their game right away.',
        ),
        FeatureSection(
          title: 'Built into chat',
          body: 'The table opens inside the message, and the result stays in chat history. It is part of the conversation between friends, not a separate hyper-casual app.',
        ),
      ],
      howTo: [
        'Open any chat or group.',
        'Tap “+” in the input and pick Game.',
        'Invite opponents and deal.',
      ],
    ),
    FeatureTopicId.meetings: FeatureTopicContent(
      title: 'Video meetings',
      tagline: 'Up to dozens of people on one screen.',
      summary:
          'Full video meetings with a participant grid, a shared chat, polls and join requests. Guests can join by link with no account — the page opens right in their browser. Works for work calls and family hangouts alike.',
      ctaLabel: 'Open meetings',
      sections: [
        FeatureSection(
          title: 'Convenient grid and active speaker',
          body:
              'The active speaker is highlighted automatically. Pin the participant you need, mute someone with one tap or step out for a while without losing your seat.',
        ),
        FeatureSection(
          title: 'Polls and join requests',
          body:
              'Run polls during the call: single, multi-choice or anonymous. Closed rooms accept guests by request — the moderator approves each one manually.',
        ),
        FeatureSection(
          title: 'No apps, no accounts',
          body:
              'For guests, the meeting opens right in the browser by link. No client to install, no signup, no waiting for updates.',
        ),
      ],
      howTo: [
        'Open the Meetings tab.',
        'Create a room or join by link.',
        'Share the link with participants.',
      ],
    ),
    FeatureTopicId.calls: FeatureTopicContent(
      title: 'Calls and video circles',
      tagline: 'From a voice call to a video postcard in a second.',
      summary:
          'High-quality 1:1 WebRTC calls and short video circles right in the chat feed — for quick replies when typing is too slow and a voice note is not enough. Face, emotion, voice — all in seconds. In chats where E2EE is on, calls and circles travel encrypted too.',
      ctaLabel: 'Call history',
      sections: [
        FeatureSection(
          title: 'Stable on the move',
          body:
              'The call switches between Wi-Fi and cellular gracefully, holds audio in any tunnel and adapts video resolution to bandwidth. No “can you hear me?” every thirty seconds.',
        ),
        FeatureSection(
          title: 'Video circles',
          body:
              'Record a circle up to 60 seconds: face, emotion, a short comment. The receiver watches it inline — the circle plays automatically, no fullscreen, no extra taps.',
        ),
        FeatureSection(
          title: 'End-to-end encrypted when enabled',
          body:
              'When E2EE is on in the chat, calls and circles travel device-to-device — the server gets neither audio nor picture, only the stream for delivery. Turn encryption on in the chat header and calls and circles pick the protection up automatically.',
        ),
      ],
      howTo: [
        'Tap the phone or camera icon in the chat header.',
        'For a circle: long-press the record button.',
        'Release to send instantly.',
      ],
    ),
    FeatureTopicId.foldersThreads: FeatureTopicContent(
      title: 'Folders and threads',
      tagline: 'Hundreds of chats without the chaos.',
      summary:
          'Sort chats into folders — Work, Family, Study, whatever fits — and switch between them with one tap. Inside group conversations, open threads on specific topics so the main chat stays clean.',
      ctaLabel: 'Open chats',
      sections: [
        FeatureSection(
          title: 'As many folders as you need',
          body:
              'Create your own folders and drag any chat into them — DMs, groups, channels. Folders sync across phone, web and desktop, order is preserved.',
        ),
        FeatureSection(
          title: 'Threads in groups',
          body:
              'Reply to a message inside a thread — the discussion stays there while the main chat stays readable. Especially valuable in big teams and active communities.',
        ),
        FeatureSection(
          title: 'Quiet noisy chats',
          body:
              'A folder of “quiet” chats does not ring with notifications: sound and badge settings live at the folder level, not per chat.',
        ),
      ],
      howTo: [
        'Open the folder rail and tap Create.',
        'Drag chats into a folder or set rules.',
        'In a group, tap “Reply in thread” under any message.',
      ],
    ),
    FeatureTopicId.liveLocation: FeatureTopicContent(
      title: 'Live location sharing',
      tagline: 'Show where you are without fiddling with the map.',
      summary:
          'Instead of swapping screenshots, turn on live location and your peer sees you move in real time. Great for meeting up at a new spot, road trips and keeping an eye on loved ones.',
      ctaLabel: 'Open chats',
      sections: [
        FeatureSection(
          title: 'Timed sharing',
          body: 'Pick how long to share: 15 minutes, an hour or 8 hours. After that the stream stops on its own — you will not forget to turn it off.',
        ),
        FeatureSection(
          title: 'No surprises',
          body: 'While you share, a clearly visible red banner stays in the chat. One tap stops the stream — exactly as many steps as needed.',
        ),
        FeatureSection(
          title: 'Battery-friendly',
          body: 'Uses the same system APIs as native Maps apps, so background sharing barely drains the battery and does not interfere with notifications.',
        ),
      ],
      howTo: [
        'In a chat, tap “+” → Location.',
        'Turn on Live and choose duration.',
        'Tap the red banner on top to stop.',
      ],
    ),
    FeatureTopicId.multiDevice: FeatureTopicContent(
      title: 'Multiple devices',
      tagline: 'One account, many screens, nothing lost.',
      summary:
          'Connect phone, tablet, web and desktop to a single account. Encryption keys sync via QR pairing and an encrypted backup with a password — your conversations stay with you, even if you lose every old device.',
      ctaLabel: 'Manage devices',
      sections: [
        FeatureSection(
          title: 'Secure QR pairing',
          body:
              'Pair a new device by scanning a QR code from an old one. Keys travel directly between devices and never sit in plaintext on the server. Takes seconds, no long passwords to type.',
        ),
        FeatureSection(
          title: 'Password backup',
          body:
              'Encrypt a backup of your keys with your own password — and recover chats on any new device, even if you lost all the old ones. The backup is useless to anyone without that password, including us.',
        ),
        FeatureSection(
          title: 'Same experience everywhere',
          body:
              'Web, desktop and mobile are built on the same platform. Chat history, folders, themes and settings sync across devices without delays.',
        ),
      ],
      howTo: [
        'On a new device, choose Sign in with QR.',
        'On an old device, open Settings → Devices.',
        'Show the QR code. Done — keys are on the new device.',
      ],
    ),
    FeatureTopicId.stickersMedia: FeatureTopicContent(
      title: 'Stickers and media',
      tagline: 'Emotion, polls and quick photo edits.',
      summary:
          'Rich sticker packs, GIF search right inside the input, one-tap polls and built-in photo and video editors. Everything to communicate brighter and faster — no app switching, no quality loss.',
      ctaLabel: 'Open chats',
      sections: [
        FeatureSection(
          title: 'Stickers and GIFs',
          body:
              'Add your own packs and use the public catalog. Search GIFs right from the input — your favourites end up in Recent automatically.',
        ),
        FeatureSection(
          title: 'Polls and reactions',
          body:
              'Start a poll in two taps: single or multi-choice, anonymous or open. Message reactions for quick feedback, so chats do not fill up with one-word replies.',
        ),
        FeatureSection(
          title: 'Photo and video editors',
          body:
              'Crop, draw, trim video and caption — built-in tools work instantly without quality loss. No third-party app needed to tidy media before sending.',
        ),
      ],
      howTo: [
        'Tap the smiley in the input — stickers and GIFs.',
        'For a poll: “+” → Poll.',
        'For the editor: tap a photo or video in the preview.',
      ],
    ),
    FeatureTopicId.privacy: FeatureTopicContent(
      title: 'Fine-grained privacy',
      tagline: 'You decide what others see.',
      summary:
          'Every detail is its own toggle: Online status, Last seen, Read receipts, who can find you and who can add you to a group. Set it up in a minute — it works on every device.',
      ctaLabel: 'Open privacy',
      sections: [
        FeatureSection(
          title: 'Activity visibility',
          body:
              'Hide Online and Last seen from the wrong eyes. Read receipts can be turned off too — peers will not see the blue check, and you will not see theirs.',
        ),
        FeatureSection(
          title: 'Who finds you',
          body:
              'Global search can be off — then you are reachable only to people who already have your contact saved. Useful if you do not want random messages.',
        ),
        FeatureSection(
          title: 'Profile for others',
          body:
              'Decide whether to show email, phone, date of birth and bio in the profile card. Each field is its own toggle, no “all or nothing” mode.',
        ),
        FeatureSection(
          title: 'Groups by your rules',
          body:
              'Pick who can add you to a group: everyone, contacts only, or nobody. That removes 99% of marketing groups without blocklists or fighting auto-invites.',
        ),
      ],
      howTo: [
        'Open Settings → Privacy.',
        'Walk through the toggles and pick your defaults.',
        'Reset returns the safe defaults.',
      ],
    ),
  },
  mockText: FeaturesMockText(
    e2eeBadge: 'End-to-end encryption',
    peerAlice: 'Alice',
    peerBob: 'Bob',
    peerHello: 'Hi, how are you?',
    fingerprintMatch: 'match',
    groupProject: 'Group · Project',
    secretStatus: '6 members',
    secretMsg1: 'Sending the price file as view-once.',
    secretMsg2: 'Got it. Copy block is on.',
    teamDesign: 'Team · Design',
    disappearingStatus: 'online',
    disappearingMsg1: 'Sharing the draft — it will vanish later.',
    disappearingMsg2: 'OK, I’ll review by tonight.',
    disappearingMsg3: 'A darker header would look better.',
    disappearingMsg4: 'Agreed. Applying and pushing.',
    peerMikhail: 'Michael',
    mikhailStatus: 'last seen today at 21:40',
    scheduledMsg1: 'Don’t forget about the standup reminder.',
    scheduledMsg2: 'Already queued for the morning.',
    scheduledMsg3: 'Good morning! Standup starts in 15 minutes.',
    scheduledQueueTitle: 'Scheduled',
    scheduledQueueDate: 'tomorrow, 08:45',
    gamesBadge: 'Durak · your turn',
    gamesTrump: 'Trump',
    gamesDeck: 'Deck',
    gamesYou: 'You',
    gamesOpponent: 'Alice',
    gamesYourTurn: 'Your turn',
    gamesActionBeat: 'Beat',
    gamesActionTake: 'Take',
    meetingDuration: 'Meeting · 24:18',
    meetingSpeaking: 'speaking',
    callsAudioTitle: 'Audio call',
    callsAudioMeta: '3:42 · HD quality',
    callsCircleTitle: 'Video circle',
    callsCircleMeta: '0:42 / 1:00',
    folderAll: 'All',
    folderWork: 'Work',
    folderFamily: 'Family',
    folderStudy: 'Study',
    folderStarred: 'Starred',
    folderWorkChats: 'Work · chats',
    chat1Name: 'Team · Design',
    chat1Last: 'Julia: pushed a new variant',
    chat2Name: 'Marketing',
    chat2Last: 'Konstantin: report is ready',
    chat3Name: 'CRM releases',
    chat3Last: 'Alina: waiting for approval',
    threadTitle: 'Thread · “Plan price” · 6 replies',
    threadReply1: 'I think 4990 fits best',
    threadReply2: 'Agree',
    liveLocationBanner: 'Sharing your location',
    liveLocationStop: 'Stop',
    multiDevicePhone: 'Phone',
    multiDeviceDesktop: 'Desktop',
    multiDevicePairing: 'QR pairing',
    multiDeviceBackup: 'Key backup',
    multiDeviceBackupSub: 'password-protected',
    stickerSearchHint: 'search stickers and GIFs',
    pollTitle: 'Where are we going on Saturday?',
    pollOption1: 'To the mountains',
    pollOption2: 'To the country',
    editorLabel: 'Editor',
    editorHint: 'crop · caption',
    privacyTitle: 'Privacy',
    privacySubtitle: 'You decide what others see.',
    privacyOnline: 'Online status',
    privacyOnlineHint: 'Others see you’re online now',
    privacyLastSeen: 'Last seen',
    privacyLastSeenHint: 'Exact time of your last visit',
    privacyReceipts: 'Read receipts',
    privacyReceiptsHint: 'Double check for the sender',
    privacyGlobalSearch: 'Global search',
    privacyGlobalSearchHint: 'Anyone can find you by name',
    privacyGroupAdd: 'Adding to groups',
    privacyGroupAddHint: 'Contacts only',
  ),
);
