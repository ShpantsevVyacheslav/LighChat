'use client';

import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { FileQuestion } from 'lucide-react'
import { useI18n } from '@/hooks/use-i18n'

export default function NotFound() {
  const { t } = useI18n();
  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-background text-foreground p-4 text-center">
      <div className="p-6 bg-muted rounded-full mb-6">
        <FileQuestion className="h-12 w-12 text-primary" />
      </div>
      <h2 className="text-3xl font-bold mb-2 font-headline">{t('errors.notFoundTitle')}</h2>
      <p className="text-muted-foreground max-w-md mb-8">
        {t('errors.notFoundDescription')}
      </p>
      <Button asChild className="rounded-full px-8 h-12 text-base font-bold shadow-lg shadow-primary/20">
        <Link href="/dashboard">
          {t('errors.notFoundBack')}
        </Link>
      </Button>
    </div>
  )
}
