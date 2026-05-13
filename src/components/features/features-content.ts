import type { FeatureTopicId } from './features-data';

export type FeatureSection = {
  /** Заголовок секции «Что это даёт». */
  title: string;
  /** 1–2 коротких абзаца простым языком. */
  body: string;
  /** Опциональный список (≤4 пунктов). */
  bullets?: string[];
};

export type FeatureTopicContent = {
  /** Короткий заголовок. */
  title: string;
  /** Тизер на главной (1 строка). */
  tagline: string;
  /** Подзаголовок на детальной странице (2–3 предложения). */
  summary: string;
  /** CTA-кнопка «Попробовать». */
  ctaLabel: string;
  /** Секции «Что это даёт». */
  sections: FeatureSection[];
  /** Шаги «Как включить». */
  howTo: string[];
};

/** Тексты, попадающие внутрь иллюстраций (имена, статусы, реплики). */
export type FeaturesMockText = {
  // Encryption
  e2eeBadge: string;
  peerAlice: string;
  peerBob: string;
  peerHello: string;
  fingerprintMatch: string;
  // Secret chats
  groupProject: string;
  secretStatus: string;
  secretMsg1: string;
  secretMsg2: string;
  secretSettingsTitle: string;
  secretSettingTtl: string;
  secretSettingTtlValue: string;
  secretSettingNoForward: string;
  secretSettingLock: string;
  // Disappearing messages
  teamDesign: string;
  disappearingStatus: string;
  disappearingMsg1: string;
  disappearingMsg2: string;
  disappearingMsg3: string;
  disappearingMsg4: string;
  // Scheduled
  peerMikhail: string;
  mikhailStatus: string;
  scheduledMsg1: string;
  scheduledMsg2: string;
  scheduledMsg3: string;
  scheduledQueueTitle: string;
  scheduledQueueDate: string;
  // Games
  gamesBadge: string;
  gamesTrump: string;
  gamesDeck: string;
  gamesYou: string;
  gamesOpponent: string;
  gamesYourTurn: string;
  gamesActionBeat: string;
  gamesActionTake: string;
  // Meetings
  meetingDuration: string;
  meetingSpeaking: string;
  // Calls
  callsAudioTitle: string;
  callsAudioMeta: string;
  callsCircleTitle: string;
  callsCircleMeta: string;
  // Folders
  folderAll: string;
  folderWork: string;
  folderFamily: string;
  folderStudy: string;
  folderStarred: string;
  folderWorkChats: string;
  chat1Name: string;
  chat1Last: string;
  chat2Name: string;
  chat2Last: string;
  chat3Name: string;
  chat3Last: string;
  threadTitle: string;
  threadReply1: string;
  threadReply2: string;
  // Live location
  liveLocationBanner: string;
  liveLocationStop: string;
  // Multi-device
  multiDevicePhone: string;
  multiDeviceDesktop: string;
  multiDevicePairing: string;
  multiDeviceBackup: string;
  multiDeviceBackupSub: string;
  // Stickers
  stickerSearchHint: string;
  pollLabel: string;
  pollTitle: string;
  pollOption1: string;
  pollOption2: string;
  editorLabel: string;
  editorHint: string;
  // Privacy
  privacyTitle: string;
  privacySubtitle: string;
  privacyOnline: string;
  privacyOnlineHint: string;
  privacyLastSeen: string;
  privacyLastSeenHint: string;
  privacyReceipts: string;
  privacyReceiptsHint: string;
  privacyGlobalSearch: string;
  privacyGlobalSearchHint: string;
  privacyGroupAdd: string;
  privacyGroupAddHint: string;
};

export type FeaturesContent = {
  pageTitle: string;
  pageSubtitle: string;
  pageHeroPrimary: string;
  pageHeroSecondary: string;
  highlightTitle: string;
  highlightSubtitle: string;
  moreTitle: string;
  moreSubtitle: string;
  helpfulTitle: string;
  howToTitle: string;
  relatedTitle: string;
  backToList: string;
  fromWelcomeBadge: string;
  welcomeOverlay: {
    title: string;
    subtitle: string;
    primaryCta: string;
    secondaryCta: string;
    bullets: string[];
  };
  topics: Record<FeatureTopicId, FeatureTopicContent>;
  mockText: FeaturesMockText;
};

const ru: FeaturesContent = {
  pageTitle: 'Возможности LighChat',
  pageSubtitle:
    'Короткий тур по тому, что делает LighChat быстрее, безопаснее и удобнее обычного мессенджера. Каждая фишка — на отдельной странице, с примером и шагами.',
  pageHeroPrimary: 'Знакомьтесь с LighChat',
  pageHeroSecondary:
    'Сквозное шифрование на выбор, секретные чаты с самоуничтожением, отложенные сообщения, видеовстречи и даже игры — всё в одном приложении и без рекламы. Откройте за пару минут.',
  highlightTitle: 'Самое полезное',
  highlightSubtitle: 'Пять возможностей, ради которых пользователи остаются с LighChat.',
  moreTitle: 'Ещё интересного',
  moreSubtitle: 'Что приложение умеет помимо переписки — от папок и тредов до прямой геолокации.',
  helpfulTitle: 'Что это даёт',
  howToTitle: 'Как включить',
  relatedTitle: 'Смотрите также',
  backToList: 'К списку возможностей',
  fromWelcomeBadge: 'Знакомство',
  welcomeOverlay: {
    title: 'Откройте возможности LighChat',
    subtitle:
      'За две минуты покажем, чем LighChat отличается от привычных мессенджеров: шифрование, секретные чаты, игры и встречи. К туру можно вернуться в любой момент через меню настроек.',
    primaryCta: 'Посмотреть',
    secondaryCta: 'Позже',
    bullets: [
      'Сквозное шифрование чатов и звонков на выбор',
      'Секретные чаты с самоуничтожением',
      'Игры и видеовстречи прямо в чате',
    ],
  },
  topics: {
    encryption: {
      title: 'Сквозное шифрование',
      tagline: 'Включите — и сообщения видите только вы и собеседник.',
      summary:
        'Сквозное шифрование (E2EE) в LighChat — отдельный включаемый режим. Можно включить его глобально для всех новых чатов или только для конкретного диалога. Когда E2EE активен, сообщения и медиа шифруются прямо на вашем устройстве и расшифровываются только у получателя — серверы не видят содержимого даже технически.',
      ctaLabel: 'Перейти к устройствам',
      sections: [
        {
          title: 'Никто посторонний не прочитает',
          body: 'Ключи шифрования живут только на ваших устройствах и никогда не покидают их в открытом виде. Сервер видит зашифрованный поток и метаданные доставки, но не текст, не голос, не файлы и не превью ссылок. Даже если базу когда-то скомпрометируют — переписка останется недоступной.',
        },
        {
          title: 'Подтверждение собеседника',
          body: 'Каждое устройство имеет свой отпечаток ключа — короткий код. Сравните его с собеседником лично или по другому каналу: если коды совпали, между вами нет «третьего». Это та же модель доверия, что используют Signal и WhatsApp в безопасных чатах.',
        },
        {
          title: 'Включается там, где нужно',
          body: 'В Настройках можно включить E2EE для всех новых чатов разом, а в шапке любого диалога — для конкретной переписки. Когда режим активен, под защиту попадает всё содержимое чата, не только текст:',
          bullets: [
            'Текстовые сообщения и реакции',
            'Голосовые и видео-кружки',
            'Фото, видео и любые файлы',
            'Превью ссылок и стикеры',
          ],
        },
        {
          title: 'Восстановление без рисков',
          body: 'Потеряли телефон? Зашифрованную копию ключей можно положить под пароль. Восстановление возможно только с этим паролем — никто, включая нас, не сможет получить доступ к ключам без него.',
        },
      ],
      howTo: [
        'В Настройках → Конфиденциальность включите E2EE по умолчанию для новых чатов.',
        'Чтобы включить шифрование в существующем чате — откройте шапку и пункт «Шифрование».',
        'В Настройках → Устройства сравните отпечатки ключей с собеседником и включите резервную копию.',
      ],
    },
    'secret-chats': {
      title: 'Секретные чаты',
      tagline: 'Чаты, которые исчезают и не разрешают пересылать.',
      summary:
        'Секретный чат — отдельный, более строгий режим переписки. Сообщения сами удаляются по таймеру, пересылку и копирование можно полностью запретить, фото и видео открываются один раз, а сам чат закрывается отдельным паролем или биометрией.',
      ctaLabel: 'Начать секретный чат',
      sections: [
        {
          title: 'Самоуничтожение по таймеру',
          body: 'Выберите, через сколько сообщения исчезают: от 5 минут до суток. Таймер отсчитывается синхронно у обеих сторон — после удаления восстановить переписку невозможно ни на одном из устройств.',
        },
        {
          title: 'Жёсткие ограничения',
          body: 'Запретите пересылку, цитирование, копирование текста и сохранение медиа. Серверная политика не пропустит копию мимо правил, а попытка скриншота сопровождается уведомлением собеседнику.',
          bullets: [
            'Запрет пересылки и цитирования',
            'Запрет копирования текста',
            'Запрет сохранения медиа',
            'Одноразовый просмотр фото и видео',
          ],
        },
        {
          title: 'Замок поверх шифрования',
          body: 'Поверх обычного E2EE можно поставить отдельный пароль или Face ID/Touch ID на сам чат. Даже если телефон уже разблокирован и лежит на столе, заглянуть в секретный чат не получится — нужен второй фактор именно для него.',
        },
        {
          title: 'Полный контроль доступа',
          body: 'В любой момент можно мгновенно очистить переписку у обеих сторон или закрыть чат паролем. Это удобно для рабочих обсуждений, юридических вопросов и любых тем, где «слишком много» лишнее.',
        },
      ],
      howTo: [
        'В чате нажмите шапку и откройте раздел «Конфиденциальность».',
        'Включите режим «Секретный чат» и задайте таймер удаления.',
        'Дополнительно включите запреты на пересылку, копирование и медиа-сейв.',
      ],
    },
    'disappearing-messages': {
      title: 'Исчезающие сообщения',
      tagline: 'Переписка не копится в архивах.',
      summary:
        'В обычном чате не обязательно держать всё навсегда. Включите таймер — и сообщения будут аккуратно исчезать у всех участников через 1 час, сутки, неделю или месяц. Идеально для рабочих обсуждений, временных тем и просто гигиены переписки.',
      ctaLabel: 'Открыть чат',
      sections: [
        {
          title: 'Готовые таймеры на любой случай',
          body: 'Не нужно вычислять секунды — выбирайте подходящий пресет. Время отсчитывается с момента отправки и одинаково работает в личных чатах и группах.',
          bullets: [
            '1 час — для разовых вопросов',
            '24 часа — для дневной переписки',
            '7 дней — для недельных задач',
            '30 дней — длинный буфер на месяц',
          ],
        },
        {
          title: 'Чисто на всех устройствах',
          body: 'Сообщения исчезают одновременно: на телефоне, в вебе и на десктопе. Не нужно вручную чистить архив или беспокоиться, что копия осталась на «другом устройстве».',
        },
        {
          title: 'Никаких остатков в облаке',
          body: 'Удалённые сообщения уходят и со стороны сервера. Из бэкапов их не достанут — это не «скрыто», а действительно удалено.',
        },
      ],
      howTo: [
        'Откройте чат и нажмите на шапку.',
        'Раздел «Исчезающие сообщения» — выберите подходящий таймер.',
        'Все новые сообщения будут жить ровно столько, сколько нужно.',
      ],
    },
    'scheduled-messages': {
      title: 'Отложенные сообщения',
      tagline: 'Напишите сейчас — отправится в нужный момент.',
      summary:
        'Готовите поздравление к утру или рабочее напоминание команде на понедельник? Поставьте сообщение в очередь — отправит сервер LighChat ровно в назначенное время. Можно выключить телефон, закрыть приложение или даже разрядить батарею — сообщение всё равно уйдёт.',
      ctaLabel: 'Открыть чат',
      sections: [
        {
          title: 'Отправка точно в срок',
          body: 'Расписание исполняется на сервере, а не на вашем устройстве. В отличие от «локальных таймеров» в других мессенджерах, доставка не сорвётся, если телефон оказался в самолёте, метро или просто без сети.',
        },
        {
          title: 'Полный контроль очереди',
          body: 'Все запланированные сообщения видны на отдельной панели. Можно изменить время или текст, отправить раньше срока или вовсе отменить отправку — пока сообщение не ушло, оно полностью под вашим контролем.',
        },
        {
          title: 'Удобно для команд и личного',
          body: 'Подходит для дни рождения, напоминаний, отчётов в начале рабочего дня и любых сообщений, которые «надо не забыть отправить». Часовые пояса учитываются автоматически.',
        },
      ],
      howTo: [
        'Введите текст сообщения как обычно.',
        'Зажмите кнопку отправки — выберите «Запланировать».',
        'Выберите дату и время. Готово, сообщение в очереди.',
      ],
    },
    games: {
      title: 'Игры в чате',
      tagline: 'Зовите друзей в «Дурака» прямо в переписке.',
      summary:
        'Не нужно ставить отдельное приложение и регистрироваться заново. Запустите партию в «Дурака» прямо в чате — игра идёт в реальном времени, карты выглядят по-настоящему, а ходы синхронизируются мгновенно. Простой повод собраться вечером.',
      ctaLabel: 'Открыть чат',
      sections: [
        {
          title: 'Реальное время и атмосфера',
          body: 'Игроки видят ходы друг друга мгновенно. Партия живёт, пока вы в чате, и ставится на паузу, если кто-то отвлёкся. Обсуждайте ходы и троллите проигравшего тут же в переписке — без переключения окон.',
        },
        {
          title: 'Понятные правила и подсказки',
          body: 'Поддерживается классический «Дурак подкидной» — те же правила, что вы знаете с детства. Подсказки помогут новичку, а опытный игрок сразу узнает родной вариант.',
        },
        {
          title: 'Интегрировано в чат',
          body: 'Стол игры открывается в самом сообщении, а итоги партии остаются в истории. Это не отдельное «гипер-казуальное» приложение, а часть переписки между друзьями.',
        },
      ],
      howTo: [
        'Откройте любой чат с другом или группу.',
        'Нажмите «+» в строке ввода и выберите «Игра».',
        'Пригласите соперников — и сдавайте.',
      ],
    },
    meetings: {
      title: 'Видеовстречи',
      tagline: 'До нескольких десятков человек на одном экране.',
      summary:
        'Полноценные видеоконференции с сеткой участников, общим чатом, опросами и заявками на вход. Подключаться можно по ссылке без аккаунта — достаточно открыть страницу в браузере. Подходит и для рабочих созвонов, и для встреч с близкими.',
      ctaLabel: 'Перейти к встречам',
      sections: [
        {
          title: 'Удобная сетка и активный спикер',
          body: 'Активный говорящий выделяется автоматически. Закрепите нужного участника, отключите чужой звук одним нажатием или временно выйдите из эфира — без потери места в комнате.',
        },
        {
          title: 'Опросы и заявки на вход',
          body: 'Запускайте голосования прямо во время встречи: одно решение, несколько ответов или анонимный режим. Закрытая комната принимает гостей по заявке — модератор подтверждает каждого вручную.',
        },
        {
          title: 'Без приложений и аккаунтов',
          body: 'Для гостей встреча открывается прямо в браузере по ссылке. Не нужно ставить отдельный клиент, регистрироваться или ждать установки обновлений.',
        },
      ],
      howTo: [
        'Откройте раздел «Встречи» в приложении.',
        'Создайте новую комнату или подключитесь по ссылке.',
        'Поделитесь ссылкой с участниками — и начинайте.',
      ],
    },
    calls: {
      title: 'Звонки и видео-кружки',
      tagline: 'От голосового до видео-открытки за секунду.',
      summary:
        'Качественные 1:1-звонки на WebRTC и короткие видео-кружки прямо в ленте чата — для быстрых реплик, когда печатать долго, а голосового мало. Лицо, эмоция, голос — всё за пару секунд. В чате со включённым E2EE звонки и кружки тоже идут зашифрованными.',
      ctaLabel: 'История звонков',
      sections: [
        {
          title: 'Стабильно даже в дороге',
          body: 'Звонок аккуратно переключается между Wi-Fi и мобильной сетью, держит звук в любом тоннеле и автоматически выбирает разрешение видео под канал. Никаких «вы слышите меня?» каждые тридцать секунд.',
        },
        {
          title: 'Видео-кружки',
          body: 'Запишите кружок до 60 секунд: лицо, эмоция, короткий комментарий. Получатель смотрит прямо в ленте — кружок играет автоматически, без полноэкранного режима и распаковки.',
        },
        {
          title: 'Сквозное шифрование, когда включено',
          body: 'Если в чате включён E2EE, звонки и кружки идут от устройства до устройства зашифрованными — серверу не достаётся ни звук, ни картинка, только поток для доставки. Включите шифрование в шапке чата, и звонки и кружки автоматически подхватят защиту.',
        },
      ],
      howTo: [
        'В шапке чата нажмите трубку или камеру для звонка.',
        'Для кружка: зажмите кнопку записи в строке ввода.',
        'Отпустите палец — кружок отправится мгновенно.',
      ],
    },
    'folders-threads': {
      title: 'Папки и треды',
      tagline: 'Сотни чатов — без хаоса в списке.',
      summary:
        'Раскладывайте чаты по папкам — «Работа», «Семья», «Учёба», как удобно — и переключайтесь между ними одним касанием. А внутри групповых обсуждений запускайте треды по конкретным темам, чтобы основной чат не превращался в кашу.',
      ctaLabel: 'Открыть чаты',
      sections: [
        {
          title: 'Сколько угодно папок',
          body: 'Создайте свои папки и тяните в них любые чаты — личные, группы, каналы. Папки синхронизируются между телефоном, вебом и десктопом, порядок сохраняется.',
        },
        {
          title: 'Треды в группах',
          body: 'Ответ на сообщение можно открыть в отдельной ветке — обсуждение идёт там, а основной чат остаётся читаемым. Особенно ценно в больших командах и активных сообществах.',
        },
        {
          title: 'Невидимые шумные чаты',
          body: 'Папка с «тихими» чатами не звонит уведомлениями: настройки звука и бейджей задаются на уровне папки, а не для каждого чата отдельно.',
        },
      ],
      howTo: [
        'В списке чатов нажмите на полку папок и «Создать».',
        'Перетащите чаты в нужную папку или назначьте автоправила.',
        'В группе — нажмите «Ответить в треде» под сообщением.',
      ],
    },
    'live-location': {
      title: 'Прямая трансляция геолокации',
      tagline: 'Покажите, где вы сейчас, не тыкая в карту.',
      summary:
        'Вместо обмена скриншотами карты включите прямую трансляцию геолокации — собеседник в реальном времени видит, как вы движетесь к точке встречи. Удобно для свиданий в новом районе, поездок и заботы о близких.',
      ctaLabel: 'Открыть чат',
      sections: [
        {
          title: 'Трансляция по таймеру',
          body: 'Выберите, сколько делиться: 15 минут, час или 8 часов. По истечении трансляция останавливается автоматически — не забудете отключить даже в спешке.',
        },
        {
          title: 'Никаких сюрпризов',
          body: 'Пока трансляция идёт, в чате висит хорошо заметный красный баннер. Остановить можно одним нажатием — ровно столько шагов, сколько нужно.',
        },
        {
          title: 'Бережно к батарее',
          body: 'Используются те же системные API, что у штатных приложений «Карты», поэтому фоновая трансляция почти не сажает аккумулятор и не мешает уведомлениям.',
        },
      ],
      howTo: [
        'В чате нажмите «+» и выберите «Геопозиция».',
        'Включите «Транслировать» и задайте срок.',
        'Чтобы остановить — нажмите красный баннер сверху.',
      ],
    },
    'multi-device': {
      title: 'Несколько устройств',
      tagline: 'Один аккаунт, много экранов, ничего не теряется.',
      summary:
        'Подключайте телефон, планшет, веб и десктоп к одному аккаунту. Ключи шифрования синхронизируются через QR-паринг и зашифрованную резервную копию с паролем — переписка остаётся с вами, даже если потеряли все старые устройства.',
      ctaLabel: 'Управление устройствами',
      sections: [
        {
          title: 'Безопасный QR-паринг',
          body: 'Чтобы подключить новое устройство, отсканируйте QR-код со старого. Ключи передаются между устройствами напрямую и никогда не лежат в открытом виде на сервере. Это занимает секунды и не требует ввода длинных паролей.',
        },
        {
          title: 'Резервная копия с паролем',
          body: 'Зашифруйте копию ключей собственным паролем — и восстанавливайте чаты на любом новом устройстве, даже если потеряли все старые. Без пароля копия бесполезна никому, включая нас.',
        },
        {
          title: 'Одинаковый опыт везде',
          body: 'Веб, десктоп и мобильные приложения собраны на одной платформе. История чатов, папки, темы и настройки синхронизируются между всеми устройствами без задержек.',
        },
      ],
      howTo: [
        'На новом устройстве выберите «Войти по QR».',
        'На старом откройте Настройки → Устройства.',
        'Покажите QR-код. Готово, ключи у нового устройства.',
      ],
    },
    'stickers-media': {
      title: 'Стикеры и медиа',
      tagline: 'Эмоции, опросы и быстрые правки картинок.',
      summary:
        'Богатые стикерпаки, GIF-поиск прямо из строки ввода, опросы в один клик и встроенные редакторы фото и видео. Всё, чтобы общаться ярче и быстрее — без переключения на сторонние приложения и без потери качества.',
      ctaLabel: 'Открыть чат',
      sections: [
        {
          title: 'Стикеры и GIF',
          body: 'Добавляйте свои стикерпаки и используйте паблик-каталог. GIF ищутся прямо в строке ввода без переключения приложений — а самые любимые попадают в «Недавние».',
        },
        {
          title: 'Опросы и реакции',
          body: 'Запустите опрос за пару касаний: с одним или несколькими ответами, анонимно или открыто. Реакции на сообщения — для быстрого фидбэка, чтобы не засорять чат односложными ответами.',
        },
        {
          title: 'Редакторы фото и видео',
          body: 'Кадрируйте, рисуйте поверх, обрезайте видео и подписывайте — встроенные инструменты работают мгновенно и не теряют качество. Не нужно отдельного приложения, чтобы перед отправкой быстро привести медиа в порядок.',
        },
      ],
      howTo: [
        'В строке ввода нажмите смайл — стикеры и GIF.',
        'Для опроса: «+» → «Опрос».',
        'Для редактора: коснитесь фото или видео в превью отправки.',
      ],
    },
    privacy: {
      title: 'Тонкая приватность',
      tagline: 'Вы решаете, что видят другие.',
      summary:
        'Каждая важная мелочь — отдельный переключатель: статус «онлайн», время «был в сети», прочитан или нет, кто может вас найти и кто может добавить в группу. Настраивается за минуту и работает на всех устройствах.',
      ctaLabel: 'Открыть приватность',
      sections: [
        {
          title: 'Видимость активности',
          body: 'Прячьте «онлайн» и «был в сети» от тех, кому это не нужно. Можно отключить и отчёты о прочтении — собеседники не увидят синюю галочку, и вам тоже её показывать не будут.',
        },
        {
          title: 'Кто вас найдёт',
          body: 'Глобальный поиск можно отключить — и вы будете доступны только тем, у кого ваш контакт уже сохранён. Полезно, если не хотите получать сообщения от случайных людей.',
        },
        {
          title: 'Профиль для других',
          body: 'Решайте, показывать ли почту, телефон, дату рождения и био в карточке профиля. Каждое поле — отдельный переключатель, без режимов «всё или ничего».',
        },
        {
          title: 'Группы по правилам',
          body: 'Выбирайте, кто может добавить вас в группу: все пользователи, только контакты или вообще никто. Это убирает 99% рекламных групп без блокировок и борьбы с автоприглашениями.',
        },
      ],
      howTo: [
        'Откройте Настройки → Приватность.',
        'Пройдитесь по переключателям и выберите своё.',
        'Кнопка «Сбросить» вернёт значения по умолчанию.',
      ],
    },
  },
  mockText: {
    e2eeBadge: 'Сквозное шифрование',
    peerAlice: 'Алиса',
    peerBob: 'Боб',
    peerHello: 'Привет, как дела?',
    fingerprintMatch: 'совпали',
    groupProject: 'Группа · Проект',
    secretStatus: '6 участников',
    secretSettingsTitle: 'Правила секретного чата',
    secretSettingTtl: 'Таймер',
    secretSettingTtlValue: 'через 1 час',
    secretSettingNoForward: 'Запретить пересылку',
    secretSettingLock: 'Замок на чат',
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
    pollLabel: 'Опрос',
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
  },
};

const en: FeaturesContent = {
  pageTitle: 'LighChat features',
  pageSubtitle:
    'A short tour of what makes LighChat faster, safer and more useful than a regular messenger. Each feature has its own page with an example and steps.',
  pageHeroPrimary: 'Meet LighChat',
  pageHeroSecondary:
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
  welcomeOverlay: {
    title: 'Discover LighChat features',
    subtitle:
      'Two minutes to see what makes LighChat different: encryption, secret chats, games and meetings. You can come back to the tour any time from the settings menu.',
    primaryCta: 'Take a look',
    secondaryCta: 'Later',
    bullets: [
      'Opt-in end-to-end encryption for chats and calls',
      'Secret chats that self-destruct',
      'Games and video meetings inside chat',
    ],
  },
  topics: {
    encryption: {
      title: 'End-to-end encryption',
      tagline: 'Turn it on — and only you and the recipient can read it.',
      summary:
        'End-to-end encryption (E2EE) in LighChat is an opt-in mode. Enable it globally for every new chat or just for one specific conversation. While E2EE is on, messages and media are encrypted right on your device and decrypted only on the other side — servers cannot read the content even technically.',
      ctaLabel: 'Open devices',
      sections: [
        {
          title: 'Nobody else reads it',
          body: 'Encryption keys live on your devices only and never leave them in plaintext. The server sees encrypted traffic and delivery metadata, but not text, voice, files or link previews. Even if the database were ever compromised, your conversations would stay private.',
        },
        {
          title: 'Verify your peer',
          body: 'Every device has a fingerprint — a short code. Compare it with your peer in person or over a separate channel: if the codes match, there is nobody in the middle. Same trust model as Signal and WhatsApp use in their secure chats.',
        },
        {
          title: 'Turn it on where you need it',
          body: 'In Settings you can enable E2EE for every new chat at once, or turn it on for a specific conversation from its header. Once the mode is active, everything in that chat travels encrypted — not just text:',
          bullets: [
            'Text messages and reactions',
            'Voice and video circles',
            'Photos, videos and files',
            'Link previews and stickers',
          ],
        },
        {
          title: 'Recovery without trade-offs',
          body: 'Lost your phone? You can keep an encrypted backup of your keys behind a password. Recovery only works with that password — nobody, including us, can reach the keys without it.',
        },
      ],
      howTo: [
        'In Settings → Privacy enable E2EE by default for new chats.',
        'To turn it on in an existing chat, open the chat header and pick “Encryption”.',
        'In Settings → Devices compare key fingerprints with your peer and enable the backup.',
      ],
    },
    'secret-chats': {
      title: 'Secret chats',
      tagline: 'Chats that disappear and refuse to forward.',
      summary:
        'A secret chat is a stricter mode of conversation. Messages auto-delete on a timer, you can fully block forwarding and copying, photos and videos open once, and the chat itself can be locked behind a separate password or biometrics.',
      ctaLabel: 'Start a secret chat',
      sections: [
        {
          title: 'Self-destructing timer',
          body: 'Pick how long messages live, from 5 minutes to a day. The timer counts down on both sides — once a message is gone, it cannot be recovered on any device.',
        },
        {
          title: 'Hard restrictions',
          body: 'Block forwarding, quoting, text copying and saving media. Server-side policy enforces every rule, and screenshot attempts notify your peer.',
          bullets: [
            'No forwarding or quoting',
            'No copying text',
            'No saving media',
            'View-once photos and videos',
          ],
        },
        {
          title: 'A lock on top of encryption',
          body: 'On top of regular E2EE, you can put a separate password or Face ID/Touch ID on the chat itself. Even an unlocked phone left on a desk will not reveal it — the second factor is required for that specific chat.',
        },
        {
          title: 'Full control of access',
          body: 'You can wipe the conversation on both sides at any moment, or lock the chat. Handy for work topics, legal matters and anything where less is more.',
        },
      ],
      howTo: [
        'Tap the chat header and open Privacy.',
        'Turn on Secret chat and set a timer.',
        'Optionally enable restrictions and the lock.',
      ],
    },
    'disappearing-messages': {
      title: 'Disappearing messages',
      tagline: 'Stop hoarding old conversations.',
      summary:
        'You do not have to keep everything forever. Set a timer and messages quietly vanish for everyone after 1 hour, a day, a week or a month. Perfect for work threads, casual topics and basic conversation hygiene.',
      ctaLabel: 'Open chats',
      sections: [
        {
          title: 'Sensible presets',
          body: 'No need to count seconds — pick a preset. The clock starts at send time and works the same in 1:1 chats and groups.',
          bullets: [
            '1 hour for one-offs',
            '24 hours for daily threads',
            '7 days for weekly tasks',
            '30 days for a month-long buffer',
          ],
        },
        {
          title: 'Clean across devices',
          body: 'Messages disappear in sync — on phone, web and desktop. No archive cleanup, no worries about a copy left somewhere.',
        },
        {
          title: 'No leftovers in the cloud',
          body: 'Deleted messages are gone server-side too. They will not surface from a backup — this is not “hidden”, it is actually deleted.',
        },
      ],
      howTo: [
        'Open a chat and tap the header.',
        'Disappearing messages — pick a timer.',
        'New messages will live exactly that long.',
      ],
    },
    'scheduled-messages': {
      title: 'Scheduled messages',
      tagline: 'Write now, send later.',
      summary:
        'Preparing a morning greeting or a Monday team reminder? Queue the message and the LighChat server will deliver it at the right moment. You can power down the device, close the app or even drain the battery — your message will still go out.',
      ctaLabel: 'Open chats',
      sections: [
        {
          title: 'Always on time',
          body: 'Delivery happens on the server, not on your phone. Unlike local timers in other messengers, the send will not fail because the device is on a plane, in a tunnel or simply offline.',
        },
        {
          title: 'Full control of the queue',
          body: 'A separate panel shows every scheduled message. Edit time or text, send earlier or cancel — until it leaves, the message is fully under your control.',
        },
        {
          title: 'Great for teams and life',
          body: 'Birthdays, reminders, morning standups and any “must not forget to send” messages. Time zones are handled automatically.',
        },
      ],
      howTo: [
        'Type your message as usual.',
        'Long-press the send button → Schedule.',
        'Pick a date and time. Done.',
      ],
    },
    games: {
      title: 'Games in chat',
      tagline: 'Invite friends to a card game inside the chat.',
      summary:
        'No separate app, no separate signup. Start a game of Durak right inside the chat — real-time, beautiful cards, instant moves. A simple reason to gather in the evening.',
      ctaLabel: 'Open chats',
      sections: [
        {
          title: 'Real time and atmosphere',
          body: 'Players see each other’s moves instantly. The match lives while you stay in the chat and pauses when someone steps away. Trash-talk and discuss right in the same conversation, no window switching.',
        },
        {
          title: 'Familiar rules with hints',
          body: 'Classic “Durak with passing on” — the rules you know from childhood. Hints help newcomers; veterans recognise their game right away.',
        },
        {
          title: 'Built into chat',
          body: 'The table opens inside the message, and the result stays in chat history. It is part of the conversation between friends, not a separate hyper-casual app.',
        },
      ],
      howTo: [
        'Open any chat or group.',
        'Tap “+” in the input and pick Game.',
        'Invite opponents and deal.',
      ],
    },
    meetings: {
      title: 'Video meetings',
      tagline: 'Up to dozens of people on one screen.',
      summary:
        'Full video meetings with a participant grid, a shared chat, polls and join requests. Guests can join by link with no account — the page opens right in their browser. Works for work calls and family hangouts alike.',
      ctaLabel: 'Open meetings',
      sections: [
        {
          title: 'Convenient grid and active speaker',
          body: 'The active speaker is highlighted automatically. Pin the participant you need, mute someone with one tap or step out for a while without losing your seat.',
        },
        {
          title: 'Polls and join requests',
          body: 'Run polls during the call: single, multi-choice or anonymous. Closed rooms accept guests by request — the moderator approves each one manually.',
        },
        {
          title: 'No apps, no accounts',
          body: 'For guests, the meeting opens right in the browser by link. No client to install, no signup, no waiting for updates.',
        },
      ],
      howTo: [
        'Open the Meetings tab.',
        'Create a room or join by link.',
        'Share the link with participants.',
      ],
    },
    calls: {
      title: 'Calls and video circles',
      tagline: 'From a voice call to a video postcard in a second.',
      summary:
        'High-quality 1:1 WebRTC calls and short video circles right in the chat feed — for quick replies when typing is too slow and a voice note is not enough. Face, emotion, voice — all in seconds. In chats where E2EE is on, calls and circles travel encrypted too.',
      ctaLabel: 'Call history',
      sections: [
        {
          title: 'Stable on the move',
          body: 'The call switches between Wi-Fi and cellular gracefully, holds audio in any tunnel and adapts video resolution to bandwidth. No “can you hear me?” every thirty seconds.',
        },
        {
          title: 'Video circles',
          body: 'Record a circle up to 60 seconds: face, emotion, a short comment. The receiver watches it inline — the circle plays automatically, no fullscreen, no extra taps.',
        },
        {
          title: 'End-to-end encrypted when enabled',
          body: 'When E2EE is on in the chat, calls and circles travel device-to-device — the server gets neither audio nor picture, only the stream for delivery. Turn encryption on in the chat header and calls and circles pick the protection up automatically.',
        },
      ],
      howTo: [
        'Tap the phone or camera icon in the chat header.',
        'For a circle: long-press the record button.',
        'Release to send instantly.',
      ],
    },
    'folders-threads': {
      title: 'Folders and threads',
      tagline: 'Hundreds of chats without the chaos.',
      summary:
        'Sort chats into folders — Work, Family, Study, whatever fits — and switch between them with one tap. Inside group conversations, open threads on specific topics so the main chat stays clean.',
      ctaLabel: 'Open chats',
      sections: [
        {
          title: 'As many folders as you need',
          body: 'Create your own folders and drag any chat into them — DMs, groups, channels. Folders sync across phone, web and desktop, order is preserved.',
        },
        {
          title: 'Threads in groups',
          body: 'Reply to a message inside a thread — the discussion stays there while the main chat stays readable. Especially valuable in big teams and active communities.',
        },
        {
          title: 'Quiet noisy chats',
          body: 'A folder of “quiet” chats does not ring with notifications: sound and badge settings live at the folder level, not per chat.',
        },
      ],
      howTo: [
        'Open the folder rail and tap Create.',
        'Drag chats into a folder or set rules.',
        'In a group, tap “Reply in thread” under any message.',
      ],
    },
    'live-location': {
      title: 'Live location sharing',
      tagline: 'Show where you are without fiddling with the map.',
      summary:
        'Instead of swapping screenshots, turn on live location and your peer sees you move in real time. Great for meeting up at a new spot, road trips and keeping an eye on loved ones.',
      ctaLabel: 'Open chats',
      sections: [
        {
          title: 'Timed sharing',
          body: 'Pick how long to share: 15 minutes, an hour or 8 hours. After that the stream stops on its own — you will not forget to turn it off.',
        },
        {
          title: 'No surprises',
          body: 'While you share, a clearly visible red banner stays in the chat. One tap stops the stream — exactly as many steps as needed.',
        },
        {
          title: 'Battery-friendly',
          body: 'Uses the same system APIs as native Maps apps, so background sharing barely drains the battery and does not interfere with notifications.',
        },
      ],
      howTo: [
        'In a chat, tap “+” → Location.',
        'Turn on Live and choose duration.',
        'Tap the red banner on top to stop.',
      ],
    },
    'multi-device': {
      title: 'Multiple devices',
      tagline: 'One account, many screens, nothing lost.',
      summary:
        'Connect phone, tablet, web and desktop to a single account. Encryption keys sync via QR pairing and an encrypted backup with a password — your conversations stay with you, even if you lose every old device.',
      ctaLabel: 'Manage devices',
      sections: [
        {
          title: 'Secure QR pairing',
          body: 'Pair a new device by scanning a QR code from an old one. Keys travel directly between devices and never sit in plaintext on the server. Takes seconds, no long passwords to type.',
        },
        {
          title: 'Password backup',
          body: 'Encrypt a backup of your keys with your own password — and recover chats on any new device, even if you lost all the old ones. The backup is useless to anyone without that password, including us.',
        },
        {
          title: 'Same experience everywhere',
          body: 'Web, desktop and mobile are built on the same platform. Chat history, folders, themes and settings sync across devices without delays.',
        },
      ],
      howTo: [
        'On a new device, choose Sign in with QR.',
        'On an old device, open Settings → Devices.',
        'Show the QR code. Done — keys are on the new device.',
      ],
    },
    'stickers-media': {
      title: 'Stickers and media',
      tagline: 'Emotion, polls and quick photo edits.',
      summary:
        'Rich sticker packs, GIF search right inside the input, one-tap polls and built-in photo and video editors. Everything to communicate brighter and faster — no app switching, no quality loss.',
      ctaLabel: 'Open chats',
      sections: [
        {
          title: 'Stickers and GIFs',
          body: 'Add your own packs and use the public catalog. Search GIFs right from the input — your favourites end up in Recent automatically.',
        },
        {
          title: 'Polls and reactions',
          body: 'Start a poll in two taps: single or multi-choice, anonymous or open. Message reactions for quick feedback, so chats do not fill up with one-word replies.',
        },
        {
          title: 'Photo and video editors',
          body: 'Crop, draw, trim video and caption — built-in tools work instantly without quality loss. No third-party app needed to tidy media before sending.',
        },
      ],
      howTo: [
        'Tap the smiley in the input — stickers and GIFs.',
        'For a poll: “+” → Poll.',
        'For the editor: tap a photo or video in the preview.',
      ],
    },
    privacy: {
      title: 'Fine-grained privacy',
      tagline: 'You decide what others see.',
      summary:
        'Every detail is its own toggle: Online status, Last seen, Read receipts, who can find you and who can add you to a group. Set it up in a minute — it works on every device.',
      ctaLabel: 'Open privacy',
      sections: [
        {
          title: 'Activity visibility',
          body: 'Hide Online and Last seen from the wrong eyes. Read receipts can be turned off too — peers will not see the blue check, and you will not see theirs.',
        },
        {
          title: 'Who finds you',
          body: 'Global search can be off — then you are reachable only to people who already have your contact saved. Useful if you do not want random messages.',
        },
        {
          title: 'Profile for others',
          body: 'Decide whether to show email, phone, date of birth and bio in the profile card. Each field is its own toggle, no “all or nothing” mode.',
        },
        {
          title: 'Groups by your rules',
          body: 'Pick who can add you to a group: everyone, contacts only, or nobody. That removes 99% of marketing groups without blocklists or fighting auto-invites.',
        },
      ],
      howTo: [
        'Open Settings → Privacy.',
        'Walk through the toggles and pick your defaults.',
        'Reset returns the safe defaults.',
      ],
    },
  },
  mockText: {
    e2eeBadge: 'End-to-end encryption',
    peerAlice: 'Alice',
    peerBob: 'Bob',
    peerHello: 'Hi, how are you?',
    fingerprintMatch: 'match',
    groupProject: 'Group · Project',
    secretStatus: '6 members',
    secretSettingsTitle: 'Secret chat rules',
    secretSettingTtl: 'Timer',
    secretSettingTtlValue: 'in 1 hour',
    secretSettingNoForward: 'Block forwarding',
    secretSettingLock: 'Lock chat',
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
    pollLabel: 'Poll',
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
  },
};

const ptBR: FeaturesContent = {
  pageTitle: 'Recursos do LighChat',
  pageSubtitle:
    'Um tour rápido pelo que torna o LighChat mais rápido, seguro e útil do que um mensageiro comum. Cada recurso tem sua própria página com exemplo e passo a passo.',
  pageHeroPrimary: 'Conheça o LighChat',
  pageHeroSecondary:
    'Criptografia ponta a ponta opcional, conversas secretas que se autodestroem, mensagens agendadas, videochamadas e até jogos — tudo em um app sem anúncios. Descubra tudo em alguns minutos.',
  highlightTitle: 'Mais úteis',
  highlightSubtitle: 'Cinco motivos para ficar no LighChat.',
  moreTitle: 'Mais para explorar',
  moreSubtitle: 'O que o app faz além de trocar mensagens — pastas, tópicos, localização ao vivo e mais.',
  helpfulTitle: 'O que você ganha',
  howToTitle: 'Como ativar',
  relatedTitle: 'Veja também',
  backToList: 'Voltar aos recursos',
  fromWelcomeBadge: 'Tour',
  welcomeOverlay: {
    title: 'Descubra os recursos do LighChat',
    subtitle:
      'Dois minutos para ver o que torna o LighChat diferente: criptografia, conversas secretas, jogos e reuniões. Você pode voltar ao tour a qualquer momento pelo menu de configurações.',
    primaryCta: 'Dar uma olhada',
    secondaryCta: 'Depois',
    bullets: [
      'Criptografia ponta a ponta opcional para conversas e chamadas',
      'Conversas secretas que se autodestroem',
      'Jogos e videochamadas dentro do chat',
    ],
  },
  topics: {
    encryption: {
      title: 'Criptografia ponta a ponta',
      tagline: 'Ative — e só você e o destinatário poderão ler.',
      summary:
        'A criptografia ponta a ponta (E2EE) no LighChat é um modo opcional. Ative globalmente para todas as novas conversas ou apenas para uma conversa específica. Enquanto a E2EE estiver ativa, mensagens e mídia são criptografadas no seu dispositivo e descriptografadas apenas do outro lado — os servidores não conseguem ler o conteúdo, nem tecnicamente.',
      ctaLabel: 'Abrir dispositivos',
      sections: [
        {
          title: 'Ninguém mais lê',
          body: 'As chaves de criptografia ficam apenas nos seus dispositivos e nunca saem em texto aberto. O servidor vê tráfego criptografado e metadados de entrega, mas não texto, voz, arquivos ou pré-visualizações de links. Mesmo que o banco de dados fosse comprometido, suas conversas continuariam privadas.',
        },
        {
          title: 'Verifique seu contato',
          body: 'Cada dispositivo tem uma impressão digital — um código curto. Compare-o com seu contato pessoalmente ou por outro canal: se os códigos coincidirem, não há ninguém no meio. Mesmo modelo de confiança que o Signal e o WhatsApp usam em seus chats seguros.',
        },
        {
          title: 'Ative onde precisar',
          body: 'Nas Configurações você pode ativar a E2EE para todas as novas conversas de uma vez, ou ativar para uma conversa específica pelo cabeçalho. Uma vez ativo, tudo naquela conversa viaja criptografado — não só texto:',
          bullets: [
            'Mensagens de texto e reações',
            'Círculos de voz e vídeo',
            'Fotos, vídeos e arquivos',
            'Pré-visualizações de links e figurinhas',
          ],
        },
        {
          title: 'Recuperação sem sacrifícios',
          body: 'Perdeu o celular? Você pode manter um backup criptografado das suas chaves protegido por senha. A recuperação só funciona com essa senha — ninguém, incluindo nós, consegue acessar as chaves sem ela.',
        },
      ],
      howTo: [
        'Em Configurações → Privacidade, ative a E2EE por padrão para novas conversas.',
        'Para ativar em uma conversa existente, abra o cabeçalho da conversa e escolha "Criptografia".',
        'Em Configurações → Dispositivos, compare as impressões digitais das chaves com seu contato e ative o backup.',
      ],
    },
    'secret-chats': {
      title: 'Conversas secretas',
      tagline: 'Conversas que desaparecem e se recusam a encaminhar.',
      summary:
        'Uma conversa secreta é um modo mais restrito de conversa. As mensagens se apagam automaticamente por um temporizador, você pode bloquear completamente o encaminhamento e a cópia, fotos e vídeos abrem uma única vez, e a conversa pode ser trancada com uma senha separada ou biometria.',
      ctaLabel: 'Iniciar conversa secreta',
      sections: [
        {
          title: 'Temporizador de autodestruição',
          body: 'Escolha por quanto tempo as mensagens vivem, de 5 minutos a um dia. O temporizador conta dos dois lados — quando uma mensagem some, não pode ser recuperada em nenhum dispositivo.',
        },
        {
          title: 'Restrições rígidas',
          body: 'Bloqueie encaminhamento, citação, cópia de texto e salvamento de mídia. A política do servidor garante cada regra, e tentativas de captura de tela notificam seu contato.',
          bullets: [
            'Sem encaminhamento ou citação',
            'Sem copiar texto',
            'Sem salvar mídia',
            'Fotos e vídeos de visualização única',
          ],
        },
        {
          title: 'Uma trava além da criptografia',
          body: 'Além da E2EE normal, você pode colocar uma senha separada ou Face ID/Touch ID na própria conversa. Mesmo um celular desbloqueado deixado na mesa não vai revelá-la — o segundo fator é necessário para aquela conversa específica.',
        },
        {
          title: 'Controle total de acesso',
          body: 'Você pode apagar a conversa dos dois lados a qualquer momento, ou trancar a conversa. Ideal para assuntos de trabalho, questões legais e qualquer situação onde menos é mais.',
        },
      ],
      howTo: [
        'Toque no cabeçalho da conversa e abra Privacidade.',
        'Ative Conversa secreta e defina um temporizador.',
        'Opcionalmente ative as restrições e a trava.',
      ],
    },
    'disappearing-messages': {
      title: 'Mensagens temporárias',
      tagline: 'Pare de acumular conversas antigas.',
      summary:
        'Você não precisa guardar tudo para sempre. Defina um temporizador e as mensagens desaparecem silenciosamente para todos após 1 hora, um dia, uma semana ou um mês. Perfeito para conversas de trabalho, assuntos casuais e higiene básica de conversa.',
      ctaLabel: 'Abrir conversas',
      sections: [
        {
          title: 'Opções práticas',
          body: 'Sem necessidade de contar segundos — escolha uma opção pronta. O relógio começa no envio e funciona igual em conversas 1:1 e em grupos.',
          bullets: [
            '1 hora para assuntos pontuais',
            '24 horas para conversas do dia',
            '7 dias para tarefas semanais',
            '30 dias para um mês de margem',
          ],
        },
        {
          title: 'Limpo em todos os dispositivos',
          body: 'As mensagens desaparecem sincronizadas — no celular, na web e no desktop. Sem limpar arquivo, sem preocupação com uma cópia esquecida em algum lugar.',
        },
        {
          title: 'Sem restos na nuvem',
          body: 'Mensagens excluídas somem do servidor também. Elas não vão aparecer de um backup — isso não é "oculto", é realmente apagado.',
        },
      ],
      howTo: [
        'Abra uma conversa e toque no cabeçalho.',
        'Mensagens temporárias — escolha um temporizador.',
        'Novas mensagens vão durar exatamente esse tempo.',
      ],
    },
    'scheduled-messages': {
      title: 'Mensagens agendadas',
      tagline: 'Escreva agora, envie depois.',
      summary:
        'Preparando uma saudação matinal ou um lembrete de segunda para a equipe? Agende a mensagem e o servidor do LighChat vai entregá-la no momento certo. Você pode desligar o aparelho, fechar o app ou até ficar sem bateria — sua mensagem será enviada mesmo assim.',
      ctaLabel: 'Abrir conversas',
      sections: [
        {
          title: 'Sempre no horário',
          body: 'O envio acontece no servidor, não no seu celular. Diferente de temporizadores locais de outros mensageiros, o envio não vai falhar porque o aparelho está no avião, num túnel ou simplesmente offline.',
        },
        {
          title: 'Controle total da fila',
          body: 'Um painel separado mostra cada mensagem agendada. Edite o horário ou o texto, envie antes ou cancele — até ser enviada, a mensagem está totalmente sob seu controle.',
        },
        {
          title: 'Ótimo para equipes e para a vida',
          body: 'Aniversários, lembretes, standups matinais e qualquer mensagem que "não posso esquecer de enviar". Fusos horários são tratados automaticamente.',
        },
      ],
      howTo: [
        'Digite sua mensagem normalmente.',
        'Pressione e segure o botão de enviar → Agendar.',
        'Escolha a data e o horário. Pronto.',
      ],
    },
    games: {
      title: 'Jogos no chat',
      tagline: 'Convide amigos para um jogo de cartas dentro da conversa.',
      summary:
        'Sem app separado, sem cadastro à parte. Comece uma partida de Durak direto na conversa — em tempo real, cartas bonitas, jogadas instantâneas. Um motivo simples para reunir a turma à noite.',
      ctaLabel: 'Abrir conversas',
      sections: [
        {
          title: 'Tempo real e atmosfera',
          body: 'Os jogadores veem as jogadas uns dos outros instantaneamente. A partida continua enquanto você está no chat e pausa quando alguém sai. Provoque e discuta na mesma conversa, sem trocar de janela.',
        },
        {
          title: 'Regras conhecidas com dicas',
          body: 'Clássico "Durak com passe" — as regras que você conhece desde a infância. Dicas ajudam iniciantes; veteranos reconhecem o jogo na hora.',
        },
        {
          title: 'Integrado ao chat',
          body: 'A mesa abre dentro da mensagem e o resultado fica no histórico da conversa. Faz parte da conversa entre amigos, não é um app hiper-casual separado.',
        },
      ],
      howTo: [
        'Abra qualquer conversa ou grupo.',
        'Toque em "+" na entrada e escolha Jogo.',
        'Convide adversários e distribua as cartas.',
      ],
    },
    meetings: {
      title: 'Videochamadas em grupo',
      tagline: 'Até dezenas de pessoas em uma tela.',
      summary:
        'Videochamadas completas com grade de participantes, chat compartilhado, enquetes e solicitações de entrada. Convidados podem entrar por link sem conta — a página abre direto no navegador. Funciona tanto para reuniões de trabalho quanto para encontros em família.',
      ctaLabel: 'Abrir reuniões',
      sections: [
        {
          title: 'Grade prática e orador ativo',
          body: 'O orador ativo é destacado automaticamente. Fixe o participante que precisa, silencie alguém com um toque ou saia por um momento sem perder seu lugar.',
        },
        {
          title: 'Enquetes e solicitações de entrada',
          body: 'Faça enquetes durante a chamada: única, múltipla escolha ou anônima. Salas fechadas aceitam convidados por solicitação — o moderador aprova cada um manualmente.',
        },
        {
          title: 'Sem apps, sem contas',
          body: 'Para convidados, a reunião abre direto no navegador por link. Sem cliente para instalar, sem cadastro, sem esperar atualizações.',
        },
      ],
      howTo: [
        'Abra a aba Reuniões.',
        'Crie uma sala ou entre por link.',
        'Compartilhe o link com os participantes.',
      ],
    },
    calls: {
      title: 'Chamadas e círculos de vídeo',
      tagline: 'De uma chamada de voz a um recado em vídeo em um segundo.',
      summary:
        'Chamadas 1:1 WebRTC de alta qualidade e círculos de vídeo curtos direto no feed da conversa — para respostas rápidas quando digitar é lento demais e um áudio não basta. Rosto, emoção, voz — tudo em segundos. Em conversas com E2EE ativa, chamadas e círculos viajam criptografados também.',
      ctaLabel: 'Histórico de chamadas',
      sections: [
        {
          title: 'Estável em movimento',
          body: 'A chamada alterna entre Wi-Fi e rede móvel suavemente, mantém o áudio em qualquer túnel e adapta a resolução do vídeo à largura de banda. Sem "tá me ouvindo?" a cada trinta segundos.',
        },
        {
          title: 'Círculos de vídeo',
          body: 'Grave um círculo de até 60 segundos: rosto, emoção, um comentário rápido. O destinatário assiste inline — o círculo toca automaticamente, sem tela cheia, sem toques extras.',
        },
        {
          title: 'Criptografado ponta a ponta quando ativado',
          body: 'Quando a E2EE está ativa na conversa, chamadas e círculos viajam de dispositivo a dispositivo — o servidor não recebe áudio nem imagem, apenas o fluxo de entrega. Ative a criptografia no cabeçalho da conversa e chamadas e círculos assumem a proteção automaticamente.',
        },
      ],
      howTo: [
        'Toque no ícone de telefone ou câmera no cabeçalho da conversa.',
        'Para um círculo: pressione e segure o botão de gravação.',
        'Solte para enviar instantaneamente.',
      ],
    },
    'folders-threads': {
      title: 'Pastas e tópicos',
      tagline: 'Centenas de conversas sem bagunça.',
      summary:
        'Organize conversas em pastas — Trabalho, Família, Estudo, o que funcionar — e alterne entre elas com um toque. Dentro de conversas em grupo, abra tópicos sobre assuntos específicos para manter o chat principal limpo.',
      ctaLabel: 'Abrir conversas',
      sections: [
        {
          title: 'Quantas pastas precisar',
          body: 'Crie suas próprias pastas e arraste qualquer conversa para elas — DMs, grupos, canais. As pastas sincronizam entre celular, web e desktop, a ordem é preservada.',
        },
        {
          title: 'Tópicos em grupos',
          body: 'Responda a uma mensagem dentro de um tópico — a discussão fica lá enquanto o chat principal permanece legível. Especialmente valioso em grandes equipes e comunidades ativas.',
        },
        {
          title: 'Silencie conversas barulhentas',
          body: 'Uma pasta de conversas "silenciosas" não toca com notificações: som e emblemas são configurados no nível da pasta, não por conversa.',
        },
      ],
      howTo: [
        'Abra a barra de pastas e toque em Criar.',
        'Arraste conversas para uma pasta ou defina regras.',
        'Em um grupo, toque em "Responder no tópico" em qualquer mensagem.',
      ],
    },
    'live-location': {
      title: 'Compartilhamento de localização ao vivo',
      tagline: 'Mostre onde você está sem mexer no mapa.',
      summary:
        'Em vez de trocar capturas de tela, ative a localização ao vivo e seu contato vê você se movendo em tempo real. Ideal para encontros em um lugar novo, viagens de carro e para ficar de olho em quem você ama.',
      ctaLabel: 'Abrir conversas',
      sections: [
        {
          title: 'Compartilhamento com tempo',
          body: 'Escolha por quanto tempo compartilhar: 15 minutos, uma hora ou 8 horas. Depois disso, a transmissão para sozinha — você não vai esquecer de desligar.',
        },
        {
          title: 'Sem surpresas',
          body: 'Enquanto compartilha, um banner vermelho bem visível fica na conversa. Um toque para a transmissão — exatamente os passos necessários.',
        },
        {
          title: 'Econômico na bateria',
          body: 'Usa as mesmas APIs do sistema que apps nativos de Mapas, então o compartilhamento em segundo plano quase não gasta bateria e não interfere nas notificações.',
        },
      ],
      howTo: [
        'Na conversa, toque em "+" → Localização.',
        'Ative Ao vivo e escolha a duração.',
        'Toque no banner vermelho no topo para parar.',
      ],
    },
    'multi-device': {
      title: 'Múltiplos dispositivos',
      tagline: 'Uma conta, várias telas, nada se perde.',
      summary:
        'Conecte celular, tablet, web e desktop a uma única conta. As chaves de criptografia sincronizam via pareamento por QR e backup criptografado com senha — suas conversas ficam com você, mesmo se perder todos os dispositivos antigos.',
      ctaLabel: 'Gerenciar dispositivos',
      sections: [
        {
          title: 'Pareamento seguro por QR',
          body: 'Pareie um novo dispositivo escaneando um código QR de um antigo. As chaves viajam diretamente entre dispositivos e nunca ficam em texto aberto no servidor. Leva segundos, sem senhas longas para digitar.',
        },
        {
          title: 'Backup com senha',
          body: 'Criptografe um backup das suas chaves com sua própria senha — e recupere conversas em qualquer dispositivo novo, mesmo que tenha perdido todos os antigos. O backup é inútil para qualquer pessoa sem essa senha, incluindo nós.',
        },
        {
          title: 'Mesma experiência em todo lugar',
          body: 'Web, desktop e celular são construídos na mesma plataforma. Histórico de conversas, pastas, temas e configurações sincronizam entre dispositivos sem atrasos.',
        },
      ],
      howTo: [
        'No novo dispositivo, escolha Entrar com QR.',
        'No dispositivo antigo, abra Configurações → Dispositivos.',
        'Mostre o código QR. Pronto — as chaves estão no novo dispositivo.',
      ],
    },
    'stickers-media': {
      title: 'Figurinhas e mídia',
      tagline: 'Emoção, enquetes e edição rápida de fotos.',
      summary:
        'Pacotes de figurinhas variados, busca de GIFs direto na entrada, enquetes com um toque e editores de foto e vídeo integrados. Tudo para se comunicar de forma mais expressiva e rápida — sem trocar de app, sem perda de qualidade.',
      ctaLabel: 'Abrir conversas',
      sections: [
        {
          title: 'Figurinhas e GIFs',
          body: 'Adicione seus próprios pacotes e use o catálogo público. Busque GIFs direto na entrada — seus favoritos vão para Recentes automaticamente.',
        },
        {
          title: 'Enquetes e reações',
          body: 'Crie uma enquete em dois toques: única ou múltipla escolha, anônima ou aberta. Reações em mensagens para feedback rápido, para que as conversas não se encham de respostas de uma palavra.',
        },
        {
          title: 'Editores de foto e vídeo',
          body: 'Corte, desenhe, apare vídeo e adicione legenda — ferramentas integradas funcionam instantaneamente sem perda de qualidade. Sem necessidade de app externo para ajustar a mídia antes de enviar.',
        },
      ],
      howTo: [
        'Toque no smiley na entrada — figurinhas e GIFs.',
        'Para uma enquete: "+" → Enquete.',
        'Para o editor: toque em uma foto ou vídeo na pré-visualização.',
      ],
    },
    privacy: {
      title: 'Privacidade detalhada',
      tagline: 'Você decide o que os outros veem.',
      summary:
        'Cada detalhe tem seu próprio botão: status Online, Visto por último, Confirmação de leitura, quem pode te encontrar e quem pode te adicionar a um grupo. Configure em um minuto — funciona em todos os dispositivos.',
      ctaLabel: 'Abrir privacidade',
      sections: [
        {
          title: 'Visibilidade de atividade',
          body: 'Esconda Online e Visto por último de olhos indesejados. Confirmações de leitura também podem ser desativadas — os contatos não verão a marca azul, e você não verá a deles.',
        },
        {
          title: 'Quem te encontra',
          body: 'A busca global pode ser desativada — então você só é encontrado por pessoas que já têm seu contato salvo. Útil se não quer mensagens aleatórias.',
        },
        {
          title: 'Perfil para os outros',
          body: 'Decida se mostra e-mail, telefone, data de nascimento e bio no cartão de perfil. Cada campo tem seu próprio botão, sem modo "tudo ou nada".',
        },
        {
          title: 'Grupos pelas suas regras',
          body: 'Escolha quem pode te adicionar a um grupo: todos, apenas contatos ou ninguém. Isso elimina 99% dos grupos de marketing sem listas de bloqueio ou luta contra convites automáticos.',
        },
      ],
      howTo: [
        'Abra Configurações → Privacidade.',
        'Passe pelos botões e escolha seus padrões.',
        'Resetar retorna aos padrões seguros.',
      ],
    },
  },
  mockText: {
    e2eeBadge: 'Criptografia ponta a ponta',
    peerAlice: 'Alice',
    peerBob: 'Bob',
    peerHello: 'Oi, tudo bem?',
    fingerprintMatch: 'confere',
    groupProject: 'Grupo · Projeto',
    secretStatus: '6 membros',
    secretSettingsTitle: 'Regras do chat secreto',
    secretSettingTtl: 'Cronômetro',
    secretSettingTtlValue: 'em 1 hora',
    secretSettingNoForward: 'Proibir encaminhamento',
    secretSettingLock: 'Bloqueio do chat',
    secretMsg1: 'Enviando o arquivo de preços como visualização única.',
    secretMsg2: 'Recebi. Bloqueio de cópia ativado.',
    teamDesign: 'Equipe · Design',
    disappearingStatus: 'online',
    disappearingMsg1: 'Compartilhando o rascunho — vai sumir depois.',
    disappearingMsg2: 'OK, vou revisar até a noite.',
    disappearingMsg3: 'Um cabeçalho mais escuro ficaria melhor.',
    disappearingMsg4: 'Concordo. Aplicando e enviando.',
    peerMikhail: 'Miguel',
    mikhailStatus: 'visto por último hoje às 21:40',
    scheduledMsg1: 'Não esquece do lembrete do standup.',
    scheduledMsg2: 'Já agendei para de manhã.',
    scheduledMsg3: 'Bom dia! Standup começa em 15 minutos.',
    scheduledQueueTitle: 'Agendadas',
    scheduledQueueDate: 'amanhã, 08:45',
    gamesBadge: 'Durak · sua vez',
    gamesTrump: 'Trunfo',
    gamesDeck: 'Baralho',
    gamesYou: 'Você',
    gamesOpponent: 'Alice',
    gamesYourTurn: 'Sua vez',
    gamesActionBeat: 'Bater',
    gamesActionTake: 'Pegar',
    meetingDuration: 'Reunião · 24:18',
    meetingSpeaking: 'falando',
    callsAudioTitle: 'Chamada de voz',
    callsAudioMeta: '3:42 · qualidade HD',
    callsCircleTitle: 'Círculo de vídeo',
    callsCircleMeta: '0:42 / 1:00',
    folderAll: 'Todas',
    folderWork: 'Trabalho',
    folderFamily: 'Família',
    folderStudy: 'Estudo',
    folderStarred: 'Favoritas',
    folderWorkChats: 'Trabalho · conversas',
    chat1Name: 'Equipe · Design',
    chat1Last: 'Julia: enviou uma nova variante',
    chat2Name: 'Marketing',
    chat2Last: 'Konstantin: relatório está pronto',
    chat3Name: 'Lançamentos CRM',
    chat3Last: 'Alina: aguardando aprovação',
    threadTitle: 'Tópico · "Preço do plano" · 6 respostas',
    threadReply1: 'Acho que 4990 é o melhor',
    threadReply2: 'Concordo',
    liveLocationBanner: 'Compartilhando sua localização',
    liveLocationStop: 'Parar',
    multiDevicePhone: 'Celular',
    multiDeviceDesktop: 'Desktop',
    multiDevicePairing: 'Pareamento por QR',
    multiDeviceBackup: 'Backup de chaves',
    multiDeviceBackupSub: 'protegido por senha',
    stickerSearchHint: 'buscar figurinhas e GIFs',
    pollLabel: 'Enquete',
    pollTitle: 'Onde vamos no sábado?',
    pollOption1: 'Para a montanha',
    pollOption2: 'Para o sítio',
    editorLabel: 'Editor',
    editorHint: 'cortar · legenda',
    privacyTitle: 'Privacidade',
    privacySubtitle: 'Você decide o que os outros veem.',
    privacyOnline: 'Status online',
    privacyOnlineHint: 'Outros veem que você está online agora',
    privacyLastSeen: 'Visto por último',
    privacyLastSeenHint: 'Horário exato da sua última visita',
    privacyReceipts: 'Confirmação de leitura',
    privacyReceiptsHint: 'Marca dupla para o remetente',
    privacyGlobalSearch: 'Busca global',
    privacyGlobalSearchHint: 'Qualquer pessoa pode te encontrar pelo nome',
    privacyGroupAdd: 'Adição a grupos',
    privacyGroupAddHint: 'Apenas contatos',
  },
};

const esMX: FeaturesContent = {
  pageTitle: 'Funciones de LighChat',
  pageSubtitle:
    'Un recorrido rápido por lo que hace a LighChat más rápido, seguro y útil que un mensajero común. Cada función tiene su propia página con un ejemplo y pasos.',
  pageHeroPrimary: 'Conoce LighChat',
  pageHeroSecondary:
    'Cifrado de extremo a extremo opcional, chats secretos que se autodestruyen, mensajes programados, videollamadas y hasta juegos — todo en una app sin anuncios. Descúbrelo en un par de minutos.',
  highlightTitle: 'Más útiles',
  highlightSubtitle: 'Cinco razones para quedarse en LighChat.',
  moreTitle: 'Más por explorar',
  moreSubtitle: 'Lo que la app hace más allá de chatear — carpetas, hilos, ubicación en vivo y más.',
  helpfulTitle: 'Lo que obtienes',
  howToTitle: 'Cómo activarlo',
  relatedTitle: 'Ver también',
  backToList: 'Volver a las funciones',
  fromWelcomeBadge: 'Tour',
  welcomeOverlay: {
    title: 'Descubre las funciones de LighChat',
    subtitle:
      'Dos minutos para ver qué hace diferente a LighChat: cifrado, chats secretos, juegos y reuniones. Pueden volver al tour en cualquier momento desde el menú de ajustes.',
    primaryCta: 'Echar un vistazo',
    secondaryCta: 'Después',
    bullets: [
      'Cifrado de extremo a extremo opcional para chats y llamadas',
      'Chats secretos que se autodestruyen',
      'Juegos y videollamadas dentro del chat',
    ],
  },
  topics: {
    encryption: {
      title: 'Cifrado de extremo a extremo',
      tagline: 'Actívenlo — y solo ustedes y el destinatario podrán leerlo.',
      summary:
        'El cifrado de extremo a extremo (E2EE) en LighChat es un modo opcional. Actívenlo de forma global para todos los chats nuevos o solo para una conversación específica. Mientras la E2EE esté activa, los mensajes y archivos multimedia se cifran en su dispositivo y se descifran únicamente del otro lado — los servidores no pueden leer el contenido ni técnicamente.',
      ctaLabel: 'Abrir dispositivos',
      sections: [
        {
          title: 'Nadie más lo lee',
          body: 'Las llaves de cifrado viven solo en sus dispositivos y nunca salen en texto plano. El servidor ve tráfico cifrado y metadatos de entrega, pero no texto, voz, archivos ni vistas previas de enlaces. Incluso si la base de datos fuera comprometida, sus conversaciones seguirían siendo privadas.',
        },
        {
          title: 'Verifiquen a su contacto',
          body: 'Cada dispositivo tiene una huella digital — un código corto. Compárenlo con su contacto en persona o por un canal aparte: si los códigos coinciden, no hay nadie en el medio. El mismo modelo de confianza que usan Signal y WhatsApp en sus chats seguros.',
        },
        {
          title: 'Actívenlo donde lo necesiten',
          body: 'En Ajustes pueden activar la E2EE para todos los chats nuevos de una vez, o activarla para una conversación específica desde su encabezado. Una vez activo, todo en ese chat viaja cifrado — no solo texto:',
          bullets: [
            'Mensajes de texto y reacciones',
            'Círculos de voz y video',
            'Fotos, videos y archivos',
            'Vistas previas de enlaces y stickers',
          ],
        },
        {
          title: 'Recuperación sin sacrificios',
          body: '¿Perdieron su celular? Pueden mantener un respaldo cifrado de sus llaves protegido con contraseña. La recuperación solo funciona con esa contraseña — nadie, incluyéndonos, puede acceder a las llaves sin ella.',
        },
      ],
      howTo: [
        'En Ajustes → Privacidad, activen la E2EE por defecto para chats nuevos.',
        'Para activarla en un chat existente, abran el encabezado del chat y elijan "Cifrado".',
        'En Ajustes → Dispositivos, comparen las huellas de las llaves con su contacto y activen el respaldo.',
      ],
    },
    'secret-chats': {
      title: 'Chats secretos',
      tagline: 'Chats que desaparecen y se niegan a reenviar.',
      summary:
        'Un chat secreto es un modo más estricto de conversación. Los mensajes se autoborran con un temporizador, pueden bloquear completamente el reenvío y la copia, las fotos y videos se abren una sola vez, y el chat puede bloquearse con una contraseña aparte o biometría.',
      ctaLabel: 'Iniciar chat secreto',
      sections: [
        {
          title: 'Temporizador de autodestrucción',
          body: 'Elijan cuánto tiempo viven los mensajes, desde 5 minutos hasta un día. El temporizador cuenta en ambos lados — cuando un mensaje desaparece, no se puede recuperar en ningún dispositivo.',
        },
        {
          title: 'Restricciones estrictas',
          body: 'Bloqueen reenvío, citas, copia de texto y guardado de multimedia. La política del servidor hace cumplir cada regla, y los intentos de captura de pantalla notifican a su contacto.',
          bullets: [
            'Sin reenvío ni citas',
            'Sin copiar texto',
            'Sin guardar multimedia',
            'Fotos y videos de vista única',
          ],
        },
        {
          title: 'Un candado además del cifrado',
          body: 'Además de la E2EE normal, pueden poner una contraseña aparte o Face ID/Touch ID en el chat mismo. Incluso un celular desbloqueado dejado en la mesa no lo revelará — el segundo factor es necesario para ese chat específico.',
        },
        {
          title: 'Control total de acceso',
          body: 'Pueden borrar la conversación en ambos lados en cualquier momento, o bloquear el chat. Ideal para temas de trabajo, asuntos legales y cualquier situación donde menos es más.',
        },
      ],
      howTo: [
        'Toquen el encabezado del chat y abran Privacidad.',
        'Activen Chat secreto y definan un temporizador.',
        'Opcionalmente activen las restricciones y el candado.',
      ],
    },
    'disappearing-messages': {
      title: 'Mensajes temporales',
      tagline: 'Dejen de acumular conversaciones viejas.',
      summary:
        'No tienen que guardar todo para siempre. Pongan un temporizador y los mensajes desaparecen silenciosamente para todos después de 1 hora, un día, una semana o un mes. Perfecto para hilos de trabajo, temas casuales e higiene básica de conversación.',
      ctaLabel: 'Abrir chats',
      sections: [
        {
          title: 'Opciones prácticas',
          body: 'Sin necesidad de contar segundos — elijan una opción predefinida. El reloj empieza al enviar y funciona igual en chats 1:1 y en grupos.',
          bullets: [
            '1 hora para asuntos puntuales',
            '24 horas para hilos diarios',
            '7 días para tareas semanales',
            '30 días para un mes de margen',
          ],
        },
        {
          title: 'Limpio en todos los dispositivos',
          body: 'Los mensajes desaparecen sincronizados — en el celular, la web y la computadora. Sin limpiar archivos, sin preocuparse por una copia olvidada en algún lado.',
        },
        {
          title: 'Sin restos en la nube',
          body: 'Los mensajes eliminados también desaparecen del servidor. No van a aparecer de un respaldo — esto no es "oculto", realmente está eliminado.',
        },
      ],
      howTo: [
        'Abran un chat y toquen el encabezado.',
        'Mensajes temporales — elijan un temporizador.',
        'Los nuevos mensajes van a durar exactamente ese tiempo.',
      ],
    },
    'scheduled-messages': {
      title: 'Mensajes programados',
      tagline: 'Escriban ahora, envíen después.',
      summary:
        '¿Preparando un saludo matutino o un recordatorio del lunes para el equipo? Programen el mensaje y el servidor de LighChat lo entregará en el momento justo. Pueden apagar el dispositivo, cerrar la app o quedarse sin batería — su mensaje se enviará de todas formas.',
      ctaLabel: 'Abrir chats',
      sections: [
        {
          title: 'Siempre a tiempo',
          body: 'El envío sucede en el servidor, no en su celular. A diferencia de temporizadores locales de otros mensajeros, el envío no va a fallar porque el dispositivo está en el avión, en un túnel o simplemente sin conexión.',
        },
        {
          title: 'Control total de la cola',
          body: 'Un panel aparte muestra cada mensaje programado. Editen el horario o el texto, envíen antes o cancelen — hasta que se envíe, el mensaje está totalmente bajo su control.',
        },
        {
          title: 'Genial para equipos y para la vida',
          body: 'Cumpleaños, recordatorios, standups matutinos y cualquier mensaje que "no debo olvidar enviar". Las zonas horarias se manejan automáticamente.',
        },
      ],
      howTo: [
        'Escriban su mensaje como siempre.',
        'Mantengan presionado el botón de enviar → Programar.',
        'Elijan la fecha y la hora. Listo.',
      ],
    },
    games: {
      title: 'Juegos en el chat',
      tagline: 'Inviten amigos a un juego de cartas dentro del chat.',
      summary:
        'Sin app aparte, sin registro adicional. Inicien una partida de Durak directo en el chat — en tiempo real, cartas bonitas, jugadas instantáneas. Una razón sencilla para reunirse por la noche.',
      ctaLabel: 'Abrir chats',
      sections: [
        {
          title: 'Tiempo real y ambiente',
          body: 'Los jugadores ven las jugadas de los demás al instante. La partida continúa mientras estén en el chat y se pausa cuando alguien se sale. Bromeen y discutan en la misma conversación, sin cambiar de ventana.',
        },
        {
          title: 'Reglas conocidas con ayudas',
          body: 'Clásico "Durak con pase" — las reglas que conocen desde niños. Las ayudas orientan a los nuevos; los veteranos reconocen su juego de inmediato.',
        },
        {
          title: 'Integrado al chat',
          body: 'La mesa se abre dentro del mensaje y el resultado queda en el historial del chat. Es parte de la conversación entre amigos, no una app hiper-casual separada.',
        },
      ],
      howTo: [
        'Abran cualquier chat o grupo.',
        'Toquen "+" en la entrada y elijan Juego.',
        'Inviten oponentes y repartan.',
      ],
    },
    meetings: {
      title: 'Videollamadas en grupo',
      tagline: 'Hasta decenas de personas en una pantalla.',
      summary:
        'Videollamadas completas con cuadrícula de participantes, chat compartido, encuestas y solicitudes de ingreso. Los invitados pueden unirse por enlace sin cuenta — la página se abre directo en su navegador. Funciona para juntas de trabajo y reuniones familiares.',
      ctaLabel: 'Abrir reuniones',
      sections: [
        {
          title: 'Cuadrícula práctica y orador activo',
          body: 'El orador activo se resalta automáticamente. Fijen al participante que necesiten, silencien a alguien con un toque o salgan un momento sin perder su lugar.',
        },
        {
          title: 'Encuestas y solicitudes de ingreso',
          body: 'Hagan encuestas durante la llamada: de opción única, múltiple o anónima. Las salas cerradas aceptan invitados por solicitud — el moderador aprueba cada uno manualmente.',
        },
        {
          title: 'Sin apps, sin cuentas',
          body: 'Para los invitados, la reunión se abre directo en el navegador por enlace. Sin cliente que instalar, sin registro, sin esperar actualizaciones.',
        },
      ],
      howTo: [
        'Abran la pestaña de Reuniones.',
        'Creen una sala o únanse por enlace.',
        'Compartan el enlace con los participantes.',
      ],
    },
    calls: {
      title: 'Llamadas y círculos de video',
      tagline: 'De una llamada de voz a un mensaje en video en un segundo.',
      summary:
        'Llamadas 1:1 WebRTC de alta calidad y círculos de video cortos directo en el feed del chat — para respuestas rápidas cuando escribir es muy lento y una nota de voz no alcanza. Rostro, emoción, voz — todo en segundos. En chats con E2EE activa, llamadas y círculos viajan cifrados también.',
      ctaLabel: 'Historial de llamadas',
      sections: [
        {
          title: 'Estable en movimiento',
          body: 'La llamada alterna entre Wi-Fi y datos móviles suavemente, mantiene el audio en cualquier túnel y adapta la resolución del video al ancho de banda. Sin "¿me escuchan?" cada treinta segundos.',
        },
        {
          title: 'Círculos de video',
          body: 'Graben un círculo de hasta 60 segundos: rostro, emoción, un comentario rápido. El destinatario lo ve inline — el círculo se reproduce automáticamente, sin pantalla completa, sin toques extra.',
        },
        {
          title: 'Cifrado de extremo a extremo cuando está activo',
          body: 'Cuando la E2EE está activa en el chat, llamadas y círculos viajan de dispositivo a dispositivo — el servidor no recibe audio ni imagen, solo el flujo de entrega. Activen el cifrado en el encabezado del chat y las llamadas y círculos toman la protección automáticamente.',
        },
      ],
      howTo: [
        'Toquen el ícono de teléfono o cámara en el encabezado del chat.',
        'Para un círculo: mantengan presionado el botón de grabación.',
        'Suelten para enviar al instante.',
      ],
    },
    'folders-threads': {
      title: 'Carpetas e hilos',
      tagline: 'Cientos de chats sin el caos.',
      summary:
        'Organicen chats en carpetas — Trabajo, Familia, Estudio, lo que les funcione — y cambien entre ellas con un toque. Dentro de conversaciones grupales, abran hilos sobre temas específicos para mantener el chat principal limpio.',
      ctaLabel: 'Abrir chats',
      sections: [
        {
          title: 'Todas las carpetas que necesiten',
          body: 'Creen sus propias carpetas y arrastren cualquier chat a ellas — DMs, grupos, canales. Las carpetas se sincronizan entre celular, web y computadora, el orden se conserva.',
        },
        {
          title: 'Hilos en grupos',
          body: 'Respondan a un mensaje dentro de un hilo — la discusión se queda ahí mientras el chat principal sigue legible. Especialmente valioso en equipos grandes y comunidades activas.',
        },
        {
          title: 'Silencien chats ruidosos',
          body: 'Una carpeta de chats "silenciosos" no suena con notificaciones: el sonido y las insignias se configuran a nivel de carpeta, no por chat.',
        },
      ],
      howTo: [
        'Abran la barra de carpetas y toquen Crear.',
        'Arrastren chats a una carpeta o definan reglas.',
        'En un grupo, toquen "Responder en hilo" en cualquier mensaje.',
      ],
    },
    'live-location': {
      title: 'Ubicación en vivo',
      tagline: 'Muestren dónde están sin batallar con el mapa.',
      summary:
        'En lugar de intercambiar capturas de pantalla, activen la ubicación en vivo y su contacto los ve moverse en tiempo real. Ideal para verse en un lugar nuevo, viajes en carro y para estar al pendiente de sus seres queridos.',
      ctaLabel: 'Abrir chats',
      sections: [
        {
          title: 'Compartir con tiempo',
          body: 'Elijan por cuánto tiempo compartir: 15 minutos, una hora u 8 horas. Después de eso, la transmisión se detiene sola — no se les va a olvidar apagarla.',
        },
        {
          title: 'Sin sorpresas',
          body: 'Mientras comparten, un banner rojo bien visible permanece en el chat. Un toque detiene la transmisión — exactamente los pasos necesarios.',
        },
        {
          title: 'Amigable con la batería',
          body: 'Usa las mismas APIs del sistema que las apps nativas de Mapas, así que compartir en segundo plano casi no gasta batería y no interfiere con las notificaciones.',
        },
      ],
      howTo: [
        'En un chat, toquen "+" → Ubicación.',
        'Activen En vivo y elijan la duración.',
        'Toquen el banner rojo de arriba para detenerlo.',
      ],
    },
    'multi-device': {
      title: 'Múltiples dispositivos',
      tagline: 'Una cuenta, muchas pantallas, nada se pierde.',
      summary:
        'Conecten celular, tableta, web y computadora a una sola cuenta. Las llaves de cifrado se sincronizan por emparejamiento QR y un respaldo cifrado con contraseña — sus conversaciones se quedan con ustedes, aunque pierdan todos los dispositivos viejos.',
      ctaLabel: 'Administrar dispositivos',
      sections: [
        {
          title: 'Emparejamiento seguro por QR',
          body: 'Emparejen un dispositivo nuevo escaneando un código QR del anterior. Las llaves viajan directamente entre dispositivos y nunca quedan en texto plano en el servidor. Toma segundos, sin contraseñas largas que escribir.',
        },
        {
          title: 'Respaldo con contraseña',
          body: 'Cifren un respaldo de sus llaves con su propia contraseña — y recuperen chats en cualquier dispositivo nuevo, aunque hayan perdido todos los anteriores. El respaldo es inútil para cualquier persona sin esa contraseña, incluyéndonos.',
        },
        {
          title: 'Misma experiencia en todos lados',
          body: 'Web, computadora y celular están construidos sobre la misma plataforma. Historial de chats, carpetas, temas y ajustes se sincronizan entre dispositivos sin retrasos.',
        },
      ],
      howTo: [
        'En el dispositivo nuevo, elijan Iniciar sesión con QR.',
        'En el dispositivo anterior, abran Ajustes → Dispositivos.',
        'Muestren el código QR. Listo — las llaves están en el nuevo dispositivo.',
      ],
    },
    'stickers-media': {
      title: 'Stickers y multimedia',
      tagline: 'Emoción, encuestas y edición rápida de fotos.',
      summary:
        'Paquetes de stickers variados, búsqueda de GIFs directo en la entrada, encuestas con un toque y editores de foto y video integrados. Todo para comunicarse de forma más expresiva y rápida — sin cambiar de app, sin pérdida de calidad.',
      ctaLabel: 'Abrir chats',
      sections: [
        {
          title: 'Stickers y GIFs',
          body: 'Agreguen sus propios paquetes y usen el catálogo público. Busquen GIFs directo desde la entrada — sus favoritos van a Recientes automáticamente.',
        },
        {
          title: 'Encuestas y reacciones',
          body: 'Creen una encuesta en dos toques: de opción única o múltiple, anónima o abierta. Reacciones en mensajes para feedback rápido, para que los chats no se llenen de respuestas de una sola palabra.',
        },
        {
          title: 'Editores de foto y video',
          body: 'Recorten, dibujen, corten video y pongan leyenda — las herramientas integradas funcionan al instante sin pérdida de calidad. Sin necesidad de una app externa para arreglar multimedia antes de enviar.',
        },
      ],
      howTo: [
        'Toquen la carita en la entrada — stickers y GIFs.',
        'Para una encuesta: "+" → Encuesta.',
        'Para el editor: toquen una foto o video en la vista previa.',
      ],
    },
    privacy: {
      title: 'Privacidad detallada',
      tagline: 'Ustedes deciden qué ven los demás.',
      summary:
        'Cada detalle tiene su propio interruptor: estado En línea, Última conexión, Confirmación de lectura, quién puede encontrarlos y quién puede agregarlos a un grupo. Configúrenlo en un minuto — funciona en todos los dispositivos.',
      ctaLabel: 'Abrir privacidad',
      sections: [
        {
          title: 'Visibilidad de actividad',
          body: 'Oculten En línea y Última conexión de ojos indeseados. Las confirmaciones de lectura también se pueden desactivar — los contactos no verán la palomita azul, y ustedes no verán la de ellos.',
        },
        {
          title: 'Quién los encuentra',
          body: 'La búsqueda global se puede desactivar — entonces solo los pueden encontrar personas que ya tienen su contacto guardado. Útil si no quieren mensajes de desconocidos.',
        },
        {
          title: 'Perfil para los demás',
          body: 'Decidan si muestran correo, teléfono, fecha de nacimiento y bio en la tarjeta de perfil. Cada campo tiene su propio interruptor, sin modo de "todo o nada".',
        },
        {
          title: 'Grupos bajo sus reglas',
          body: 'Elijan quién puede agregarlos a un grupo: todos, solo contactos o nadie. Eso elimina el 99% de los grupos de marketing sin listas de bloqueo ni pelear con invitaciones automáticas.',
        },
      ],
      howTo: [
        'Abran Ajustes → Privacidad.',
        'Revisen los interruptores y elijan sus valores por defecto.',
        'Restablecer regresa a los valores seguros.',
      ],
    },
  },
  mockText: {
    e2eeBadge: 'Cifrado de extremo a extremo',
    peerAlice: 'Alice',
    peerBob: 'Bob',
    peerHello: '¡Hola! ¿Cómo están?',
    fingerprintMatch: 'coincide',
    groupProject: 'Grupo · Proyecto',
    secretStatus: '6 miembros',
    secretSettingsTitle: 'Reglas del chat secreto',
    secretSettingTtl: 'Temporizador',
    secretSettingTtlValue: 'en 1 hora',
    secretSettingNoForward: 'Bloquear reenvío',
    secretSettingLock: 'Bloqueo del chat',
    secretMsg1: 'Enviando el archivo de precios como vista única.',
    secretMsg2: 'Listo. Bloqueo de copia activado.',
    teamDesign: 'Equipo · Diseño',
    disappearingStatus: 'en línea',
    disappearingMsg1: 'Compartiendo el borrador — desaparecerá después.',
    disappearingMsg2: 'OK, lo reviso en la noche.',
    disappearingMsg3: 'Un encabezado más oscuro se vería mejor.',
    disappearingMsg4: 'De acuerdo. Aplicando y subiendo.',
    peerMikhail: 'Miguel',
    mikhailStatus: 'últ. vez hoy a las 21:40',
    scheduledMsg1: 'No olviden el recordatorio del standup.',
    scheduledMsg2: 'Ya lo programé para la mañana.',
    scheduledMsg3: '¡Buenos días! El standup empieza en 15 minutos.',
    scheduledQueueTitle: 'Programados',
    scheduledQueueDate: 'mañana, 08:45',
    gamesBadge: 'Durak · tu turno',
    gamesTrump: 'Triunfo',
    gamesDeck: 'Baraja',
    gamesYou: 'Tú',
    gamesOpponent: 'Alice',
    gamesYourTurn: 'Tu turno',
    gamesActionBeat: 'Ganar',
    gamesActionTake: 'Tomar',
    meetingDuration: 'Reunión · 24:18',
    meetingSpeaking: 'hablando',
    callsAudioTitle: 'Llamada de voz',
    callsAudioMeta: '3:42 · calidad HD',
    callsCircleTitle: 'Círculo de video',
    callsCircleMeta: '0:42 / 1:00',
    folderAll: 'Todos',
    folderWork: 'Trabajo',
    folderFamily: 'Familia',
    folderStudy: 'Estudio',
    folderStarred: 'Destacados',
    folderWorkChats: 'Trabajo · chats',
    chat1Name: 'Equipo · Diseño',
    chat1Last: 'Julia: subió una nueva variante',
    chat2Name: 'Marketing',
    chat2Last: 'Konstantin: el reporte está listo',
    chat3Name: 'Lanzamientos CRM',
    chat3Last: 'Alina: esperando aprobación',
    threadTitle: 'Hilo · "Precio del plan" · 6 respuestas',
    threadReply1: 'Yo creo que 4990 queda mejor',
    threadReply2: 'De acuerdo',
    liveLocationBanner: 'Compartiendo tu ubicación',
    liveLocationStop: 'Detener',
    multiDevicePhone: 'Celular',
    multiDeviceDesktop: 'Computadora',
    multiDevicePairing: 'Emparejamiento QR',
    multiDeviceBackup: 'Respaldo de llaves',
    multiDeviceBackupSub: 'protegido con contraseña',
    stickerSearchHint: 'buscar stickers y GIFs',
    pollLabel: 'Encuesta',
    pollTitle: '¿A dónde vamos el sábado?',
    pollOption1: 'A la montaña',
    pollOption2: 'Al campo',
    editorLabel: 'Editor',
    editorHint: 'recortar · leyenda',
    privacyTitle: 'Privacidad',
    privacySubtitle: 'Ustedes deciden qué ven los demás.',
    privacyOnline: 'Estado en línea',
    privacyOnlineHint: 'Los demás ven que están en línea',
    privacyLastSeen: 'Última conexión',
    privacyLastSeenHint: 'Hora exacta de su última visita',
    privacyReceipts: 'Confirmación de lectura',
    privacyReceiptsHint: 'Doble palomita para el remitente',
    privacyGlobalSearch: 'Búsqueda global',
    privacyGlobalSearchHint: 'Cualquier persona puede encontrarlos por nombre',
    privacyGroupAdd: 'Agregar a grupos',
    privacyGroupAddHint: 'Solo contactos',
  },
};

import type { ResolvedWebLocale } from '@/lib/i18n/preference';
import { kk } from './content/kk';
import { tr } from './content/tr';
import { uz } from './content/uz';
import { id_ID } from './content/id';

const CONTENT: Record<ResolvedWebLocale, FeaturesContent> = {
  ru,
  en,
  kk,
  uz,
  tr,
  id: id_ID,
  'pt-BR': ptBR,
  'es-MX': esMX,
};

export function getFeaturesContent(locale: ResolvedWebLocale): FeaturesContent {
  return CONTENT[locale] ?? ru;
}
