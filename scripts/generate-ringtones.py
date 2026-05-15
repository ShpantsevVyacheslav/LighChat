#!/usr/bin/env python3
"""Generate built-in notification ringtones for LighChat.

Synthesizes 5 ringtone presets and 1 system "hand raise" ping, writes
each to MP3 in both:
  - public/sounds/ringtones/        (web)
  - mobile/app/assets/audio/ringtones/   (Flutter bundle)
and the conference ping to:
  - public/sounds/conference/hand_raise.mp3
  - mobile/app/assets/audio/conference/hand_raise.mp3

Requires: numpy, ffmpeg on PATH. Re-run after editing — files are
overwritten in place.
"""

from __future__ import annotations

import shutil
import struct
import subprocess
import sys
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent.parent
OUT_WEB_RING = ROOT / "public" / "sounds" / "ringtones"
OUT_MOBILE_RING = ROOT / "mobile" / "app" / "assets" / "audio" / "ringtones"
OUT_WEB_CONF = ROOT / "public" / "sounds" / "conference"
OUT_MOBILE_CONF = ROOT / "mobile" / "app" / "assets" / "audio" / "conference"

SR = 44100  # sample rate


def ensure_dirs() -> None:
    for d in (OUT_WEB_RING, OUT_MOBILE_RING, OUT_WEB_CONF, OUT_MOBILE_CONF):
        d.mkdir(parents=True, exist_ok=True)


def t_axis(duration_s: float) -> np.ndarray:
    return np.linspace(0.0, duration_s, int(SR * duration_s), endpoint=False)


def bell_fm(freq: float, duration: float, mod_ratio: float = 1.4,
            mod_index: float = 5.0, decay: float = 4.0) -> np.ndarray:
    """Chowning-style bell via simple FM synthesis."""
    t = t_axis(duration)
    env = np.exp(-decay * t)
    mod = np.sin(2 * np.pi * freq * mod_ratio * t) * mod_index * env
    sig = np.sin(2 * np.pi * freq * t + mod) * env
    return sig


def marimba_hit(freq: float, duration: float, decay: float = 8.0) -> np.ndarray:
    """Wooden mallet feel: fundamental + 4th partial, fast decay."""
    t = t_axis(duration)
    env = np.exp(-decay * t)
    fund = np.sin(2 * np.pi * freq * t)
    harm = 0.35 * np.sin(2 * np.pi * freq * 4.0 * t) * np.exp(-decay * 2.0 * t)
    # tiny pitch glide down (~5%)
    glide = 1.0 - 0.05 * t / duration
    sig = (fund * glide + harm) * env
    return sig


def soft_sine(freq: float, duration: float, attack: float = 0.05,
              release: float = 0.4) -> np.ndarray:
    t = t_axis(duration)
    sig = np.sin(2 * np.pi * freq * t)
    env = np.ones_like(t)
    a_n = int(attack * SR)
    r_n = int(release * SR)
    if a_n:
        env[:a_n] = np.linspace(0.0, 1.0, a_n)
    if r_n:
        env[-r_n:] *= np.linspace(1.0, 0.0, r_n)
    return sig * env


def silence(duration: float) -> np.ndarray:
    return np.zeros(int(SR * duration), dtype=np.float64)


def normalize(audio: np.ndarray, peak_db: float = -3.0) -> np.ndarray:
    peak = np.max(np.abs(audio))
    if peak < 1e-9:
        return audio
    target = 10 ** (peak_db / 20.0)
    return audio * (target / peak)


def gain_db(audio: np.ndarray, db: float) -> np.ndarray:
    return audio * (10 ** (db / 20.0))


# ---- Preset compositions ----

def build_classic_chime() -> np.ndarray:
    # Descending two-note chime E5 -> C5, bell-like
    e5 = bell_fm(659.25, 1.0, mod_ratio=1.4, mod_index=4.0, decay=3.5)
    c5 = bell_fm(523.25, 1.4, mod_ratio=1.4, mod_index=4.0, decay=3.0)
    out = np.concatenate([e5[: int(0.45 * SR)], silence(0.05), c5])
    return normalize(out, -3.0)


def build_gentle_bells() -> np.ndarray:
    # Arpeggio C5 E5 G5, soft bell timbre, mild overlap
    notes = [(523.25, 0.0), (659.25, 0.18), (783.99, 0.36)]
    total_n = int(2.0 * SR)
    buf = np.zeros(total_n, dtype=np.float64)
    for f, start in notes:
        tone = bell_fm(f, 1.6, mod_ratio=2.0, mod_index=3.0, decay=2.5)
        s = int(start * SR)
        end = min(s + len(tone), total_n)
        buf[s:end] += tone[: end - s]
    return normalize(buf, -3.0)


def build_marimba_tap() -> np.ndarray:
    # A4 + E5 grace double-tap
    a4 = marimba_hit(440.0, 0.6, decay=9.0)
    e5 = marimba_hit(659.25, 0.5, decay=10.0)
    out = np.concatenate([a4[: int(0.18 * SR)], silence(0.04), e5])
    return normalize(out, -3.5)


def build_soft_pulse() -> np.ndarray:
    # Two soft sine pulses an octave apart, slow attack
    p1 = soft_sine(440.0, 0.6, attack=0.08, release=0.35)
    p2 = soft_sine(880.0, 0.7, attack=0.08, release=0.4) * 0.7
    gap = silence(0.08)
    out = np.concatenate([p1, gap, p2])
    return normalize(out, -4.0)


def build_ascending_chord() -> np.ndarray:
    # C5-E5-G5 stacking, bell-ish, hold ringing tail
    total = 2.2
    total_n = int(total * SR)
    buf = np.zeros(total_n, dtype=np.float64)
    for i, f in enumerate([523.25, 659.25, 783.99]):
        tone = bell_fm(f, 1.8, mod_ratio=1.4, mod_index=3.5, decay=2.2)
        s = int((0.0 + i * 0.22) * SR)
        end = min(s + len(tone), total_n)
        buf[s:end] += tone[: end - s] * 0.85
    return normalize(buf, -3.0)


def build_hand_raise_ping() -> np.ndarray:
    # Very short, polite double-blip at ~1200Hz, quiet (-10 dB)
    p1 = soft_sine(1175.0, 0.13, attack=0.005, release=0.08)
    p2 = soft_sine(1568.0, 0.18, attack=0.005, release=0.12) * 0.85
    out = np.concatenate([p1, silence(0.04), p2])
    out = normalize(out, -3.0)
    return gain_db(out, -7.0)  # final perceived level ~ -10 dB


# ---- Encoding ----

def write_wav(path: Path, audio: np.ndarray) -> None:
    pcm = np.clip(audio, -1.0, 1.0)
    pcm16 = (pcm * 32767.0).astype(np.int16)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm16.tobytes())


def wav_to_mp3(wav_path: Path, mp3_path: Path, bitrate: str = "96k") -> None:
    subprocess.run(
        [
            "ffmpeg", "-y", "-loglevel", "error",
            "-i", str(wav_path),
            "-codec:a", "libmp3lame", "-b:a", bitrate, "-ac", "1",
            str(mp3_path),
        ],
        check=True,
    )


def emit(name: str, audio: np.ndarray, web_dir: Path, mobile_dir: Path) -> None:
    tmp_wav = web_dir / f"{name}.wav"
    write_wav(tmp_wav, audio)
    web_mp3 = web_dir / f"{name}.mp3"
    wav_to_mp3(tmp_wav, web_mp3)
    tmp_wav.unlink()
    mobile_mp3 = mobile_dir / f"{name}.mp3"
    shutil.copyfile(web_mp3, mobile_mp3)
    dur = len(audio) / SR
    print(f"  {name}.mp3  duration={dur:.2f}s  size={web_mp3.stat().st_size} bytes")


def main() -> int:
    ensure_dirs()

    print("Ringtones →", OUT_WEB_RING, "+", OUT_MOBILE_RING)
    emit("classic_chime", build_classic_chime(), OUT_WEB_RING, OUT_MOBILE_RING)
    emit("gentle_bells", build_gentle_bells(), OUT_WEB_RING, OUT_MOBILE_RING)
    emit("marimba_tap", build_marimba_tap(), OUT_WEB_RING, OUT_MOBILE_RING)
    emit("soft_pulse", build_soft_pulse(), OUT_WEB_RING, OUT_MOBILE_RING)
    emit("ascending_chord", build_ascending_chord(), OUT_WEB_RING, OUT_MOBILE_RING)

    print("\nConference ping →", OUT_WEB_CONF, "+", OUT_MOBILE_CONF)
    emit("hand_raise", build_hand_raise_ping(), OUT_WEB_CONF, OUT_MOBILE_CONF)

    print("\nDone.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
