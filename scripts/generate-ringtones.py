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
# Post-processing chain: reverb → stereo widening → soft limiter
# ============================================================================

def build_ir(duration_s: float, rt60_s: float, seed: int = 1) -> np.ndarray:
    """Synthesize a compact synthetic IR.

    - Кластер early reflections (~5–40 мс), затем гладкий диффузный хвост.
    - Слабая low-pass через сглаживающий 5-tap kernel — убирает «sandy»
      высокие частоты у белого шума, имитирует поглощение комнатой.
    """
    n = int(duration_s * SR)
    rng = np.random.default_rng(seed=seed)
    noise = rng.standard_normal(n)
    decay = np.exp(-6.908 * np.linspace(0.0, duration_s, n) / rt60_s)
    diffuse = noise * decay
    kernel = np.array([0.10, 0.25, 0.30, 0.25, 0.10])
    diffuse = np.convolve(diffuse, kernel, mode='same')
    # Early reflections (короткий кластер impulse'ов)
    early = np.zeros(n)
    for t_ms, amp in ((7.5, 0.45), (14.0, -0.30), (22.0, 0.25), (33.0, -0.18)):
        idx = int(t_ms * SR / 1000)
        if idx < n:
            early[idx] = amp
    ir = early + diffuse * 0.55
    # Нормируем чтобы reverb добавлял энергию контролируемо.
    peak = max(abs(ir).max(), 1e-6)
    return ir / peak * 0.42


def apply_reverb(audio: np.ndarray, ir: np.ndarray, wet: float = 0.30) -> np.ndarray:
    """Mix dry + convolved (wet) signal. Хвост IR расширяет длительность."""
    if wet <= 0.0:
        return audio
    wet_sig = np.convolve(audio, ir, mode='full')
    out = np.zeros(len(wet_sig), dtype=np.float64)
    # Слегка ослабим dry для баланса (не слишком много, иначе звучит мутно).
    out[: len(audio)] = audio * (1.0 - wet * 0.35)
    out += wet_sig * wet
    return out


def widen_stereo(mono: np.ndarray, delay_ms: float = 9.0,
                 gain_r: float = 0.86) -> np.ndarray:
    """Haas-эффект: правый канал задерживается на ~7–12 мс. Создаёт
    ощущение ширины без потери mono-совместимости (на динамике смартфона
    практически совпадает с mono mix-down)."""
    n = len(mono)
    d = int(delay_ms * SR / 1000)
    out = np.zeros((n, 2), dtype=np.float64)
    out[:, 0] = mono
    if d > 0 and d < n:
        out[d:, 1] = mono[: n - d] * gain_r
    # Чтобы правый канал не начинался с тишины — заполним начало мягко.
    fill = min(d, n)
    if fill > 0:
        out[:fill, 1] = mono[:fill] * gain_r * 0.45
    return out


def soft_limit(audio: np.ndarray, threshold: float = 0.92) -> np.ndarray:
    """Tanh-based soft clipping — мягкий ceiling без жёстких overshoot'ов."""
    return np.tanh(audio / threshold) * threshold


# ============================================================================
# Pitch reference
# ============================================================================
C2 = 65.41
C3 = 130.81
D3 = 146.83
F3 = 174.61
G3 = 196.00
A3 = 220.00
C4 = 261.63
D4 = 293.66
E4 = 329.63
F4 = 349.23
G4 = 392.00
A4 = 440.00
B4 = 493.88
C5 = 523.25
D5 = 587.33
E5 = 659.25
F5 = 698.46
G5 = 783.99
A5 = 880.00
B5 = 987.77
C6 = 1046.50
E6 = 1318.51
G6 = 1567.98


# ============================================================================
# Lo-fi helpers — Rhodes-like FM, warm LP filter, tape saturation, chord stack
# ============================================================================

def rhodes_note(freq: float, duration: float, decay: float = 2.4,
                attack: float = 0.008, mod_decay_mult: float = 2.4) -> np.ndarray:
    """FM Rhodes-like timbre: carrier sine modulated by sine envelope-driven
    by faster decay → классический «pluck» с теплым sustain."""
    t = t_axis(duration)
    env = np.exp(-decay * t)
    mod_env = np.exp(-decay * mod_decay_mult * t)
    mod = np.sin(2 * np.pi * freq * t) * 2.0 * mod_env
    sig = np.sin(2 * np.pi * freq * t + mod) * env
    a_n = int(attack * SR)
    if a_n:
        sig[:a_n] *= np.linspace(0.0, 1.0, a_n) ** 1.5
    return sig


def lp_filter(audio: np.ndarray, alpha: float = 0.18) -> np.ndarray:
    """One-pole low-pass: y[n] = α·x[n] + (1-α)·y[n-1]. Малое α — теплее.

    Используется на массивах ~30–150k семплов — скорость нормально через
    np.empty + loop в numpy-векторизации не получится из-за рекурсии."""
    out = np.empty_like(audio)
    out[0] = audio[0]
    one_minus = 1.0 - alpha
    for i in range(1, len(audio)):
        out[i] = alpha * audio[i] + one_minus * out[i - 1]
    return out


def tape_saturate(audio: np.ndarray, drive: float = 1.5, mix: float = 0.55) -> np.ndarray:
    """Tape-like soft clipping (tanh) с wet/dry mix — даёт «винтажную»
    окраску без сильного искажения."""
    sat = np.tanh(audio * drive) / drive
    return audio * (1.0 - mix) + sat * mix


def chord_stack(freqs, duration: float, attack: float = 0.04,
                release: float = 0.5, decay: float = 0.0,
                timbre: str = 'sine') -> np.ndarray:
    """Полифонический аккорд: сумма голосов с общим ADR-конвертом."""
    t = t_axis(duration)
    sig = np.zeros_like(t)
    for f in freqs:
        if timbre == 'rhodes':
            sig = sig + rhodes_note(f, duration, decay=max(decay, 1.2))
        elif timbre == 'pad':
            sig = sig + np.sin(2 * np.pi * f * t) + 0.30 * np.sin(2 * np.pi * f * 2 * t) \
                  + 0.12 * np.sin(2 * np.pi * f * 3 * t)
        else:
            sig = sig + np.sin(2 * np.pi * f * t)
    sig /= max(len(freqs), 1)
    env = _envelope(len(t), attack, release)
    if decay > 0:
        env = env * np.exp(-decay * t * 0.3)
    return sig * env


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


def msg_glass_drop() -> np.ndarray:
    # Single bright glass-like drop with a subtle shimmer partial.
    sig = bell_fm(D5, 0.62, mod_ratio=3.0, mod_index=1.6, decay=5.2)
    shimmer = bell_fm(D5 * 2, 0.4, mod_ratio=3.0, mod_index=1.2, decay=8.0) * 0.32
    n = max(len(sig), len(shimmer))
    buf = np.zeros(n, dtype=np.float64)
    buf[: len(sig)] += sig
    buf[: len(shimmer)] += shimmer
    return normalize(edge_fades(buf), -5.0)


def msg_wood_block() -> np.ndarray:
    # Crisp wooden tap — short and dry.
    sig = warm_mallet(G4, 0.40, decay=12.0)
    return normalize(edge_fades(sig, fade_out_ms=18.0), -5.5)


def msg_sparkle() -> np.ndarray:
    # Two high quick bells C6→E6, sparkly but soft.
    a = bell_fm(C6, 0.42, mod_ratio=2.5, mod_index=1.4, decay=6.0)
    b = bell_fm(E6, 0.42, mod_ratio=2.5, mod_index=1.4, decay=6.0)
    n = int(0.72 * SR)
    buf = np.zeros(n, dtype=np.float64)
    buf[: len(a)] += a[: min(len(a), n)] * 0.9
    s = int(0.12 * SR)
    end = min(s + len(b), n)
    buf[s:end] += b[: end - s] * 0.85
    return normalize(edge_fades(buf), -5.5)


def msg_airy_note() -> np.ndarray:
    # Airy single tone with soft harmonics, breathy character.
    sig = soft_tone(F5, 0.70, attack=0.07, release=0.40,
                    harmonics=((1.5, 0.20), (2.0, 0.10)))
    return normalize(edge_fades(sig), -5.5)


def msg_tap_tone() -> np.ndarray:
    # Polite double-blip in mid range, no harshness.
    a = soft_tone(A5, 0.16, attack=0.005, release=0.10)
    b = soft_tone(A5, 0.20, attack=0.005, release=0.14)
    out = np.concatenate([a, silence(0.06), b])
    return normalize(edge_fades(out), -5.0)


# --- Lo-fi family (полифоничные, тёплые, кинематографичные) ---

def msg_lofi_keys() -> np.ndarray:
    # Короткий Rhodes Cmaj7 stab — мягкая профессиональная клавиша.
    chord = chord_stack([C4, E4, G4, B4], 0.95, attack=0.012, release=0.4,
                        timbre='rhodes', decay=1.6)
    sig = tape_saturate(lp_filter(chord, alpha=0.22), drive=1.4, mix=0.55)
    return normalize(edge_fades(sig), -5.0)


def msg_tape_chime() -> np.ndarray:
    # Тёплый bell с vibrato + tape saturation. Однонотный, но «дорогой».
    t = t_axis(0.85)
    vibrato = 1.0 + 0.005 * np.sin(2 * np.pi * 5.0 * t)
    bell = bell_fm(E5, 0.85, mod_ratio=2.0, mod_index=2.0, decay=3.6) * vibrato
    bell = lp_filter(bell, alpha=0.30)
    sig = tape_saturate(bell, drive=1.3, mix=0.5)
    return normalize(edge_fades(sig), -5.0)


def msg_dream_pad() -> np.ndarray:
    # Воздушный pad Fmaj9, медленный attack — для мечтательного уведомления.
    chord = chord_stack([F4, A4, C5, E5, G5], 1.0, attack=0.18, release=0.5,
                        timbre='pad', decay=0.6)
    sig = lp_filter(chord, alpha=0.28) * 0.85
    return normalize(edge_fades(sig, fade_in_ms=12, fade_out_ms=80), -5.5)


def msg_chill_arp() -> np.ndarray:
    # Короткое арпеджио Dm9: D5 → F5 → A5, Rhodes, lo-fi.
    n = int(0.95 * SR)
    buf = np.zeros(n, dtype=np.float64)
    for f, start in ((D5, 0.0), (F5, 0.16), (A5, 0.32)):
        tone = rhodes_note(f, 0.7, decay=2.0)
        s = int(start * SR)
        end = min(s + len(tone), n)
        buf[s:end] += tone[: end - s] * 0.85
    buf = tape_saturate(lp_filter(buf, alpha=0.24), drive=1.3, mix=0.5)
    return normalize(edge_fades(buf), -5.0)


def msg_velvet_pulse() -> np.ndarray:
    # Один теплый Fmaj9 удар + sub-нота под ним. Бархатистый short hit.
    chord = chord_stack([F4, A4, C5, E5], 0.75, attack=0.02, release=0.35,
                        timbre='rhodes', decay=2.0)
    sub = rhodes_note(F3, 0.75, decay=2.6) * 0.55
    n = max(len(chord), len(sub))
    buf = np.zeros(n, dtype=np.float64)
    buf[: len(chord)] += chord
    buf[: len(sub)] += sub
    sig = tape_saturate(lp_filter(buf, alpha=0.22), drive=1.5, mix=0.5)
    return normalize(edge_fades(sig), -5.0)


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


def call_glass_drop() -> np.ndarray:
    # 4 glass drops drifting upward into a held tail.
    notes = [(D5, 0.00, 0.9), (F5, 0.45, 1.0), (A5, 0.90, 1.1), (D5, 1.55, 1.7)]
    n = int(3.0 * SR)
    buf = np.zeros(n, dtype=np.float64)
    for f, start, dur in notes:
        tone = bell_fm(f, dur, mod_ratio=3.0, mod_index=1.6, decay=3.4) * 0.75
        s = int(start * SR)
        end = min(s + len(tone), n)
        buf[s:end] += tone[: end - s]
    return normalize(edge_fades(buf, fade_out_ms=180.0), -4.8)


def call_wood_block() -> np.ndarray:
    # Wooden phrase G4-B4-D5 repeated, gentle decay.
    pattern = [
        (G4, 0.00, 0.40),
        (B4, 0.18, 0.40),
        (D5, 0.36, 0.50),
        (B4, 0.60, 0.50),
        (G4, 0.85, 0.70),
        (G4, 1.45, 0.45),
        (B4, 1.65, 0.45),
        (D5, 1.88, 0.55),
        (G4, 2.20, 0.70),
    ]
    n = int(2.9 * SR)
    buf = np.zeros(n, dtype=np.float64)
    for f, start, dur in pattern:
        tone = warm_mallet(f, dur, decay=6.5) * 0.85
        s = int(start * SR)
        end = min(s + len(tone), n)
        buf[s:end] += tone[: end - s]
    return normalize(edge_fades(buf, fade_out_ms=120.0), -5.0)


def call_sparkle() -> np.ndarray:
    # Sparkle arpeggio C6 E6 G6 with shimmer cascade.
    pattern = [
        (C6, 0.00, 1.4),
        (E6, 0.20, 1.4),
        (G6, 0.42, 1.5),
        (E6, 0.72, 1.4),
        (C6, 1.05, 1.7),
        (G6, 1.45, 1.5),
        (E6, 1.80, 1.7),
    ]
    n = int(3.0 * SR)
    buf = np.zeros(n, dtype=np.float64)
    for f, start, dur in pattern:
        tone = bell_fm(f, dur, mod_ratio=2.5, mod_index=1.4, decay=2.4) * 0.55
        s = int(start * SR)
        end = min(s + len(tone), n)
        buf[s:end] += tone[: end - s]
    return normalize(edge_fades(buf, fade_out_ms=160.0), -5.0)


def call_airy_note() -> np.ndarray:
    # Sustained breathy phrase F5 → A5 → C6 with pad-like tail.
    notes = [(F5, 0.00, 1.4), (A5, 0.55, 1.4), (C6, 1.10, 2.0)]
    n = int(3.1 * SR)
    buf = np.zeros(n, dtype=np.float64)
    for f, start, dur in notes:
        tone = soft_tone(f, dur, attack=0.10, release=0.5,
                         harmonics=((1.5, 0.18), (2.0, 0.10))) * 0.7
        s = int(start * SR)
        end = min(s + len(tone), n)
        buf[s:end] += tone[: end - s]
    return normalize(edge_fades(buf, fade_out_ms=220.0), -4.8)


def call_tap_tone() -> np.ndarray:
    # Polite repeated taps with breathing pauses.
    pattern = [
        (A5, 0.00),
        (A5, 0.30),
        (A5, 0.60),
        (A5, 1.10),
        (A5, 1.40),
        (A5, 1.70),
        (A5, 2.20),
        (A5, 2.50),
    ]
    n = int(2.9 * SR)
    buf = np.zeros(n, dtype=np.float64)
    for f, start in pattern:
        tone = soft_tone(f, 0.18, attack=0.005, release=0.10) * 0.8
        s = int(start * SR)
        end = min(s + len(tone), n)
        buf[s:end] += tone[: end - s]
    return normalize(edge_fades(buf, fade_out_ms=100.0), -5.0)


# --- Lo-fi family (длиннее, мелодичнее, кинематографичный профессиональный фид) ---

def call_lofi_keys() -> np.ndarray:
    # Rhodes-progressия Cmaj7 → Fmaj9 → Am7 → G — классический лофи-loop.
    progression = [
        ([C4, E4, G4, B4], 0.00, 0.85),   # Cmaj7
        ([F4, A4, C5, E5], 0.75, 0.85),   # Fmaj9 (без 9 для краткости)
        ([A3, C4, E4, G4], 1.50, 0.85),   # Am7
        ([G3, B4, D5, F5], 2.25, 0.95),   # G7
    ]
    n = int(3.4 * SR)
    buf = np.zeros(n, dtype=np.float64)
    for chord, start, dur in progression:
        block = chord_stack(chord, dur, attack=0.020, release=0.40,
                            timbre='rhodes', decay=1.4)
        s = int(start * SR)
        end = min(s + len(block), n)
        buf[s:end] += block[: end - s] * 0.85
    sig = tape_saturate(lp_filter(buf, alpha=0.20), drive=1.5, mix=0.55)
    return normalize(edge_fades(sig, fade_out_ms=150.0), -4.8)


def call_tape_chime() -> np.ndarray:
    # Серия мягких bell-аккордов через tape-фильтр + vibrato.
    n = int(3.2 * SR)
    buf = np.zeros(n, dtype=np.float64)
    sequence = [
        ([C5, E5, G5], 0.00, 1.4),
        ([D5, F5, A5], 0.60, 1.4),
        ([E5, G5, B5], 1.20, 1.4),
        ([C5, E5, G5], 1.80, 1.6),
    ]
    for chord, start, dur in sequence:
        block = chord_stack(chord, dur, attack=0.010, release=0.45,
                            timbre='rhodes', decay=1.6)
        s = int(start * SR)
        end = min(s + len(block), n)
        buf[s:end] += block[: end - s] * 0.6
    # Лёгкий vibrato на финальной фазе.
    t = np.arange(n) / SR
    buf = buf * (1.0 + 0.004 * np.sin(2 * np.pi * 4.5 * t))
    sig = tape_saturate(lp_filter(buf, alpha=0.26), drive=1.3, mix=0.5)
    return normalize(edge_fades(sig, fade_out_ms=180.0), -4.8)


def call_dream_pad() -> np.ndarray:
    # Sustained ambient pad: Fmaj9 → Cmaj7 → Dm9 длинный crossfade.
    n = int(3.6 * SR)
    buf = np.zeros(n, dtype=np.float64)
    pads = [
        ([F4, A4, C5, E5, G5], 0.00, 2.0),
        ([C4, E4, G4, B4, D5], 1.40, 2.0),
        ([D4, F4, A4, C5, E5], 2.50, 1.6),
    ]
    for chord, start, dur in pads:
        block = chord_stack(chord, dur, attack=0.25, release=0.7,
                            timbre='pad', decay=0.5)
        s = int(start * SR)
        end = min(s + len(block), n)
        buf[s:end] += block[: end - s] * 0.55
    sig = lp_filter(buf, alpha=0.22)
    return normalize(edge_fades(sig, fade_in_ms=20, fade_out_ms=240.0), -5.2)


def call_chill_arp() -> np.ndarray:
    # Арпеджио Dm9 → Am7 → Fmaj7 в верхнем регистре, Rhodes lo-fi.
    pattern = [
        # (note, start)
        (D5, 0.00), (F5, 0.18), (A5, 0.36), (C6, 0.54),
        (A5, 0.78), (E5, 0.96), (C5, 1.14),
        (E5, 1.40), (G5, 1.58), (B5, 1.76),
        (G5, 2.00), (E5, 2.18), (C5, 2.36),
        (F5, 2.60), (A5, 2.78), (C6, 2.96),
    ]
    n = int(3.5 * SR)
    buf = np.zeros(n, dtype=np.float64)
    for f, start in pattern:
        tone = rhodes_note(f, 0.60, decay=2.2)
        s = int(start * SR)
        end = min(s + len(tone), n)
        buf[s:end] += tone[: end - s] * 0.7
    sig = tape_saturate(lp_filter(buf, alpha=0.24), drive=1.3, mix=0.5)
    return normalize(edge_fades(sig, fade_out_ms=160.0), -5.0)


def call_velvet_pulse() -> np.ndarray:
    # Пульсирующий Fmaj9 на четверти + sub-bass F2, тёплый и кинематографичный.
    n = int(3.4 * SR)
    buf = np.zeros(n, dtype=np.float64)
    beats = [0.00, 0.55, 1.10, 1.65, 2.20, 2.75]
    for start in beats:
        chord = chord_stack([F4, A4, C5, E5], 0.50, attack=0.015,
                            release=0.30, timbre='rhodes', decay=2.4)
        s = int(start * SR)
        end = min(s + len(chord), n)
        buf[s:end] += chord[: end - s] * 0.7
    # Sub-bass F3 длинный.
    sub_t = t_axis(3.2)
    sub = np.sin(2 * np.pi * F3 * sub_t) * 0.32 * _envelope(len(sub_t), 0.15, 0.6)
    buf[: len(sub)] += sub
    sig = tape_saturate(lp_filter(buf, alpha=0.22), drive=1.4, mix=0.55)
    return normalize(edge_fades(sig, fade_out_ms=180.0), -4.8)


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
    """Write mono (1D) or stereo (N,2) audio to 16-bit PCM WAV."""
    pcm = np.clip(audio, -1.0, 1.0)
    if pcm.ndim == 1:
        nch = 1
        frames = (pcm * 32767.0).astype(np.int16)
    else:
        nch = pcm.shape[1]
        # shape (N, nch) → reshape(-1) даёт interleaved order L0,R0,L1,R1,...
        frames = (pcm * 32767.0).astype(np.int16).reshape(-1)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(nch)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(frames.tobytes())


def wav_to_mp3(wav_path: Path, mp3_path: Path, bitrate: str = "128k") -> None:
    subprocess.run(
        [
            "ffmpeg", "-y", "-loglevel", "error",
            "-i", str(wav_path),
            "-codec:a", "libmp3lame", "-b:a", bitrate,
            str(mp3_path),
        ],
        check=True,
    )


# Variant-specific reverb caches (создаются один раз).
_IR_MESSAGE: np.ndarray | None = None
_IR_CALL: np.ndarray | None = None
_IR_PING: np.ndarray | None = None


def _ensure_irs() -> None:
    global _IR_MESSAGE, _IR_CALL, _IR_PING
    if _IR_MESSAGE is None:
        # Короткая «комната» для сообщений — тёплая, ~180 мс.
        _IR_MESSAGE = build_ir(duration_s=0.22, rt60_s=0.18, seed=11)
        # Просторный «зал» для звонков — длиннее, более глубокий.
        _IR_CALL = build_ir(duration_s=0.50, rt60_s=0.42, seed=23)
        # Очень короткий plate-like для конференц-пинга.
        _IR_PING = build_ir(duration_s=0.12, rt60_s=0.10, seed=7)


# Какие пресеты лучше воспринимаются с уменьшенным reverb (сухие/деревянные).
_DRY_PRESETS = {"marimba_tap", "wood_block", "tap_tone"}

# Lo-fi пресеты — больше реверба для атмосферности, меньше limiter punch.
_LOFI_PRESETS = {"lofi_keys", "tape_chime", "dream_pad", "chill_arp", "velvet_pulse"}


def emit(rel_path: str, audio: np.ndarray) -> None:
    """Apply post-processing (reverb → stereo widening → soft limit), encode."""
    _ensure_irs()

    # Выбор IR и базовой влажности по variant.
    if rel_path.startswith("ringtones/messages/"):
        ir = _IR_MESSAGE
        wet = 0.22
        delay_ms = 7.0
    elif rel_path.startswith("ringtones/calls/"):
        ir = _IR_CALL
        wet = 0.30
        delay_ms = 11.0
    else:
        ir = _IR_PING
        wet = 0.18
        delay_ms = 5.0

    # Сухие пресеты — режем reverb, чтобы wood/marimba/tap не «плыли».
    preset_id = Path(rel_path).stem
    if preset_id in _DRY_PRESETS:
        wet *= 0.5
    elif preset_id in _LOFI_PRESETS:
        # Lo-fi любит чуть больше пространства.
        wet = min(wet * 1.25, 0.40)

    processed = apply_reverb(audio, ir, wet=wet)
    processed = widen_stereo(processed, delay_ms=delay_ms, gain_r=0.86)
    processed = soft_limit(processed, threshold=0.92)

    web_path = OUT_WEB / f"{rel_path}.mp3"
    mobile_path = OUT_MOBILE / f"{rel_path}.mp3"
    tmp_wav = web_path.with_suffix(".wav")
    write_wav(tmp_wav, processed)
    wav_to_mp3(tmp_wav, web_path, bitrate="128k")
    tmp_wav.unlink()
    shutil.copyfile(web_path, mobile_path)
    dur = len(processed) / SR
    print(f"  {rel_path}.mp3  dur={dur:.2f}s  size={web_path.stat().st_size} B")


def main() -> int:
    ensure_dirs()

    print("Messages (short, single soft signals):")
    emit("ringtones/messages/classic_chime", msg_classic_chime())
    emit("ringtones/messages/gentle_bells", msg_gentle_bells())
    emit("ringtones/messages/marimba_tap", msg_marimba_tap())
    emit("ringtones/messages/soft_pulse", msg_soft_pulse())
    emit("ringtones/messages/ascending_chord", msg_ascending_chord())
    emit("ringtones/messages/glass_drop", msg_glass_drop())
    emit("ringtones/messages/wood_block", msg_wood_block())
    emit("ringtones/messages/sparkle", msg_sparkle())
    emit("ringtones/messages/airy_note", msg_airy_note())
    emit("ringtones/messages/tap_tone", msg_tap_tone())
    emit("ringtones/messages/lofi_keys", msg_lofi_keys())
    emit("ringtones/messages/tape_chime", msg_tape_chime())
    emit("ringtones/messages/dream_pad", msg_dream_pad())
    emit("ringtones/messages/chill_arp", msg_chill_arp())
    emit("ringtones/messages/velvet_pulse", msg_velvet_pulse())

    print("\nCalls (longer, mellow):")
    emit("ringtones/calls/classic_chime", call_classic_chime())
    emit("ringtones/calls/gentle_bells", call_gentle_bells())
    emit("ringtones/calls/marimba_tap", call_marimba_tap())
    emit("ringtones/calls/soft_pulse", call_soft_pulse())
    emit("ringtones/calls/ascending_chord", call_ascending_chord())
    emit("ringtones/calls/glass_drop", call_glass_drop())
    emit("ringtones/calls/wood_block", call_wood_block())
    emit("ringtones/calls/sparkle", call_sparkle())
    emit("ringtones/calls/airy_note", call_airy_note())
    emit("ringtones/calls/tap_tone", call_tap_tone())
    emit("ringtones/calls/lofi_keys", call_lofi_keys())
    emit("ringtones/calls/tape_chime", call_tape_chime())
    emit("ringtones/calls/dream_pad", call_dream_pad())
    emit("ringtones/calls/chill_arp", call_chill_arp())
    emit("ringtones/calls/velvet_pulse", call_velvet_pulse())

    print("\nConference ping:")
    emit("conference/hand_raise", hand_raise_ping())

    print("\nDone.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
