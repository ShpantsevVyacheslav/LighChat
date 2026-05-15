"use client";

import { useEffect, useRef, useState } from "react";
import { Play, Square, ChevronDown } from "lucide-react";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import {
  RINGTONE_PRESETS,
  type RingtoneVariant,
  getRingtonePreset,
  ringtoneUrl,
} from "@/lib/ringtone-presets";
import { useI18n } from "@/hooks/use-i18n";
import { cn } from "@/lib/utils";

interface RingtonePickerProps {
  value: string | null;
  onChange: (value: string | null) => void;
  variant: RingtoneVariant;
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

const ACCENT = "rgb(77, 162, 255)";

export function RingtonePicker({
  value,
  onChange,
  variant,
  disabled,
  ariaLabel,
}: RingtonePickerProps) {
  const { t } = useI18n();
  const [playingId, setPlayingId] = useState<string | null>(null);
  const [open, setOpen] = useState(false);
  const audioRef = useRef<HTMLAudioElement | null>(null);

  useEffect(() => {
    return () => {
      if (audioRef.current) {
        audioRef.current.pause();
        audioRef.current = null;
      }
    };
  }, []);

  // Останавливаем превью при закрытии поповера.
  useEffect(() => {
    if (!open && audioRef.current) {
      audioRef.current.pause();
      audioRef.current = null;
      setPlayingId(null);
    }
  }, [open]);

  const togglePreview = (id: string) => {
    const preset = getRingtonePreset(id);
    if (!preset) return;
    if (audioRef.current) {
      audioRef.current.pause();
      audioRef.current = null;
    }
    if (playingId === id) {
      setPlayingId(null);
      return;
    }
    try {
      const audio = new Audio(ringtoneUrl(preset, variant));
      audio.volume = 0.9;
      audio.addEventListener("ended", () => setPlayingId(null));
      audioRef.current = audio;
      void audio.play().catch(() => setPlayingId(null));
      setPlayingId(id);
    } catch {
      setPlayingId(null);
    }
  };

  const selectedPreset = getRingtonePreset(value);
  const triggerLabel = selectedPreset
    ? t(RINGTONE_LABEL_KEYS[selectedPreset.id] ?? selectedPreset.id)
    : t("notifications.ringtoneDefault");

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <button
          type="button"
          disabled={disabled}
          aria-label={ariaLabel}
          className={cn(
            "group flex w-[210px] items-center justify-between gap-2 rounded-xl",
            "border border-white/10 bg-white/[0.03] px-3.5 py-2.5",
            "text-sm font-medium text-foreground transition",
            "hover:border-white/20 hover:bg-white/[0.05]",
            "disabled:cursor-not-allowed disabled:opacity-50",
            "data-[state=open]:border-[rgb(77,162,255)]/60 data-[state=open]:shadow-[0_0_24px_-6px_rgba(77,162,255,0.45)]",
          )}
        >
          <span className="truncate">{triggerLabel}</span>
          <ChevronDown
            className="h-4 w-4 shrink-0 opacity-60 transition group-data-[state=open]:rotate-180"
          />
        </button>
      </PopoverTrigger>
      <PopoverContent
        align="end"
        sideOffset={6}
        className={cn(
          "w-[260px] rounded-2xl border-white/10 p-1.5",
          "bg-[linear-gradient(180deg,#161B26_0%,#0B0F18_100%)]",
          "shadow-[0_24px_48px_-12px_rgba(0,0,0,0.6)]",
          "backdrop-blur-xl",
        )}
      >
        <PickerOption
          label={t("notifications.ringtoneDefault")}
          selected={!value}
          onSelect={() => {
            onChange(null);
            setOpen(false);
          }}
          onTogglePreview={null}
          playing={false}
        />
        {RINGTONE_PRESETS.map((preset) => (
          <PickerOption
            key={preset.id}
            label={t(RINGTONE_LABEL_KEYS[preset.id] ?? preset.id)}
            selected={value === preset.id}
            onSelect={() => {
              onChange(preset.id);
              setOpen(false);
            }}
            onTogglePreview={() => togglePreview(preset.id)}
            playing={playingId === preset.id}
            previewAriaLabel={t("notifications.ringtonePreviewLabel")}
          />
        ))}
      </PopoverContent>
    </Popover>
  );
}

interface PickerOptionProps {
  label: string;
  selected: boolean;
  onSelect: () => void;
  onTogglePreview: (() => void) | null;
  playing: boolean;
  previewAriaLabel?: string;
}

function PickerOption({
  label,
  selected,
  onSelect,
  onTogglePreview,
  playing,
  previewAriaLabel,
}: PickerOptionProps) {
  return (
    <div
      role="button"
      tabIndex={0}
      onClick={onSelect}
      onKeyDown={(e) => {
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          onSelect();
        }
      }}
      className={cn(
        "group/option flex cursor-pointer items-center gap-3 rounded-xl border px-3 py-2.5 transition",
        selected
          ? "border-[rgb(77,162,255)]/55 bg-[linear-gradient(135deg,rgba(77,162,255,0.18),rgba(77,162,255,0.04))] shadow-[0_0_18px_-2px_rgba(77,162,255,0.35)]"
          : "border-white/[0.06] bg-white/[0.025] hover:border-white/12 hover:bg-white/[0.05]",
      )}
      style={{ marginTop: 3, marginBottom: 3 }}
    >
      <SelectionDot selected={selected} />
      <span
        className={cn(
          "flex-1 truncate text-[14.5px] tracking-[-0.1px]",
          selected ? "font-semibold text-white" : "font-medium text-white/85",
        )}
      >
        {label}
      </span>
      {onTogglePreview && (
        <button
          type="button"
          aria-label={previewAriaLabel}
          onClick={(e) => {
            e.stopPropagation();
            onTogglePreview();
          }}
          className={cn(
            "flex h-8 w-8 shrink-0 items-center justify-center rounded-full border transition",
            playing
              ? "border-[rgb(77,162,255)]/60 bg-[rgba(77,162,255,0.18)] text-[rgb(77,162,255)]"
              : "border-white/10 bg-white/5 text-white/75 hover:border-white/20 hover:bg-white/10",
          )}
        >
          {playing ? <Square className="h-3.5 w-3.5" /> : <Play className="h-3.5 w-3.5" />}
        </button>
      )}
    </div>
  );
}

function SelectionDot({ selected }: { selected: boolean }) {
  return (
    <span className="relative flex h-5 w-5 shrink-0 items-center justify-center">
      <span
        className={cn(
          "absolute inset-0 rounded-full border-[1.6px] transition",
          selected
            ? "border-[rgb(77,162,255)]/95 shadow-[0_0_10px_-1px_rgba(77,162,255,0.55)]"
            : "border-white/30",
        )}
      />
      <span
        className={cn(
          "h-2.5 w-2.5 rounded-full transition-transform duration-200",
          selected
            ? "scale-100 bg-[linear-gradient(135deg,#7BC1FF,rgb(77,162,255))]"
            : "scale-0",
        )}
        style={{ backgroundColor: selected ? undefined : ACCENT }}
      />
    </span>
  );
}
