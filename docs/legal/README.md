# Юридическая документация LighChat

Каталог содержит юридические документы LighChat в двух языковых версиях: русской (`ru/`) и английской (`en/`).

> ⚠️ Все документы являются **черновиками** и требуют ревью юриста до публикации. Места для заполнения помечены `[…]`.

## Состав

| Документ | Описание | Юрисдикции |
|----------|----------|------------|
| `privacy-policy.md` | Политика конфиденциальности | РФ (152-ФЗ), ЕЭЗ (GDPR), США (CCPA) |
| `terms-of-service.md` | Пользовательское соглашение / договор-оферта | Все |
| `cookie-policy.md` | Политика использования cookies (web/PWA) | ЕЭЗ (ePrivacy), РФ |
| `eula.md` | Лицензионное соглашение конечного пользователя | Все, для desktop/mobile |
| `data-processing-agreement.md` | DPA — шаблон для корпоративных клиентов | ЕЭЗ (GDPR Art. 28), РФ |
| `children-policy.md` | Политика в отношении несовершеннолетних | США (COPPA), ЕЭЗ (GDPR Art. 8), РФ (436-ФЗ) |
| `content-moderation-policy.md` | Политика модерации контента | Все |
| `acceptable-use-policy.md` | Правила допустимого использования (AUP) | Все |

## Применимость к платформам

| Документ | web/PWA | Desktop (Electron) | Mobile (iOS/Android) |
|----------|:-:|:-:|:-:|
| Privacy Policy | ✅ | ✅ | ✅ |
| Terms of Service | ✅ | ✅ | ✅ |
| Cookie Policy | ✅ | — | — |
| EULA | — | ✅ | ✅ |
| DPA | По договору | По договору | По договору |
| Children Policy | ✅ | ✅ | ✅ |
| Content Moderation | ✅ | ✅ | ✅ |
| Acceptable Use | ✅ | ✅ | ✅ |

## Структура

```
docs/legal/
├── README.md            ← этот файл
├── ru/                  ← русская версия (основная)
│   ├── privacy-policy.md
│   ├── terms-of-service.md
│   └── …
└── en/                  ← английская версия
    ├── privacy-policy.md
    ├── terms-of-service.md
    └── …
```

## Интеграция в клиентах

### Web (Next.js, `src/`)
- Динамический роут `/legal/[slug]` рендерит соответствующий MD-документ из `docs/legal/{lang}/{slug}.md`.
- Согласие в формах sign-in/sign-up: `src/components/auth/`.
- Cookie banner на лендинге: `src/components/landing/`.
- Ссылки в футере приложения и лендинга.

### Mobile (Flutter, `mobile/app/`)
- Экран `mobile/app/lib/features/legal/ui/legal_document_screen.dart` рендерит документы из ассетов `mobile/app/assets/legal/`.
- Согласие в `register_form.dart` (ссылки на `/legal/<slug>` через `go_router`).
- Раздел «Правовая информация» в Settings → About.

## Перед публикацией

Юристу необходимо:
1. Заполнить плейсхолдеры `[НАЗВАНИЕ ЮРЛИЦА]`, `[АДРЕС]`, `[ОГРН/ИНН]`, `[DPO_NAME]` и т.п.
2. Проверить ссылки на актуальное законодательство (номера статей, ФЗ).
3. Согласовать суммы лимитов ответственности и подсудность.
4. При необходимости — добавить версии для других юрисдикций.
5. Ввести процедуру нотификации пользователей при существенных изменениях (≥14 дней до вступления в силу).

## Контакты

- Общие: legal@lighchat.app
- Жалобы: abuse@lighchat.app
- DPO (для ЕЭЗ): dpo@lighchat.app
