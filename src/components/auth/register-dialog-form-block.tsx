"use client";

import * as React from "react";
import type { Control, FieldValues, UseFormReturn } from "react-hook-form";
import { AtSign, AlertCircle, Camera, Eye, EyeOff } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { PhoneInput } from "@/components/ui/phone-input";
import { DateOfBirthPicker } from "@/components/ui/date-of-birth-picker";
import type { User } from "@/lib/types";
import { userAvatarListUrl } from "@/lib/user-avatar-display";
import type { EmailPasswordRegistrationValues, GoogleProfileFormValues } from "@/lib/register-profile-schema";
import {
  AUTH_GLASS_INPUT_CLASS,
  AUTH_GLASS_INPUT_ERROR_CLASS,
  AUTH_LABEL_CLASS,
} from "@/components/auth/auth-glass-classes";
import { cn } from "@/lib/utils";
import { useI18n } from "@/hooks/use-i18n";
import type { TranslateFn } from "@/components/i18n-provider";

export type RegisterDialogMode = "email" | "google";

type CommonProps = {
  registerMode: RegisterDialogMode;
  user: User | null;
  avatarPreview: string | null;
  avatarInputRef: React.RefObject<HTMLInputElement>;
  onAvatarChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
  showRegisterPassword: boolean;
  setShowRegisterPassword: (v: boolean) => void;
  registerOpen: boolean;
  error: string | null;
};

type RegisterDialogFormBlockProps =
  | (CommonProps & {
      mode: "email";
      form: UseFormReturn<EmailPasswordRegistrationValues>;
      onValidSubmit: (values: EmailPasswordRegistrationValues) => void;
    })
  | (CommonProps & {
      mode: "google";
      form: UseFormReturn<GoogleProfileFormValues>;
      onValidSubmit: (values: GoogleProfileFormValues) => void;
    });

function RegisterSharedFields(props: {
  control: Control<FieldValues>;
  clearErrors: (name?: string | string[]) => void;
  registerMode: RegisterDialogMode;
  user: User | null;
  avatarPreview: string | null;
  avatarInputRef: React.RefObject<HTMLInputElement>;
  onAvatarChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
  t: TranslateFn;
}) {
  const {
    control,
    clearErrors,
    registerMode,
    user,
    avatarPreview,
    avatarInputRef,
    onAvatarChange,
    t,
  } = props;

  return (
    <>
      <div className="flex flex-col items-center gap-1 pb-2">
        <button type="button" onClick={() => avatarInputRef.current?.click()} className="group relative">
          <div className="flex h-20 w-20 items-center justify-center overflow-hidden rounded-full border-2 border-dashed border-white/45 bg-white/20 backdrop-blur-md transition-colors group-hover:border-primary/60 dark:border-white/25 dark:bg-white/[0.06]">
            {avatarPreview ? (
              <img src={avatarPreview} alt="" className="h-full w-full object-cover" />
            ) : registerMode === "google" && user?.avatar ? (
              <img
                src={userAvatarListUrl(user)}
                alt=""
                className="h-full w-full object-cover"
              />
            ) : (
              <Camera className="h-7 w-7 text-slate-500 transition-colors group-hover:text-primary dark:text-white/45" />
            )}
          </div>
          <div className="absolute -bottom-1 -right-1 flex h-6 w-6 items-center justify-center rounded-full bg-primary shadow-md">
            <span className="text-xs font-bold text-white">+</span>
          </div>
        </button>
        <input
          ref={avatarInputRef}
          type="file"
          accept="image/*"
          className="hidden"
          onChange={onAvatarChange}
        />
        <p className="max-w-[240px] text-center text-[10px] leading-snug text-slate-500 dark:text-white/40">
          {t("auth.registerForm.avatarHint")}
        </p>
      </div>

      <FormField
        control={control}
        name="name"
        render={({ field }) => (
          <FormItem className="space-y-1">
            <FormLabel className={AUTH_LABEL_CLASS}>{t("auth.registerForm.nameLabel")}</FormLabel>
            <FormControl>
              <Input
                placeholder={t("auth.registerForm.namePlaceholder")}
                {...field}
                className={AUTH_GLASS_INPUT_CLASS}
              />
            </FormControl>
            <FormMessage className="text-[10px]" />
          </FormItem>
        )}
      />
      <FormField
        control={control}
        name="username"
        render={({ field, fieldState }) => (
          <FormItem className="space-y-1">
            <FormLabel className={AUTH_LABEL_CLASS}>{t("auth.registerForm.usernameLabel")}</FormLabel>
            <FormControl>
              <div className="relative">
                <AtSign className="absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-500 dark:text-white/45" />
                <Input
                  placeholder="username"
                  {...field}
                  onChange={(e) => {
                    clearErrors("username");
                    field.onChange(e);
                  }}
                  className={cn(
                    AUTH_GLASS_INPUT_CLASS,
                    "pl-10",
                    fieldState.error && AUTH_GLASS_INPUT_ERROR_CLASS,
                  )}
                />
              </div>
            </FormControl>
            <FormMessage className="text-[10px]" />
          </FormItem>
        )}
      />
      <FormField
        control={control}
        name="phone"
        render={({ field, fieldState }) => (
          <FormItem className="space-y-1">
            <FormLabel className={AUTH_LABEL_CLASS}>{t("auth.registerForm.phoneLabel")}</FormLabel>
            <FormControl>
              <PhoneInput
                value={field.value}
                onChange={(v) => {
                  clearErrors("phone");
                  field.onChange(v);
                }}
                className={cn(
                  AUTH_GLASS_INPUT_CLASS,
                  fieldState.error && AUTH_GLASS_INPUT_ERROR_CLASS,
                )}
              />
            </FormControl>
            <FormMessage className="text-[10px]" />
          </FormItem>
        )}
      />
      <FormField
        control={control}
        name="email"
        render={({ field, fieldState }) => (
          <FormItem className="space-y-1">
            <FormLabel className={AUTH_LABEL_CLASS}>{t("auth.registerForm.emailLabel")}</FormLabel>
            <FormControl>
              <Input
                type="email"
                placeholder="you@example.com"
                readOnly={registerMode === "google"}
                disabled={registerMode === "google"}
                {...field}
                onChange={(e) => {
                  clearErrors("email");
                  field.onChange(e);
                }}
                className={cn(
                  AUTH_GLASS_INPUT_CLASS,
                  fieldState.error && AUTH_GLASS_INPUT_ERROR_CLASS,
                  registerMode === "google" && "cursor-not-allowed opacity-85",
                )}
              />
            </FormControl>
            <FormMessage className="text-[10px]" />
          </FormItem>
        )}
      />
    </>
  );
}

function RegisterOptionalFields(props: { control: Control<FieldValues>; t: TranslateFn }) {
  const { control, t } = props;
  return (
    <>
      <div className="pb-0.5 pt-2">
        <p className="ml-0.5 text-[10px] font-semibold uppercase tracking-wide text-slate-500 dark:text-white/45">
          {t("auth.registerForm.optionalSectionTitle")}
        </p>
      </div>

      <FormField
        control={control}
        name="dateOfBirth"
        render={({ field }) => (
          <FormItem className="space-y-1">
            <FormLabel className={AUTH_LABEL_CLASS}>{t("auth.registerForm.dateOfBirthLabel")}</FormLabel>
            <FormControl>
              <DateOfBirthPicker
                value={field.value}
                onChange={field.onChange}
                className={AUTH_GLASS_INPUT_CLASS}
              />
            </FormControl>
            <FormMessage className="text-[10px]" />
          </FormItem>
        )}
      />
      <FormField
        control={control}
        name="bio"
        render={({ field }) => (
          <FormItem className="space-y-1">
            <FormLabel className={AUTH_LABEL_CLASS}>{t("auth.registerForm.bioLabel")}</FormLabel>
            <FormControl>
              <Textarea
                placeholder={t("auth.registerForm.bioPlaceholder")}
                {...field}
                rows={2}
                className="resize-none rounded-[14px] border border-white/35 bg-white/45 px-3.5 py-2.5 text-sm shadow-inner shadow-black/5 backdrop-blur-md placeholder:text-slate-500/80 focus-visible:border-primary/50 dark:border-white/12 dark:bg-white/[0.08] dark:text-white dark:placeholder:text-white/40"
              />
            </FormControl>
            <FormMessage className="text-[10px]" />
          </FormItem>
        )}
      />
    </>
  );
}

export function RegisterDialogFormBlock(props: RegisterDialogFormBlockProps) {
  const { t } = useI18n();
  const {
    registerMode,
    user,
    avatarPreview,
    avatarInputRef,
    onAvatarChange,
    showRegisterPassword,
    setShowRegisterPassword,
    registerOpen,
    error,
  } = props;

  if (props.mode === "email") {
    const { form, onValidSubmit } = props;
    return (
      <Form {...form}>
        <form
          id="register-form"
          onSubmit={form.handleSubmit(onValidSubmit)}
          className="space-y-3"
        >
          <RegisterSharedFields
            control={form.control as unknown as Control<FieldValues>}
            clearErrors={(name) => form.clearErrors(name as never)}
            registerMode={registerMode}
            user={user}
            avatarPreview={avatarPreview}
            avatarInputRef={avatarInputRef}
            onAvatarChange={onAvatarChange}
            t={t}
          />
          <FormField
            control={form.control}
            name="password"
            render={({ field, fieldState }) => (
              <FormItem className="space-y-1">
                <FormLabel className={AUTH_LABEL_CLASS}>{t("auth.registerForm.passwordLabel")}</FormLabel>
                <FormControl>
                  <div className="relative">
                    <Input
                      type={showRegisterPassword ? "text" : "password"}
                      placeholder={t("auth.registerForm.passwordPlaceholder")}
                      {...field}
                      onChange={(e) => {
                        form.clearErrors("password");
                        field.onChange(e);
                      }}
                      className={cn(
                        AUTH_GLASS_INPUT_CLASS,
                        "pr-10",
                        fieldState.error && AUTH_GLASS_INPUT_ERROR_CLASS,
                      )}
                    />
                    <Button
                      type="button"
                      variant="ghost"
                      size="icon"
                      className="absolute right-0.5 top-1/2 h-9 w-9 -translate-y-1/2 text-slate-500 hover:bg-white/30 hover:text-slate-800 dark:text-white/50 dark:hover:bg-white/10 dark:hover:text-white"
                      onClick={() => setShowRegisterPassword(!showRegisterPassword)}
                    >
                      {showRegisterPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                    </Button>
                  </div>
                </FormControl>
                <FormMessage className="text-[10px]" />
              </FormItem>
            )}
          />
          <FormField
            control={form.control}
            name="confirmPassword"
            render={({ field }) => (
              <FormItem className="space-y-1">
                <FormLabel className={AUTH_LABEL_CLASS}>{t("auth.registerForm.confirmPasswordLabel")}</FormLabel>
                <FormControl>
                  <Input
                    type={showRegisterPassword ? "text" : "password"}
                    placeholder={t("auth.registerForm.confirmPasswordPlaceholder")}
                    {...field}
                    className={AUTH_GLASS_INPUT_CLASS}
                  />
                </FormControl>
                <FormMessage className="text-[10px]" />
              </FormItem>
            )}
          />
          <RegisterOptionalFields control={form.control as unknown as Control<FieldValues>} t={t} />
          {error && registerOpen ? (
            <div className="flex items-center gap-2 rounded-[14px] border border-destructive/20 bg-destructive/10 p-2.5 text-[11px] font-medium text-destructive backdrop-blur-sm dark:bg-destructive/15 animate-in slide-in-from-top-1">
              <AlertCircle className="h-4 w-4 shrink-0" />
              {error}
            </div>
          ) : null}
        </form>
      </Form>
    );
  }

  const { form, onValidSubmit } = props;
  return (
    <Form {...form}>
      <form
        id="register-form"
        onSubmit={form.handleSubmit(onValidSubmit)}
        className="space-y-3"
      >
        <RegisterSharedFields
          control={form.control as unknown as Control<FieldValues>}
          clearErrors={(name) => form.clearErrors(name as never)}
          registerMode={registerMode}
          user={user}
          avatarPreview={avatarPreview}
          avatarInputRef={avatarInputRef}
          onAvatarChange={onAvatarChange}
          t={t}
        />
        <RegisterOptionalFields control={form.control as unknown as Control<FieldValues>} t={t} />
        {error && registerOpen ? (
          <div className="flex items-center gap-2 rounded-[14px] border border-destructive/20 bg-destructive/10 p-2.5 text-[11px] font-medium text-destructive backdrop-blur-sm dark:bg-destructive/15 animate-in slide-in-from-top-1">
            <AlertCircle className="h-4 w-4 shrink-0" />
            {error}
          </div>
        ) : null}
      </form>
    </Form>
  );
}
