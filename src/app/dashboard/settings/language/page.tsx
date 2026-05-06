"use client";

import { Languages } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { useI18n } from "@/hooks/use-i18n";
import type { AppLanguagePreference } from "@/lib/i18n/preference";

export default function LanguageSettingsPage() {
  const { preference, setPreference, t } = useI18n();

  return (
    <div className="space-y-6 max-w-3xl mx-auto pb-10">
      <div className="animate-in fade-in slide-in-from-top-4 duration-700 flex items-center gap-2">
        <div className="min-w-0">
          <h1 className="text-2xl sm:text-3xl font-bold flex items-center gap-2 leading-tight">
            <Languages className="text-primary h-6 w-6 sm:h-8 sm:w-8" />
            {t("settings.language.title")}
          </h1>
          <p className="text-xs sm:text-sm text-muted-foreground">
            {t("settings.language.description")}
          </p>
        </div>
      </div>

      <Card>
        <CardContent className="pt-6">
          <RadioGroup
            value={preference}
            onValueChange={(v) => setPreference(v as AppLanguagePreference)}
            className="gap-3"
          >
            <div className="flex items-center space-x-2">
              <RadioGroupItem value="system" id="lang-system" />
              <Label htmlFor="lang-system" className="font-normal cursor-pointer">
                {t("settings.language.system")}
              </Label>
            </div>
            <div className="flex items-center space-x-2">
              <RadioGroupItem value="ru" id="lang-ru" />
              <Label htmlFor="lang-ru" className="font-normal cursor-pointer">
                {t("settings.language.ru")}
              </Label>
            </div>
            <div className="flex items-center space-x-2">
              <RadioGroupItem value="en" id="lang-en" />
              <Label htmlFor="lang-en" className="font-normal cursor-pointer">
                {t("settings.language.en")}
              </Label>
            </div>
          </RadioGroup>
        </CardContent>
      </Card>
    </div>
  );
}
