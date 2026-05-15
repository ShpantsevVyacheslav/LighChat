"use client";

import { useEffect, useRef, useState } from "react";
import { Play, Square } from "lucide-react";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Button } from "@/components/ui/button";
import {
  RINGTONE_PRESETS,
  getRingtonePreset,
  ringtoneUrl,
} from "@/lib/ringtone-presets";
import { useI18n } from "@/hooks/use-i18n";

interface RingtonePickerProps {
  value: string | null;
  onChange: (value: string | null) => void;
  disabled?: boolean;
  ariaLabel?: string;
}

const RINGTONE_LABEL_KEYS: Record<string, string> = {
  classic_chime: "notifications.ringtoneClassicChime",
  gentle_bells: "notifications.ringtoneGentleBells",
  marimba_tap: "notifications.ringtoneMarimbaTap",
  soft_pulse: "notifications.ringtoneSoftPulse",
  ascending_chord: "notifications.ringtoneAscendingChord",
};

export function RingtonePicker({ value, onChange, disabled, ariaLabel }: RingtonePickerProps) {
  const { t } = useI18n();
  const [playingId, setPlayingId] = useState<string | null>(null);
  const audioRef = useRef<HTMLAudioElement | null>(null);

  useEffect(() => {
    return () => {
      if (audioRef.current) {
        audioRef.current.pause();
        audioRef.current = null;
      }
    };
  }, []);

  const previewSelected = () => {
    const preset = getRingtonePreset(value);
    if (!preset) return;
    if (audioRef.current) {
      audioRef.current.pause();
      audioRef.current = null;
    }
    if (playingId === preset.id) {
      setPlayingId(null);
      return;
    }
    try {
      const audio = new Audio(ringtoneUrl(preset));
      audio.volume = 0.9;
      audio.addEventListener("ended", () => setPlayingId(null));
      audioRef.current = audio;
      void audio.play().catch(() => setPlayingId(null));
      setPlayingId(preset.id);
    } catch {
      setPlayingId(null);
    }
  };

  return (
    <div className="flex items-center gap-2">
      <Select
        value={value ?? "__default__"}
        onValueChange={(v) => onChange(v === "__default__" ? null : v)}
        disabled={disabled}
      >
        <SelectTrigger className="w-[200px] rounded-xl" aria-label={ariaLabel}>
          <SelectValue />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="__default__">{t("notifications.ringtoneDefault")}</SelectItem>
          {RINGTONE_PRESETS.map((preset) => (
            <SelectItem key={preset.id} value={preset.id}>
              {t(RINGTONE_LABEL_KEYS[preset.id] ?? preset.id)}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
      <Button
        type="button"
        variant="ghost"
        size="icon"
        disabled={disabled || !value}
        onClick={previewSelected}
        aria-label={t("notifications.ringtonePreviewLabel")}
        title={t("notifications.ringtonePreviewLabel")}
      >
        {playingId ? <Square className="h-4 w-4" /> : <Play className="h-4 w-4" />}
      </Button>
    </div>
  );
}
