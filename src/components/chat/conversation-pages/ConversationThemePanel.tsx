'use client';

import { useRef, useState } from 'react';
import { ImagePlus, Loader2 } from 'lucide-react';
import { doc, updateDoc, arrayUnion } from 'firebase/firestore';
import { ref as storageRef, uploadBytes, getDownloadURL } from 'firebase/storage';
import { useFirestore, useStorage } from '@/firebase';
import { useChatConversationPrefs } from '@/hooks/use-chat-conversation-prefs';
import { useSettings } from '@/hooks/use-settings';
import { useToast } from '@/hooks/use-toast';
import { compressImage } from '@/lib/image-compression';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { cn } from '@/lib/utils';

const WALLPAPERS: { value: string | null; label: string }[] = [
  { value: null, label: 'Как в общих настройках' },
  { value: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)', label: 'Фиолетовый' },
  { value: 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)', label: 'Розовый' },
  { value: 'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)', label: 'Голубой' },
  { value: 'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)', label: 'Зелёный' },
  { value: 'linear-gradient(135deg, #0c0c0c 0%, #1a1a2e 100%)', label: 'Ночь' },
];

function isImageUrl(value: string | null | undefined): boolean {
  return !!(value && (value.startsWith('http') || value.startsWith('data:')));
}

export function ConversationThemePanel({
  conversationId,
  userId,
}: {
  conversationId: string;
  userId: string;
}) {
  const firestore = useFirestore();
  const storage = useStorage();
  const { toast } = useToast();
  const globalWallpaper = useSettings().chatSettings.chatWallpaper;
  const { prefs, updatePrefs, clearChatWallpaperOverride } = useChatConversationPrefs(userId, conversationId);
  const effectiveLocal = prefs?.chatWallpaper;
  const [uploading, setUploading] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);

  const activeWallpaper =
    effectiveLocal != null && effectiveLocal !== '' ? effectiveLocal : globalWallpaper;

  const setGradient = (value: string | null) => {
    if (value === null) {
      clearChatWallpaperOverride();
      toast({ title: 'Фон как в общих настройках' });
    } else {
      updatePrefs({ chatWallpaper: value });
      toast({ title: 'Фон сохранён для этого чата' });
    }
  };

  const onUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !userId || !storage || !firestore) return;
    if (fileRef.current) fileRef.current.value = '';
    if (!file.type.startsWith('image/')) {
      toast({ variant: 'destructive', title: 'Выберите изображение' });
      return;
    }
    setUploading(true);
    try {
      const compressed = await compressImage(file, 0.8, 1920);
      const blob = await fetch(compressed).then((r) => r.blob());
      const ext = file.name.split('.').pop() || 'jpg';
      const path = `wallpapers/${userId}/${Date.now()}.${ext}`;
      const ref = storageRef(storage, path);
      await uploadBytes(ref, blob);
      const url = await getDownloadURL(ref);
      await updateDoc(doc(firestore, 'users', userId), { customBackgrounds: arrayUnion(url) });
      updatePrefs({ chatWallpaper: url });
      toast({ title: 'Фон загружен для этого чата' });
    } catch (err) {
      console.error(err);
      toast({ variant: 'destructive', title: 'Не удалось загрузить фон' });
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="text-zinc-100 [&_label]:text-zinc-300">
      <p className="mb-4 text-sm text-zinc-400">
        Фон переписки только для этого диалога. Общие настройки оформления чатов не меняются.
      </p>

      <div className="mb-6 rounded-2xl border border-zinc-800/80 p-4">
        <Label className="text-xs font-bold uppercase text-zinc-500">Текущий фон</Label>
        <div
          className={cn(
            'mt-2 flex h-28 w-full items-center justify-center overflow-hidden rounded-xl border border-zinc-800 bg-zinc-900 text-xs text-zinc-500'
          )}
          style={
            isImageUrl(activeWallpaper)
              ? undefined
              : activeWallpaper
                ? { background: activeWallpaper }
                : undefined
          }
        >
          {isImageUrl(activeWallpaper) ? (
            <img src={activeWallpaper!} alt="" className="h-full w-full object-cover" />
          ) : activeWallpaper ? null : (
            'По умолчанию (общие настройки)'
          )}
        </div>
      </div>

      <div className="space-y-3">
        <Label>Пресеты</Label>
        <div className="flex flex-wrap gap-2">
          {WALLPAPERS.map((w) => (
            <Button
              key={w.label}
              type="button"
              variant="outline"
              size="sm"
              className="rounded-full border-zinc-700 bg-zinc-900/50 text-xs text-zinc-200 hover:bg-zinc-800"
              onClick={() => setGradient(w.value)}
            >
              {w.label}
            </Button>
          ))}
        </div>
      </div>

      <div className="mt-6">
        <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={(e) => void onUpload(e)} />
        <Button
          type="button"
          variant="secondary"
          disabled={uploading || !storage}
          className="rounded-full bg-zinc-800 text-zinc-100 hover:bg-zinc-700"
          onClick={() => fileRef.current?.click()}
        >
          {uploading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <ImagePlus className="mr-2 h-4 w-4" />}
          Загрузить своё фото
        </Button>
      </div>
    </div>
  );
}
