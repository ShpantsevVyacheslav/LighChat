"use client";

import { useCallback, useMemo } from "react";
import { doc, updateDoc } from "firebase/firestore";
import { useFirestore } from "@/firebase";
import { useAuth } from "@/hooks/use-auth";
import type { ChatSettings, NotificationSettings, PrivacySettings } from "@/lib/types";
import {
  DEFAULT_E2EE_ENCRYPTED_DATA_TYPES,
  parseE2eeEncryptedDataTypes,
} from "@/lib/e2ee/e2ee-data-type-policy";
import { normalizeBubbleRadius } from "@/lib/chat-bubble-radius";
import { logger } from "@/lib/logger";

export const DEFAULT_CHAT_SETTINGS: ChatSettings = {
  fontSize: "medium",
  bubbleColor: null,
  incomingBubbleColor: null,
  chatWallpaper: null,
  bubbleRadius: "rounded",
  showTimestamps: true,
  emojiBurstAnimationProfile: "balanced",
  bottomNavAppearance: "colorful",
  bottomNavIconNames: {},
  bottomNavIconGlobalStyle: {},
  bottomNavIconStyles: {},
};

export const DEFAULT_NOTIFICATION_SETTINGS: NotificationSettings = {
  soundEnabled: true,
  showPreview: true,
  muteAll: false,
  quietHoursEnabled: false,
  quietHoursStart: "23:00",
  quietHoursEnd: "07:00",
};

export const DEFAULT_PRIVACY_SETTINGS: PrivacySettings = {
  showOnlineStatus: true,
  showLastSeen: true,
  showReadReceipts: true,
  showEmailToOthers: true,
  showPhoneToOthers: true,
  showBioToOthers: true,
  showDateOfBirthToOthers: true,
  showInGlobalUserSearch: true,
  groupInvitePolicy: "everyone",
  e2eeForNewDirectChats: false,
  e2eeEncryptedDataTypes: DEFAULT_E2EE_ENCRYPTED_DATA_TYPES,
};

/** Строка фона или null; пустые значения из БД не ломают тему «Авто» и слой обоев. */
function normalizeChatWallpaperStored(value: unknown): string | null {
  if (value == null) return null;
  const s = String(value).trim();
  return s === "" ? null : s;
}

function normalizeEmojiBurstAnimationProfileStored(
  value: unknown
): NonNullable<ChatSettings["emojiBurstAnimationProfile"]> {
  const v = String(value ?? "").trim().toLowerCase();
  if (v === "lite" || v === "cinematic" || v === "balanced") return v;
  return "balanced";
}

export function useSettings() {
  const { user } = useAuth();
  const firestore = useFirestore();

  const chatSettings = useMemo<ChatSettings>(() => {
    const merged = { ...DEFAULT_CHAT_SETTINGS, ...user?.chatSettings } as ChatSettings & {
      sendByEnter?: unknown;
    };
    const { sendByEnter: _legacySendByEnter, ...rest } = merged;
    return {
      ...rest,
      chatWallpaper: normalizeChatWallpaperStored(rest.chatWallpaper),
      bubbleRadius: normalizeBubbleRadius(merged.bubbleRadius as string | undefined),
      emojiBurstAnimationProfile: normalizeEmojiBurstAnimationProfileStored(
        (rest as { emojiBurstAnimationProfile?: unknown }).emojiBurstAnimationProfile
      ),
      bottomNavIconNames:
        rest.bottomNavIconNames && typeof rest.bottomNavIconNames === "object"
          ? rest.bottomNavIconNames
          : {},
      bottomNavIconGlobalStyle:
        rest.bottomNavIconGlobalStyle && typeof rest.bottomNavIconGlobalStyle === "object"
          ? rest.bottomNavIconGlobalStyle
          : {},
      bottomNavIconStyles:
        rest.bottomNavIconStyles && typeof rest.bottomNavIconStyles === "object"
          ? rest.bottomNavIconStyles
          : {},
    };
  }, [user?.chatSettings, user?.chatSettings?.chatWallpaper]);

  const notificationSettings = useMemo<NotificationSettings>(
    () => ({ ...DEFAULT_NOTIFICATION_SETTINGS, ...user?.notificationSettings }),
    [user?.notificationSettings]
  );

  const privacySettings = useMemo<PrivacySettings>(
    () => {
      const merged = { ...DEFAULT_PRIVACY_SETTINGS, ...user?.privacySettings } as PrivacySettings;
      return {
        ...merged,
        e2eeEncryptedDataTypes: parseE2eeEncryptedDataTypes(
          (user?.privacySettings as Record<string, unknown> | undefined)?.e2eeEncryptedDataTypes
        ),
      };
    },
    [user?.privacySettings]
  );

  const updateChatSettings = useCallback(
    async (patch: Partial<ChatSettings>) => {
      if (!user || !firestore) return false;
      try {
        const merged = { ...chatSettings, ...patch };
        await updateDoc(doc(firestore, "users", user.id), { chatSettings: merged });
        return true;
      } catch (err) {
        logger.error('settings', 'update chat settings failed', err);
        return false;
      }
    },
    [user, firestore, chatSettings]
  );

  const updateNotificationSettings = useCallback(
    async (patch: Partial<NotificationSettings>) => {
      if (!user || !firestore) return false;
      try {
        const merged = { ...notificationSettings, ...patch };
        await updateDoc(doc(firestore, "users", user.id), { notificationSettings: merged });
        return true;
      } catch (err) {
        logger.error('settings', 'update notification settings failed', err);
        return false;
      }
    },
    [user, firestore, notificationSettings]
  );

  const updatePrivacySettings = useCallback(
    async (patch: Partial<PrivacySettings>) => {
      if (!user || !firestore) return false;
      try {
        const merged = { ...privacySettings, ...patch };
        await updateDoc(doc(firestore, "users", user.id), { privacySettings: merged });
        return true;
      } catch (err) {
        logger.error('settings', 'update privacy settings failed', err);
        return false;
      }
    },
    [user, firestore, privacySettings]
  );

  return {
    chatSettings,
    notificationSettings,
    privacySettings,
    updateChatSettings,
    updateNotificationSettings,
    updatePrivacySettings,
  };
}
