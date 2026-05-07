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

const CONTENT: Record<ResolvedWebLocale, LandingContent> = {
  ru,
  en,
  kk: ru,
  uz: ru,
  tr: en,
  id: en,
  'pt-BR': en,
  'es-MX': en,
};

export function getLandingContent(locale: ResolvedWebLocale): LandingContent {
  return CONTENT[locale] ?? ru;
}
