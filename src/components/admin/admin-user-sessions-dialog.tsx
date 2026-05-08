'use client';

import React, { useEffect, useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Loader2, Monitor, Smartphone, Tablet, LogOut } from 'lucide-react';
import { useAuth as useFirebaseAuth } from '@/firebase';
import { useToast } from '@/hooks/use-toast';
import { fetchUserSessionsAction, terminateUserSessionsAction, type DeviceSession } from '@/actions/session-actions';
import { useI18n } from '@/hooks/use-i18n';

interface Props {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  targetUserId: string;
  targetUserName: string;
}

function getPlatformIcon(platform?: string) {
  if (!platform) return Monitor;
  const p = platform.toLowerCase();
  if (p.includes('ios') || p.includes('android') || p.includes('mobile')) return Smartphone;
  if (p.includes('tablet') || p.includes('ipad')) return Tablet;
  return Monitor;
}

export function AdminUserSessionsDialog({ open, onOpenChange, targetUserId, targetUserName }: Props) {
  const { t } = useI18n();
  const firebaseAuth = useFirebaseAuth();
  const { toast } = useToast();
  const [sessions, setSessions] = useState<DeviceSession[]>([]);
  const [loading, setLoading] = useState(true);
  const [terminating, setTerminating] = useState(false);

  useEffect(() => {
    if (!open) return;
    const load = async () => {
      const token = await firebaseAuth?.currentUser?.getIdToken();
      if (!token) return;
      setLoading(true);
      const res = await fetchUserSessionsAction({ idToken: token, targetUserId });
      if (res.ok) setSessions(res.sessions);
      setLoading(false);
    };
    load();
  }, [open, firebaseAuth, targetUserId]);

  const terminateAll = async () => {
    const token = await firebaseAuth?.currentUser?.getIdToken();
    if (!token) return;
    setTerminating(true);
    const res = await terminateUserSessionsAction({ idToken: token, targetUserId, targetUserName });
    setTerminating(false);
    if (res.ok) {
      toast({ title: t('admin.sessions.terminated') });
      setSessions([]);
    } else {
      toast({ variant: 'destructive', title: res.error });
    }
  };

  const formatDate = (iso?: string) => {
    if (!iso) return '—';
    return new Date(iso).toLocaleString('ru-RU', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' });
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="rounded-3xl max-w-md">
        <DialogHeader>
          <DialogTitle>{t('admin.sessions.title').replace('{name}', targetUserName)}</DialogTitle>
          <DialogDescription>{t('admin.sessions.description')}</DialogDescription>
        </DialogHeader>

        {loading ? (
          <div className="flex justify-center py-6"><Loader2 className="h-5 w-5 animate-spin" /></div>
        ) : sessions.length === 0 ? (
          <p className="text-sm text-muted-foreground text-center py-4">{t('admin.sessions.noSessions')}</p>
        ) : (
          <div className="space-y-3 max-h-[300px] overflow-y-auto">
            {sessions.map((s) => {
              const Icon = getPlatformIcon(s.platform);
              return (
                <div key={s.deviceId} className="flex items-center gap-3 rounded-xl border p-3">
                  <Icon className="h-5 w-5 text-muted-foreground shrink-0" />
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-medium truncate">{s.platform ?? 'Unknown'} / {s.app ?? '—'}</p>
                    <p className="text-xs text-muted-foreground">
                      {t('admin.sessions.loginLabel')} {formatDate(s.lastLoginAt)} &middot; {t('admin.sessions.activityLabel')} {formatDate(s.lastSeenAt)}
                    </p>
                  </div>
                  {s.isActive && <Badge variant="secondary" className="text-[10px] bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400">Online</Badge>}
                </div>
              );
            })}
          </div>
        )}

        {sessions.length > 0 && (
          <Button
            variant="destructive"
            className="rounded-full w-full mt-2"
            onClick={terminateAll}
            disabled={terminating}
          >
            {terminating ? <Loader2 className="h-4 w-4 animate-spin mr-2" /> : <LogOut className="h-4 w-4 mr-2" />}
            {t('admin.sessions.terminateAll')}
          </Button>
        )}
      </DialogContent>
    </Dialog>
  );
}
