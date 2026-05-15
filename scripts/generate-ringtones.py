#!/usr/bin/env python3
"""Generate built-in notification ringtones for LighChat.

Two preset banks share the same 5 ids:
  - messages: short (~0.5–0.8s), single mellow soft signal
  - calls:    longer (~2.5–3s) gentle, loop-friendly tone

Plus the system "raise hand" ping for video meetings.

Output paths:
  - public/sounds/ringtones/messages/<id>.mp3
  - public/sounds/ringtones/calls/<id>.mp3
  - mobile/app/assets/audio/ringtones/messages/<id>.mp3
  - mobile/app/assets/audio/ringtones/calls/<id>.mp3
  - public/sounds/conference/hand_raise.mp3
  - mobile/app/assets/audio/conference/hand_raise.mp3

Requires: numpy, ffmpeg on PATH.
"""

from __future__ import annotations

import shutil
import subprocess
import sys
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent.parent
OUT_WEB = ROOT / "public" / "sounds"
OUT_MOBILE = ROOT / "mobile" / "app" / "assets" / "audio"

SR = 44100  # sample rate


def ensure_dirs() -> None:
    for sub in ("ringtones/messages", "ringtones/calls", "conference"):
        (OUT_WEB / sub).mkdir(parents=True, exist_ok=True)
        (OUT_MOBILE / sub).mkdir(parents=True, exist_ok=True)


def t_axis(duration_s: float) -> np.ndarray:
    return np.linspace(0.0, duration_s, int(SR * duration_s), endpoint=False)


def bell_fm(freq: float, duration: float, mod_ratio: float = 1.4,
            mod_index: float = 3.0, decay: float = 3.5) -> np.ndarray:
    """Chowning-style bell FM. Lower mod_index = mellower, less metallic."""
    t = t_axis(duration)
    env = np.exp(-decay * t)
    mod = np.sin(2 * np.pi * freq * mod_ratio * t) * mod_index * env
    sig = np.sin(2 * np.pi * freq * t + mod) * env
    return sig


def soft_tone(freq: float, duration: float, attack: float = 0.015,
              release: float = 0.35, harmonics: tuple[tuple[float, float], ...] = ()) -> np.ndarray:
    """Sine + optional weak harmonics with smooth ADSR-like envelope."""
    t = t_axis(duration)
    sig = np.sin(2 * np.pi * freq * t)
    for ratio, amp in harmonics:
        sig = sig + amp * np.sin(2 * np.pi * freq * ratio * t)
    sig = sig / (1.0 + sum(a for _, a in harmonics))
    env = _envelope(len(t), attack, release)
    return sig * env


def warm_mallet(freq: float, duration: float, decay: float = 6.0) -> np.ndarray:
    """Soft wooden mallet (marimba-like) with low harmonic clarity."""
    t = t_axis(duration)
    env = np.exp(-decay * t)
    fund = np.sin(2 * np.pi * freq * t)
    sub = 0.25 * np.sin(2 * np.pi * freq * 0.5 * t) * np.exp(-decay * 0.8 * t)
    harm = 0.18 * np.sin(2 * np.pi * freq * 4.0 * t) * np.exp(-decay * 2.4 * t)
    glide = 1.0 - 0.04 * t / max(duration, 1e-6)
    sig = (fund * glide + sub + harm) * env
    return sig


def _envelope(n: int, attack: float, release: float) -> np.ndarray:
    env = np.ones(n, dtype=np.float64)
    a_n = int(attack * SR)
    r_n = int(release * SR)
    if a_n:
        env[:a_n] = np.linspace(0.0, 1.0, a_n) ** 1.4
    if r_n:
        tail = np.linspace(1.0, 0.0, r_n) ** 1.6
        env[-r_n:] *= tail
    return env


def silence(duration: float) -> np.ndarray:
    return np.zeros(int(SR * duration), dtype=np.float64)


def normalize(audio: np.ndarray, peak_db: float = -4.0) -> np.ndarray:
    peak = np.max(np.abs(audio))
    if peak < 1e-9:
        return audio
    target = 10 ** (peak_db / 20.0)
    return audio * (target / peak)


def gain_db(audio: np.ndarray, db: float) -> np.ndarray:
    return audio * (10 ** (db / 20.0))


def edge_fades(audio: np.ndarray, fade_in_ms: float = 4.0,
               fade_out_ms: float = 18.0) -> np.ndarray:
    """Anti-click fades on both ends."""
    n = len(audio)
    fi = int(fade_in_ms * SR / 1000)
    fo = int(fade_out_ms * SR / 1000)
    out = audio.copy()
    if fi > 0:
        out[:fi] *= np.linspace(0.0, 1.0, fi)
    if fo > 0 and fo <= n:
        out[-fo:] *= np.linspace(1.0, 0.0, fo)
    return out


# ============================================================================
# Pitch reference
# ============================================================================
C4 = 261.63
E4 = 329.63
G4 = 392.00
A4 = 440.00
C5 = 523.25
D5 = 587.33
E5 = 659.25
G5 = 783.99
A5 = 880.00


# ============================================================================
# MESSAGES — short, single mellow soft signal (~0.4–0.8s)
# ============================================================================

def msg_classic_chime() -> np.ndarray:
    # Single warm bell at C5, very gentle.
    sig = bell_fm(C5, 0.75, mod_ratio=2.0, mod_index=2.2, decay=4.5)
    return normalize(edge_fades(sig), -5.0)


def msg_gentle_bells() -> np.ndarray:
    # One close-stacked soft chord ring: C5 + G5 quickly overlapping.
    a = bell_fm(C5, 0.8, mod_ratio=2.0, mod_index=2.0, decay=4.0) * 0.85
    b = bell_fm(G5, 0.65, mod_ratio=2.0, mod_index=1.6, decay=4.6) * 0.7
    n = int(0.85 * SR)
    buf = np.zeros(n, dtype=np.float64)
    buf[: len(a)] += a[: min(len(a), n)]
    s = int(0.06 * SR)
    end = min(s + len(b), n)
    buf[s:end] += b[: end - s]
    return normalize(edge_fades(buf), -5.0)


def msg_marimba_tap() -> np.ndarray:
    # Single wooden tap with subtle sub.
    sig = warm_mallet(A4, 0.55, decay=7.0)
    return normalize(edge_fades(sig, fade_out_ms=24.0), -5.5)


def msg_soft_pulse() -> np.ndarray:
    # One short sine pulse with soft attack/release.
    sig = soft_tone(E5, 0.55, attack=0.025, release=0.30,
                    harmonics=((2.0, 0.15),))
    return normalize(edge_fades(sig), -5.5)


def msg_ascending_chord() -> np.ndarray:
    # Tiny two-note grace: C5→E5, mellow bells, short.
    a = bell_fm(C5, 0.55, mod_ratio=2.0, mod_index=1.8, decay=5.5)
    b = bell_fm(E5, 0.55, mod_ratio=2.0, mod_index=1.8, decay=5.5)
    n = int(0.78 * SR)
    buf = np.zeros(n, dtype=np.float64)
    buf[: len(a)] += a[: min(len(a), n)] * 0.85
    s = int(0.18 * SR)
    end = min(s + len(b), n)
    buf[s:end] += b[: end - s] * 0.9
    return normalize(edge_fades(buf), -5.0)


# ============================================================================
# CALLS — longer (~2.5–3s) gentle, loop-friendly, never harsh
# ============================================================================

def call_classic_chime() -> np.ndarray:
    # Slow descending chime: E5 → C5 → G4, mellow bells.
    a = bell_fm(E5, 1.2, mod_ratio=2.0, mod_index=2.4, decay=2.8)
    b = bell_fm(C5, 1.4, mod_ratio=2.0, mod_index=2.2, decay=2.4)
    c = bell_fm(G4, 1.6, mod_ratio=2.0, mod_index=2.0, decay=2.0)
    n = int(2.8 * SR)
    buf = np.zeros(n, dtype=np.float64)
    pos = 0
    for clip, step in ((a, 0.42), (b, 0.42), (c, None)):
        end = min(pos + len(clip), n)
        buf[pos:end] += clip[: end - pos]
        if step is not None:
            pos += int(step * SR)
    return normalize(edge_fades(buf, fade_out_ms=120.0), -4.5)


def call_gentle_bells() -> np.ndarray:
    # Soft ostinato: C5 E5 G5 C5 ... two passes, light overlap.
    notes = [
        (C5, 0.00, 1.4),
        (E5, 0.32, 1.4),
        (G5, 0.64, 1.6),
        (E5, 1.05, 1.4),
        (C5, 1.45, 1.7),
    ]
    n = int(3.0 * SR)
    buf = np.zeros(n, dtype=np.float64)
    for f, start, dur in notes:
        tone = bell_fm(f, dur, mod_ratio=2.0, mod_index=1.8, decay=2.6)
        s = int(start * SR)
        end = min(s + len(tone), n)
        buf[s:end] += tone[: end - s] * 0.7
    return normalize(edge_fades(buf, fade_out_ms=160.0), -4.5)


def call_marimba_tap() -> np.ndarray:
    # Looping marimba phrase A4-C5-E5-D5-A4, two soft repeats.
    pattern = [
        (A4, 0.00, 0.5),
        (C5, 0.22, 0.5),
        (E5, 0.44, 0.6),
        (D5, 0.72, 0.6),
        (A4, 1.10, 0.9),
        (A4, 1.55, 0.6),
        (C5, 1.78, 0.6),
        (E5, 2.05, 1.0),
    ]
    n = int(2.9 * SR)
    buf = np.zeros(n, dtype=np.float64)
    for f, start, dur in pattern:
        tone = warm_mallet(f, dur, decay=5.5) * 0.85
        s = int(start * SR)
        end = min(s + len(tone), n)
        buf[s:end] += tone[: end - s]
    return normalize(edge_fades(buf, fade_out_ms=140.0), -5.0)


def call_soft_pulse() -> np.ndarray:
    # Four breathy pulses at 330/440Hz, gentle alternation.
    n = int(2.8 * SR)
    buf = np.zeros(n, dtype=np.float64)
    schedule = [
        (E4, 0.0, 0.55),
        (A4, 0.7, 0.55),
        (E4, 1.4, 0.55),
        (A4, 2.1, 0.65),
    ]
    for f, start, dur in schedule:
        tone = soft_tone(f, dur, attack=0.06, release=0.30,
                         harmonics=((2.0, 0.18), (3.0, 0.08)))
        s = int(start * SR)
        end = min(s + len(tone), n)
        buf[s:end] += tone[: end - s] * 0.85
    return normalize(edge_fades(buf, fade_out_ms=140.0), -5.0)


def call_ascending_chord() -> np.ndarray:
    # Sustained arpeggio C5-E5-G5 ringing into a soft tail.
    n = int(3.0 * SR)
    buf = np.zeros(n, dtype=np.float64)
    starts = [(C5, 0.00, 2.6), (E5, 0.32, 2.4), (G5, 0.64, 2.4)]
    for f, start, dur in starts:
        tone = bell_fm(f, dur, mod_ratio=2.0, mod_index=2.0, decay=1.4) * 0.7
        s = int(start * SR)
        end = min(s + len(tone), n)
        buf[s:end] += tone[: end - s]
    # add quiet sustained pad chord under the tail
    pad_t = t_axis(2.6)
    pad = (
        0.16 * np.sin(2 * np.pi * C5 * pad_t)
        + 0.13 * np.sin(2 * np.pi * E5 * pad_t)
        + 0.11 * np.sin(2 * np.pi * G5 * pad_t)
    )
    pad *= _envelope(len(pad_t), attack=0.35, release=1.2)
    s = int(0.30 * SR)
    end = min(s + len(pad), n)
    buf[s:end] += pad[: end - s] * 0.6
    return normalize(edge_fades(buf, fade_out_ms=200.0), -4.5)


# ============================================================================
# Hand-raise ping (unchanged: short, polite, quiet)
# ============================================================================

def hand_raise_ping() -> np.ndarray:
    p1 = soft_tone(1175.0, 0.13, attack=0.005, release=0.08)
    p2 = soft_tone(1568.0, 0.18, attack=0.005, release=0.12) * 0.85
    out = np.concatenate([p1, silence(0.04), p2])
    out = normalize(edge_fades(out), -3.0)
    return gain_db(out, -7.0)


# ============================================================================
# Encoding
# ============================================================================

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


def emit(rel_path: str, audio: np.ndarray) -> None:
    web_path = OUT_WEB / f"{rel_path}.mp3"
    mobile_path = OUT_MOBILE / f"{rel_path}.mp3"
    tmp_wav = web_path.with_suffix(".wav")
    write_wav(tmp_wav, audio)
    wav_to_mp3(tmp_wav, web_path)
    tmp_wav.unlink()
    shutil.copyfile(web_path, mobile_path)
    dur = len(audio) / SR
    print(f"  {rel_path}.mp3  duration={dur:.2f}s  size={web_path.stat().st_size} B")


def main() -> int:
    ensure_dirs()

    print("Messages (short, single soft signals):")
    emit("ringtones/messages/classic_chime", msg_classic_chime())
    emit("ringtones/messages/gentle_bells", msg_gentle_bells())
    emit("ringtones/messages/marimba_tap", msg_marimba_tap())
    emit("ringtones/messages/soft_pulse", msg_soft_pulse())
    emit("ringtones/messages/ascending_chord", msg_ascending_chord())

    print("\nCalls (longer, mellow):")
    emit("ringtones/calls/classic_chime", call_classic_chime())
    emit("ringtones/calls/gentle_bells", call_gentle_bells())
    emit("ringtones/calls/marimba_tap", call_marimba_tap())
    emit("ringtones/calls/soft_pulse", call_soft_pulse())
    emit("ringtones/calls/ascending_chord", call_ascending_chord())

    print("\nConference ping:")
    emit("conference/hand_raise", hand_raise_ping())

    print("\nDone.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
