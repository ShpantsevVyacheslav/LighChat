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
  /** Короткий заголовок (≤6 слов). */
  title: string;
  /** Тизер на главной (1 строка). */
  tagline: string;
  /** Подзаголовок на детальной странице (1–2 предложения). */
  summary: string;
  /** CTA-кнопка «Попробовать». */
  ctaLabel: string;
  /** Секции «Что это даёт». */
  sections: FeatureSection[];
  /** Шаги «Как включить». */
  howTo: string[];
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
};

const ru: FeaturesContent = {
  pageTitle: 'Возможности LighChat',
  pageSubtitle:
    'Короткий тур по тому, что делает LighChat быстрее, безопаснее и интереснее обычного мессенджера.',
  pageHeroPrimary: 'Знакомьтесь с LighChat',
  pageHeroSecondary:
    'Сильное шифрование, секретные чаты, отложенные сообщения и встроенные игры. Откройте всё за пару минут.',
  highlightTitle: 'Самое полезное',
  highlightSubtitle: 'Пять фишек, ради которых пользователи остаются.',
  moreTitle: 'Ещё интересного',
  moreSubtitle: 'Что ещё умеет приложение, помимо переписки.',
  helpfulTitle: 'Что это даёт',
  howToTitle: 'Как включить',
  relatedTitle: 'Смотрите также',
  backToList: 'К списку возможностей',
  fromWelcomeBadge: 'Знакомство',
  welcomeOverlay: {
    title: 'Откройте возможности LighChat',
    subtitle:
      'За 2 минуты покажем, чем LighChat отличается от привычных мессенджеров. Можно вернуться к туру в любой момент через настройки.',
    primaryCta: 'Посмотреть',
    secondaryCta: 'Позже',
    bullets: [
      'Сквозное шифрование сообщений и звонков',
      'Секретные чаты с самоуничтожением',
      'Игры и видеовстречи прямо в чате',
    ],
  },
  topics: {
    encryption: {
      title: 'Сквозное шифрование',
      tagline: 'Сообщения видите только вы и собеседник.',
      summary:
        'Каждое личное сообщение и звонок шифруются на вашем устройстве и расшифровываются только у получателя. Серверы LighChat не могут прочитать переписку — даже если бы захотели.',
      ctaLabel: 'Перейти к устройствам',
      sections: [
        {
          title: 'Никто посторонний не прочитает',
          body: 'Ключи живут только на ваших устройствах. Сервер видит зашифрованный трафик и метаданные, но не содержимое сообщений и медиа.',
        },
        {
          title: 'Подтверждение собеседника',
          body: 'Можно сравнить отпечаток ключа в карточке устройства — короткий цифровой код. Если он совпал у вас и собеседника, посередине нет «третьего».',
        },
        {
          title: 'Шифруется всё',
          body: 'Шифрование включается автоматически для текста, голосовых, фото, файлов и медиа в личных чатах.',
          bullets: [
            'Текстовые сообщения и реакции',
            'Голосовые и видео-кружки',
            'Фото, видео и файлы',
            'Превью ссылок и стикеры',
          ],
        },
      ],
      howTo: [
        'Откройте Настройки → Устройства.',
        'Проверьте список своих устройств и отпечатки ключей.',
        'Уберите устройства, которыми больше не пользуетесь.',
      ],
    },
    'secret-chats': {
      title: 'Секретные чаты',
      tagline: 'Чаты, которые исчезают и не разрешают пересылать.',
      summary:
        'Секретный чат живёт по строгим правилам: сообщения сами удаляются по таймеру, можно запретить пересылку, скриншоты и копирование, а медиа открывается один раз.',
      ctaLabel: 'Начать секретный чат',
      sections: [
        {
          title: 'Самоуничтожение по таймеру',
          body: 'Выбирайте, через сколько сообщения исчезают: от 5 минут до суток. Таймер отсчитывается у обеих сторон.',
        },
        {
          title: 'Жёсткие ограничения',
          body: 'Включите запрет на пересылку, цитирование и сохранение медиа. Серверная политика не пропустит копию мимо правил.',
          bullets: [
            'Запрет пересылки и цитат',
            'Запрет копирования текста',
            'Запрет сохранения медиа',
            'Одноразовый просмотр фото и видео',
          ],
        },
        {
          title: 'Замок на чат',
          body: 'Доступ к секретному чату можно закрыть отдельным паролем или биометрией — даже разблокированный телефон не выдаст переписку.',
        },
      ],
      howTo: [
        'В чате нажмите шапку и откройте «Конфиденциальность».',
        'Включите режим «Секретный чат» и задайте таймер.',
        'Дополнительно включите запреты и замок.',
      ],
    },
    'disappearing-messages': {
      title: 'Исчезающие сообщения',
      tagline: 'Переписка не копится в архивах.',
      summary:
        'Включите таймер в обычном чате — и сообщения будут исчезать у всех участников через 1 час, сутки, неделю или месяц. Удобно для рабочих обсуждений и случайных тем.',
      ctaLabel: 'Открыть чат',
      sections: [
        {
          title: 'Удобные пресеты',
          body: 'Готовые таймеры покрывают большинство случаев — от часа до тридцати дней. Время отсчитывается с момента отправки.',
          bullets: ['1 час — для разовых вопросов', '24 часа — для дневной переписки', '7 дней — для недельных задач', '30 дней — длинный буфер'],
        },
        {
          title: 'Чисто на всех устройствах',
          body: 'Сообщения исчезают синхронно: на телефоне, в вебе и на десктопе. Отдельно чистить архив не нужно.',
        },
      ],
      howTo: [
        'Откройте чат и нажмите на шапку.',
        'Раздел «Исчезающие сообщения» — выберите таймер.',
        'Все новые сообщения будут жить заданное время.',
      ],
    },
    'scheduled-messages': {
      title: 'Отложенные сообщения',
      tagline: 'Напишите сейчас — отправится в нужный момент.',
      summary:
        'Готовите поздравление к утру или напоминание команде на понедельник? Поставьте сообщение в очередь — сервер LighChat сам отправит его в назначенное время.',
      ctaLabel: 'Открыть чат',
      sections: [
        {
          title: 'Точно в срок',
          body: 'Отправка происходит на сервере, не на вашем телефоне. Можно выключить устройство и закрыть приложение — сообщение всё равно уйдёт.',
        },
        {
          title: 'Полный контроль',
          body: 'Все запланированные сообщения видны в отдельной панели. Можно изменить время, отредактировать текст или отменить отправку.',
        },
      ],
      howTo: [
        'Введите текст сообщения как обычно.',
        'Зажмите кнопку отправки — выберите «Запланировать».',
        'Выберите дату и время. Готово.',
      ],
    },
    games: {
      title: 'Игры в чате',
      tagline: 'Зовите друзей в «Дурака» прямо в переписке.',
      summary:
        'Не нужно ставить отдельное приложение. Запустите партию в «Дурака» прямо в чате — игра идёт в реальном времени, а карты выглядят так же красиво, как настоящие.',
      ctaLabel: 'Открыть чат',
      sections: [
        {
          title: 'Реальное время',
          body: 'Игроки видят ходы друг друга мгновенно. Партия живёт пока вы в чате и сохраняется, если кто-то отвлёкся.',
        },
        {
          title: 'Понятные правила',
          body: 'Поддерживается классический «Дурак» с подкидыванием. Подсказки помогут новичку, а ветеран сразу узнает родные правила.',
        },
      ],
      howTo: [
        'Откройте любой чат с другом или группу.',
        'Нажмите «+» и выберите «Игра».',
        'Пригласите соперников — и сдавайте.',
      ],
    },
    meetings: {
      title: 'Видеовстречи',
      tagline: 'До нескольких десятков человек на одном экране.',
      summary:
        'Полноценные видеоконференции с сеткой участников, чатом, опросами и заявками на вход. Подключаться можно по ссылке — даже без аккаунта.',
      ctaLabel: 'Перейти к встречам',
      sections: [
        {
          title: 'Удобная сетка',
          body: 'Активный спикер выделяется автоматически. Можно закрепить нужного участника, отключить чужой звук или выйти из эфира на время.',
        },
        {
          title: 'Опросы и заявки',
          body: 'Запускайте голосования прямо во время встречи. Закрытая комната принимает гостей по заявке — модератор подтверждает вход.',
        },
      ],
      howTo: [
        'Откройте раздел «Встречи».',
        'Создайте новую комнату или подключитесь по ссылке.',
        'Поделитесь ссылкой с участниками.',
      ],
    },
    calls: {
      title: 'Звонки и видео-кружки',
      tagline: 'От голосового до видео-открытки за секунду.',
      summary:
        'Качественные 1:1-звонки на WebRTC с шифрованием и короткие видео-кружки прямо в ленте чата — для коротких реплик, когда лень печатать.',
      ctaLabel: 'История звонков',
      sections: [
        {
          title: 'Стабильное качество',
          body: 'Звонок переключается между сетями, держит звук в любом тоннеле и автоматически выбирает разрешение видео под канал.',
        },
        {
          title: 'Видео-кружки',
          body: 'Запишите кружок до 60 секунд: лицо, эмоция, голос. Получатель смотрит без распаковки — кружок играет прямо в ленте.',
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
        'Раскладывайте чаты по папкам — «Работа», «Семья», «Учёба», как удобно. А внутри группы запускайте треды по конкретным темам, чтобы основной чат не превращался в кашу.',
      ctaLabel: 'Открыть чаты',
      sections: [
        {
          title: 'Свои папки',
          body: 'Создайте сколько угодно папок и тяните в них любые чаты. Папки синхронизируются между телефоном, вебом и десктопом.',
        },
        {
          title: 'Треды в группах',
          body: 'Ответ на сообщение можно открыть в отдельной ветке — обсуждение идёт там, а основной чат остаётся чистым.',
        },
      ],
      howTo: [
        'В списке чатов нажмите на полку папок и «Создать».',
        'Перетащите чаты в нужную папку.',
        'В группе — нажмите «Ответить в треде» под сообщением.',
      ],
    },
    'live-location': {
      title: 'Прямая трансляция геолокации',
      tagline: 'Покажите, где вы сейчас, не тыкая в карту.',
      summary:
        'Включите трансляцию геолокации — собеседник в реальном времени видит, как вы двигаетесь. Удобно для встреч в новом месте и поездок.',
      ctaLabel: 'Открыть чат',
      sections: [
        {
          title: 'Трансляция по таймеру',
          body: 'Выберите, сколько делиться: 15 минут, час или 8 часов. По истечении трансляция останавливается автоматически.',
        },
        {
          title: 'Никаких сюрпризов',
          body: 'Пока вы делитесь — в чате висит баннер-напоминание. Остановить трансляцию можно одним нажатием.',
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
        'Подключайте телефон, планшет, веб и десктоп к одному аккаунту. Ключи шифрования синхронизируются через QR-паринг и резервную копию с паролем.',
      ctaLabel: 'Управление устройствами',
      sections: [
        {
          title: 'Безопасный QR-паринг',
          body: 'Чтобы подключить новое устройство, отсканируйте QR-код со старого. Ключи передаются напрямую и никогда не лежат в открытом виде на сервере.',
        },
        {
          title: 'Резервная копия с паролем',
          body: 'Зашифруйте копию ключей паролем — и восстанавливайте чаты на любом новом устройстве, даже если потеряли все старые.',
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
        'Богатые стикерпаки и GIF, опросы в один клик и встроенные редакторы фото и видео. Всё, чтобы сообщать ярче и быстрее.',
      ctaLabel: 'Открыть чат',
      sections: [
        {
          title: 'Стикеры и GIF',
          body: 'Добавляйте свои стикерпаки и используйте паблик-каталог. GIF ищутся прямо в строке ввода без переключения приложений.',
        },
        {
          title: 'Опросы и реакции',
          body: 'Запустите опрос за пару касаний: с одним или несколькими ответами, анонимно или открыто. Реакции на сообщения — для быстрого фидбэка.',
        },
        {
          title: 'Редакторы фото и видео',
          body: 'Кадрируйте, рисуйте, обрезайте видео и подписывайте — без сторонних приложений.',
        },
      ],
      howTo: [
        'В строке ввода нажмите смайл — стикеры и GIF.',
        'Для опроса: «+» → «Опрос».',
        'Для редактора: коснитесь фото или видео в превью.',
      ],
    },
    privacy: {
      title: 'Тонкая приватность',
      tagline: 'Вы решаете, что видят другие.',
      summary:
        'Каждая важная мелочь — отдельный переключатель: статус «онлайн», время «был в сети», прочитан или нет, кто может вас найти и добавить в группу.',
      ctaLabel: 'Открыть приватность',
      sections: [
        {
          title: 'Видимость активности',
          body: 'Прячьте «онлайн» и «был в сети» от тех, кому не нужно. Можно отключить и отчёты о прочтении.',
        },
        {
          title: 'Кто вас найдёт',
          body: 'Глобальный поиск можно отключить — и вы будете доступны только тем, у кого ваш контакт уже есть.',
        },
        {
          title: 'Профиль для других',
          body: 'Решайте, показывать ли почту, телефон, дату рождения и био в карточке профиля.',
        },
      ],
      howTo: [
        'Откройте Настройки → Приватность.',
        'Пройдитесь по переключателям и выберите своё.',
        'Кнопка «Сбросить» вернёт значения по умолчанию.',
      ],
    },
  },
};

const en: FeaturesContent = {
  pageTitle: 'LighChat features',
  pageSubtitle:
    'A short tour of what makes LighChat faster, safer and more fun than a regular messenger.',
  pageHeroPrimary: 'Meet LighChat',
  pageHeroSecondary:
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
  welcomeOverlay: {
    title: 'Discover LighChat features',
    subtitle:
      'Two minutes to see what makes LighChat different. You can come back to the tour any time from settings.',
    primaryCta: 'Take a look',
    secondaryCta: 'Later',
    bullets: [
      'End-to-end encrypted messages and calls',
      'Secret chats that self-destruct',
      'Games and video meetings inside chat',
    ],
  },
  topics: {
    encryption: {
      title: 'End-to-end encryption',
      tagline: 'Only you and the recipient can read it.',
      summary:
        'Every personal message and call is encrypted on your device and decrypted only on the other side. LighChat servers cannot read your conversations — by design.',
      ctaLabel: 'Open devices',
      sections: [
        {
          title: 'Nobody else reads it',
          body: 'Keys live on your devices only. The server sees encrypted traffic and metadata, but not the content of messages or media.',
        },
        {
          title: 'Verify your peer',
          body: 'Compare the device fingerprint — a short numeric code — with your peer. If both match, there is nobody in the middle.',
        },
        {
          title: 'Encrypts everything',
          body: 'Encryption turns on automatically for text, voice, photos, files and media in 1:1 chats.',
          bullets: [
            'Text messages and reactions',
            'Voice and video circles',
            'Photos, videos and files',
            'Link previews and stickers',
          ],
        },
      ],
      howTo: [
        'Open Settings → Devices.',
        'Review your devices and key fingerprints.',
        'Remove devices you no longer use.',
      ],
    },
    'secret-chats': {
      title: 'Secret chats',
      tagline: 'Chats that disappear and refuse to forward.',
      summary:
        'A secret chat plays by stricter rules: messages auto-delete on a timer, you can block forwarding, screenshots and copy, and media opens once.',
      ctaLabel: 'Start a secret chat',
      sections: [
        {
          title: 'Self-destructing timer',
          body: 'Pick how long messages live, from 5 minutes to a day. The timer counts down on both sides.',
        },
        {
          title: 'Hard restrictions',
          body: 'Block forwarding, quotes and saving media. Server-side policy enforces every rule.',
          bullets: [
            'No forwarding or quoting',
            'No copying text',
            'No saving media',
            'View-once photos and videos',
          ],
        },
        {
          title: 'Lock the chat',
          body: 'Add a separate password or biometrics on top of a secret chat — even an unlocked phone will not reveal it.',
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
        'Set a timer in a regular chat and messages will vanish for everyone after 1 hour, a day, a week or a month. Great for work threads and casual topics.',
      ctaLabel: 'Open chats',
      sections: [
        {
          title: 'Sensible presets',
          body: 'Ready-made timers cover most cases, from one hour to thirty days. The clock starts at send time.',
          bullets: ['1 hour for one-offs', '24 hours for daily threads', '7 days for weekly tasks', '30 days for a long buffer'],
        },
        {
          title: 'Clean across devices',
          body: 'Messages disappear in sync — on phone, web and desktop. No archive cleanup needed.',
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
        'Preparing a morning greeting or a Monday reminder? Queue the message and the LighChat server will deliver it at the right moment.',
      ctaLabel: 'Open chats',
      sections: [
        {
          title: 'Always on time',
          body: 'Delivery happens on the server, not on your phone. Power down the device, close the app — your message will still go out.',
        },
        {
          title: 'Full control',
          body: 'A separate panel shows every scheduled message. Edit time or text, or cancel the send.',
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
        'No separate app needed. Start a game of Durak right inside the chat — real-time, with cards that look like the real thing.',
      ctaLabel: 'Open chats',
      sections: [
        {
          title: 'Real time',
          body: 'Players see each other’s moves instantly. The match lives while you stay in the chat and pauses if someone steps away.',
        },
        {
          title: 'Familiar rules',
          body: 'Classic Durak with passing on. Hints help newcomers, and veterans will recognize their rules right away.',
        },
      ],
      howTo: [
        'Open any chat or group.',
        'Tap “+” and pick Game.',
        'Invite opponents and deal.',
      ],
    },
    meetings: {
      title: 'Video meetings',
      tagline: 'Up to dozens of people on one screen.',
      summary:
        'Full video meetings with a participant grid, chat, polls and join requests. Anyone can join by link — even without an account.',
      ctaLabel: 'Open meetings',
      sections: [
        {
          title: 'Convenient grid',
          body: 'The active speaker is highlighted automatically. Pin the participant you need, mute someone or step out for a while.',
        },
        {
          title: 'Polls and join requests',
          body: 'Run polls during the call. Closed rooms accept guests by request — the moderator approves entry.',
        },
      ],
      howTo: [
        'Open the Meetings tab.',
        'Create a new room or join by link.',
        'Share the link with participants.',
      ],
    },
    calls: {
      title: 'Calls and video circles',
      tagline: 'From a voice call to a video postcard in a second.',
      summary:
        'High-quality 1:1 WebRTC calls with encryption and short video circles right in the chat feed — perfect for quick replies when typing is too slow.',
      ctaLabel: 'Call history',
      sections: [
        {
          title: 'Stable quality',
          body: 'The call switches networks gracefully, keeps audio in any tunnel and adapts video resolution to bandwidth.',
        },
        {
          title: 'Video circles',
          body: 'Record a circle up to 60 seconds: face, emotion, voice. The receiver watches it inline — no extra taps.',
        },
      ],
      howTo: [
        'Tap the phone or camera icon in the chat header.',
        'For a circle: long-press the record button in the input.',
        'Release to send instantly.',
      ],
    },
    'folders-threads': {
      title: 'Folders and threads',
      tagline: 'Hundreds of chats without the chaos.',
      summary:
        'Sort chats into folders — Work, Family, Study, whatever fits. Inside groups, open threads on specific topics so the main chat stays clean.',
      ctaLabel: 'Open chats',
      sections: [
        {
          title: 'Custom folders',
          body: 'Create as many folders as you need and drag any chat into them. Folders sync across phone, web and desktop.',
        },
        {
          title: 'Threads in groups',
          body: 'Reply to a message inside a thread — the discussion stays there while the main chat stays focused.',
        },
      ],
      howTo: [
        'In the chat list, open the folder rail and tap Create.',
        'Drag chats into the folder you want.',
        'In a group, tap “Reply in thread” under any message.',
      ],
    },
    'live-location': {
      title: 'Live location sharing',
      tagline: 'Show where you are without fiddling with the map.',
      summary:
        'Turn on live location and your peer sees you move in real time. Great for meeting up at a new spot or during a trip.',
      ctaLabel: 'Open chats',
      sections: [
        {
          title: 'Timed sharing',
          body: 'Pick how long to share: 15 minutes, an hour or 8 hours. After that the stream stops on its own.',
        },
        {
          title: 'No surprises',
          body: 'While you share, a banner reminds you in the chat. One tap stops the stream.',
        },
      ],
      howTo: [
        'In a chat, tap “+” and pick Location.',
        'Turn on Live and choose duration.',
        'Tap the red banner on top to stop.',
      ],
    },
    'multi-device': {
      title: 'Multiple devices',
      tagline: 'One account, many screens, nothing lost.',
      summary:
        'Connect phone, tablet, web and desktop to a single account. Encryption keys sync via QR pairing and a password-protected backup.',
      ctaLabel: 'Manage devices',
      sections: [
        {
          title: 'Secure QR pairing',
          body: 'Pair a new device by scanning a QR code from an old one. Keys travel directly and never sit in plaintext on the server.',
        },
        {
          title: 'Password backup',
          body: 'Encrypt a backup of your keys with a password — and recover chats on any new device, even if you lost the old ones.',
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
        'Rich stickers and GIFs, one-tap polls and built-in photo and video editors. Everything to communicate brighter and faster.',
      ctaLabel: 'Open chats',
      sections: [
        {
          title: 'Stickers and GIFs',
          body: 'Add your own packs and use the public catalog. Search GIFs right from the input — no app switching.',
        },
        {
          title: 'Polls and reactions',
          body: 'Spin up a poll in two taps: single or multiple choice, anonymous or open. Message reactions for quick feedback.',
        },
        {
          title: 'Photo and video editors',
          body: 'Crop, draw, trim video and caption — without third-party apps.',
        },
      ],
      howTo: [
        'In the input, tap the smiley — stickers and GIFs.',
        'For a poll: “+” → Poll.',
        'For the editor: tap a photo or video in the preview.',
      ],
    },
    privacy: {
      title: 'Fine-grained privacy',
      tagline: 'You decide what others see.',
      summary:
        'Every detail is its own toggle — Online, Last seen, Read receipts, who can find you and who can add you to a group.',
      ctaLabel: 'Open privacy',
      sections: [
        {
          title: 'Activity visibility',
          body: 'Hide Online and Last seen from the wrong eyes. Read receipts can be turned off too.',
        },
        {
          title: 'Who finds you',
          body: 'Global search can be off — then you are reachable only to people who already have your contact.',
        },
        {
          title: 'Profile for others',
          body: 'Decide whether to show email, phone, date of birth and bio in the profile card.',
        },
      ],
      howTo: [
        'Open Settings → Privacy.',
        'Walk through the toggles and pick your defaults.',
        'Reset returns everything to the safe defaults.',
      ],
    },
  },
};

const CONTENT: Record<'ru' | 'en', FeaturesContent> = { ru, en };

export function getFeaturesContent(locale: string): FeaturesContent {
  return locale === 'en' ? CONTENT.en : CONTENT.ru;
}
