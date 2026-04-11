# 06: Agent Change Policy

## Цель

Сделать изменения предсказуемыми и безопасными для агентов: минимум регрессий, синхронная документация, понятный audit trail.

## Обязательные правила

- Перед правками сверяйся с `src/lib/types.ts`, `firestore.rules`, `functions/src/index.ts`.
- Не ломай связку `participantIds` <-> `conversations/*/members/*` без синхронного обновления trigger/rules.
- При изменениях Firestore security обновляй одновременно `firestore.rules` и `src/firestore.rules`.
- Не добавляй новую интеграцию без отражения в `docs/arcitecture/05-integrations.md`.
- Для **mobile (Flutter)** изменения в auth/registration должны сохранять **паритет с web**: обновляй чеклист `docs/mobile/auth-parity.md` вместе с кодом.

## Правило документации (обязательное)

Если изменён код, влияющий на архитектуру/сущности/потоки/интеграции, документы обновляются в этой же задаче.

Матрица соответствия:

- Изменился layout модулей/директорий -> `AGENTS.md`, `01-codebase-map.md`.
- Изменились типы/DTO/сущности -> `02-domain-entities.md`.
- Изменилась Firestore модель/индексы/rules -> `03-firestore-model.md` (+ `05-integrations.md` при необходимости).
- Изменились сценарии auth/chat/calls/meetings/notifications -> `04-runtime-flows.md`.
- Изменились внешние сервисы/env/runtime -> `05-integrations.md`.
- Изменились правила для агентов -> `AGENTS.md`, `06-agent-change-policy.md`.

## Мини-чеклист перед завершением

- Проверил, есть ли архитектурный эффект от изменений.
- Обновил релевантные docs при необходимости.
- Проверил, что пути/названия файлов в docs валидны.
- Проверил, что правила Firestore синхронизированы (оба файла).

## Когда нужна дополнительная проверка

- Изменения в `functions/src/triggers/*` (риск денормализации индексов).
- Изменения в `src/hooks/use-auth.tsx` и presence-логике.
- Изменения в `src/components/chat/ChatWindow.tsx` и схеме сообщений.
- Любые изменения правил доступа (`*.rules`).
