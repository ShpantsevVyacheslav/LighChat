'use client';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Lightbulb } from 'lucide-react';

/**
 * Идеи развития админки под LighChat (мессенджер + конференции + PWA).
 */
export function AdminCapabilitiesRoadmapCard() {
  const items = [
    'Модерация контента: массовое скрытие сообщений, стоп-слова, жалобы на сообщения.',
    'Аудит: журнал действий админов (кто заблокировал, кто сменил квоту).',
    'Аналитика: MAU, объём трафика Storage, пики нагрузки по времени.',
    'Управление конференциями: принудительное завершение комнаты, бан в meetings.',
    'Feature flags в platformSettings для поэтапного включения функций.',
    'Экспорт данных пользователя (GDPR) и полное удаление (right to be forgotten).',
    'Лимиты API / анти-спам: rate limit на создание чатов и отправку сообщений.',
    'Резервное копирование и политика хранения логов Cloud Functions.',
    'Кастомные роли между admin и worker (модератор, только чтение).',
    'Интеграция биллинга при лимите Storage (уведомление до отсечения FIFO).',
  ];

  return (
    <Card className="rounded-3xl">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-lg">
          <Lightbulb className="h-5 w-5 text-amber-500" />
          Что ещё может делать администратор
        </CardTitle>
        <CardDescription>Ориентир для следующих этапов разработки платформы.</CardDescription>
      </CardHeader>
      <CardContent>
        <ul className="list-disc space-y-2 pl-5 text-sm text-muted-foreground">
          {items.map((t) => (
            <li key={t}>{t}</li>
          ))}
        </ul>
      </CardContent>
    </Card>
  );
}
