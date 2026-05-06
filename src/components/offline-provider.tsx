'use client';

import React, { createContext, useContext } from 'react';
import { WifiOff } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { useOnlineStatus } from '@/hooks/use-online-status';
import { useI18n } from '@/hooks/use-i18n';

interface OfflineContextType {
  isOnline: boolean;
  showOfflineToast: () => void;
}

const OfflineContext = createContext<OfflineContextType | undefined>(undefined);

export const OfflineProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const isOnline = useOnlineStatus();
  const { toast } = useToast();
  const { t } = useI18n();

  const showOfflineToast = () => {
    toast({
      variant: 'destructive',
      title: t('offline.toastTitle'),
      description: t('offline.toastDescription'),
      duration: 5000,
    });
  };

  return (
    <OfflineContext.Provider value={{ isOnline, showOfflineToast }}>
      {!isOnline && (
        <div className="fixed top-4 left-1/2 -translate-x-1/2 z-[200] bg-destructive/90 backdrop-blur-md text-destructive-foreground px-4 py-1.5 rounded-full flex items-center gap-2 shadow-lg border border-white/10 animate-in slide-in-from-top-4 duration-500">
          <WifiOff className="h-3.5 w-3.5" />
          <span className='text-[10px] font-bold uppercase tracking-wider'>{t('offline.badgeOffline')}</span>
        </div>
      )}
      {children}
    </OfflineContext.Provider>
  );
};

export const useOffline = (): OfflineContextType => {
  const context = useContext(OfflineContext);
  if (context === undefined) {
    throw new Error('useOffline must be used within an OfflineProvider');
  }
  return context;
};
