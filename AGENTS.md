# AGENTS.md

Краткий входной файл для AI-агентов по проекту LighChat.

## Как работать с проектом

- Сначала прочитай `AGENTS.md`, затем `docs/arcitecture/00-project-overview.md`.
- Дальше открывай только профильные доки из `docs/arcitecture/*` под текущую задачу.
- Перед изменениями проверь актуальные типы в `src/lib/types.ts` и ограничения в `firestore.rules`.
- Для бэкенд-логики смотри `functions/src/index.ts` и соответствующие `functions/src/triggers/*`.

## Карта путей

- `src/app` - страницы Next.js App Router, layout-уровень, API route.
- `src/components` - UI и feature-компоненты (chat, meetings, admin, settings, contacts).
- `src/hooks` - клиентские хуки состояния/поведения (auth, settings, notifications, webrtc).
- `src/firebase` - инициализация Firebase, провайдеры, Firestore-хуки, транспорт.
- `src/actions` - server actions (админ-операции, уведомления, статистика).
- `src/lib` - доменные типы, утилиты, policy/check helpers.
- `functions/src` - Cloud Functions (auth/http/firestore/scheduler триггеры).
- `firestore.rules`, `src/firestore.rules` - правила Firestore (держать синхронно).
- `storage.rules` - правила Firebase Storage.
- `electron` - desktop shell (main/preload).
- `scripts` - утилиты сборки/брендинга.
- `public` - статика, PWA-иконки и манифест.

## Набор архитектурных доков

- `docs/arcitecture/00-project-overview.md` - назначение продукта и платформы.
- `docs/arcitecture/01-codebase-map.md` - где что лежит и зона ответственности модулей.
- `docs/arcitecture/02-domain-entities.md` - ключевые доменные сущности и индексы.
- `docs/arcitecture/03-firestore-model.md` - модель коллекций и связи Firestore.
- `docs/arcitecture/04-runtime-flows.md` - основные runtime-потоки.
- `docs/arcitecture/05-integrations.md` - внешние интеграции и окружение.
- `docs/arcitecture/06-agent-change-policy.md` - правила безопасных изменений для агентов.

## Обязательное правило синхронизации документации

Если после задачи изменился код, который влияет на архитектуру, структуру директорий, доменные сущности, модель данных, интеграции или runtime-потоки, агент ОБЯЗАН обновить соответствующие документы в `AGENTS.md` и/или `docs/arcitecture/*` в рамках той же задачи.

Минимальная матрица обновления:

- Изменены пути/модули/ответственность директорий -> обнови `AGENTS.md`, `docs/arcitecture/01-codebase-map.md`.
- Изменены типы/сущности (`src/lib/types.ts`, функции, DTO) -> обнови `docs/arcitecture/02-domain-entities.md`.
- Изменены коллекции, связи, индексы, правила -> обнови `docs/arcitecture/03-firestore-model.md` и при необходимости `docs/arcitecture/05-integrations.md`.
- Изменены пользовательские/системные потоки (auth/chat/calls/meetings/notifications) -> обнови `docs/arcitecture/04-runtime-flows.md`.
- Изменены внешние сервисы, env, деплой/рантайм -> обнови `docs/arcitecture/05-integrations.md`.
- Изменены инженерные правила работы агентов -> обнови `AGENTS.md`, `docs/arcitecture/06-agent-change-policy.md`.

## Чеклист перед завершением задачи

- Проверил, затронуты ли архитектурно значимые части.
- При необходимости обновил docs синхронно с кодом.
- Проверил, что ссылки на пути в документах валидны.
- Убедился, что `firestore.rules` и `src/firestore.rules` остаются согласованными.
