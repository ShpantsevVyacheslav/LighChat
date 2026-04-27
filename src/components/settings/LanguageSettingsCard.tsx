'use client';

import * as React from 'react';
import { Languages } from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Label } from '@/components/ui/label';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { useI18n } from '@/hooks/use-i18n';
import type { AppLanguagePreference } from '@/lib/i18n/preference';

export function LanguageSettingsCard() {
  const { preference, setPreference, t } = useI18n();

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base flex items-center gap-2">
          <Languages className="h-4 w-4 text-muted-foreground" />
          {t('settings.language.title')}
        </CardTitle>
        <CardDescription>{t('settings.language.description')}</CardDescription>
      </CardHeader>
      <CardContent>
        <RadioGroup
          value={preference}
          onValueChange={(v) => setPreference(v as AppLanguagePreference)}
          className="gap-3"
        >
          <div className="flex items-center space-x-2">
            <RadioGroupItem value="system" id="lang-system" />
            <Label htmlFor="lang-system" className="font-normal cursor-pointer">
              {t('settings.language.system')}
            </Label>
          </div>
          <div className="flex items-center space-x-2">
            <RadioGroupItem value="ru" id="lang-ru" />
            <Label htmlFor="lang-ru" className="font-normal cursor-pointer">
              {t('settings.language.ru')}
            </Label>
          </div>
          <div className="flex items-center space-x-2">
            <RadioGroupItem value="en" id="lang-en" />
            <Label htmlFor="lang-en" className="font-normal cursor-pointer">
              {t('settings.language.en')}
            </Label>
          </div>
        </RadioGroup>
      </CardContent>
    </Card>
  );
}
