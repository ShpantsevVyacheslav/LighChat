'use client';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { MessageSquareWarning } from 'lucide-react';

/** Заготовка под обращения: коллекция supportTickets, ответы админа — в следующей итерации. */
export function AdminSupportInboxPlaceholder() {
  return (
    <Card className="rounded-3xl border-dashed">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-lg">
          <MessageSquareWarning className="h-5 w-5 text-muted-foreground" />
          Обращения пользователей
        </CardTitle>
        <CardDescription>
          Правила Firestore для <code className="text-xs">supportTickets</code> зарезервированы (чтение — только
          админы). Форма обращения с клиента и ответы из этой панели будут добавлены позже.
        </CardDescription>
      </CardHeader>
      <CardContent>
        <p className="text-sm text-muted-foreground">
          После появления обращений здесь появится список тикетов, статусы и переписка.
        </p>
      </CardContent>
    </Card>
  );
}
