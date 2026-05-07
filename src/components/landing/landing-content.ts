import type { ResolvedWebLocale } from '@/lib/i18n/preference';

export type LandingContent = {
  /** Тег над брендом в hero. */
  heroBadge: string;
  /** Большой заголовок hero. */
  heroTitle: string;
  /** Подзаголовок под hero. */
  heroSubtitle: string;
  /** CTA-кнопка «Войти» (вверху и в hero). */
  loginCta: string;
  /** CTA-кнопка «Создать аккаунт». */
  registerCta: string;
  /** Подпись «Доступно в:». */
  storesEyebrow: string;
  /** Подпись под кнопками сторов («скоро»). */
  storesNote: string;
  /** Title секции highlights. */
  highlightsTitle: string;
  /** Subtitle секции highlights. */
  highlightsSubtitle: string;
  /** Title секции «больше». */
  moreTitle: string;
  /** Subtitle секции «больше». */
  moreSubtitle: string;
  /** Title секции с детальным описанием. */
  detailsTitle: string;
  /** Subtitle секции с детальным описанием. */
  detailsSubtitle: string;
  /** Маленький заголовок «Как включить». */
  howToTitle: string;
  /** Маленький заголовок «Что это даёт». */
  whatYouGetTitle: string;
  /** Заголовок CTA-блока в подвале. */
  ctaTitle: string;
  /** Подзаголовок CTA-блока в подвале. */
  ctaSubtitle: string;
  /** Подпись «Бесплатно. Без рекламы. Без слежки.» */
  ctaTagline: string;
  /** Аккуратная сноска с уважением к приватности. */
  privacyFootnote: string;
  /** Подвал — права. */
  copyrightSuffix: string;
  /** Заголовки бейджей сторов. */
  appStoreLine1: string;
  appStoreLine2: string;
  googlePlayLine1: string;
  googlePlayLine2: string;
};

const ru: LandingContent = {
  heroBadge: 'Мессенджер нового поколения',
  heroTitle: 'Общайтесь свободно. Безопасно. Без рекламы.',
  heroSubtitle:
    'LighChat — это лёгкий мессенджер с честным сквозным шифрованием на выбор, секретными чатами, отложенными сообщениями, видеовстречами и даже играми. Один аккаунт работает на телефоне, в браузере и на десктопе.',
  loginCta: 'Войти',
  registerCta: 'Создать аккаунт',
  storesEyebrow: 'Скачайте приложение',
  storesNote: 'Мобильные приложения скоро в сторах. Web-версия уже доступна.',
  highlightsTitle: 'Самое полезное',
  highlightsSubtitle: 'Пять возможностей, ради которых пользователи остаются с LighChat.',
  moreTitle: 'И ещё больше',
  moreSubtitle: 'Что приложение умеет помимо переписки — от папок и тредов до прямой геолокации.',
  detailsTitle: 'Подробно про каждую возможность',
  detailsSubtitle:
    'Что именно получают пользователи и как это включить — без маркетинговой воды.',
  howToTitle: 'Как включить',
  whatYouGetTitle: 'Что это даёт',
  ctaTitle: 'Готовы попробовать?',
  ctaSubtitle:
    'Откройте LighChat в браузере прямо сейчас или установите приложение, как только оно появится в сторе.',
  ctaTagline: 'Бесплатно. Без рекламы. Без слежки за пользователями.',
  privacyFootnote:
    'Мы не продаём данные, не показываем рекламу и не следим за вашей перепиской. E2EE-чаты остаются приватными даже от нас.',
  copyrightSuffix: 'Все права защищены.',
  appStoreLine1: 'Скачать в',
  appStoreLine2: 'App Store',
  googlePlayLine1: 'Скачать в',
  googlePlayLine2: 'Google Play',
};

const en: LandingContent = {
  heroBadge: 'Next-generation messenger',
  heroTitle: 'Talk freely. Safely. With no ads.',
  heroSubtitle:
    'LighChat is a lightweight messenger with honest opt-in end-to-end encryption, secret chats, scheduled messages, video meetings and even games. One account on phone, web and desktop.',
  loginCta: 'Sign in',
  registerCta: 'Create account',
  storesEyebrow: 'Download the app',
  storesNote: 'Mobile apps are coming soon. The web version is already available.',
  highlightsTitle: 'Most useful',
  highlightsSubtitle: 'Five reasons people stay with LighChat.',
  moreTitle: 'And more',
  moreSubtitle: 'What the app can do beyond chatting — folders, threads, live location and more.',
  detailsTitle: 'A closer look at every feature',
  detailsSubtitle: 'What you actually get and how to enable it — no marketing fluff.',
  howToTitle: 'How to enable',
  whatYouGetTitle: 'What you get',
  ctaTitle: 'Ready to try?',
  ctaSubtitle:
    'Open LighChat in your browser right now or install the app once it lands in the stores.',
  ctaTagline: 'Free. Ad-free. No user tracking.',
  privacyFootnote:
    "We don't sell data, don't show ads and don't read your chats. E2EE conversations stay private even from us.",
  copyrightSuffix: 'All rights reserved.',
  appStoreLine1: 'Download on the',
  appStoreLine2: 'App Store',
  googlePlayLine1: 'Get it on',
  googlePlayLine2: 'Google Play',
};

const kk: LandingContent = {
  heroBadge: 'Жаңа буын мессенджер',
  heroTitle: 'Еркін сөйлесіңіз. Қауіпсіз. Жарнамасыз.',
  heroSubtitle:
    'LighChat — адал ұштан-ұшқа шифрлеуі, құпия чаттары, кейінге қалдырылған хабарламалары, бейне кездесулері және тіпті ойындары бар жеңіл мессенджер. Бір аккаунт телефонда, браузерде және компьютерде жұмыс істейді.',
  loginCta: 'Кіру',
  registerCta: 'Аккаунт жасау',
  storesEyebrow: 'Қосымшаны жүктеп алыңыз',
  storesNote: 'Мобильді қосымшалар жақында сторларда. Web-нұсқасы қазірдің өзінде қолжетімді.',
  highlightsTitle: 'Ең пайдалысы',
  highlightsSubtitle: 'Пайдаланушылардың LighChat-пен қалуының бес себебі.',
  moreTitle: 'Және тағы да көп',
  moreSubtitle: 'Хат жазысудан басқа не істей алады — қалталар, тредтер, тікелей геолокация және т.б.',
  detailsTitle: 'Әр мүмкіндік туралы толығырақ',
  detailsSubtitle: 'Пайдаланушылар нақты не алады және оны қалай қосу керек — маркетингсіз.',
  howToTitle: 'Қалай қосу керек',
  whatYouGetTitle: 'Не береді',
  ctaTitle: 'Байқап көруге дайынсыз ба?',
  ctaSubtitle:
    'LighChat-ты қазір браузерде ашыңыз немесе сторда пайда болғанда қосымшаны орнатыңыз.',
  ctaTagline: 'Тегін. Жарнамасыз. Бақылаусыз.',
  privacyFootnote:
    'Біз деректерді сатпаймыз, жарнама көрсетпейміз және хат-хабарларыңызды оқымаймыз. E2EE-чаттар тіпті бізден де құпия.',
  copyrightSuffix: 'Барлық құқықтар қорғалған.',
  appStoreLine1: 'Жүктеп алу:',
  appStoreLine2: 'App Store',
  googlePlayLine1: 'Жүктеп алу:',
  googlePlayLine2: 'Google Play',
};

const id_ID: LandingContent = {
  heroBadge: 'Messenger generasi baru',
  heroTitle: 'Berkomunikasi dengan bebas. Aman. Tanpa iklan.',
  heroSubtitle:
    'LighChat adalah messenger ringan dengan enkripsi end-to-end opsional yang jujur, chat rahasia, pesan terjadwal, pertemuan video, dan bahkan game. Satu akun untuk ponsel, web, dan desktop.',
  loginCta: 'Masuk',
  registerCta: 'Buat akun',
  storesEyebrow: 'Unduh aplikasi',
  storesNote: 'Aplikasi mobile segera hadir. Versi web sudah tersedia.',
  highlightsTitle: 'Paling berguna',
  highlightsSubtitle: 'Lima alasan orang tetap menggunakan LighChat.',
  moreTitle: 'Dan masih banyak lagi',
  moreSubtitle: 'Apa yang bisa dilakukan aplikasi selain berkirim pesan — folder, utas, lokasi langsung, dan lainnya.',
  detailsTitle: 'Lihat lebih dekat setiap fitur',
  detailsSubtitle: 'Apa yang sebenarnya Anda dapatkan dan cara mengaktifkannya — tanpa basa-basi pemasaran.',
  howToTitle: 'Cara mengaktifkan',
  whatYouGetTitle: 'Apa yang Anda dapatkan',
  ctaTitle: 'Siap mencoba?',
  ctaSubtitle:
    'Buka LighChat di peramban Anda sekarang juga atau instal aplikasi begitu tersedia di toko.',
  ctaTagline: 'Gratis. Tanpa iklan. Tanpa pelacakan pengguna.',
  privacyFootnote:
    'Kami tidak menjual data, tidak menampilkan iklan, dan tidak membaca chat Anda. Percakapan E2EE tetap privat bahkan dari kami.',
  copyrightSuffix: 'Semua hak dilindungi.',
  appStoreLine1: 'Unduh di',
  appStoreLine2: 'App Store',
  googlePlayLine1: 'Dapatkan di',
  googlePlayLine2: 'Google Play',
};

const ptBR: LandingContent = {
  heroBadge: 'Mensageiro de nova geração',
  heroTitle: 'Converse livremente. Com segurança. Sem anúncios.',
  heroSubtitle:
    'LighChat é um mensageiro leve com criptografia ponta a ponta opcional e transparente, chats secretos, mensagens agendadas, videoconferências e até jogos. Uma conta funciona no celular, no navegador e no desktop.',
  loginCta: 'Entrar',
  registerCta: 'Criar conta',
  storesEyebrow: 'Baixe o aplicativo',
  storesNote: 'Apps móveis em breve nas lojas. A versão web já está disponível.',
  highlightsTitle: 'O mais útil',
  highlightsSubtitle: 'Cinco motivos pelos quais os usuários ficam com o LighChat.',
  moreTitle: 'E muito mais',
  moreSubtitle: 'O que o app faz além de mensagens — pastas, tópicos, localização ao vivo e mais.',
  detailsTitle: 'Uma visão detalhada de cada recurso',
  detailsSubtitle: 'O que você realmente recebe e como ativar — sem enrolação de marketing.',
  howToTitle: 'Como ativar',
  whatYouGetTitle: 'O que você ganha',
  ctaTitle: 'Pronto para experimentar?',
  ctaSubtitle:
    'Abra o LighChat no navegador agora mesmo ou instale o app assim que ele estiver disponível nas lojas.',
  ctaTagline: 'Grátis. Sem anúncios. Sem rastreamento de usuários.',
  privacyFootnote:
    'Não vendemos dados, não exibimos anúncios e não lemos suas conversas. Chats E2EE permanecem privados até de nós.',
  copyrightSuffix: 'Todos os direitos reservados.',
  appStoreLine1: 'Baixar na',
  appStoreLine2: 'App Store',
  googlePlayLine1: 'Disponível no',
  googlePlayLine2: 'Google Play',
};

const esMX: LandingContent = {
  heroBadge: 'Mensajero de nueva generación',
  heroTitle: 'Comunícate libremente. De forma segura. Sin anuncios.',
  heroSubtitle:
    'LighChat es un mensajero ligero con cifrado de extremo a extremo opcional y transparente, chats secretos, mensajes programados, videollamadas y hasta juegos. Una sola cuenta en tu celular, navegador y computadora.',
  loginCta: 'Iniciar sesión',
  registerCta: 'Crear cuenta',
  storesEyebrow: 'Descarga la app',
  storesNote: 'Las apps móviles estarán disponibles pronto. La versión web ya está lista.',
  highlightsTitle: 'Lo más útil',
  highlightsSubtitle: 'Cinco razones por las que los usuarios se quedan con LighChat.',
  moreTitle: 'Y mucho más',
  moreSubtitle: 'Lo que la app puede hacer además de chatear: carpetas, hilos, ubicación en vivo y más.',
  detailsTitle: 'Una mirada a fondo a cada función',
  detailsSubtitle: 'Lo que realmente obtienes y cómo activarlo, sin palabrería de marketing.',
  howToTitle: 'Cómo activarlo',
  whatYouGetTitle: 'Qué obtienes',
  ctaTitle: '¿Listo para probarlo?',
  ctaSubtitle:
    'Abre LighChat en tu navegador ahora mismo o instala la app en cuanto esté disponible en las tiendas.',
  ctaTagline: 'Gratis. Sin anuncios. Sin rastreo de usuarios.',
  privacyFootnote:
    'No vendemos datos, no mostramos anuncios y no leemos tus chats. Las conversaciones E2EE se mantienen privadas incluso para nosotros.',
  copyrightSuffix: 'Todos los derechos reservados.',
  appStoreLine1: 'Descargar en',
  appStoreLine2: 'App Store',
  googlePlayLine1: 'Disponible en',
  googlePlayLine2: 'Google Play',
};

const tr: LandingContent = {
  heroBadge: 'Yeni nesil mesajlaşma uygulaması',
  heroTitle: 'Özgürce konuşun. Güvenle. Reklamsız.',
  heroSubtitle:
    'LighChat, isteğe bağlı uçtan uca şifreleme, gizli sohbetler, zamanlı mesajlar, video toplantılar ve hatta oyunlar sunan hafif bir mesajlaşma uygulamasıdır. Tek hesapla telefon, tarayıcı ve masaüstünde kullanın.',
  loginCta: 'Giriş yap',
  registerCta: 'Hesap oluştur',
  storesEyebrow: 'Uygulamayı indirin',
  storesNote: 'Mobil uygulamalar yakında mağazalarda. Web sürümü şu anda kullanılabilir.',
  highlightsTitle: 'En faydalı özellikler',
  highlightsSubtitle: 'Kullanıcıların LighChat ile kalmalarının beş nedeni.',
  moreTitle: 'Ve daha fazlası',
  moreSubtitle: 'Mesajlaşmanın ötesinde uygulamanın sunduğu olanaklar — klasörler, diziler, canlı konum ve daha fazlası.',
  detailsTitle: 'Her özelliğe yakından bakış',
  detailsSubtitle: 'Gerçekte ne elde ediyorsunuz ve nasıl etkinleştiriyorsunuz — pazarlama jargonu olmadan.',
  howToTitle: 'Nasıl etkinleştirilir',
  whatYouGetTitle: 'Ne elde edersiniz',
  ctaTitle: 'Denemeye hazır mısınız?',
  ctaSubtitle:
    'LighChat\'i hemen tarayıcınızda açın veya mağazalarda yayınlandığında uygulamayı yükleyin.',
  ctaTagline: 'Ücretsiz. Reklamsız. Kullanıcı takibi yok.',
  privacyFootnote:
    'Veri satmıyoruz, reklam göstermiyoruz ve sohbetlerinizi okumuyoruz. E2EE konuşmalar bizden bile gizli kalır.',
  copyrightSuffix: 'Tüm hakları saklıdır.',
  appStoreLine1: 'İndir',
  appStoreLine2: 'App Store',
  googlePlayLine1: 'İndir',
  googlePlayLine2: 'Google Play',
};

const uz: LandingContent = {
  heroBadge: 'Yangi avlod messenjeri',
  heroTitle: 'Erkin muloqot qiling. Xavfsiz. Reklamasiz.',
  heroSubtitle:
    'LighChat — ixtiyoriy uchidan-uchiga shifrlash, maxfiy chatlar, kechiktirilgan xabarlar, videouchrashuvlar va hatto oʻyinlar bilan yengil messenjer. Bitta hisob telefon, brauzer va kompyuterda ishlaydi.',
  loginCta: 'Kirish',
  registerCta: 'Hisob yaratish',
  storesEyebrow: 'Ilovani yuklab oling',
  storesNote: 'Mobil ilovalar tez orada doʻkonlarda. Web-versiya allaqachon mavjud.',
  highlightsTitle: 'Eng foydali',
  highlightsSubtitle: 'Foydalanuvchilar LighChat bilan qolishining beshta sababi.',
  moreTitle: 'Va yana koʻproq',
  moreSubtitle: 'Ilova yozishmadan tashqari nima qila oladi — papkalar, mavzular, jonli geolokatsiya va boshqalar.',
  detailsTitle: 'Har bir imkoniyat haqida batafsil',
  detailsSubtitle:
    'Foydalanuvchilar nimaga ega boʻladi va buni qanday yoqish mumkin — marketing suvisiz.',
  howToTitle: 'Qanday yoqish kerak',
  whatYouGetTitle: 'Bu nima beradi',
  ctaTitle: 'Sinab koʻrishga tayyormisiz?',
  ctaSubtitle:
    'LighChat ni hoziroq brauzerda oching yoki ilova doʻkonda paydo boʻlganda oʻrnating.',
  ctaTagline: 'Bepul. Reklamasiz. Foydalanuvchilarni kuzatmasdan.',
  privacyFootnote:
    'Biz maʼlumotlarni sotmaymiz, reklama koʻrsatmaymiz va yozishmalaringizni kuzatmaymiz. E2EE chatlar biz uchun ham maxfiy qoladi.',
  copyrightSuffix: 'Barcha huquqlar himoyalangan.',
  appStoreLine1: 'Yuklab olish',
  appStoreLine2: 'App Store',
  googlePlayLine1: 'Yuklab olish',
  googlePlayLine2: 'Google Play',
};

const CONTENT: Record<ResolvedWebLocale, LandingContent> = {
  ru,
  en,
  kk,
  uz,
  tr,
  id: id_ID,
  'pt-BR': ptBR,
  'es-MX': esMX,
};

export function getLandingContent(locale: ResolvedWebLocale): LandingContent {
  return CONTENT[locale] ?? ru;
}
