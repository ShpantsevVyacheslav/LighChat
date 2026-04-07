

"use client";

import React, { useTransition, useState } from "react";
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
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { applyPhoneMask } from "@/lib/phone-utils";
import { tryApplyRuPhoneMaskKeyEdit } from "@/lib/ru-phone-mask-edit";
import { ScrollArea } from "../ui/scroll-area";
import { Loader2, X, Eye, EyeOff, User as UserIcon } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { useStorage, useFirestore, updateDocumentNonBlocking } from "@/firebase";
import { doc } from 'firebase/firestore';
import { ref as storageRef, uploadBytes, getDownloadURL } from "firebase/storage";
import Image from 'next/image';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogTrigger, DialogClose } from "@/components/ui/dialog";
import { compressImage } from "@/lib/image-compression";
import { cn } from "@/lib/utils";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";

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
  const fileInputRef = React.useRef<HTMLInputElement>(null);
  const { toast } = useToast();
  const [isUploading, startUploading] = useTransition();
  const [showPassword, setShowPassword] = React.useState(false);
  const storage = useStorage();
  const firestore = useFirestore();


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
      phone: initialData?.phone || "",
      dateOfBirth: isoToDisplay(initialData?.dateOfBirth) || "",
      bio: initialData?.bio || "",
      password: "",
      confirmPassword: "",
      role: initialData?.role || "worker",
      avatar: initialData?.avatar || "",
    },
  });
  
  const handleAvatarUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;
    
    if (!initialData?.id || !firestore) {
      // Handle case for new user (no initialData.id)
      startUploading(async () => {
         try {
           const compressedDataUri = await compressImage(file);
           form.setValue('avatar', compressedDataUri, { shouldValidate: true });
            toast({ title: 'Фото готово к загрузке', description: 'Аватар будет загружен после создания пользователя.' });
         } catch(e) {
            toast({ variant: 'destructive', title: 'Ошибка обработки фото' });
         }
      });
      return;
    }

    startUploading(async () => {
      try {
        const MAX_SIZE_BYTES = 500 * 1024; // 500 KB
        let imageBlob: Blob = file;

        if (file.size > MAX_SIZE_BYTES && file.type.startsWith('image/')) {
          toast({ title: 'Файл слишком большой', description: 'Сжимаем изображение...' });
          const compressedDataUri = await compressImage(file);
          const response = await fetch(compressedDataUri);
          imageBlob = await response.blob();
        }

        // 1. Create a storage reference on the client
        const filePath = `avatars/${initialData.id}/${Date.now()}_${file.name.replace(/\s/g, '_')}`;
        const fileRef = storageRef(storage, filePath);

        // 2. Upload the file using the client SDK
        await uploadBytes(fileRef, imageBlob);

        // 3. Get the public download URL
        const publicUrl = await getDownloadURL(fileRef);

        // 4. Update the form for immediate UI feedback
        form.setValue('avatar', publicUrl, { shouldValidate: true, shouldDirty: true });
        
        // 5. Asynchronously update the user document in Firestore.
        // The onSnapshot listener in useAuth will handle the state update.
        const userDocRef = doc(firestore, 'users', initialData.id!);
        await updateDocumentNonBlocking(userDocRef, { avatar: publicUrl });

        toast({ title: 'Аватар обновлен!', description: 'Ваш новый аватар был успешно сохранен.' });

      } catch (error: any) {
        console.error("Upload failed:", error);
        toast({ variant: 'destructive', title: 'Ошибка загрузки', description: error.message });
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
      {/* Avatar Section */}
      <div className={cn(layout === 'horizontal' && "md:col-span-1")}>
        <FormField
          control={form.control}
          name="avatar"
          render={({ field }) => (
            <FormItem>
              <FormControl>
                <div className="flex flex-col items-center gap-4">
                  <Dialog>
                    <DialogTrigger asChild disabled={!field.value}>
                       <div className="relative w-32 h-32 rounded-full overflow-hidden cursor-pointer group bg-muted border">
                        {field.value ? (
                          <Avatar className="h-full w-full">
                            <AvatarImage src={field.value} alt={form.getValues('name')} className="object-cover" />
                            <AvatarFallback><UserIcon className="h-16 w-16 text-muted-foreground"/></AvatarFallback>
                          </Avatar>
                        ) : (
                          <div className="flex items-center justify-center h-full">
                            <UserIcon className="h-16 w-16 text-muted-foreground" />
                          </div>
                        )}
                      </div>
                    </DialogTrigger>
                    {field.value && (
                       <DialogContent showCloseButton={false} className="bg-black/90 backdrop-blur-sm border-none shadow-none p-0 w-screen h-screen max-w-full max-h-full rounded-none flex flex-col items-center justify-center">
                        <header className="absolute top-0 left-0 right-0 z-50 h-24 bg-gradient-to-b from-black/70 to-transparent flex items-start justify-between p-4 text-white">
                            <p className="font-semibold">{form.getValues('name')}</p>
                            <DialogClose asChild>
                                <Button variant="ghost" size="icon" className="text-white hover:bg-white/20 hover:text-white" aria-label="Закрыть">
                                    <X className="h-6 w-6" />
                                </Button>
                            </DialogClose>
                        </header>
                        <div className="relative h-[85vh] w-[95vw]">
                            <Image src={field.value} alt={form.getValues('name')} fill sizes="(max-width: 768px) 100vw, 80vw" className="object-contain w-full h-full" />
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
                      {isEditing ? 'Изменить аватар' : 'Добавить аватар'}
                    </Button>
                  </div>
                </div>
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
                    <Input 
                    type="tel" 
                    inputMode="tel"
                    placeholder="+7 (999) 123-45-67" 
                    {...field} 
                    value={field.value ?? ''}
                    onChange={(e) => field.onChange(applyPhoneMask(e.target.value))}
                    onKeyDown={(e) => {
                      const el = e.currentTarget;
                      const res = tryApplyRuPhoneMaskKeyEdit(
                        e.key,
                        field.value ?? "",
                        el.selectionStart ?? 0,
                        el.selectionEnd ?? 0
                      );
                      if (!res) return;
                      e.preventDefault();
                      field.onChange(res.display);
                      requestAnimationFrame(() => el.setSelectionRange(res.caret, res.caret));
                    }}
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
    </Form>
  );
}
