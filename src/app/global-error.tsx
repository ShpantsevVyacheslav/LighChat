'use client';

import { useEffect } from 'react';
import { Button } from '@/components/ui/button';

export default function GlobalError({
  error,
}: {
  error: Error & { digest?: string };
}) {
  useEffect(() => {
    console.error('Global Runtime Error:', error);
  }, [error]);

  return (
    <html lang="ru">
      <body className="bg-[#0a0e17] text-white flex items-center justify-center min-h-screen font-sans">
        <div className="max-w-md w-full p-8 text-center space-y-6">
          <div className="text-6xl">⚠️</div>
          <h1 className="text-3xl font-bold">Критическая ошибка</h1>
          <p className="text-slate-400">
            Приложение не может продолжать работу из-за системной ошибки. 
            Пожалуйста, перезагрузите страницу.
          </p>
          <Button
            onClick={() => window.location.reload()}
            className="w-full h-14 rounded-2xl bg-blue-600 hover:bg-blue-500 font-bold text-lg"
          >
            Перезагрузить LighChat
          </Button>
        </div>
      </body>
    </html>
  );
}
