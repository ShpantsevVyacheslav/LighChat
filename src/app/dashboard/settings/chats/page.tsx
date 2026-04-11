"use client";

import { useState, useRef } from "react";
import { useSettings, DEFAULT_CHAT_SETTINGS } from "@/hooks/use-settings";
import { useAuth } from "@/hooks/use-auth";
import { useToast } from "@/hooks/use-toast";
import { useFirestore, useStorage } from "@/firebase";
import { ref as storageRef, uploadBytes, getDownloadURL } from "firebase/storage";
import { doc, updateDoc, arrayUnion, arrayRemove } from "firebase/firestore";
import { compressImage } from "@/lib/image-compression";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { MessageSquare, Check, RotateCcw, ImagePlus, Loader2, Trash2 } from "lucide-react";
import { cn } from "@/lib/utils";
import { BUBBLE_RADIUS_OPTIONS, bubbleRadiusToClass, normalizeBubbleRadius } from "@/lib/chat-bubble-radius";
import { BottomNavIconsSettingsSection } from "@/components/settings/BottomNavIconsSettingsSection";

const FONT_SIZES = [
  { value: "small" as const, label: "Мелкий", textClass: "text-xs" },
  { value: "medium" as const, label: "Средний", textClass: "text-sm" },
  { value: "large" as const, label: "Крупный", textClass: "text-base" },
];

const BUBBLE_COLORS = [
  { value: null, label: "По умолчанию" },
  { value: "#3B82F6", label: "Синий" },
  { value: "#10B981", label: "Зелёный" },
  { value: "#8B5CF6", label: "Фиолетовый" },
  { value: "#F59E0B", label: "Оранжевый" },
  { value: "#EF4444", label: "Красный" },
  { value: "#EC4899", label: "Розовый" },
  { value: "#06B6D4", label: "Бирюзовый" },
];

const WALLPAPERS = [
  { value: null, label: "Без фона", isGradient: false },
  { value: "linear-gradient(135deg, #667eea 0%, #764ba2 100%)", label: "Фиолетовый", isGradient: true },
  { value: "linear-gradient(135deg, #f093fb 0%, #f5576c 100%)", label: "Розовый", isGradient: true },
  { value: "linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)", label: "Голубой", isGradient: true },
  { value: "linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)", label: "Зелёный", isGradient: true },
  { value: "linear-gradient(135deg, #fa709a 0%, #fee140 100%)", label: "Закат", isGradient: true },
  { value: "linear-gradient(135deg, #a18cd1 0%, #fbc2eb 100%)", label: "Лавандовый", isGradient: true },
  { value: "linear-gradient(135deg, #0c0c0c 0%, #1a1a2e 100%)", label: "Ночь", isGradient: true },
  { value: "linear-gradient(135deg, #d4fc79 0%, #96e6a1 100%)", label: "Мята", isGradient: true },
];

function getDisplayColor(hex: string | null, fallback: string) {
  return hex ?? fallback;
}

function isImageUrl(value: string | null): boolean {
  if (!value) return false;
  return value.startsWith("http") || value.startsWith("data:");
}

export default function ChatSettingsPage() {
  const { user, isLoading } = useAuth();
  const { chatSettings, updateChatSettings } = useSettings();
  const { toast } = useToast();
  const firestore = useFirestore();
  const storage = useStorage();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);

  const handleUpdate = async (patch: Partial<typeof chatSettings>) => {
    const ok = await updateChatSettings(patch);
    if (!ok) {
      toast({ variant: "destructive", title: "Ошибка", description: "Не удалось сохранить настройки." });
    }
  };

  const handleReset = async () => {
    const ok = await updateChatSettings(DEFAULT_CHAT_SETTINGS);
    if (ok) {
      toast({ title: "Сброшено", description: "Настройки чатов восстановлены по умолчанию." });
    }
  };

  const handleUploadWallpaper = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !user || !storage || !firestore) return;
    if (fileInputRef.current) fileInputRef.current.value = "";

    if (!file.type.startsWith("image/")) {
      toast({ variant: "destructive", title: "Ошибка", description: "Выберите изображение (JPG, PNG, WebP)." });
      return;
    }

    setUploading(true);
    try {
      const compressed = await compressImage(file, 0.8, 1920);
      const blob = await fetch(compressed).then((r) => r.blob());
      const ext = file.name.split(".").pop() || "jpg";
      const path = `wallpapers/${user.id}/${Date.now()}.${ext}`;
      const ref = storageRef(storage, path);
      await uploadBytes(ref, blob);
      const url = await getDownloadURL(ref);
      await updateDoc(doc(firestore, "users", user.id), { customBackgrounds: arrayUnion(url) });
      await handleUpdate({ chatWallpaper: url });
      toast({ title: "Готово", description: "Фон загружен и применён." });
    } catch (err) {
      console.error("Wallpaper upload failed:", err);
      toast({ variant: "destructive", title: "Ошибка", description: "Не удалось загрузить изображение." });
    } finally {
      setUploading(false);
    }
  };

  const handleDeleteCustomWallpaper = async (url: string) => {
    if (!user || !firestore) return;
    try {
      await updateDoc(doc(firestore, "users", user.id), { customBackgrounds: arrayRemove(url) });
      if (chatSettings.chatWallpaper === url) {
        await handleUpdate({ chatWallpaper: null });
      }
    } catch (err) {
      console.error("Failed to delete wallpaper:", err);
    }
  };

  if (isLoading || !user) {
    return (
      <div className="space-y-4 max-w-3xl mx-auto">
        <Skeleton className="h-8 w-64" />
        <Skeleton className="h-40 w-full" />
        <Skeleton className="h-40 w-full" />
      </div>
    );
  }

  const outgoingColor = getDisplayColor(chatSettings.bubbleColor, "hsl(var(--primary))");
  const incomingColor = getDisplayColor(chatSettings.incomingBubbleColor, "hsl(var(--muted))");
  const currentWallpaper = chatSettings.chatWallpaper;
  const isCustomImage = isImageUrl(currentWallpaper);
  const previewRadius = bubbleRadiusToClass(chatSettings.bubbleRadius);
  const activeBubblePreset = normalizeBubbleRadius(
    chatSettings.bubbleRadius as string | undefined
  );

  return (
    <div className="space-y-6 max-w-3xl mx-auto pb-10">
      <div className="animate-in fade-in slide-in-from-top-4 duration-700 flex items-center gap-2">
        <div className="min-w-0">
          <h1 className="text-2xl sm:text-3xl font-bold flex items-center gap-2 leading-tight">
            <MessageSquare className="text-primary h-6 w-6 sm:h-8 sm:w-8" /> Настройки чатов
          </h1>
          <p className="text-xs sm:text-sm text-muted-foreground">Внешний вид сообщений и чатов.</p>
        </div>
      </div>

      <BottomNavIconsSettingsSection />

      <section className="space-y-4">
        <h2 className="text-base font-semibold leading-none tracking-tight">Предпросмотр</h2>
        <div
            className="relative rounded-2xl overflow-hidden p-4 min-h-[160px] flex flex-col justify-end gap-2"
            style={{
              background: isCustomImage ? undefined : (currentWallpaper ?? "var(--muted)"),
            }}
          >
            {isCustomImage && (
              <>
                <img src={currentWallpaper!} alt="" className="absolute inset-0 w-full h-full object-cover" />
                <div className="absolute inset-0 bg-black/40 dark:bg-black/55" />
              </>
            )}
            {/* Incoming */}
            <div className="relative flex flex-col gap-1 items-start">
              <div
                className={cn(
                  "px-4 py-2 text-sm max-w-[220px] shadow-sm rounded-tl-none",
                  previewRadius,
                  chatSettings.fontSize === "small" && "text-xs",
                  chatSettings.fontSize === "medium" && "text-sm",
                  chatSettings.fontSize === "large" && "text-base",
                )}
                style={{
                  backgroundColor: incomingColor,
                  color: chatSettings.incomingBubbleColor ? "#fff" : "var(--foreground)",
                }}
              >
                Привет! Как дела?
              </div>
              {chatSettings.showTimestamps && <span className="text-[10px] text-muted-foreground ml-1">11:58</span>}
            </div>
            {/* Outgoing */}
            <div className="relative flex flex-col gap-1 items-end">
              <div
                className={cn(
                  "px-4 py-2 text-white text-sm max-w-[220px] shadow-sm rounded-tr-none",
                  previewRadius,
                  chatSettings.fontSize === "small" && "text-xs",
                  chatSettings.fontSize === "medium" && "text-sm",
                  chatSettings.fontSize === "large" && "text-base",
                )}
                style={{ backgroundColor: outgoingColor }}
              >
                Отлично, спасибо!
              </div>
              {chatSettings.showTimestamps && <span className="text-[10px] text-muted-foreground mr-1">12:00</span>}
            </div>
          </div>
      </section>

      <section className="space-y-4">
        <h2 className="text-base font-semibold leading-none tracking-tight">Исходящие сообщения</h2>
        <div className="flex flex-wrap gap-3">
            {BUBBLE_COLORS.map((opt) => {
              const isActive = chatSettings.bubbleColor === opt.value;
              const bg = opt.value ?? "hsl(var(--primary))";
              return (
                <button
                  key={opt.value ?? "default"}
                  type="button"
                  title={opt.label}
                  onClick={() => handleUpdate({ bubbleColor: opt.value })}
                  className={cn(
                    "relative h-10 w-10 rounded-full border-2 transition-all hover:scale-110 active:scale-95",
                    isActive ? "border-foreground scale-110 shadow-lg" : "border-transparent"
                  )}
                  style={{ backgroundColor: bg }}
                >
                  {isActive && <Check className="absolute inset-0 m-auto h-4 w-4 text-white drop-shadow" />}
                </button>
              );
            })}
        </div>
      </section>

      <section className="space-y-4">
        <h2 className="text-base font-semibold leading-none tracking-tight">Входящие сообщения</h2>
        <div className="flex flex-wrap gap-3">
            {BUBBLE_COLORS.map((opt) => {
              const isActive = chatSettings.incomingBubbleColor === opt.value;
              const bg = opt.value ?? "hsl(var(--muted))";
              return (
                <button
                  key={opt.value ?? "default-in"}
                  type="button"
                  title={opt.label}
                  onClick={() => handleUpdate({ incomingBubbleColor: opt.value })}
                  className={cn(
                    "relative h-10 w-10 rounded-full border-2 transition-all hover:scale-110 active:scale-95",
                    isActive ? "border-foreground scale-110 shadow-lg" : "border-transparent"
                  )}
                  style={{ backgroundColor: bg }}
                >
                  {isActive && <Check className="absolute inset-0 m-auto h-4 w-4 text-white drop-shadow" />}
                </button>
              );
            })}
        </div>
      </section>

      <section className="space-y-4">
        <h2 className="text-base font-semibold leading-none tracking-tight">Размер шрифта</h2>
        <div className="flex gap-2">
            {FONT_SIZES.map((opt) => (
              <Button
                key={opt.value}
                variant={chatSettings.fontSize === opt.value ? "default" : "outline"}
                size="sm"
                className="rounded-xl flex-1"
                onClick={() => handleUpdate({ fontSize: opt.value })}
              >
                <span className={opt.textClass}>{opt.label}</span>
              </Button>
            ))}
        </div>
      </section>

      <section className="space-y-4">
        <h2 className="text-base font-semibold leading-none tracking-tight">Форма пузырьков</h2>
        <div className="grid grid-cols-2 gap-3 max-w-md">
            {BUBBLE_RADIUS_OPTIONS.map((opt) => {
              const isActive = activeBubblePreset === opt.value;
              return (
                <button
                  key={opt.value}
                  type="button"
                  onClick={() => handleUpdate({ bubbleRadius: opt.value })}
                  className={cn(
                    "flex flex-col items-center gap-3 p-3 sm:p-4 rounded-xl border-2 transition-all",
                    isActive ? "border-primary bg-primary/5 shadow-sm ring-1 ring-primary/15" : "border-transparent bg-muted/50 hover:bg-muted"
                  )}
                >
                  <div className="w-full flex flex-col gap-2.5 min-h-[76px] justify-center">
                    <div className="flex justify-end w-full">
                      <div className={cn("px-3.5 py-2 min-w-[4.5rem] text-center text-[11px] text-white bg-primary shadow-sm rounded-tr-none", opt.radius)}>
                        Привет
                      </div>
                    </div>
                    <div className="flex justify-start w-full">
                      <div className={cn("px-3.5 py-2 min-w-[5rem] text-center text-[11px] bg-muted-foreground/20 shadow-sm rounded-tl-none", opt.radius)}>
                        Как дела?
                      </div>
                    </div>
                  </div>
                  <span className="text-xs font-medium">{opt.label}</span>
                </button>
              );
            })}
        </div>
      </section>

      <section className="space-y-4">
        <h2 className="text-base font-semibold leading-none tracking-tight">Фон чата</h2>
        <div className="space-y-4">
          <div className="grid grid-cols-3 sm:grid-cols-4 gap-3">
            {WALLPAPERS.map((wp) => {
              const isActive = currentWallpaper === wp.value;
              return (
                <button
                  key={wp.value ?? "none"}
                  type="button"
                  onClick={() => handleUpdate({ chatWallpaper: wp.value })}
                  className={cn(
                    "relative h-20 rounded-2xl border-2 overflow-hidden transition-all hover:scale-105 active:scale-95",
                    isActive ? "border-primary ring-2 ring-primary/30" : "border-transparent"
                  )}
                  style={{ background: wp.value ?? "var(--background)" }}
                >
                  {!wp.value && (
                    <div className="absolute inset-0 flex items-center justify-center bg-muted text-muted-foreground text-[10px] font-medium">
                      Нет
                    </div>
                  )}
                  {isActive && (
                    <div className="absolute inset-0 flex items-center justify-center bg-black/20">
                      <Check className="h-5 w-5 text-white drop-shadow" />
                    </div>
                  )}
                  {wp.value && (
                    <span className="absolute bottom-1 left-0 right-0 text-center text-[9px] font-medium text-white drop-shadow-md">
                      {wp.label}
                    </span>
                  )}
                </button>
              );
            })}
          </div>

          {/* Custom wallpapers section */}
          <div>
            <p className="text-xs font-medium text-muted-foreground mb-2">Ваши фоны</p>
            <div className="grid grid-cols-3 sm:grid-cols-4 gap-3">
              {(user.customBackgrounds || []).map((url) => {
                const isActive = currentWallpaper === url;
                return (
                  <div key={url} className="relative group">
                    <button
                      type="button"
                      onClick={() => handleUpdate({ chatWallpaper: url })}
                      className={cn(
                        "relative h-20 w-full rounded-2xl border-2 overflow-hidden transition-all hover:scale-105 active:scale-95",
                        isActive ? "border-primary ring-2 ring-primary/30" : "border-transparent"
                      )}
                    >
                      <img src={url} alt="" className="absolute inset-0 w-full h-full object-cover" />
                      <div className="absolute inset-0 bg-black/30" />
                      {isActive && (
                        <div className="absolute inset-0 flex items-center justify-center">
                          <Check className="h-5 w-5 text-white drop-shadow" />
                        </div>
                      )}
                    </button>
                    <button
                      type="button"
                      onClick={() => handleDeleteCustomWallpaper(url)}
                      className="absolute -top-1.5 -right-1.5 h-5 w-5 rounded-full bg-destructive text-white flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity shadow-md hover:scale-110"
                    >
                      <Trash2 className="h-3 w-3" />
                    </button>
                  </div>
                );
              })}

              {/* Upload button */}
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                disabled={uploading}
                className="relative h-20 rounded-2xl border-2 border-dashed overflow-hidden transition-all hover:scale-105 active:scale-95 flex flex-col items-center justify-center gap-1 border-muted-foreground/30 hover:border-muted-foreground/50"
              >
                {uploading ? (
                  <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
                ) : (
                  <>
                    <ImagePlus className="h-5 w-5 text-muted-foreground" />
                    <span className="text-[9px] text-muted-foreground font-medium">Добавить</span>
                  </>
                )}
              </button>
            </div>
            <p className="text-[10px] text-muted-foreground mt-2">Изображения затемняются автоматически для читаемости.</p>
          </div>

          <input
            ref={fileInputRef}
            type="file"
            accept="image/jpeg,image/png,image/webp"
            className="hidden"
            onChange={handleUploadWallpaper}
          />
        </div>
      </section>

      <section className="space-y-4">
        <h2 className="text-base font-semibold leading-none tracking-tight">Дополнительно</h2>
        <div className="space-y-5">
          <div className="flex items-center justify-between gap-4">
            <div>
              <Label className="text-sm font-medium">Показывать время</Label>
              <p className="text-xs text-muted-foreground">Время отправки под каждым сообщением.</p>
            </div>
            <Switch
              checked={chatSettings.showTimestamps}
              onCheckedChange={(v) => handleUpdate({ showTimestamps: v })}
            />
          </div>
        </div>
      </section>

      {/* Reset */}
      <div className="flex justify-center pt-2">
        <Button variant="ghost" onClick={handleReset} className="rounded-full gap-2 text-sm text-muted-foreground hover:text-foreground">
          <RotateCcw className="h-4 w-4" />
          Сбросить настройки
        </Button>
      </div>
    </div>
  );
}
