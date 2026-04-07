"use client";

import * as React from "react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";

import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
} from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { PhoneInput } from "@/components/ui/phone-input";
import { DateOfBirthPicker } from "@/components/ui/date-of-birth-picker";
import { useAuth } from "@/hooks/use-auth";
import {
  AuthBrandWordmarkBlock,
  AuthBrandWordmarkTitle,
  AuthRegisterDescriptionLine,
} from "@/components/auth/auth-brand-wordmark";
import { RegisterAvatarCropOverlay } from "@/components/auth/register-avatar-crop-overlay";
import {
  AUTH_GLASS_CARD_HIGHLIGHT_CLASS,
  AUTH_GLASS_CARD_SHELL_CLASS,
  AUTH_DIALOG_OVERLAY_CLASS,
  AUTH_GLASS_INPUT_CLASS,
  AUTH_LABEL_CLASS,
} from "@/components/auth/auth-glass-classes";
import { cn } from "@/lib/utils";
import { Eye, EyeOff, Loader2, AlertCircle, AtSign, UserPlus, Camera } from "lucide-react";

/** Фирменный знак: `public/brand/lighchat-mark.png` (квадратный PNG с альфой; см. `scripts/transparent-lighchat-mark.mjs`). */
const BRAND_LOGO_SRC = "/brand/lighchat-mark.png";
/** 1:1 с файлом знака — избегаем лишнего letterbox у Next/Image на мобильных. */
const BRAND_LOGO_SIZE = 575;

const loginSchema = z.object({
  email: z.string().email({ message: "Неверный формат email." }),
  password: z.string().min(1, { message: "Пароль не может быть пустым." }),
});

const registerSchema = z.object({
  name: z.string().min(2, { message: "Имя должно содержать не менее 2 символов." }),
  username: z
    .string()
    .min(3, { message: "Логин должен содержать не менее 3 символов." })
    .max(30, { message: "Логин не должен превышать 30 символов." })
    .regex(/^@?[a-zA-Z0-9_]+$/, { message: "Только латиница, цифры и _" }),
  phone: z
    .string()
    .refine((val) => val.replace(/\D/g, "").length === 11, { message: "Введите полный номер телефона." }),
  email: z.string().email({ message: "Неверный формат email." }),
  password: z.string().min(6, { message: "Пароль должен содержать не менее 6 символов." }),
  confirmPassword: z.string(),
  dateOfBirth: z.string().optional().refine((val) => {
    if (!val) return true;
    const year = new Date(val).getFullYear();
    const currentYear = new Date().getFullYear();
    return year >= 1920 && year <= currentYear;
  }, { message: "Некорректная дата рождения." }),
  bio: z.string().max(200, { message: "Не более 200 символов." }).optional(),
}).refine((data) => data.password === data.confirmPassword, {
  message: "Пароли не совпадают.",
  path: ["confirmPassword"],
});

function GoogleIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none">
      <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 01-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z" fill="#4285F4"/>
      <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
      <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
      <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
    </svg>
  );
}

function VkIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor">
      <path d="M12.785 16.241s.288-.032.436-.194c.136-.148.132-.427.132-.427s-.02-1.304.587-1.496c.598-.188 1.368 1.259 2.183 1.815.616.42 1.084.328 1.084.328l2.175-.03s1.14-.07.599-.964c-.044-.073-.314-.661-1.618-1.869-1.366-1.265-1.183-1.06.462-3.246.999-1.33 1.398-2.142 1.273-2.49-.12-.332-.856-.244-.856-.244l-2.45.015s-.182-.025-.316.056c-.131.079-.215.263-.215.263s-.386 1.028-.9 1.902c-1.085 1.844-1.52 1.943-1.696 1.828-.413-.267-.31-1.075-.31-1.649 0-1.793.272-2.54-.53-2.733-.266-.064-.462-.106-1.143-.113-.873-.009-1.612.003-2.03.208-.278.136-.493.44-.362.457.161.022.527.099.72.363.25.341.24 1.11.24 1.11s.144 2.11-.335 2.372c-.327.18-.777-.187-1.74-1.865-.493-.86-.866-1.81-.866-1.81s-.072-.176-.2-.27c-.155-.115-.372-.151-.372-.151l-2.328.015s-.35.01-.478.162c-.114.135-.009.414-.009.414s1.815 4.244 3.87 6.382c1.883 1.96 4.024 1.832 4.024 1.832h.97z"/>
    </svg>
  );
}

function TelegramIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor">
      <path d="M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.479.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.893-.663 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z"/>
    </svg>
  );
}

function YandexIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor">
      <path d="M2.04 12c0-5.523 4.476-10 10-10 5.522 0 10 4.477 10 10s-4.478 10-10 10c-5.524 0-10-4.477-10-10zm10.09 4.5V7.27h-.74c-1.47 0-2.24.69-2.24 1.83 0 1.31.58 1.9 1.78 2.74l.99.7-2.87 3.96h-1.72l2.56-3.53c-1.46-1.05-2.28-1.91-2.28-3.56 0-1.94 1.32-3.18 3.78-3.18h2.18v10.27h-1.44z"/>
    </svg>
  );
}

export default function AuthPage() {
  const { login, register, signInWithGoogle, error, clearError, isAuthenticated, isLoading } = useAuth();
  const router = useRouter();
  const [isSubmitting, setIsSubmitting] = React.useState(false);

  React.useEffect(() => {
    if (!isLoading && isAuthenticated) {
      router.replace('/dashboard');
    }
  }, [isLoading, isAuthenticated, router]);
  const [showPassword, setShowPassword] = React.useState(false);
  const [showRegisterPassword, setShowRegisterPassword] = React.useState(false);
  const [registerOpen, setRegisterOpen] = React.useState(false);
  const [avatarFile, setAvatarFile] = React.useState<File | null>(null);
  const [avatarPreview, setAvatarPreview] = React.useState<string | null>(null);
  const [cropOpen, setCropOpen] = React.useState(false);
  const [cropSrc, setCropSrc] = React.useState<string | null>(null);
  const avatarInputRef = React.useRef<HTMLInputElement>(null);

  const loginForm = useForm<z.infer<typeof loginSchema>>({
    resolver: zodResolver(loginSchema),
    defaultValues: { email: "", password: "" },
  });

  const registerForm = useForm<z.infer<typeof registerSchema>>({
    resolver: zodResolver(registerSchema),
    defaultValues: { name: "", username: "", phone: "", email: "", password: "", confirmPassword: "", dateOfBirth: "", bio: "" },
  });

  const onLogin = async (values: z.infer<typeof loginSchema>) => {
    setIsSubmitting(true);
    const success = await login(values.email, values.password);
    if (success) {
      router.push('/dashboard');
    } else {
      setIsSubmitting(false);
    }
  };

  const onRegister = async (values: z.infer<typeof registerSchema>) => {
    setIsSubmitting(true);
    const success = await register({
      name: values.name,
      username: values.username,
      phone: values.phone,
      email: values.email,
      password: values.password,
      dateOfBirth: values.dateOfBirth || undefined,
      bio: values.bio || undefined,
      avatarFile: avatarFile || undefined,
    });
    if (success) {
      router.push('/dashboard');
    } else {
      setIsSubmitting(false);
    }
  };

  const onGoogleSignIn = async () => {
    setIsSubmitting(true);
    try {
      const success = await signInWithGoogle();
      if (success) {
        router.push('/dashboard');
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleOpenRegister = () => {
    clearError();
    registerForm.reset();
    setShowRegisterPassword(false);
    if (avatarPreview?.startsWith("blob:")) URL.revokeObjectURL(avatarPreview);
    if (cropSrc?.startsWith("blob:")) URL.revokeObjectURL(cropSrc);
    setAvatarFile(null);
    setAvatarPreview(null);
    setCropOpen(false);
    setCropSrc(null);
    setRegisterOpen(true);
  };

  const handleAvatarChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file || !file.type.startsWith("image/")) return;
    const url = URL.createObjectURL(file);
    setCropSrc(url);
    setCropOpen(true);
  };

  const handleCropCancel = () => {
    if (cropSrc?.startsWith("blob:")) URL.revokeObjectURL(cropSrc);
    setCropSrc(null);
    setCropOpen(false);
  };

  const handleCropApply = (file: File) => {
    if (cropSrc?.startsWith("blob:")) URL.revokeObjectURL(cropSrc);
    setCropSrc(null);
    setCropOpen(false);
    if (avatarPreview?.startsWith("blob:")) URL.revokeObjectURL(avatarPreview);
    setAvatarFile(file);
    setAvatarPreview(URL.createObjectURL(file));
  };

  return (
    <div className="relative min-h-dvh w-full overflow-x-hidden overflow-y-auto">
      {/* Фиксированный яркий фон под стеклянный слой (iOS-like vibrancy) */}
      <div aria-hidden className="fixed inset-0 z-0 bg-slate-100 dark:bg-[#070b14]" />
      <div
        aria-hidden
        className="fixed inset-0 z-[1] bg-gradient-to-br from-sky-200/80 via-indigo-100/70 to-violet-200/75 dark:from-[#0f172a] dark:via-[#1e1b4b] dark:to-[#0c4a6e]"
      />
      <div
        aria-hidden
        className="fixed inset-0 z-[2] bg-[radial-gradient(ellipse_90%_60%_at_50%_-20%,hsl(var(--primary)_/_0.35),transparent_55%)] dark:bg-[radial-gradient(ellipse_90%_55%_at_50%_-25%,hsl(var(--primary)_/_0.45),transparent_50%)]"
      />
      <div aria-hidden className="fixed inset-0 z-[3] overflow-hidden pointer-events-none">
        <div className="absolute -left-[20%] top-[-15%] h-[55%] w-[70%] rounded-full bg-cyan-300/25 blur-[90px] dark:bg-primary/20 dark:blur-[100px]" />
        <div className="absolute -right-[15%] bottom-[-20%] h-[50%] w-[60%] rounded-full bg-fuchsia-300/20 blur-[100px] dark:bg-sky-500/15 dark:blur-[110px]" />
      </div>

      {/* Прокрутка на низких экранах; отступ сверху — половина прежнего (pt-7 / sm:pt-10) */}
      <div className="relative z-20 mx-auto flex w-full max-w-sm flex-1 flex-col px-4 pb-6 pt-[max(0.875rem,env(safe-area-inset-top))] sm:pt-[max(2.5rem,env(safe-area-inset-top))] animate-in fade-in zoom-in-95 duration-500 sm:min-h-dvh sm:justify-center sm:pb-8">
        {/* Шапка: компактнее, чтобы форма помещалась */}
        <AuthBrandWordmarkBlock className="mb-4 shrink-0">
          <div className="mx-auto flex aspect-square w-[min(7.25rem,38vw)] max-w-[8.75rem] items-center justify-center sm:w-32">
            <Image
              src={BRAND_LOGO_SRC}
              alt="LighChat"
              width={BRAND_LOGO_SIZE}
              height={BRAND_LOGO_SIZE}
              className="h-full w-full object-contain drop-shadow-[0_6px_20px_rgba(0,0,0,0.12)] dark:drop-shadow-[0_8px_28px_rgba(0,0,0,0.35)]"
              priority
            />
          </div>
          <AuthBrandWordmarkTitle size="hero" className="mt-1" />
        </AuthBrandWordmarkBlock>

        {/* Стеклянная карточка */}
        <Card className={cn("shrink-0", AUTH_GLASS_CARD_SHELL_CLASS)}>
          <div className={AUTH_GLASS_CARD_HIGHLIGHT_CLASS} />
          <CardContent className="relative p-4 pt-5 sm:p-5 sm:pt-6">
            <Form {...loginForm}>
              <form onSubmit={loginForm.handleSubmit(onLogin)} className="space-y-3">
                <FormField
                  control={loginForm.control}
                  name="email"
                  render={({ field }) => (
                    <FormItem className="space-y-1">
                      <FormLabel className={AUTH_LABEL_CLASS}>Email</FormLabel>
                      <FormControl>
                        <Input type="email" placeholder="you@example.com" {...field} className={AUTH_GLASS_INPUT_CLASS} />
                      </FormControl>
                      <FormMessage className="text-[10px]" />
                    </FormItem>
                  )}
                />
                <FormField
                  control={loginForm.control}
                  name="password"
                  render={({ field }) => (
                    <FormItem className="space-y-1">
                      <FormLabel className={AUTH_LABEL_CLASS}>Пароль</FormLabel>
                      <FormControl>
                        <div className="relative">
                          <Input
                            type={showPassword ? "text" : "password"}
                            placeholder="••••••••"
                            {...field}
                            className={`${AUTH_GLASS_INPUT_CLASS} pr-10`}
                          />
                          <Button
                            type="button"
                            variant="ghost"
                            size="icon"
                            className="absolute right-0.5 top-1/2 h-9 w-9 -translate-y-1/2 text-slate-500 hover:bg-white/30 hover:text-slate-800 dark:text-white/50 dark:hover:bg-white/10 dark:hover:text-white"
                            onClick={() => setShowPassword(!showPassword)}
                          >
                            {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                          </Button>
                        </div>
                      </FormControl>
                      <FormMessage className="text-[10px]" />
                    </FormItem>
                  )}
                />

                {error && !registerOpen && (
                  <div className="flex items-center gap-2 rounded-[14px] border border-destructive/20 bg-destructive/10 p-2.5 text-[11px] font-medium text-destructive backdrop-blur-sm dark:bg-destructive/15 animate-in slide-in-from-top-1">
                    <AlertCircle className="h-4 w-4 shrink-0" />
                    {error}
                  </div>
                )}

                <Button
                  type="submit"
                  variant="default"
                  disabled={isSubmitting}
                  className="h-11 w-full rounded-[14px] font-semibold shadow-md shadow-primary/25 transition-all active:scale-[0.99]"
                >
                  {isSubmitting && !registerOpen ? (
                    <>
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      Вход...
                    </>
                  ) : (
                    "Войти"
                  )}
                </Button>
              </form>
            </Form>

            <p className="my-3 text-center text-[9px] font-semibold uppercase tracking-wide text-slate-600/80 dark:text-white/45">
              или
            </p>

            <div className="grid grid-cols-4 gap-2">
              <Button
                type="button"
                variant="outline"
                onClick={onGoogleSignIn}
                disabled={isSubmitting}
                className="h-10 rounded-[12px] border-white/50 bg-white/30 backdrop-blur-md transition-all active:scale-[0.97] dark:border-white/15 dark:bg-white/[0.06] dark:hover:bg-white/10"
                title="Google"
              >
                <GoogleIcon className="h-[18px] w-[18px]" />
              </Button>
              <Button
                type="button"
                variant="outline"
                disabled
                className="h-10 rounded-[12px] border-white/40 bg-white/20 opacity-50 backdrop-blur-md dark:border-white/10 dark:bg-white/[0.04]"
                title="VK (скоро)"
              >
                <VkIcon className="h-[18px] w-[18px]" />
              </Button>
              <Button
                type="button"
                variant="outline"
                disabled
                className="h-10 rounded-[12px] border-white/40 bg-white/20 opacity-50 backdrop-blur-md dark:border-white/10 dark:bg-white/[0.04]"
                title="Telegram (скоро)"
              >
                <TelegramIcon className="h-[18px] w-[18px]" />
              </Button>
              <Button
                type="button"
                variant="outline"
                disabled
                className="h-10 rounded-[12px] border-white/40 bg-white/20 opacity-50 backdrop-blur-md dark:border-white/10 dark:bg-white/[0.04]"
                title="Яндекс (скоро)"
              >
                <YandexIcon className="h-[18px] w-[18px]" />
              </Button>
            </div>

            <div className="mt-3">
              <Button
                type="button"
                variant="ghost"
                onClick={handleOpenRegister}
                className="h-10 w-full gap-2 rounded-[12px] font-semibold text-primary hover:bg-primary/10 dark:text-sky-300 dark:hover:bg-white/10 dark:hover:text-sky-200"
              >
                <UserPlus className="h-4 w-4" />
                Создать аккаунт
              </Button>
            </div>
          </CardContent>
        </Card>

        <div className="mt-5 shrink-0 pb-[env(safe-area-inset-bottom)] text-center">
          <p className="text-[8px] text-slate-500/90 dark:text-white/35">© {new Date().getFullYear()} LighChat</p>
        </div>
      </div>

      {/* Registration Dialog — тот же стеклянный стиль, что у карточки входа */}
      <Dialog
        open={registerOpen}
        onOpenChange={(open) => {
          setRegisterOpen(open);
          if (!open) {
            clearError();
            if (cropSrc?.startsWith("blob:")) URL.revokeObjectURL(cropSrc);
            setCropOpen(false);
            setCropSrc(null);
          }
        }}
      >
        <DialogContent
          overlayClassName={AUTH_DIALOG_OVERLAY_CLASS}
          closeButtonClassName="right-3 top-3 z-30 flex h-9 w-9 items-center justify-center rounded-full border border-white/45 bg-white/35 shadow-sm backdrop-blur-md hover:bg-white/50 hover:opacity-100 dark:border-white/15 dark:bg-white/10 dark:hover:bg-white/20"
          className={cn(
            AUTH_GLASS_CARD_SHELL_CLASS,
            "flex min-h-0 w-full max-w-md flex-col gap-0 overflow-hidden p-0 sm:max-w-md",
            "max-h-[min(90dvh,calc(100dvh-env(safe-area-inset-top)-env(safe-area-inset-bottom)-2rem))]"
          )}
        >
          <div className={AUTH_GLASS_CARD_HIGHLIGHT_CLASS} />
          <DialogHeader className="relative z-10 shrink-0 space-y-2 px-5 pb-2 pt-5 text-center sm:text-center">
            <DialogTitle className="text-lg font-bold text-slate-900 dark:text-white">
              Создать аккаунт
            </DialogTitle>
            <DialogDescription asChild>
              <AuthRegisterDescriptionLine />
            </DialogDescription>
          </DialogHeader>

          <div className="relative z-10 min-h-0 flex-1 overflow-y-auto overscroll-y-contain px-5 pb-4 [-webkit-overflow-scrolling:touch]">
            <Form {...registerForm}>
              <form id="register-form" onSubmit={registerForm.handleSubmit(onRegister)} className="space-y-3">
                {/* Аватар (необязательно): после выбора файла — полноэкранная круглая обрезка */}
                <div className="flex flex-col items-center gap-1 pb-2">
                  <button
                    type="button"
                    onClick={() => avatarInputRef.current?.click()}
                    className="group relative"
                  >
                    <div className="flex h-20 w-20 items-center justify-center overflow-hidden rounded-full border-2 border-dashed border-white/45 bg-white/20 backdrop-blur-md transition-colors group-hover:border-primary/60 dark:border-white/25 dark:bg-white/[0.06]">
                      {avatarPreview ? (
                        <img src={avatarPreview} alt="" className="h-full w-full object-cover" />
                      ) : (
                        <Camera className="h-7 w-7 text-slate-500 transition-colors group-hover:text-primary dark:text-white/45" />
                      )}
                    </div>
                    <div className="absolute -bottom-1 -right-1 flex h-6 w-6 items-center justify-center rounded-full bg-primary shadow-md">
                      <span className="text-xs font-bold text-white">+</span>
                    </div>
                  </button>
                  <input ref={avatarInputRef} type="file" accept="image/*" className="hidden" onChange={handleAvatarChange} />
                  <p className="max-w-[240px] text-center text-[10px] leading-snug text-slate-500 dark:text-white/40">
                    Необязательно. После выбора фото можно сдвинуть и увеличить область в круге — как в Telegram.
                  </p>
                </div>

                <FormField
                  control={registerForm.control}
                  name="name"
                  render={({ field }) => (
                    <FormItem className="space-y-1">
                      <FormLabel className={AUTH_LABEL_CLASS}>Имя *</FormLabel>
                      <FormControl>
                        <Input placeholder="Ваше имя" {...field} className={AUTH_GLASS_INPUT_CLASS} />
                      </FormControl>
                      <FormMessage className="text-[10px]" />
                    </FormItem>
                  )}
                />
                <FormField
                  control={registerForm.control}
                  name="username"
                  render={({ field }) => (
                    <FormItem className="space-y-1">
                      <FormLabel className={AUTH_LABEL_CLASS}>Логин *</FormLabel>
                      <FormControl>
                        <div className="relative">
                          <AtSign className="absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-500 dark:text-white/45" />
                          <Input placeholder="username" {...field} className={`${AUTH_GLASS_INPUT_CLASS} pl-10`} />
                        </div>
                      </FormControl>
                      <FormMessage className="text-[10px]" />
                    </FormItem>
                  )}
                />
                <FormField
                  control={registerForm.control}
                  name="phone"
                  render={({ field }) => (
                    <FormItem className="space-y-1">
                      <FormLabel className={AUTH_LABEL_CLASS}>Телефон *</FormLabel>
                      <FormControl>
                        <PhoneInput value={field.value} onChange={field.onChange} className={AUTH_GLASS_INPUT_CLASS} />
                      </FormControl>
                      <FormMessage className="text-[10px]" />
                    </FormItem>
                  )}
                />
                <FormField
                  control={registerForm.control}
                  name="email"
                  render={({ field }) => (
                    <FormItem className="space-y-1">
                      <FormLabel className={AUTH_LABEL_CLASS}>Email *</FormLabel>
                      <FormControl>
                        <Input type="email" placeholder="you@example.com" {...field} className={AUTH_GLASS_INPUT_CLASS} />
                      </FormControl>
                      <FormMessage className="text-[10px]" />
                    </FormItem>
                  )}
                />
                <FormField
                  control={registerForm.control}
                  name="password"
                  render={({ field }) => (
                    <FormItem className="space-y-1">
                      <FormLabel className={AUTH_LABEL_CLASS}>Пароль *</FormLabel>
                      <FormControl>
                        <div className="relative">
                          <Input type={showRegisterPassword ? 'text' : 'password'} placeholder="Минимум 6 символов" {...field} className={`${AUTH_GLASS_INPUT_CLASS} pr-10`} />
                          <Button type="button" variant="ghost" size="icon" className="absolute right-0.5 top-1/2 h-9 w-9 -translate-y-1/2 text-slate-500 hover:bg-white/30 hover:text-slate-800 dark:text-white/50 dark:hover:bg-white/10 dark:hover:text-white" onClick={() => setShowRegisterPassword(!showRegisterPassword)}>
                            {showRegisterPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                          </Button>
                        </div>
                      </FormControl>
                      <FormMessage className="text-[10px]" />
                    </FormItem>
                  )}
                />
                <FormField
                  control={registerForm.control}
                  name="confirmPassword"
                  render={({ field }) => (
                    <FormItem className="space-y-1">
                      <FormLabel className={AUTH_LABEL_CLASS}>Подтвердите пароль *</FormLabel>
                      <FormControl>
                        <Input type={showRegisterPassword ? 'text' : 'password'} placeholder="Повторите пароль" {...field} className={AUTH_GLASS_INPUT_CLASS} />
                      </FormControl>
                      <FormMessage className="text-[10px]" />
                    </FormItem>
                  )}
                />

                <div className="pb-0.5 pt-2">
                  <p className="ml-0.5 text-[10px] font-semibold uppercase tracking-wide text-slate-500 dark:text-white/45">
                    Необязательные поля
                  </p>
                </div>

                <FormField
                  control={registerForm.control}
                  name="dateOfBirth"
                  render={({ field }) => (
                    <FormItem className="space-y-1">
                      <FormLabel className={AUTH_LABEL_CLASS}>Дата рождения</FormLabel>
                      <FormControl>
                        <DateOfBirthPicker value={field.value} onChange={field.onChange} className={AUTH_GLASS_INPUT_CLASS} />
                      </FormControl>
                      <FormMessage className="text-[10px]" />
                    </FormItem>
                  )}
                />
                <FormField
                  control={registerForm.control}
                  name="bio"
                  render={({ field }) => (
                    <FormItem className="space-y-1">
                      <FormLabel className={AUTH_LABEL_CLASS}>О себе</FormLabel>
                      <FormControl>
                        <Textarea
                          placeholder="Расскажите немного о себе..."
                          {...field}
                          rows={2}
                          className="resize-none rounded-[14px] border border-white/35 bg-white/45 px-3.5 py-2.5 text-sm shadow-inner shadow-black/5 backdrop-blur-md placeholder:text-slate-500/80 focus-visible:border-primary/50 dark:border-white/12 dark:bg-white/[0.08] dark:text-white dark:placeholder:text-white/40"
                        />
                      </FormControl>
                      <FormMessage className="text-[10px]" />
                    </FormItem>
                  )}
                />

                {error && registerOpen && (
                  <div className="flex items-center gap-2 rounded-[14px] border border-destructive/20 bg-destructive/10 p-2.5 text-[11px] font-medium text-destructive backdrop-blur-sm dark:bg-destructive/15 animate-in slide-in-from-top-1">
                    <AlertCircle className="h-4 w-4 shrink-0" />
                    {error}
                  </div>
                )}
              </form>
            </Form>
          </div>

          <div className="relative z-10 shrink-0 border-t border-white/40 bg-white/30 px-5 pb-[max(1.25rem,env(safe-area-inset-bottom))] pt-3 backdrop-blur-md dark:border-white/10 dark:bg-white/[0.06]">
            <Button form="register-form" type="submit" variant="default" disabled={isSubmitting} className="h-11 w-full rounded-[14px] font-semibold shadow-md shadow-primary/25 transition-all active:scale-[0.99]">
              {isSubmitting ? <><Loader2 className="mr-2 h-4 w-4 animate-spin" />Создание...</> : "Создать аккаунт"}
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      <RegisterAvatarCropOverlay
        open={cropOpen}
        imageSrc={cropSrc}
        onCancel={handleCropCancel}
        onApply={handleCropApply}
      />
    </div>
  );
}
