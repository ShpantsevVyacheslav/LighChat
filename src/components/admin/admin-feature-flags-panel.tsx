'use client';

import React, { useEffect, useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { ToggleLeft, Loader2, Plus, Trash2 } from 'lucide-react';
import { doc, onSnapshot } from 'firebase/firestore';
import { useFirestore, useAuth as useFirebaseAuth } from '@/firebase';
import { useToast } from '@/hooks/use-toast';
import { setFeatureFlagAction, deleteFeatureFlagAction } from '@/actions/feature-flags-actions';
import type { FeatureFlag, PlatformSettingsDoc } from '@/lib/types';
import { useI18n } from '@/hooks/use-i18n';

export function AdminFeatureFlagsPanel() {
  const firestore = useFirestore();
  const firebaseAuth = useFirebaseAuth();
  const { toast } = useToast();
  const { t } = useI18n();
  const [flags, setFlags] = useState<Record<string, FeatureFlag>>({});
  const [loading, setLoading] = useState(true);
  const [newFlagName, setNewFlagName] = useState('');
  const [newFlagDesc, setNewFlagDesc] = useState('');
  const [busy, setBusy] = useState<string | null>(null);

  useEffect(() => {
    if (!firestore) return;
    const ref = doc(firestore, 'platformSettings', 'main');
    return onSnapshot(ref, (snap) => {
      const data = snap.data() as PlatformSettingsDoc | undefined;
      setFlags(data?.featureFlags ?? {});
      setLoading(false);
    });
  }, [firestore]);

  const toggle = async (name: string, enabled: boolean, description?: string) => {
    const token = await firebaseAuth?.currentUser?.getIdToken();
    if (!token) return;
    setBusy(name);
    const res = await setFeatureFlagAction({ idToken: token, flagName: name, enabled, description });
    setBusy(null);
    if (!res.ok) toast({ variant: 'destructive', title: res.error });
  };

  const remove = async (name: string) => {
    const token = await firebaseAuth?.currentUser?.getIdToken();
    if (!token) return;
    setBusy(name);
    const res = await deleteFeatureFlagAction({ idToken: token, flagName: name });
    setBusy(null);
    if (!res.ok) toast({ variant: 'destructive', title: res.error });
  };

  const create = async () => {
    if (!newFlagName.trim()) return;
    const normalized = newFlagName.trim().replace(/[^a-zA-Z0-9_]/g, '_');
    await toggle(normalized, false, newFlagDesc.trim() || undefined);
    setNewFlagName('');
    setNewFlagDesc('');
  };

  return (
    <Card className="rounded-3xl">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-lg">
          <ToggleLeft className="h-5 w-5 text-primary" />
          Feature flags
        </CardTitle>
        <CardDescription>{t('adminPage.featureFlags.description')}</CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        {loading ? (
          <div className="flex justify-center py-6"><Loader2 className="h-5 w-5 animate-spin" /></div>
        ) : (
          <>
            {Object.keys(flags).length === 0 ? (
              <p className="text-sm text-muted-foreground text-center py-4">{t('adminPage.featureFlags.noFlags')}</p>
            ) : (
              <div className="space-y-2">
                {Object.entries(flags).map(([name, flag]) => (
                  <div key={name} className="flex items-center gap-3 rounded-xl border p-3">
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-mono font-medium truncate">{name}</p>
                      {flag.description && <p className="text-xs text-muted-foreground line-clamp-1">{flag.description}</p>}
                    </div>
                    <Switch
                      checked={flag.enabled}
                      disabled={busy === name}
                      onCheckedChange={(v) => toggle(name, v, flag.description)}
                    />
                    <Button
                      size="icon"
                      variant="ghost"
                      className="rounded-xl text-destructive h-8 w-8"
                      disabled={busy === name}
                      onClick={() => remove(name)}
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                ))}
              </div>
            )}

            <div className="rounded-xl border border-dashed p-3 space-y-3">
              <p className="text-sm font-medium">{t('adminPage.featureFlags.createNew')}</p>
              <div className="space-y-2">
                <Label className="text-xs">{t('adminPage.featureFlags.nameLabel')}</Label>
                <Input
                  value={newFlagName}
                  onChange={(e) => setNewFlagName(e.target.value)}
                  placeholder="new_chat_ui"
                  className="rounded-xl font-mono text-sm"
                />
              </div>
              <div className="space-y-2">
                <Label className="text-xs">{t('adminPage.featureFlags.descriptionLabel')}</Label>
                <Input
                  value={newFlagDesc}
                  onChange={(e) => setNewFlagDesc(e.target.value)}
                  placeholder={t('adminPage.featureFlags.descriptionPlaceholder')}
                  className="rounded-xl text-sm"
                />
              </div>
              <Button onClick={create} disabled={!newFlagName.trim()} className="rounded-full w-full">
                <Plus className="h-4 w-4 mr-1" /> {t('adminPage.featureFlags.add')}
              </Button>
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
}
