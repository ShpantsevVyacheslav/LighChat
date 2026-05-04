"use client";

import * as React from "react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { useForm, type Resolver } from "react-hook-form";
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
import { useAuth } from "@/hooks/use-auth";
import { isRegistrationProfileComplete } from "@/lib/registration-profile-complete";
import {
  createEmailPasswordRegistrationSchema,
  createGoogleProfileFormSchema,
  type EmailPasswordRegistrationValues,
  type GoogleProfileFormValues,
} from "@/lib/register-profile-schema";
import {
  AuthBrandWordmarkBlock,
  AuthBrandWordmarkTitle,
} from "@/components/auth/auth-brand-wordmark";
import { RegisterAvatarCropOverlay } from "@/components/auth/register-avatar-crop-overlay";
import { RegisterDialogFormBlock } from "@/components/auth/register-dialog-form-block";
import {
  AUTH_GLASS_CARD_HIGHLIGHT_CLASS,
  AUTH_GLASS_CARD_SHELL_CLASS,
  AUTH_DIALOG_OVERLAY_CLASS,
  AUTH_GLASS_INPUT_CLASS,
  AUTH_LABEL_CLASS,
} from "@/components/auth/auth-glass-classes";
import { TelegramLoginDialog } from "@/components/auth/telegram-login-dialog";
import { QrLoginPanel } from "@/components/auth/QrLoginPanel";
import { cn } from "@/lib/utils";
import { useToast } from "@/hooks/use-toast";
import { useI18n } from "@/hooks/use-i18n";
import { PublicLanguageMenu } from "@/components/i18n/public-language-menu";
import { Eye, EyeOff, Loader2, AlertCircle, UserPlus, QrCode } from "lucide-react";

/** UI-фазы экрана авторизации. */
type AuthStage = "entry" | "qr" | "methods";

/** Фирменный знак: `public/brand/lighchat-mark.png` (квадратный PNG с альфой; см. `scripts/transparent-lighchat-mark.mjs`). */
const BRAND_LOGO_SRC = "/brand/lighchat-mark.png";
/** 1:1 с файлом знака — избегаем лишнего letterbox у Next/Image на мобильных. */
const BRAND_LOGO_SIZE = 575;

const TELEGRAM_BOT_NAME =
  typeof process.env.NEXT_PUBLIC_TELEGRAM_BOT_NAME === "string"
    ? process.env.NEXT_PUBLIC_TELEGRAM_BOT_NAME.trim()
    : "";

function AppleIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M17.05 20.28c-.98.95-2.05.88-3.08.4-1.09-.5-2.08-.48-3.24 0-1.44.62-2.2.44-3.06-.4C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09l.01-.01zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z" />
    </svg>
  );
}

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

function TelegramIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor">
      <path d="M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.479.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.893-.663 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z"/>
    </svg>
  );
}

type LoginValues = { email: string; password: string };

function HomeLoginEmailPasswordForm({
  profileIncomplete,
  registerOpen,
  error,
  isSubmitting,
  onValidSubmit,
}: {
  profileIncomplete: boolean;
  registerOpen: boolean;
  error: string | null | undefined;
  isSubmitting: boolean;
  onValidSubmit: (values: LoginValues) => void | Promise<void>;
}) {
  const { t } = useI18n();
  const [showPassword, setShowPassword] = React.useState(false);
  const loginSchema = React.useMemo(
    () =>
      z.object({
        email: z.string().email({ message: t("auth.loginEmailInvalid") }),
        password: z.string().min(1, { message: t("auth.loginPasswordRequired") }),
      }),
    [t],
  );
  const loginForm = useForm<LoginValues>({
    resolver: zodResolver(loginSchema),
    defaultValues: { email: "", password: "" },
  });

  return (
    <Form {...loginForm}>
      <form
        onSubmit={loginForm.handleSubmit(onValidSubmit)}
        className={cn("space-y-3", profileIncomplete && "hidden")}
      >
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
              <FormLabel className={AUTH_LABEL_CLASS}>{t("auth.loginPasswordLabel")}</FormLabel>
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
              {t("auth.loginSubmitting")}
            </>
          ) : (
            t("auth.loginSubmit")
          )}
        </Button>
      </form>
    </Form>
  );
}

function YandexIcon({ className, title }: { className?: string; title: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" role="img" aria-label={title}>
      <circle cx="12" cy="12" r="12" fill="#FC3F1D" />
      <text
        x="12"
        y="12"
        textAnchor="middle"
        dominantBaseline="central"
        fontSize="16"
        fontWeight="800"
        fontFamily="Inter, system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif"
        fill="#FFFFFF"
      >Я</text>
    </svg>
  );
}

export default function AuthPage() {
  const {
    user,
    login,
    register,
    completeGoogleProfile,
    signInWithGoogle,
    signInWithApple,
    signInWithYandex,
    signInWithTelegramPayload,
    error,
    clearError,
    isAuthenticated,
    isLoading,
  } = useAuth();
  const router = useRouter();
  const { toast } = useToast();
  const { t, locale } = useI18n();
  const [isSubmitting, setIsSubmitting] = React.useState(false);
  const [stage, setStage] = React.useState<AuthStage>("entry");

  React.useEffect(() => {
    if (typeof window === "undefined") return;
    const u = new URL(window.location.href);
    const yandexErr = u.searchParams.get("yandex_error");
    if (!yandexErr) return;
    u.searchParams.delete("yandex_error");
    window.history.replaceState({}, "", `${u.pathname}${u.search}${u.hash}`);
    toast({
      variant: "destructive",
      title: t("auth.yandexLoginFailedTitle"),
      description:
        yandexErr === "bad_state"
          ? t("auth.yandexErrorBadState")
          : yandexErr === "not_configured"
            ? t("auth.yandexErrorNotConfigured")
            : yandexErr === "access_denied"
              ? t("auth.yandexErrorAccessDenied")
              : t("auth.yandexErrorCode", { code: yandexErr }),
    });
  }, [toast, t]);

  React.useEffect(() => {
    if (!isLoading && isAuthenticated && user && isRegistrationProfileComplete(user)) {
      router.replace("/dashboard");
    }
  }, [isLoading, isAuthenticated, user, router]);

  const [showRegisterPassword, setShowRegisterPassword] = React.useState(false);
  const [registerOpen, setRegisterOpen] = React.useState(false);
  const [registerMode, setRegisterMode] = React.useState<"email" | "google">("email");
  /** Полный файл после выбора + обрезки (в Storage — `avatar`). */
  const [avatarFullFile, setAvatarFullFile] = React.useState<File | null>(null);
  /** Круг 512×512 из overlay (`avatarThumb`). */
  const [avatarThumbFile, setAvatarThumbFile] = React.useState<File | null>(null);
  const [avatarPreview, setAvatarPreview] = React.useState<string | null>(null);
  const [cropOpen, setCropOpen] = React.useState(false);
  const [cropSrc, setCropSrc] = React.useState<string | null>(null);
  const [telegramDialogOpen, setTelegramDialogOpen] = React.useState(false);
  const avatarInputRef = React.useRef<HTMLInputElement>(null);
  const pendingAvatarFullRef = React.useRef<File | null>(null);

  const registerValidationMessages = React.useMemo(
    () => ({
      usernameMin: t("auth.registerValidation.usernameMin"),
      usernameMax: t("auth.registerValidation.usernameMax"),
      usernameRegex: t("auth.registerValidation.usernameRegex"),
      usernameRefine: t("auth.registerValidation.usernameRefine"),
      phoneFull: t("auth.registerValidation.phoneFull"),
      dateOfBirthInvalid: t("auth.registerValidation.dateOfBirthInvalid"),
      nameMin: t("auth.registerValidation.nameMin"),
      emailInvalid: t("auth.registerValidation.emailInvalid"),
      bioMax: t("auth.registerValidation.bioMax"),
      passwordMin: t("auth.registerValidation.passwordMin"),
      passwordsMismatch: t("auth.registerValidation.passwordsMismatch"),
    }),
    [t],
  );

  const emailPasswordRegistrationSchemaResolved = React.useMemo(
    () => createEmailPasswordRegistrationSchema(registerValidationMessages),
    [registerValidationMessages],
  );
  const googleProfileFormSchemaResolved = React.useMemo(
    () => createGoogleProfileFormSchema(registerValidationMessages),
    [registerValidationMessages],
  );

  const emailSchemaRef = React.useRef(emailPasswordRegistrationSchemaResolved);
  emailSchemaRef.current = emailPasswordRegistrationSchemaResolved;
  const googleSchemaRef = React.useRef(googleProfileFormSchemaResolved);
  googleSchemaRef.current = googleProfileFormSchemaResolved;

  const emailRegisterResolver = React.useCallback<Resolver<EmailPasswordRegistrationValues>>(
    (values, context, options) => zodResolver(emailSchemaRef.current)(values, context, options),
    [],
  );
  const googleRegisterResolver = React.useCallback<Resolver<GoogleProfileFormValues>>(
    (values, context, options) => zodResolver(googleSchemaRef.current)(values, context, options),
    [],
  );

  const emailRegisterForm = useForm<EmailPasswordRegistrationValues>({
    resolver: emailRegisterResolver,
    defaultValues: {
      name: "",
      username: "",
      phone: "",
      email: "",
      password: "",
      confirmPassword: "",
      dateOfBirth: "",
      bio: "",
    },
  });

  const googleRegisterForm = useForm<GoogleProfileFormValues>({
    resolver: googleRegisterResolver,
    defaultValues: {
      name: "",
      username: "",
      phone: "",
      email: "",
      dateOfBirth: "",
      bio: "",
    },
  });

  React.useEffect(() => {
    if (isLoading || !isAuthenticated || !user) return;
    if (!isRegistrationProfileComplete(user)) {
      // Profile completion happens on /dashboard/profile now (no modal on home).
      router.replace("/dashboard/profile");
    } else {
      setRegisterOpen(false);
    }
  }, [isLoading, isAuthenticated, user, router]);

  /** Один раз при открытии шага Google — иначе snapshot пользователя (online и т.д.) затирал бы ввод. */
  const googleFormPrefilledRef = React.useRef(false);
  React.useEffect(() => {
    if (!registerOpen || registerMode !== "google") {
      if (!registerOpen) googleFormPrefilledRef.current = false;
      return;
    }
    if (!user || googleFormPrefilledRef.current) return;
    googleFormPrefilledRef.current = true;
    googleRegisterForm.reset({
      name: (user.name ?? "").trim(),
      username: user.username ?? "",
      phone: user.phone ?? "",
      email: user.email ?? "",
      dateOfBirth: user.dateOfBirth ? String(user.dateOfBirth) : "",
      bio: user.bio ?? "",
    });
  }, [registerOpen, registerMode, user, googleRegisterForm]);

  const onLogin = async (values: LoginValues) => {
    setIsSubmitting(true);
    const success = await login(values.email, values.password);
    if (success) {
      router.push('/dashboard');
    } else {
      setIsSubmitting(false);
    }
  };

  const onRegister = async (values: EmailPasswordRegistrationValues) => {
    setIsSubmitting(true);
    emailRegisterForm.clearErrors();
    const result = await register({
      name: values.name,
      username: values.username,
      phone: values.phone,
      email: values.email,
      password: values.password,
      dateOfBirth: values.dateOfBirth || undefined,
      bio: values.bio || undefined,
      avatarFile: avatarFullFile || undefined,
      avatarThumbFile: avatarThumbFile || undefined,
    });
    if (result.ok) {
      router.replace("/dashboard");
    } else {
      if (result.conflictField) {
        emailRegisterForm.setError(result.conflictField, {
          type: "duplicate",
          message: result.message,
        });
      }
      setIsSubmitting(false);
    }
  };

  const onGoogleProfileComplete = async (values: GoogleProfileFormValues) => {
    setIsSubmitting(true);
    googleRegisterForm.clearErrors();
    const result = await completeGoogleProfile({
      name: values.name,
      username: values.username,
      phone: values.phone,
      email: values.email,
      dateOfBirth: values.dateOfBirth || undefined,
      bio: values.bio || undefined,
      avatarFile: avatarFullFile || undefined,
      avatarThumbFile: avatarThumbFile || undefined,
    });
    if (result.ok) {
      router.replace("/dashboard");
    } else {
      if (result.conflictField) {
        const cf = result.conflictField;
        if (cf === "email" || cf === "username" || cf === "phone") {
          googleRegisterForm.setError(cf, {
            type: "duplicate",
            message: result.message,
          });
        }
      }
      setIsSubmitting(false);
    }
  };

  const onGoogleSignIn = async () => {
    setIsSubmitting(true);
    try {
      await signInWithGoogle();
    } finally {
      setIsSubmitting(false);
    }
  };

  const onAppleSignIn = async () => {
    setIsSubmitting(true);
    try {
      await signInWithApple();
    } finally {
      setIsSubmitting(false);
    }
  };

  const onTelegramAuthUser = React.useCallback(
    async (user: Record<string, unknown>) => {
      setIsSubmitting(true);
      try {
        const ok = await signInWithTelegramPayload(user);
        if (ok) setTelegramDialogOpen(false);
      } finally {
        setIsSubmitting(false);
      }
    },
    [signInWithTelegramPayload],
  );

  const profileIncomplete =
    Boolean(isAuthenticated && user && !isRegistrationProfileComplete(user));

  const handleOpenRegister = () => {
    clearError();
    setRegisterMode("email");
    emailRegisterForm.reset({
      name: "",
      username: "",
      phone: "",
      email: "",
      password: "",
      confirmPassword: "",
      dateOfBirth: "",
      bio: "",
    });
    setShowRegisterPassword(false);
    if (avatarPreview?.startsWith("blob:")) URL.revokeObjectURL(avatarPreview);
    if (cropSrc?.startsWith("blob:")) URL.revokeObjectURL(cropSrc);
    pendingAvatarFullRef.current = null;
    setAvatarFullFile(null);
    setAvatarThumbFile(null);
    setAvatarPreview(null);
    setCropOpen(false);
    setCropSrc(null);
    setRegisterOpen(true);
  };

  const handleAvatarChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file || !file.type.startsWith("image/")) return;
    pendingAvatarFullRef.current = file;
    const url = URL.createObjectURL(file);
    setCropSrc(url);
    setCropOpen(true);
  };

  const handleCropCancel = () => {
    pendingAvatarFullRef.current = null;
    if (cropSrc?.startsWith("blob:")) URL.revokeObjectURL(cropSrc);
    setCropSrc(null);
    setCropOpen(false);
  };

  const handleCropApply = (circleFile: File) => {
    const full = pendingAvatarFullRef.current;
    pendingAvatarFullRef.current = null;
    if (!full) return;
    if (cropSrc?.startsWith("blob:")) URL.revokeObjectURL(cropSrc);
    setCropSrc(null);
    setCropOpen(false);
    if (avatarPreview?.startsWith("blob:")) URL.revokeObjectURL(avatarPreview);
    setAvatarFullFile(full);
    setAvatarThumbFile(circleFile);
    setAvatarPreview(URL.createObjectURL(circleFile));
  };

  return (
    <div className="relative min-h-dvh w-full overflow-x-hidden overflow-y-auto">
      <PublicLanguageMenu className="fixed top-[max(0.5rem,env(safe-area-inset-top))] right-3 z-[100]" />
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
            {profileIncomplete ? (
              <p className="rounded-[14px] border border-white/35 bg-white/25 px-3 py-3 text-center text-sm leading-snug text-slate-700 backdrop-blur-md dark:border-white/12 dark:bg-white/[0.06] dark:text-white/85">
                {t('auth.landingProfileIncomplete')}
              </p>
            ) : null}

            {!profileIncomplete && stage === "entry" && (
              <div className="flex flex-col gap-3 py-2">
                <Button
                  type="button"
                  variant="default"
                  onClick={() => setStage("qr")}
                  className="h-12 w-full gap-2 rounded-[14px] text-sm font-semibold shadow-md shadow-primary/25 transition-all active:scale-[0.99]"
                >
                  <QrCode className="h-4 w-4" />
                  {t("auth.entry.signIn")}
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  onClick={handleOpenRegister}
                  className="h-12 w-full gap-2 rounded-[14px] border-white/50 bg-white/35 text-sm font-semibold backdrop-blur-md transition-all active:scale-[0.99] dark:border-white/15 dark:bg-white/[0.06] dark:hover:bg-white/10"
                >
                  <UserPlus className="h-4 w-4" />
                  {t("auth.entry.signUp")}
                </Button>
              </div>
            )}

            {!profileIncomplete && stage === "qr" && (
              <div className="flex flex-col gap-3 py-1">
                <QrLoginPanel
                  onOtherMethodClick={() => setStage("methods")}
                  onSignedIn={() => router.replace("/dashboard")}
                />
                <Button
                  type="button"
                  variant="ghost"
                  onClick={() => setStage("entry")}
                  className="h-9 w-full rounded-full text-[11px] font-medium text-slate-500 hover:bg-white/30 dark:text-white/55 dark:hover:bg-white/10"
                >
                  {t("common.back")}
                </Button>
              </div>
            )}

            {!profileIncomplete && stage === "methods" && (
              <>
                <HomeLoginEmailPasswordForm
                  key={locale}
                  profileIncomplete={profileIncomplete}
                  registerOpen={registerOpen}
                  error={error}
                  isSubmitting={isSubmitting}
                  onValidSubmit={onLogin}
                />

                <p
                  className="my-3 text-center text-[9px] font-semibold uppercase tracking-wide text-slate-600/80 dark:text-white/45"
                >
                  {t("auth.dividerOr")}
                </p>

                <div className="grid grid-cols-4 gap-1.5 sm:gap-2">
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
                    onClick={onAppleSignIn}
                    disabled={isSubmitting}
                    className="h-10 rounded-[12px] border-white/50 bg-white/30 backdrop-blur-md transition-all active:scale-[0.97] text-slate-900 dark:border-white/15 dark:bg-white/[0.06] dark:text-white dark:hover:bg-white/10"
                    title="Apple"
                  >
                    <AppleIcon className="h-[18px] w-[18px]" />
                  </Button>
                  <Button
                    type="button"
                    variant="outline"
                    onClick={() => setTelegramDialogOpen(true)}
                    disabled={isSubmitting || TELEGRAM_BOT_NAME.length === 0}
                    title={TELEGRAM_BOT_NAME ? "Telegram" : t("auth.telegramBotMissing")}
                    className="h-10 rounded-[12px] border-white/50 bg-white/30 text-slate-900 backdrop-blur-md transition-all active:scale-[0.97] dark:border-white/15 dark:bg-white/[0.06] dark:text-white dark:hover:bg-white/10"
                  >
                    <TelegramIcon className="h-[18px] w-[18px]" />
                  </Button>
                  <Button
                    type="button"
                    variant="outline"
                    onClick={() => void signInWithYandex()}
                    disabled={isSubmitting}
                    className="h-10 rounded-[12px] border-white/50 bg-white/30 text-slate-900 backdrop-blur-md transition-all active:scale-[0.97] dark:border-white/15 dark:bg-white/[0.06] dark:text-white dark:hover:bg-white/10"
                    title={t("auth.yandexTitle")}
                  >
                    <YandexIcon className="h-[18px] w-[18px]" title={t("auth.yandexTitle")} />
                  </Button>
                </div>

                <div className="mt-3 flex flex-col gap-2">
                  <Button
                    type="button"
                    variant="ghost"
                    onClick={handleOpenRegister}
                    className="h-10 w-full gap-2 rounded-[12px] font-semibold text-primary hover:bg-primary/10 dark:text-sky-300 dark:hover:bg-white/10 dark:hover:text-sky-200"
                  >
                    <UserPlus className="h-4 w-4" />
                    {t("auth.registerCta")}
                  </Button>
                  <Button
                    type="button"
                    variant="ghost"
                    onClick={() => setStage("qr")}
                    className="h-9 w-full gap-2 rounded-full text-xs font-medium text-slate-500 hover:bg-white/30 dark:text-white/55 dark:hover:bg-white/10"
                  >
                    <QrCode className="h-3.5 w-3.5" /> {t("auth.methods.useQr")}
                  </Button>
                </div>
              </>
            )}
          </CardContent>
        </Card>

        <div className="mt-5 shrink-0 pb-[env(safe-area-inset-bottom)] text-center">
          <p className="text-[8px] text-slate-500/90 dark:text-white/35">© {new Date().getFullYear()} LighChat</p>
        </div>
      </div>

      <TelegramLoginDialog
        open={telegramDialogOpen}
        onOpenChange={setTelegramDialogOpen}
        botName={TELEGRAM_BOT_NAME || undefined}
        onAuthUser={onTelegramAuthUser}
      />

      {/* Registration Dialog — тот же стеклянный стиль, что у карточки входа */}
      <Dialog
        open={registerOpen}
        onOpenChange={(open) => {
          if (!open && cropOpen) {
            handleCropCancel();
            return;
          }
          if (!open && user && !isRegistrationProfileComplete(user)) {
            return;
          }
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
          showCloseButton={!cropOpen}
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
              {registerMode === "google"
                ? t("auth.registerDialogCompleteTitle")
                : t("auth.registerDialogCreateTitle")}
            </DialogTitle>
            <DialogDescription className="text-center text-xs leading-relaxed text-slate-600 dark:text-white/55">
              {registerMode === "google" ? (
                <>
                  {t("auth.registerDialogGoogleBody")}{" "}
                  <AuthBrandWordmarkTitle as="span" size="inline" className="inline font-bold" />
                </>
              ) : (
                <>
                  <span className="text-slate-500 dark:text-white/45">
                    {t("auth.registerDialogEmailIntro")}{" "}
                  </span>
                  <AuthBrandWordmarkTitle as="span" size="inline" className="inline font-bold" />
                </>
              )}
            </DialogDescription>
          </DialogHeader>

          <div className="relative z-10 min-h-0 flex-1 overflow-y-auto overscroll-y-contain px-5 pb-4 [-webkit-overflow-scrolling:touch]">
            {registerMode === "email" ? (
              <RegisterDialogFormBlock
                mode="email"
                form={emailRegisterForm}
                onValidSubmit={onRegister}
                registerMode={registerMode}
                user={user}
                avatarPreview={avatarPreview}
                avatarInputRef={avatarInputRef}
                onAvatarChange={handleAvatarChange}
                showRegisterPassword={showRegisterPassword}
                setShowRegisterPassword={setShowRegisterPassword}
                registerOpen={registerOpen}
                error={error}
              />
            ) : (
              <RegisterDialogFormBlock
                mode="google"
                form={googleRegisterForm}
                onValidSubmit={onGoogleProfileComplete}
                registerMode={registerMode}
                user={user}
                avatarPreview={avatarPreview}
                avatarInputRef={avatarInputRef}
                onAvatarChange={handleAvatarChange}
                showRegisterPassword={showRegisterPassword}
                setShowRegisterPassword={setShowRegisterPassword}
                registerOpen={registerOpen}
                error={error}
              />
            )}
          </div>

          <div className="relative z-10 shrink-0 border-t border-white/40 bg-white/30 px-5 pb-[max(1.25rem,env(safe-area-inset-bottom))] pt-3 backdrop-blur-md dark:border-white/10 dark:bg-white/[0.06]">
            <Button form="register-form" type="submit" variant="default" disabled={isSubmitting} className="h-11 w-full rounded-[14px] font-semibold shadow-md shadow-primary/25 transition-all active:scale-[0.99]">
              {isSubmitting ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  {registerMode === "google" ? t("auth.registerSaving") : t("auth.registerCreating")}
                </>
              ) : registerMode === "google" ? (
                t("auth.registerSaveContinue")
              ) : (
                t("auth.registerSubmitCreate")
              )}
            </Button>
          </div>

          <RegisterAvatarCropOverlay
            open={cropOpen}
            imageSrc={cropSrc}
            onCancel={handleCropCancel}
            onApply={handleCropApply}
          />
        </DialogContent>
      </Dialog>
    </div>
  );
}
