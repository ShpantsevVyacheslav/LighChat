'use client';

import React, { useEffect, useState } from 'react';
import { collection, onSnapshot, query, where } from 'firebase/firestore';
import { Info, AlertTriangle, Wrench, Sparkles, X } from 'lucide-react';
import { useFirestore } from '@/firebase';
import { useAuth } from '@/hooks/use-auth';
import type { Announcement, AnnouncementType } from '@/lib/types';
import { useI18n } from '@/hooks/use-i18n';

const ICONS: Record<AnnouncementType, React.ElementType> = {
  info: Info,
  warning: AlertTriangle,
  maintenance: Wrench,
  update: Sparkles,
};

const STYLES: Record<AnnouncementType, string> = {
  info: 'bg-blue-50 text-blue-900 border-blue-200 dark:bg-blue-950/40 dark:text-blue-100 dark:border-blue-900',
  warning: 'bg-yellow-50 text-yellow-900 border-yellow-200 dark:bg-yellow-950/40 dark:text-yellow-100 dark:border-yellow-900',
  maintenance: 'bg-orange-50 text-orange-900 border-orange-200 dark:bg-orange-950/40 dark:text-orange-100 dark:border-orange-900',
  update: 'bg-green-50 text-green-900 border-green-200 dark:bg-green-950/40 dark:text-green-100 dark:border-green-900',
};

const DISMISSED_KEY = 'lighchat:announcements:dismissed';

function getDismissed(): string[] {
  try {
    return JSON.parse(localStorage.getItem(DISMISSED_KEY) ?? '[]');
  } catch {
    return [];
  }
}

function addDismissed(id: string) {
  const list = getDismissed();
  if (!list.includes(id)) {
    list.push(id);
    localStorage.setItem(DISMISSED_KEY, JSON.stringify(list));
  }
}

export function AnnouncementBanner() {
  const firestore = useFirestore();
  const { user } = useAuth();
  const { t } = useI18n();
  const [items, setItems] = useState<Announcement[]>([]);
  const [dismissed, setDismissed] = useState<string[]>([]);

  useEffect(() => {
    setDismissed(getDismissed());
  }, []);

  useEffect(() => {
    if (!firestore || !user) return;
    const q = query(collection(firestore, 'announcements'), where('isActive', '==', true));
    return onSnapshot(q, (snap) => {
      const now = new Date().toISOString();
      const list = snap.docs
        .map((d) => d.data() as Announcement)
        .filter((a) => !a.expiresAt || a.expiresAt > now)
        .filter((a) => !a.targetRoles || a.targetRoles.includes(user.role ?? 'worker'))
        .sort((a, b) => (b.priority ?? 0) - (a.priority ?? 0));
      setItems(list);
    });
  }, [firestore, user]);

  const dismiss = (id: string) => {
    addDismissed(id);
    setDismissed((prev) => [...prev, id]);
  };

  const visible = items.filter((a) => !dismissed.includes(a.id));
  if (visible.length === 0) return null;

  return (
    <div className="space-y-2 mb-3">
      {visible.map((a) => {
        const Icon = ICONS[a.type];
        return (
          <div
            key={a.id}
            className={`rounded-2xl border px-4 py-3 flex items-start gap-3 ${STYLES[a.type]}`}
          >
            <Icon className="h-5 w-5 mt-0.5 shrink-0" />
            <div className="min-w-0 flex-1">
              <p className="text-sm font-semibold">{a.title}</p>
              <p className="text-xs whitespace-pre-wrap">{a.body}</p>
            </div>
            {a.dismissible && (
              <button
                onClick={() => dismiss(a.id)}
                className="rounded-lg p-1 hover:bg-black/5 dark:hover:bg-white/5"
                aria-label={t('common.close')}
              >
                <X className="h-4 w-4" />
              </button>
            )}
          </div>
        );
      })}
    </div>
  );
}
