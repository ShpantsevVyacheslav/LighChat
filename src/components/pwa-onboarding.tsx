'use client';

import React, { useState, useEffect } from 'react';
import { useNotifications } from '@/hooks/use-notifications';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle, CardDescription, CardFooter } from '@/components/ui/card';
import { ShieldCheck, Bell, Camera, Mic, Sparkles, Loader2 } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';

export function PwaOnboarding() {
  const { t } = useI18n();
  const [isVisible, setIsVisible] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const { permission: notificationPermission, subscribe } = useNotifications();

  useEffect(() => {
    // Проверяем, был ли уже показан онбординг
    const hasShown = localStorage.getItem('pwa_onboarding_shown');
    
    // Показываем, если не показывали ранее ИЛИ если разрешения еще не запрашивались (default)
    if (!hasShown || (typeof Notification !== 'undefined' && Notification.permission === 'default')) {
        setIsVisible(true);
    }
  }, []);

  const handleEnablePermissions = () => {
    setIsProcessing(true);
    localStorage.setItem('pwa_onboarding_shown', 'true');

    // Не блокируем экран iOS PWA долгой инициализацией FCM.
    setTimeout(() => {
      setIsVisible(false);
      setIsProcessing(false);
    }, 250);

    void (async () => {
      try {
        // Уведомления: ограничиваем ожидание, остальное догонится на следующих попытках.
        await Promise.race([
          subscribe(),
          new Promise<void>((resolve) => setTimeout(resolve, 20_000)),
        ]);

        try {
          const stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
          stream.getTracks().forEach(track => track.stop());
        } catch (e) {
          console.warn("Media permissions denied or failed:", e);
        }
      } catch (error) {
        console.error("Onboarding permissions error:", error);
      }
    })();
  };

  if (!isVisible) return null;

  return (
    <div className="fixed inset-0 z-[300] bg-background/80 backdrop-blur-md flex items-center justify-center p-4 animate-in fade-in duration-500">
      <Card className="max-w-md w-full rounded-[2.5rem] shadow-2xl border-primary/10 overflow-hidden relative">
        <div className="absolute top-0 right-0 p-6 opacity-10">
            <Sparkles className="h-20 w-20 text-primary" />
        </div>
        
        <CardHeader className="text-center pt-10">
          <div className="mx-auto w-16 h-16 bg-primary/10 rounded-3xl flex items-center justify-center mb-4">
            <ShieldCheck className="h-8 w-8 text-primary" />
          </div>
          <CardTitle className="text-2xl font-bold">{t('pwaOnboarding.title')}</CardTitle>
          <CardDescription>
            {t('pwaOnboarding.description')}
          </CardDescription>
        </CardHeader>
        
        <CardContent className="space-y-4 py-6">
          <div className="flex items-center gap-4 p-3 bg-muted/30 rounded-2xl border border-white/5">
            <div className="p-2 bg-blue-500/10 rounded-xl">
                <Bell className="h-5 w-5 text-blue-500" />
            </div>
            <div className="flex-1">
                <p className="text-sm font-bold leading-tight">{t('pwaOnboarding.notificationsTitle')}</p>
                <p className="text-xs text-muted-foreground">
                  {t('pwaOnboarding.notificationsHint')}
                </p>
            </div>
          </div>

          <div className="flex items-center gap-4 p-3 bg-muted/30 rounded-2xl border border-white/5">
            <div className="p-2 bg-green-500/10 rounded-xl">
                <Camera className="h-5 w-5 text-green-500" />
            </div>
            <div className="flex-1">
                <p className="text-sm font-bold leading-tight">{t('pwaOnboarding.cameraTitle')}</p>
                <p className="text-xs text-muted-foreground">{t('pwaOnboarding.cameraHint')}</p>
            </div>
          </div>
          
          <p className="text-[10px] text-center text-muted-foreground px-4 italic leading-tight">
            {t('pwaOnboarding.browserPromptHint')}
          </p>
        </CardContent>

        <CardFooter className="pb-10 px-10 flex flex-col gap-3">
          <Button 
            onClick={handleEnablePermissions} 
            disabled={isProcessing}
            className="w-full h-14 rounded-2xl text-lg font-bold shadow-xl shadow-primary/20"
          >
            {isProcessing ? (
                <>
                    <Loader2 className="mr-2 h-5 w-5 animate-spin" />
                    {t('pwaOnboarding.processing')}
                </>
            ) : t('pwaOnboarding.enableButton')}
          </Button>
          <Button 
            variant="ghost" 
            onClick={() => {
                localStorage.setItem('pwa_onboarding_shown', 'true');
                setIsVisible(false);
            }} 
            className="text-muted-foreground hover:bg-transparent"
          >
            {t('pwaOnboarding.later')}
          </Button>
        </CardFooter>
      </Card>
    </div>
  );
}
