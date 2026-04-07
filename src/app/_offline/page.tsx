import { WifiOff } from 'lucide-react';

export default function OfflinePage() {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-background text-foreground text-center p-4">
      <WifiOff className="h-16 w-16 text-muted-foreground mb-4" />
      <h1 className="text-2xl font-bold mb-2">Вы оффлайн</h1>
      <p className="text-muted-foreground max-w-md">
        Похоже, у вас нет подключения к интернету. Приложение будет работать в оффлайн-режиме, но некоторые функции могут быть недоступны.
      </p>
      <p className="text-muted-foreground max-w-md mt-2">
        Данные будут синхронизированы после восстановления подключения.
      </p>
    </div>
  );
}
