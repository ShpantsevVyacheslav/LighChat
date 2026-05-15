/**
 * Каталог встроенных пресетов рингтонов. Источник правды: общий с mobile
 * (mobile/app/lib/features/chat/data/ringtone_presets.dart) — id и имена
 * файлов синхронизированы.
 *
 * Каждый пресет существует в двух вариантах:
 *   - messages: короткий мягкий одиночный сигнал (~0.5–0.8s)
 *   - calls:    длиннее, мелодичный, не режущий слух (~2.5–3s)
 *
 * Файлы лежат в:
 *   public/sounds/ringtones/messages/<id>.mp3
 *   public/sounds/ringtones/calls/<id>.mp3
 *
 * Сгенерированы скриптом scripts/generate-ringtones.py.
 */

export type RingtoneVariant = "messages" | "calls";

export type RingtonePreset = {
  id: string;
  fileName: string;
  /** Ключ локализации для отображаемого имени пресета. */
  labelKey: string;
};

export const RINGTONE_PRESETS: readonly RingtonePreset[] = [
  { id: "classic_chime", fileName: "classic_chime.mp3", labelKey: "ringtone_classic_chime" },
  { id: "gentle_bells", fileName: "gentle_bells.mp3", labelKey: "ringtone_gentle_bells" },
  { id: "marimba_tap", fileName: "marimba_tap.mp3", labelKey: "ringtone_marimba_tap" },
  { id: "soft_pulse", fileName: "soft_pulse.mp3", labelKey: "ringtone_soft_pulse" },
  { id: "ascending_chord", fileName: "ascending_chord.mp3", labelKey: "ringtone_ascending_chord" },
  { id: "glass_drop", fileName: "glass_drop.mp3", labelKey: "ringtone_glass_drop" },
  { id: "wood_block", fileName: "wood_block.mp3", labelKey: "ringtone_wood_block" },
  { id: "sparkle", fileName: "sparkle.mp3", labelKey: "ringtone_sparkle" },
  { id: "airy_note", fileName: "airy_note.mp3", labelKey: "ringtone_airy_note" },
  { id: "tap_tone", fileName: "tap_tone.mp3", labelKey: "ringtone_tap_tone" },
] as const;

export const DEFAULT_MESSAGE_RINGTONE_ID = "classic_chime";

/**
 * Спец-id для мелодии звонка, загружаемой из Firebase Storage
 * (`audio/ringtone.mp3`). Не входит в [RINGTONE_PRESETS]. Применяется
 * только для callRingtoneId.
 */
export const STORAGE_RINGTONE_ID = "storage_original";
export const STORAGE_RINGTONE_PATH = "audio/ringtone.mp3";

export function getRingtonePreset(id: string | null | undefined): RingtonePreset | null {
  if (!id) return null;
  return RINGTONE_PRESETS.find((p) => p.id === id) ?? null;
}

export function ringtoneUrl(preset: RingtonePreset, variant: RingtoneVariant): string {
  return `/sounds/ringtones/${variant}/${preset.fileName}`;
}

export const HAND_RAISE_SOUND_URL = "/sounds/conference/hand_raise.mp3";
