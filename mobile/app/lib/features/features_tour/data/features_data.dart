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
      'Сильное шифрование по умолчанию, секретные чаты с самоуничтожением, отложенные сообщения, видеовстречи и даже игры — всё в одном приложении и без рекламы.',
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
    'Сквозное шифрование сообщений и звонков',
    'Секретные чаты с самоуничтожением',
    'Игры и видеовстречи прямо в чате',
  ],
  topics: {
    FeatureTopicId.encryption: FeatureTopicContent(
      title: 'Сквозное шифрование',
      tagline: 'Сообщения видите только вы и собеседник.',
      summary:
          'В LighChat сквозное шифрование (E2EE) включается автоматически для каждого личного чата и звонка. Сообщения и медиа зашифровываются прямо на вашем устройстве и расшифровываются только у получателя — серверы не видят содержимого даже технически.',
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
          title: 'Шифруется всё, что важно',
          body: 'Шифруются не только текстовые сообщения. В личных чатах под защиту попадают голосовые, видео-кружки, фото, видео, файлы, превью ссылок и стикеры — без переключения режимов.',
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
        'Откройте Настройки → Устройства.',
        'Проверьте список устройств и отпечатки ключей.',
        'Уберите устройства, которыми больше не пользуетесь.',
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
          'Качественные 1:1-звонки на WebRTC с шифрованием по умолчанию и короткие видео-кружки прямо в ленте чата — для быстрых реплик, когда печатать долго, а голосового мало. Лицо, эмоция, голос — всё за пару секунд.',
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
          title: 'Сквозное шифрование',
          body: 'И звонки, и кружки шифруются от устройства до устройства. Серверу не достаётся ни звук, ни картинка — только зашифрованный поток для доставки.',
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
);

// ---------- EN ----------

const _kEn = FeaturesContent(
  pageTitle: 'LighChat features',
  pageSubtitle:
      'A short tour of what makes LighChat faster, safer and more fun than a regular messenger.',
  heroPrimary: 'Meet LighChat',
  heroSecondary:
      'Strong encryption, secret chats, scheduled messages and built-in games. Discover it all in a couple of minutes.',
  highlightTitle: 'Most useful',
  highlightSubtitle: 'Five reasons people stay.',
  moreTitle: 'More to explore',
  moreSubtitle: 'What else the app can do beyond chatting.',
  helpfulTitle: 'What you get',
  howToTitle: 'How to enable',
  relatedTitle: 'See also',
  backToList: 'Back to features',
  fromWelcomeBadge: 'Tour',
  welcomeTitle: 'Discover LighChat features',
  welcomeSubtitle:
      'Two minutes to see what makes LighChat different. You can come back to the tour any time from settings.',
  welcomePrimaryCta: 'Take a look',
  welcomeSecondaryCta: 'Later',
  welcomeBullets: [
    'End-to-end encrypted messages and calls',
    'Secret chats that self-destruct',
    'Games and video meetings inside chat',
  ],
  topics: {
    FeatureTopicId.encryption: FeatureTopicContent(
      title: 'End-to-end encryption',
      tagline: 'Only you and the recipient can read it.',
      summary:
          'Every personal message and call is encrypted on your device and decrypted only on the other side.',
      ctaLabel: 'Open devices',
      sections: [
        FeatureSection(title: 'Nobody else reads it', body: 'Keys live on your devices only.'),
        FeatureSection(title: 'Verify your peer', body: 'Compare the device fingerprint with your peer.'),
        FeatureSection(
          title: 'Encrypts everything',
          body: 'Encryption turns on automatically for text, voice, photos, files and media.',
          bullets: [
            'Text messages and reactions',
            'Voice and video circles',
            'Photos, videos and files',
            'Link previews and stickers',
          ],
        ),
      ],
      howTo: ['Open Settings → Devices.', 'Review your devices and key fingerprints.', 'Remove devices you no longer use.'],
    ),
    FeatureTopicId.secretChats: FeatureTopicContent(
      title: 'Secret chats',
      tagline: 'Chats that disappear and refuse to forward.',
      summary: 'Stricter rules: timed self-destruct, no forwarding, view-once media.',
      ctaLabel: 'Start a secret chat',
      sections: [
        FeatureSection(title: 'Self-destructing timer', body: 'From 5 minutes to a day.'),
        FeatureSection(
          title: 'Hard restrictions',
          body: 'Block forwarding, quotes and saving media.',
          bullets: [
            'No forwarding or quoting',
            'No copying text',
            'No saving media',
            'View-once photos and videos',
          ],
        ),
        FeatureSection(title: 'Lock the chat', body: 'Add a separate password or biometrics.'),
      ],
      howTo: ['Tap the chat header and open Privacy.', 'Turn on Secret chat and set a timer.', 'Optionally enable restrictions and the lock.'],
    ),
    FeatureTopicId.disappearingMessages: FeatureTopicContent(
      title: 'Disappearing messages',
      tagline: 'Stop hoarding old conversations.',
      summary: 'Set a timer in a regular chat and messages vanish for everyone.',
      ctaLabel: 'Open chats',
      sections: [
        FeatureSection(
          title: 'Sensible presets',
          body: 'Ready-made timers cover most cases.',
          bullets: ['1 hour for one-offs', '24 hours for daily threads', '7 days for weekly tasks', '30 days for a long buffer'],
        ),
        FeatureSection(title: 'Clean across devices', body: 'Disappear in sync on phone, web and desktop.'),
      ],
      howTo: ['Open a chat and tap the header.', 'Disappearing messages — pick a timer.', 'New messages will live exactly that long.'],
    ),
    FeatureTopicId.scheduledMessages: FeatureTopicContent(
      title: 'Scheduled messages',
      tagline: 'Write now, send later.',
      summary: 'The server delivers your message at the right moment.',
      ctaLabel: 'Open chats',
      sections: [
        FeatureSection(title: 'Always on time', body: 'Delivery happens on the server, not on your phone.'),
        FeatureSection(title: 'Full control', body: 'Edit time or text, or cancel the send.'),
      ],
      howTo: ['Type your message as usual.', 'Long-press the send button → Schedule.', 'Pick a date and time.'],
    ),
    FeatureTopicId.games: FeatureTopicContent(
      title: 'Games in chat',
      tagline: 'Invite friends to a card game inside the chat.',
      summary: 'Start a game of Durak right inside the chat — real-time.',
      ctaLabel: 'Open chats',
      sections: [
        FeatureSection(title: 'Real time', body: 'Players see each other’s moves instantly.'),
        FeatureSection(title: 'Familiar rules', body: 'Classic Durak with passing on.'),
      ],
      howTo: ['Open any chat or group.', 'Tap “+” and pick Game.', 'Invite opponents and deal.'],
    ),
    FeatureTopicId.meetings: FeatureTopicContent(
      title: 'Video meetings',
      tagline: 'Up to dozens of people on one screen.',
      summary: 'Full video meetings with a participant grid, chat, polls and join requests.',
      ctaLabel: 'Open meetings',
      sections: [
        FeatureSection(title: 'Convenient grid', body: 'Active speaker is highlighted automatically.'),
        FeatureSection(title: 'Polls and join requests', body: 'Run polls during the call.'),
      ],
      howTo: ['Open the Meetings tab.', 'Create a room or join by link.', 'Share the link with participants.'],
    ),
    FeatureTopicId.calls: FeatureTopicContent(
      title: 'Calls and video circles',
      tagline: 'From a voice call to a video postcard in a second.',
      summary: 'High-quality 1:1 WebRTC calls and short video circles.',
      ctaLabel: 'Call history',
      sections: [
        FeatureSection(title: 'Stable quality', body: 'Switches networks gracefully.'),
        FeatureSection(title: 'Video circles', body: 'Up to 60 seconds, plays inline.'),
      ],
      howTo: ['Tap the phone or camera icon.', 'For a circle: long-press the record button.', 'Release to send.'],
    ),
    FeatureTopicId.foldersThreads: FeatureTopicContent(
      title: 'Folders and threads',
      tagline: 'Hundreds of chats without the chaos.',
      summary: 'Sort chats into folders and open threads on specific topics.',
      ctaLabel: 'Open chats',
      sections: [
        FeatureSection(title: 'Custom folders', body: 'Create as many folders as you need.'),
        FeatureSection(title: 'Threads in groups', body: 'Reply to a message inside a thread.'),
      ],
      howTo: ['Open the folder rail and tap Create.', 'Drag chats into the folder.', 'In a group: Reply in thread.'],
    ),
    FeatureTopicId.liveLocation: FeatureTopicContent(
      title: 'Live location sharing',
      tagline: 'Show where you are without fiddling with the map.',
      summary: 'Your peer sees you move in real time.',
      ctaLabel: 'Open chats',
      sections: [
        FeatureSection(title: 'Timed sharing', body: '15 minutes, an hour or 8 hours.'),
        FeatureSection(title: 'No surprises', body: 'A banner reminds you while sharing.'),
      ],
      howTo: ['In a chat tap “+” → Location.', 'Turn on Live and choose duration.', 'Tap the red banner to stop.'],
    ),
    FeatureTopicId.multiDevice: FeatureTopicContent(
      title: 'Multiple devices',
      tagline: 'One account, many screens, nothing lost.',
      summary: 'QR pairing and password-protected backup of keys.',
      ctaLabel: 'Manage devices',
      sections: [
        FeatureSection(title: 'Secure QR pairing', body: 'Keys travel directly between devices.'),
        FeatureSection(title: 'Password backup', body: 'Recover chats on any new device.'),
      ],
      howTo: ['On a new device, choose Sign in with QR.', 'On an old device, open Settings → Devices.', 'Show the QR code.'],
    ),
    FeatureTopicId.stickersMedia: FeatureTopicContent(
      title: 'Stickers and media',
      tagline: 'Emotion, polls and quick photo edits.',
      summary: 'Rich stickers and GIFs, polls and built-in photo and video editors.',
      ctaLabel: 'Open chats',
      sections: [
        FeatureSection(title: 'Stickers and GIFs', body: 'Add your own packs and search GIFs in the input.'),
        FeatureSection(title: 'Polls and reactions', body: 'A poll in two taps; reactions for quick feedback.'),
        FeatureSection(title: 'Photo and video editors', body: 'Crop, draw, trim — built-in.'),
      ],
      howTo: ['Tap the smiley in the input.', 'For a poll: “+” → Poll.', 'For the editor: tap a photo or video preview.'],
    ),
    FeatureTopicId.privacy: FeatureTopicContent(
      title: 'Fine-grained privacy',
      tagline: 'You decide what others see.',
      summary: 'Every detail is its own toggle.',
      ctaLabel: 'Open privacy',
      sections: [
        FeatureSection(title: 'Activity visibility', body: 'Hide Online and Last seen.'),
        FeatureSection(title: 'Who finds you', body: 'Global search can be off.'),
        FeatureSection(title: 'Profile for others', body: 'Decide what to show in the profile card.'),
      ],
      howTo: ['Open Settings → Privacy.', 'Walk through the toggles.', 'Reset returns the safe defaults.'],
    ),
  },
);
