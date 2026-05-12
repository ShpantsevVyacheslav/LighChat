'use client';

import { useEffect, useMemo } from 'react';
import { Button } from '@/components/ui/button';
import { messagesEn } from '@/lib/i18n/messages/en';
import { messagesRu } from '@/lib/i18n/messages/ru';
import { logger } from '@/lib/logger';

export default function GlobalError({
  error,
}: {
  error: Error & { digest?: string };
}) {
  useEffect(() => {
    logger.error('global-error', 'Runtime Error', error);
  }, [error]);

  const messages = useMemo(() => {
    if (typeof navigator === 'undefined') return messagesRu;
    const lang = (navigator.language || 'ru').toLowerCase();
    return lang.startsWith('en') ? messagesEn : messagesRu;
  }, []);

  const lang = messages === messagesEn ? 'en' : 'ru';

  return (
    <html lang={lang}>
      <body className="bg-[#0a0e17] text-white flex items-center justify-center min-h-screen font-sans">
        <div className="max-w-md w-full p-8 text-center space-y-6">
          <div className="text-6xl">⚠️</div>
          <h1 className="text-3xl font-bold">{messages.errors.globalTitle}</h1>
          <p className="text-slate-400">
            {messages.errors.globalDescription}
          </p>
          <Button
            onClick={() => window.location.reload()}
            className="w-full h-14 rounded-2xl bg-blue-600 hover:bg-blue-500 font-bold text-lg"
          >
            {messages.errors.globalReload}
          </Button>
        </div>
      </body>
    </html>
  );
}
