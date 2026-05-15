/**
 * Каталог встроенных пресетов рингтонов. Источник правды: общий с mobile
 * (mobile/app/lib/features/chat/data/ringtone_presets.dart) — id и имена
 * файлов синхронизированы. Файлы лежат в public/sounds/ringtones/.
 *
 * Сгенерированы скриптом scripts/generate-ringtones.py.
 */

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
] as const;

export const DEFAULT_MESSAGE_RINGTONE_ID = "classic_chime";

export function getRingtonePreset(id: string | null | undefined): RingtonePreset | null {
  if (!id) return null;
  return RINGTONE_PRESETS.find((p) => p.id === id) ?? null;
}

export function ringtoneUrl(preset: RingtonePreset): string {
  return `/sounds/ringtones/${preset.fileName}`;
}

export const HAND_RAISE_SOUND_URL = "/sounds/conference/hand_raise.mp3";
