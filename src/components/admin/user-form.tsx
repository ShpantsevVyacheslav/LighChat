

"use client";

import React, { useTransition } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import type { User, UserRole } from "@/lib/types";
import { ROLES } from "@/lib/constants";
import { Button } from "@/components/ui/button";
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { PhoneInput } from "@/components/ui/phone-input";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { phoneFormValueFromStored } from "@/lib/phone-utils";
import { ScrollArea } from "../ui/scroll-area";
import { Loader2, X, Eye, EyeOff, User as UserIcon, Camera } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { useStorage, useFirestore, updateDocumentNonBlocking } from "@/firebase";
import { doc, deleteField } from 'firebase/firestore';
import { ref as storageRef, uploadBytes, getDownloadURL } from "firebase/storage";
import Image from 'next/image';
import { Dialog, DialogContent, DialogTrigger, DialogClose } from "@/components/ui/dialog";
import { compressImage } from "@/lib/image-compression";
import { cn } from "@/lib/utils";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { RegisterAvatarCropOverlay } from "@/components/auth/register-avatar-crop-overlay";
import { uploadUserAvatarPair } from "@/lib/upload-user-avatar-pair";
import { userAvatarListUrl } from "@/lib/user-avatar-display";
import { useDashboardMainColumnScope } from "@/contexts/dashboard-main-column-scope";

const applyDateMask = (value: string): string => {
  if (!value) return "";
  const cleaned = value.replace(/\D/g, '');
  const match = cleaned.match(/^(\d{0,2})(\d{0,2})(\d{0,4})$/);
  if (!match) return '';
  
  const part1 = match[1];
  const part2 = match[2];
  const part3 = match[3];

  if (part3) {
    return `${part1}.${part2}.${part3}`;
  }
  if (part2) {
    return `${part1}.${part2}`;
  }
  return part1;
};

/** Converts "yyyy-MM-dd" to "ДД.ММ.ГГГГ" for display */
const isoToDisplay = (value: string | null | undefined): string => {
  if (!value) return "";
  const match = value.match(/^(\d{4})-(\d{2})-(\d{2})$/);
  if (match) return `${match[3]}.${match[2]}.${match[1]}`;
  return value;
};

/** ДД.ММ.ГГГГ → yyyy-MM-dd для Firestore (как при регистрации). */
const displayDateToIso = (display: string | undefined): string | undefined => {
  if (!display?.trim()) return undefined;
  const t = display.trim();
  const m = t.match(/^(\d{2})\.(\d{2})\.(\d{4})$/);
  if (!m) return undefined;
  const y = Number(m[3]);
  const mo = Number(m[2]);
  const d = Number(m[1]);
  const dt = new Date(Date.UTC(y, mo - 1, d, 12));
  if (Number.isNaN(dt.getTime())) return undefined;
  const year = dt.getUTCFullYear();
  const currentYear = new Date().getFullYear();
  if (year < 1920 || year > currentYear) return undefined;
  return `${m[3]}-${m[2]}-${m[1]}`;
};

const userFormSchema = z.object({
  name: z.string().min(2, { message: "Имя должно содержать не менее 2 символов." }),
  username: z.string().max(30, { message: "Логин не должен превышать 30 символов." }),
  email: z.string().email({ message: "Неверный формат email." }),
  phone: z.string().optional(),
  dateOfBirth: z.string().optional(),
  bio: z.string().max(200, { message: "Не более 200 символов." }).optional(),
  password: z.string().optional(),
  /** Только для страницы профиля: должен совпадать с password при смене пароля. */
  confirmPassword: z.string().optional(),
  role: z.enum(Object.keys(ROLES) as [UserRole, ...UserRole[]], { required_error: "Необходимо выбрать роль." }),
  avatar: z.string().url({ message: "Пожалуйста, введите действительный URL." }).optional().or(z.literal('')),
  avatarThumb: z.string().url({ message: "Некорректный URL превью." }).optional().or(z.literal('')),
});

export type UserFormValues = z.infer<typeof userFormSchema>;
/** Данные для сохранения (confirmPassword не уходит в API/Firestore). */
export type UserFormSavePayload = Omit<UserFormValues, "confirmPassword">;

interface UserFormProps {
  initialData: Partial<User> | null;
  onSave: (data: UserFormSavePayload) => void;
  onCancel: () => void;
  isSubmitting?: boolean;
  isProfilePage?: boolean;
  hideCancelButton?: boolean;
  layout?: 'vertical' | 'horizontal';
}


export function UserForm({ initialData, onSave, onCancel, isSubmitting, isProfilePage = false, hideCancelButton = false, layout = 'vertical' }: UserFormProps) {
  const isEditing = !!(initialData && 'id' in initialData && initialData.id);
  const getDashboardMainColumnEl = useDashboardMainColumnScope();
  const fileInputRef = React.useRef<HTMLInputElement>(null);
  const { toast } = useToast();
  const [isUploading, startUploading] = useTransition();
  const [showPassword, setShowPassword] = React.useState(false);
  const [profileCropOpen, setProfileCropOpen] = React.useState(false);
  const [profileCropSrc, setProfileCropSrc] = React.useState<string | null>(null);
  const profileAvatarFullRef = React.useRef<File | null>(null);
  const storage = useStorage();
  const firestore = useFirestore();

  React.useEffect(() => {
    return () => {
      if (profileCropSrc?.startsWith("blob:")) URL.revokeObjectURL(profileCropSrc);
    };
  }, [profileCropSrc]);

  const form = useForm<UserFormValues>({
    resolver: zodResolver(userFormSchema.superRefine((data, ctx) => {
        if (!isEditing && (!data.password || data.password.length < 6)) {
            ctx.addIssue({
                code: z.ZodIssueCode.custom,
                message: "Пароль должен содержать не менее 6 символов.",
                path: ["password"],
            });
        }
        if (isEditing && data.password && data.password.length > 0 && data.password.length < 6) {
             ctx.addIssue({
                code: z.ZodIssueCode.custom,
                message: "Пароль должен быть не менее 6 символов.",
                path: ["password"],
            });
        }
        if (isProfilePage && data.password && data.password.length >= 6) {
            if ((data.confirmPassword ?? "") !== data.password) {
                ctx.addIssue({
                    code: z.ZodIssueCode.custom,
                    message: "Пароли не совпадают.",
                    path: ["confirmPassword"],
                });
            }
        }

        const normU = (data.username ?? "").trim().replace(/^@/, "").toLowerCase();
        if (normU.length > 0) {
          if (normU.length < 3) {
            ctx.addIssue({
              code: z.ZodIssueCode.custom,
              message: "Логин должен содержать не менее 3 символов.",
              path: ["username"],
            });
          } else if (!/^[a-zA-Z0-9_]+$/.test(normU)) {
            ctx.addIssue({
              code: z.ZodIssueCode.custom,
              message: "Только латиница, цифры и _",
              path: ["username"],
            });
          }
        }

        if (isProfilePage) {
          const digits = (data.phone ?? "").replace(/\D/g, "");
          if (digits.length > 0 && digits.length !== 11) {
            ctx.addIssue({
              code: z.ZodIssueCode.custom,
              message: "Введите полный номер телефона.",
              path: ["phone"],
            });
          }
          if (data.dateOfBirth?.trim()) {
            if (!displayDateToIso(data.dateOfBirth)) {
              ctx.addIssue({
                code: z.ZodIssueCode.custom,
                message: "Некорректная дата рождения (ДД.ММ.ГГГГ).",
                path: ["dateOfBirth"],
              });
            }
          }
        }
    })),
    defaultValues: {
      name: initialData?.name || "",
      username: initialData?.username || "",
      email: initialData?.email || "",
      phone: phoneFormValueFromStored(initialData?.phone),
      dateOfBirth: isoToDisplay(initialData?.dateOfBirth) || "",
      bio: initialData?.bio || "",
      password: "",
      confirmPassword: "",
      role: initialData?.role || "worker",
      avatar: initialData?.avatar || "",
      avatarThumb: initialData?.avatarThumb || "",
    },
  });
  
  const processAvatarFile = React.useCallback(
    (file: File | undefined) => {
      if (!file || !file.type.startsWith("image/")) return;

      if (!initialData?.id || !firestore) {
        startUploading(async () => {
          try {
            const compressedDataUri = await compressImage(file);
            form.setValue("avatar", compressedDataUri, { shouldValidate: true });
            toast({
              title: "Фото готово к загрузке",
              description: "Аватар будет загружен после создания пользователя.",
            });
          } catch (e) {
            console.error("[UserForm] avatar preview", e);
            toast({ variant: "destructive", title: "Ошибка обработки фото" });
          }
        });
        return;
      }

      startUploading(async () => {
        try {
          const MAX_SIZE_BYTES = 500 * 1024;
          let imageBlob: Blob = file;

          if (file.size > MAX_SIZE_BYTES && file.type.startsWith("image/")) {
            toast({ title: "Файл слишком большой", description: "Сжимаем изображение..." });
            const compressedDataUri = await compressImage(file);
            const response = await fetch(compressedDataUri);
            imageBlob = await response.blob();
          }

          const filePath = `avatars/${initialData.id}/${Date.now()}_${file.name.replace(/\s/g, "_")}`;
          const fileRef = storageRef(storage, filePath);
          await uploadBytes(fileRef, imageBlob);
          const publicUrl = await getDownloadURL(fileRef);

          form.setValue("avatar", publicUrl, { shouldValidate: true, shouldDirty: true });
          form.setValue("avatarThumb", "", { shouldValidate: true, shouldDirty: true });

          const userDocRef = doc(firestore, "users", initialData.id!);
          await updateDocumentNonBlocking(userDocRef, {
            avatar: publicUrl,
            avatarThumb: deleteField(),
          });

          toast({ title: "Аватар обновлен!", description: "Новый аватар сохранён." });
        } catch (error: unknown) {
          const message = error instanceof Error ? error.message : String(error);
          console.error("[UserForm] avatar upload failed:", error);
          toast({ variant: "destructive", title: "Ошибка загрузки", description: message });
        }
      });
    },
    [firestore, form, initialData?.id, startUploading, storage, toast]
  );

  const handleAvatarUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    event.target.value = "";
    processAvatarFile(file);
  };

  const handleProfileAvatarPick = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file || !file.type.startsWith("image/")) return;
    profileAvatarFullRef.current = file;
    const url = URL.createObjectURL(file);
    setProfileCropSrc(url);
    setProfileCropOpen(true);
  };

  const handleProfileCropCancel = () => {
    profileAvatarFullRef.current = null;
    if (profileCropSrc?.startsWith("blob:")) URL.revokeObjectURL(profileCropSrc);
    setProfileCropSrc(null);
    setProfileCropOpen(false);
  };

  const handleProfileCropApply = (circleFile: File) => {
    const full = profileAvatarFullRef.current;
    profileAvatarFullRef.current = null;
    if (profileCropSrc?.startsWith("blob:")) URL.revokeObjectURL(profileCropSrc);
    setProfileCropSrc(null);
    setProfileCropOpen(false);
    if (!full || !initialData?.id || !storage || !firestore) return;

    startUploading(async () => {
      try {
        const { avatarUrl, avatarThumbUrl } = await uploadUserAvatarPair(
          storage,
          initialData.id!,
          full,
          circleFile,
        );
        form.setValue("avatar", avatarUrl, { shouldValidate: true, shouldDirty: true });
        if (avatarThumbUrl) {
          form.setValue("avatarThumb", avatarThumbUrl, { shouldValidate: true, shouldDirty: true });
        } else {
          form.setValue("avatarThumb", "", { shouldValidate: true, shouldDirty: true });
        }
        const userDocRef = doc(firestore, "users", initialData!.id!);
        await updateDocumentNonBlocking(userDocRef, {
          avatar: avatarUrl,
          avatarThumb: avatarThumbUrl ?? deleteField(),
        });
        toast({
          title: "Аватар обновлён!",
          description: "Сохранены полное фото и круглое превью.",
        });
      } catch (error: unknown) {
        const message = error instanceof Error ? error.message : String(error);
        console.error("[UserForm] profile avatar pair upload failed:", error);
        toast({ variant: "destructive", title: "Ошибка загрузки", description: message });
      }
    });
  };

  const onSubmit = (data: UserFormValues) => {
    const { confirmPassword: _confirm, password, ...rest } = data;
    const usernameNorm = (rest.username ?? "").trim().replace(/^@/, "").toLowerCase();
    const dobRaw = rest.dateOfBirth?.trim() ?? "";
    const dobIso = displayDateToIso(dobRaw);

    const payload: UserFormSavePayload = {
      ...rest,
      username: usernameNorm,
      bio: rest.bio?.trim() ?? "",
      dateOfBirth: dobRaw === "" ? "" : (dobIso ?? rest.dateOfBirth),
      ...(password && password.length > 0 ? { password } : {}),
    };
    onSave(payload);
  };
  
  const formContent = (
    <div className={cn(
      "space-y-4 p-1",
      layout === 'horizontal' && "grid grid-cols-1 md:grid-cols-3 gap-8"
    )}>
      {/* Avatar: профиль — как при регистрации (круг + обрезка); админ — превью в диалоге */}
      <div className={cn(layout === 'horizontal' && "md:col-span-1")}>
        <FormField
          control={form.control}
          name="avatar"
          render={({ field }) => (
            <FormItem>
              <FormControl>
                {isProfilePage ? (
                  <div className="flex flex-col items-center gap-1 pb-2">
                    <button
                      type="button"
                      onClick={() => fileInputRef.current?.click()}
                      disabled={isUploading}
                      className="group relative disabled:opacity-60"
                      aria-label="Изменить аватар"
                    >
                      <div className="flex h-20 w-20 items-center justify-center overflow-hidden rounded-full border-2 border-dashed border-white/45 bg-white/20 backdrop-blur-md transition-colors group-hover:border-primary/60 group-disabled:pointer-events-none dark:border-white/25 dark:bg-white/[0.06]">
                        {field.value ? (
                          <img
                            src={userAvatarListUrl({
                              avatar: field.value,
                              avatarThumb: form.watch("avatarThumb"),
                            })}
                            alt=""
                            className="h-full w-full object-cover"
                          />
                        ) : (
                          <Camera className="h-7 w-7 text-slate-500 transition-colors group-hover:text-primary dark:text-white/45" />
                        )}
                      </div>
                      <div className="pointer-events-none absolute -bottom-1 -right-1 flex h-6 w-6 items-center justify-center rounded-full bg-primary shadow-md">
                        <span className="text-xs font-bold text-white">+</span>
                      </div>
                    </button>
                    <input
                      ref={fileInputRef}
                      type="file"
                      accept="image/*"
                      className="hidden"
                      onChange={handleProfileAvatarPick}
                    />
                    <p className="max-w-[240px] text-center text-[10px] leading-snug text-slate-500 dark:text-white/40">
                      Необязательно. Полный кадр — в профиле при открытии фото; круг из окна — в списках и сообщениях.
                    </p>
                  </div>
                ) : (
                  <div className="flex flex-col items-center gap-4">
                    <Dialog>
                      <DialogTrigger asChild disabled={!field.value}>
                        <div className="relative h-32 w-32 cursor-pointer overflow-hidden rounded-full border bg-muted group">
                          {field.value ? (
                            <Avatar className="h-full w-full">
                              <AvatarImage
                                src={userAvatarListUrl({
                                  avatar: field.value,
                                  avatarThumb: form.watch("avatarThumb"),
                                })}
                                alt={form.getValues("name")}
                                className="object-cover"
                              />
                              <AvatarFallback>
                                <UserIcon className="h-16 w-16 text-muted-foreground" />
                              </AvatarFallback>
                            </Avatar>
                          ) : (
                            <div className="flex h-full items-center justify-center">
                              <UserIcon className="h-16 w-16 text-muted-foreground" />
                            </div>
                          )}
                        </div>
                      </DialogTrigger>
                      {field.value && (
                        <DialogContent
                          showCloseButton={false}
                          className="flex h-screen max-h-full w-screen max-w-full flex-col items-center justify-center rounded-none border-none bg-black/90 p-0 shadow-none backdrop-blur-sm"
                        >
                          <header className="absolute left-0 right-0 top-0 z-50 flex h-24 items-start justify-between bg-gradient-to-b from-black/70 to-transparent p-4 text-white">
                            <p className="font-semibold">{form.getValues("name")}</p>
                            <DialogClose asChild>
                              <Button
                                variant="ghost"
                                size="icon"
                                className="text-white hover:bg-white/20 hover:text-white"
                                aria-label="Закрыть"
                              >
                                <X className="h-6 w-6" />
                              </Button>
                            </DialogClose>
                          </header>
                          <div className="relative h-[85vh] w-[95vw]">
                            <Image
                              src={field.value}
                              alt={form.getValues("name")}
                              fill
                              sizes="(max-width: 768px) 100vw, 80vw"
                              className="h-full w-full object-contain"
                            />
                          </div>
                        </DialogContent>
                      )}
                    </Dialog>
                    <div>
                      <input
                        type="file"
                        ref={fileInputRef}
                        onChange={handleAvatarUpload}
                        className="hidden"
                        accept="image/*"
                      />
                      <Button
                        type="button"
                        variant="outline"
                        onClick={() => fileInputRef.current?.click()}
                        disabled={isUploading}
                        className="rounded-full"
                      >
                        {isUploading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                        {isEditing ? "Изменить аватар" : "Добавить аватар"}
                      </Button>
                    </div>
                  </div>
                )}
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
      </div>

      {/* Details Section */}
      <div className={cn("space-y-4", layout === 'horizontal' && "md:col-span-2")}>
        <FormField
          control={form.control}
          name="name"
          render={({ field }) => (
            <FormItem>
              <FormLabel>ФИО</FormLabel>
              <FormControl>
                <Input placeholder="Иванов Иван" {...field} className="rounded-xl" />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
        <FormField
          control={form.control}
          name="username"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Логин</FormLabel>
              <FormControl>
                <Input placeholder="username" {...field} className="rounded-xl" autoComplete="username" />
              </FormControl>
              <FormDescription className="text-xs">
                Латиница, цифры и символ подчёркивания; не менее 3 символов, если указан.
              </FormDescription>
              <FormMessage />
            </FormItem>
          )}
        />
        <FormField
          control={form.control}
          name="email"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Email</FormLabel>
              <FormControl>
                <Input
                  type="email"
                  placeholder="user@alliance.com"
                  {...field}
                  disabled={isEditing && !isProfilePage}
                  className="rounded-xl"
                />
              </FormControl>
              {isEditing && !isProfilePage && (
                <FormDescription>Email нельзя изменить после создания.</FormDescription>
              )}
              {isProfilePage && (
                <FormDescription className="text-xs">
                  Меняет email для входа в Firebase; при ошибке может потребоваться недавний вход.
                </FormDescription>
              )}
              <FormMessage />
            </FormItem>
          )}
        />
         <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <FormField
            control={form.control}
            name="phone"
            render={({ field }) => (
                <FormItem>
                <FormLabel>Телефон</FormLabel>
                <FormControl>
                    <PhoneInput
                      value={field.value ?? ""}
                      onChange={field.onChange}
                      className="rounded-xl"
                    />
                </FormControl>
                <FormMessage />
                </FormItem>
            )}
            />
            <FormField
            control={form.control}
            name="dateOfBirth"
            render={({ field }) => (
                <FormItem>
                    <FormLabel>Дата рождения</FormLabel>
                    <FormControl>
                    <Input 
                        placeholder="ДД.ММ.ГГГГ" 
                        {...field} 
                        value={field.value ?? ''}
                        onChange={(e) => field.onChange(applyDateMask(e.target.value))}
                        className="rounded-xl"
                    />
                    </FormControl>
                    <FormMessage />
                </FormItem>
            )}
            />
            </div>
        <FormField
          control={form.control}
          name="bio"
          render={({ field }) => (
            <FormItem>
              <FormLabel>О себе</FormLabel>
              <FormControl>
                <Textarea
                  placeholder="Кратко о себе (необязательно)"
                  className="min-h-[100px] rounded-xl resize-y"
                  maxLength={200}
                  {...field}
                  value={field.value ?? ""}
                />
              </FormControl>
              <FormDescription className="text-xs">Не более 200 символов.</FormDescription>
              <FormMessage />
            </FormItem>
          )}
        />
        {isProfilePage ? (
          <div className="rounded-xl space-y-3">
            <div className="flex items-center justify-between">
              <p className="text-sm font-medium">Смена пароля</p>
              <Button
                type="button"
                variant="ghost"
                size="sm"
                className="text-xs text-primary h-auto py-1 px-2"
                onClick={() => {
                  const next = !showPassword;
                  setShowPassword(next);
                  if (!next) {
                    form.setValue("password", "");
                    form.setValue("confirmPassword", "");
                    form.clearErrors(["password", "confirmPassword"]);
                  }
                }}
              >
                {showPassword ? "Скрыть" : "Изменить пароль"}
              </Button>
            </div>
            {showPassword && (
              <div className="space-y-3 animate-in slide-in-from-top-2 duration-200">
                <FormField
                  control={form.control}
                  name="password"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel className="text-xs text-muted-foreground">Новый пароль</FormLabel>
                      <FormControl>
                        <Input
                          type="password"
                          placeholder="Минимум 6 символов"
                          {...field}
                          className="rounded-xl"
                          autoComplete="new-password"
                        />
                      </FormControl>
                      <FormDescription className="text-[11px]">Оставьте пустым, чтобы не менять.</FormDescription>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="confirmPassword"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel className="text-xs text-muted-foreground">Подтвердите пароль</FormLabel>
                      <FormControl>
                        <Input
                          type="password"
                          placeholder="Повторите новый пароль"
                          {...field}
                          className="rounded-xl"
                          autoComplete="new-password"
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>
            )}
          </div>
        ) : (
          <FormField
            control={form.control}
            name="password"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Пароль</FormLabel>
                <FormControl>
                  <div className="relative">
                    <Input 
                      type={showPassword ? 'text' : 'password'}
                      placeholder={isEditing ? "Оставьте пустым, чтобы не менять" : "••••••••"} 
                      {...field} 
                      className="rounded-xl pr-10" />
                    <Button
                      type="button"
                      variant="ghost"
                      size="icon"
                      className="absolute right-1 top-1/2 -translate-y-1/2 h-8 w-8 text-muted-foreground hover:bg-transparent"
                      onClick={() => setShowPassword(!showPassword)}
                    >
                      {showPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
                    </Button>
                  </div>
                </FormControl>
                {isEditing && <FormDescription>Введите новый пароль, чтобы сбросить его для этого пользователя.</FormDescription>}
                {!isEditing && <FormDescription>Пароль должен содержать не менее 6 символов.</FormDescription>}
                <FormMessage />
              </FormItem>
            )}
          />
        )}
        {!isProfilePage && (
          <FormField
            control={form.control}
            name="role"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Роль</FormLabel>
                <Select onValueChange={field.onChange} defaultValue={field.value}>
                  <FormControl>
                    <SelectTrigger className="rounded-xl">
                      <SelectValue placeholder="Выберите роль" />
                    </SelectTrigger>
                  </FormControl>
                  <SelectContent>
                    {Object.entries(ROLES).map(([role, name]) => (
                      <SelectItem key={role} value={role}>
                        {name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <FormMessage />
              </FormItem>
            )}
          />
        )}
      </div>
    </div>
  );

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
        {layout === 'vertical' ? (
          <ScrollArea className="h-[60vh] pr-4">{formContent}</ScrollArea>
        ) : (
          <div>{formContent}</div>
        )}
        <div className="flex justify-end gap-2 pt-6">
          {!hideCancelButton && (
            <Button type="button" variant="ghost" onClick={onCancel} disabled={isSubmitting || isUploading} className="rounded-full">
              Отмена
            </Button>
          )}
          <Button type="submit" disabled={isProfilePage ? (isSubmitting || isUploading || !form.formState.isDirty) : (isSubmitting || isUploading)} className="rounded-full bg-primary hover:bg-primary/90 text-white shadow-md px-8">
            {(isSubmitting || isUploading) && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
            Сохранить
          </Button>
        </div>
      </form>
      {isProfilePage && (
        <RegisterAvatarCropOverlay
          variant="compact"
          open={profileCropOpen}
          imageSrc={profileCropSrc}
          onCancel={handleProfileCropCancel}
          onApply={handleProfileCropApply}
          scopeWithinElement={getDashboardMainColumnEl ?? undefined}
        />
      )}
    </Form>
  );
}
