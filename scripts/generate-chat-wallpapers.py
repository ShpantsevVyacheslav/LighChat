#!/usr/bin/env python3
"""Generate built-in chat wallpapers for LighChat.

Outputs 8 concepts x light/dark = 16 portrait WebP files (1440x2880 each)
into both `public/wallpapers/` (web) and `mobile/app/assets/wallpapers/`
(Flutter). Each composition reuses the brand mascots' canonical geometry
(lighthouse / keeper / crab) and the brand palette
(navy #1E3A5F + coral #F4A12C).

Re-run after editing — files are overwritten in place.
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

W, H = 1440, 2880
ROOT = Path(__file__).resolve().parent.parent
OUT_WEB = ROOT / "public" / "wallpapers"
OUT_MOBILE = ROOT / "mobile" / "app" / "assets" / "wallpapers"

NAVY = (30, 58, 95)
NAVY_DARK = (14, 33, 56)
CORAL = (244, 161, 44)
CORAL_DEEP = (220, 130, 30)
WHITE = (255, 255, 255)

# Aspect ratios (height/width) match each mascot's natural bounding box so
# `stamp()` doesn't pad the layer with tall empty space (which previously caused
# offset/clipping artefacts).
LH_LIGHTHOUSE = 2.05
LH_KEEPER = 1.65
LH_CRAB = 0.65


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def vertical_gradient(size, top, bottom):
    w, h = size
    img = Image.new("RGB", size, top)
    d = ImageDraw.Draw(img)
    for y in range(h):
        c = lerp(top, bottom, y / max(h - 1, 1))
        d.line([(0, y), (w, y)], fill=c)
    return img


def diagonal_gradient(size, top_left, bottom_right):
    w, h = size
    img = Image.new("RGB", size, top_left)
    px = img.load()
    diag = w + h
    for y in range(h):
        for x in range(w):
            t = (x + y) / diag
            px[x, y] = lerp(top_left, bottom_right, t)
    return img


def radial_glow(size, center, radius, color, alpha=200):
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    cx, cy = center
    steps = 24
    for i in range(steps, 0, -1):
        r = radius * (i / steps)
        a = int(alpha * (1 - i / steps) ** 2)
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color + (a,))
    return layer.filter(ImageFilter.GaussianBlur(radius=radius * 0.05))


# ---------------------------------------------------------------------------
# Mascots — coords mirror LighthousePainter / KeeperPainter / CrabPainter
# (see mobile/app/lib/features/welcome/ui/welcome_painters.dart). The internal
# coordinate ranges of each mascot are normalised so the source canvas equals
# the mascot's *bounding box* (no padding) — callers must request a layer of
# size (W*scale, W*scale*aspect) to keep proportions.
# ---------------------------------------------------------------------------


def draw_lighthouse(size, navy=NAVY, coral=CORAL, body=WHITE):
    """Lighthouse drawn into a 1×2.05 portrait box.

    Original painter coords (y: 0.118→0.97, x: 0.31→0.74) are remapped so the
    full painter spans the entire layer height (kept y-domain 0.058→1.00 to
    leave a little headroom for the spire tip).
    """
    w, h = size
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    stroke = max(2, int(w * 0.045))

    def poly(points, fill, outline=None, width=0):
        pts = [(int(w * x), int(h * y)) for x, y in points]
        d.polygon(pts, fill=fill, outline=outline, width=width)

    def rect(x, y, rw, rh, fill):
        d.rectangle([int(w * x), int(h * y), int(w * (x + rw)), int(h * (y + rh))], fill=fill)

    # Постамент
    poly([(0.04, 0.86), (0.92, 0.86), (1.00, 0.97), (-0.02, 0.97)], navy + (255,))
    # Башня
    poly([(0.14, 0.36), (0.84, 0.36), (0.97, 0.86), (-0.02, 0.86)], body + (255,), navy + (255,), stroke)
    # Coral диагональ
    poly([(0.52, 0.43), (0.71, 0.43), (0.46, 0.81), (0.27, 0.81)], coral + (255,))
    # Балкон
    rect(0.10, 0.34, 0.80, 0.020, navy + (255,))
    # Фонарная комната + окно
    rect(0.20, 0.23, 0.60, 0.115, navy + (255,))
    rect(0.30, 0.255, 0.40, 0.066, coral + (255,))
    # Купол
    rect(0.13, 0.193, 0.74, 0.038, navy + (255,))
    rect(0.34, 0.128, 0.32, 0.066, navy + (255,))
    # Шпиль
    rect(0.48, 0.054, 0.04, 0.072, navy + (255,))
    d.ellipse(
        [int(w * 0.44), int(h * 0.030), int(w * 0.56), int(h * 0.075)],
        fill=navy + (255,),
    )
    return layer


def draw_keeper(size, coat=(10, 22, 38), scarf=CORAL, lantern=CORAL, lantern_up=False):
    """Keeper drawn into a 1×1.65 portrait box. If `lantern_up=True`, the right
    hand is raised holding the lantern (used for the 'watch' concept)."""
    w, h = size
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    def poly(points, fill):
        d.polygon([(int(w * x), int(h * y)) for x, y in points], fill=fill)

    def rect(x, y, rw, rh, fill):
        d.rectangle([int(w * x), int(h * y), int(w * (x + rw)), int(h * (y + rh))], fill=fill)

    def circle(cx, cy, r_x, r_y, fill):
        d.ellipse(
            [int(w * (cx - r_x)), int(h * (cy - r_y)),
             int(w * (cx + r_x)), int(h * (cy + r_y))],
            fill=fill,
        )

    # Ноги
    poly([(0.36, 1.00), (0.32, 0.66), (0.48, 0.66), (0.46, 1.00)], coat + (255,))
    poly([(0.54, 1.00), (0.52, 0.66), (0.68, 0.66), (0.64, 1.00)], coat + (255,))
    # Пальто (трапеция)
    poly([(0.20, 0.70), (0.80, 0.70), (0.74, 0.36), (0.26, 0.36)], coat + (255,))
    # Шарф
    rect(0.26, 0.33, 0.48, 0.045, scarf + (255,))
    # Голова
    circle(0.50, 0.255, 0.090, 0.060, (240, 217, 187, 255))
    # Шляпа (поля + корона)
    poly([(0.20, 0.215), (0.80, 0.215), (0.74, 0.195), (0.26, 0.195)], coat + (255,))
    rect(0.34, 0.110, 0.32, 0.075, coat + (255,))
    if lantern_up:
        # Правая рука высоко поднята с фонарём
        poly([(0.74, 0.40), (0.82, 0.40), (0.90, 0.05), (0.82, 0.02)], coat + (255,))
        rect(0.80, 0.00, 0.13, 0.060, lantern + (255,))
        # Левая рука — спокойно вниз
        poly([(0.18, 0.42), (0.26, 0.42), (0.30, 0.66), (0.22, 0.66)], coat + (255,))
    else:
        # Левая рука с фонарём
        poly([(0.18, 0.42), (0.26, 0.42), (0.30, 0.66), (0.22, 0.66)], coat + (255,))
        rect(0.16, 0.66, 0.16, 0.055, lantern + (255,))
        # Правая рука — приветственный замах
        poly([(0.74, 0.42), (0.82, 0.42), (0.90, 0.18), (0.84, 0.13)], coat + (255,))
    return layer


def draw_crab(size, body=CORAL, eye=(255, 255, 255), pupil=(20, 20, 30)):
    """Crab drawn into a 1×0.65 horizontal box (wider than tall — matches the
    canonical mascot proportions)."""
    w, h = size
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    def rect(x, y, rw, rh, fill):
        d.rectangle([int(w * x), int(h * y), int(w * (x + rw)), int(h * (y + rh))], fill=fill)

    def ellipse(cx, cy, r_x, r_y, fill):
        d.ellipse(
            [int(w * (cx - r_x)), int(h * (cy - r_y)),
             int(w * (cx + r_x)), int(h * (cy + r_y))],
            fill=fill,
        )

    # Лапки (4 на каждый бок)
    for i, x in enumerate([0.10, 0.20, 0.78, 0.88]):
        rect(x, 0.55, 0.040, 0.40 + (i % 2) * 0.08, body + (255,))
    # Тело
    ellipse(0.50, 0.55, 0.32, 0.30, body + (255,))
    # Клешни-волны
    ellipse(0.10, 0.25, 0.10, 0.10, body + (255,))
    ellipse(0.90, 0.25, 0.10, 0.10, body + (255,))
    rect(0.13, 0.30, 0.05, 0.30, body + (255,))
    rect(0.82, 0.30, 0.05, 0.30, body + (255,))
    # Глаза
    ellipse(0.40, 0.48, 0.06, 0.085, eye + (255,))
    ellipse(0.60, 0.48, 0.07, 0.10, eye + (255,))
    ellipse(0.40, 0.49, 0.026, 0.038, pupil + (255,))
    ellipse(0.60, 0.49, 0.030, 0.044, pupil + (255,))
    # Улыбка
    d.arc(
        [int(w * 0.43), int(h * 0.62), int(w * 0.57), int(h * 0.72)],
        start=0,
        end=180,
        fill=pupil + (255,),
        width=max(2, int(w * 0.012)),
    )
    return layer


def stamp(base, layer_fn, fx, fy, scale, aspect=1.4, **kwargs):
    """Composite a mascot at fractional center position with the given scale.

    `scale` is the fraction of base width that the mascot occupies (its layer
    width). `aspect` is the mascot's natural height/width ratio.
    """
    bw, bh = base.size
    lw = int(bw * scale)
    lh = int(lw * aspect)
    sub = layer_fn((lw, lh), **kwargs)
    base.paste(sub, (int(bw * fx - lw / 2), int(bh * fy - lh / 2)), sub)


# ---------------------------------------------------------------------------
# Background helpers
# ---------------------------------------------------------------------------


def starfield(size, density=400, color=(255, 255, 255), seed=1):
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    rng = random.Random(seed)
    w, h = size
    for _ in range(density):
        x = rng.randint(0, w - 1)
        y = rng.randint(0, int(h * 0.7))
        r = rng.choice([1, 1, 1, 2, 2, 3])
        a = rng.randint(120, 255)
        d.ellipse([x - r, y - r, x + r, y + r], fill=color + (a,))
    return layer


def aurora_bands(size, palette):
    w, h = size
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    for i, color in enumerate(palette):
        band = Image.new("RGBA", size, (0, 0, 0, 0))
        bd = ImageDraw.Draw(band)
        base_y = int(h * (0.18 + i * 0.07))
        for x in range(0, w + 30, 30):
            wave = math.sin((x / w) * math.pi * (2 + i * 0.4) + i) * 80
            y = base_y + wave
            bd.line(
                [(x, y), (x, y + int(h * 0.12))],
                fill=color + (130,),
                width=42,
            )
        band = band.filter(ImageFilter.GaussianBlur(radius=60))
        layer = Image.alpha_composite(layer, band)
    return layer


def waves_overlay(size, color, count=8, alpha=110, top=0.55):
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    w, h = size
    for i in range(count):
        y = int(h * (top + i * 0.05))
        pts = []
        for x in range(0, w + 30, 30):
            wave = math.sin((x / w) * math.pi * 3 + i * 0.7) * (h * 0.014)
            pts.append((x, y + wave))
        pts.append((w, h))
        pts.append((0, h))
        d.polygon(pts, fill=color + (max(20, alpha - i * 10),))
    return layer


def rain_streaks(size, color=(200, 220, 255), count=120, seed=4):
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    rng = random.Random(seed)
    w, h = size
    for _ in range(count):
        x = rng.randint(-50, w)
        y = rng.randint(0, h)
        length = rng.randint(20, 60)
        d.line([(x, y), (x - 10, y + length)], fill=color + (140,), width=2)
    return layer


def vignette(size, strength=0.4):
    w, h = size
    layer = Image.new("L", size, 0)
    d = ImageDraw.Draw(layer)
    steps = 30
    for i in range(steps):
        r = int(max(w, h) * (1 - i / steps) * 0.9)
        a = int(255 * strength * (i / steps) ** 2)
        d.ellipse([w // 2 - r, h // 2 - r, w // 2 + r, h // 2 + r], fill=255 - a)
    return layer.filter(ImageFilter.GaussianBlur(radius=100))


# ---------------------------------------------------------------------------
# Concepts (8)
# ---------------------------------------------------------------------------


def concept_lighthouse_dawn(theme):
    if theme == "light":
        bg = vertical_gradient((W, H), (255, 220, 188), (212, 232, 235))
    else:
        bg = vertical_gradient((W, H), (20, 30, 56), (54, 28, 24))
    sun = radial_glow((W, H), (W // 2, int(H * 0.40)), int(H * 0.32),
                      (255, 200, 120) if theme == "light" else (255, 170, 90), alpha=180)
    bg.paste(sun, (0, 0), sun)
    # Скала
    rock = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    rd = ImageDraw.Draw(rock)
    rd.polygon(
        [(0, int(H * 0.86)), (int(W * 0.30), int(H * 0.76)),
         (int(W * 0.70), int(H * 0.78)), (W, int(H * 0.84)), (W, H), (0, H)],
        fill=(NAVY_DARK if theme == "dark" else NAVY) + (230,),
    )
    bg.paste(rock, (0, 0), rock)
    stamp(
        bg, draw_lighthouse, 0.50, 0.58, scale=0.26, aspect=LH_LIGHTHOUSE,
        navy=NAVY_DARK if theme == "dark" else NAVY,
        coral=CORAL,
        body=(245, 240, 230) if theme == "light" else (220, 200, 175),
    )
    return bg.convert("RGB")


def concept_keeper_watch(theme):
    """Хранитель с поднятым фонарём смотрит на ночное/предрассветное море
    в сторону маяка."""
    if theme == "light":
        bg = vertical_gradient((W, H), (210, 226, 244), (244, 220, 196))
    else:
        bg = vertical_gradient((W, H), (8, 16, 34), (24, 38, 60))
    if theme == "dark":
        bg.paste(starfield((W, H), density=320, seed=11), (0, 0),
                 starfield((W, H), density=320, seed=11))
    # Море-горизонт
    sea = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sea)
    sea_color = (80, 120, 150) if theme == "light" else (16, 32, 56)
    sd.rectangle([0, int(H * 0.62), W, H], fill=sea_color + (255,))
    bg.paste(sea, (0, 0), sea)
    bg.paste(waves_overlay((W, H), (255, 255, 255) if theme == "light" else (90, 130, 170),
                           count=5, alpha=80, top=0.64),
             (0, 0),
             waves_overlay((W, H), (255, 255, 255) if theme == "light" else (90, 130, 170),
                           count=5, alpha=80, top=0.64))
    # Дальний маяк
    stamp(bg, draw_lighthouse, 0.82, 0.55, scale=0.10, aspect=LH_LIGHTHOUSE,
          navy=NAVY, coral=CORAL, body=(245, 240, 230))
    # Свечение поднятого фонаря — рисуем под керпером
    glow = radial_glow((W, H), (int(W * 0.50), int(H * 0.50)), int(H * 0.18),
                       CORAL, alpha=210)
    bg.paste(glow, (0, 0), glow)
    # Хранитель крупно с поднятым фонарём
    stamp(bg, draw_keeper, 0.40, 0.78, scale=0.30, aspect=LH_KEEPER,
          coat=NAVY_DARK if theme == "dark" else NAVY,
          scarf=CORAL, lantern=CORAL, lantern_up=True)
    return bg.convert("RGB")


def concept_crab_shore(theme):
    if theme == "light":
        bg = vertical_gradient((W, H), (200, 230, 235), (244, 220, 178))
    else:
        bg = vertical_gradient((W, H), (10, 22, 40), (40, 38, 56))
    # Море
    sea = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sea)
    sea_color = (90, 140, 165) if theme == "light" else (30, 60, 90)
    sd.rectangle([0, int(H * 0.55), W, int(H * 0.78)], fill=sea_color + (230,))
    bg.paste(sea, (0, 0), sea)
    bg.paste(waves_overlay((W, H), (255, 255, 255), count=4, alpha=80, top=0.55),
             (0, 0),
             waves_overlay((W, H), (255, 255, 255), count=4, alpha=80, top=0.55))
    # Песок (нижняя четверть)
    sand = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sdd = ImageDraw.Draw(sand)
    sand_color = (235, 215, 175) if theme == "light" else (50, 40, 60)
    sdd.rectangle([0, int(H * 0.78), W, H], fill=sand_color + (255,))
    bg.paste(sand, (0, 0), sand)
    # Дальний маяк
    stamp(bg, draw_lighthouse, 0.78, 0.46, scale=0.07, aspect=LH_LIGHTHOUSE,
          navy=NAVY, coral=CORAL, body=(245, 240, 230))
    # Крабик внизу — с корректным aspect (шире чем высоко)
    stamp(bg, draw_crab, 0.5, 0.88, scale=0.34, aspect=LH_CRAB, body=CORAL)
    return bg.convert("RGB")


def concept_lighthouse_aurora(theme):
    if theme == "light":
        bg = vertical_gradient((W, H), (235, 240, 250), (215, 235, 240))
        palette = [(140, 200, 220), (180, 180, 230), (210, 170, 230)]
    else:
        bg = vertical_gradient((W, H), (4, 8, 22), (14, 26, 50))
        palette = [(80, 220, 180), (120, 90, 220), (60, 200, 200)]
    if theme == "dark":
        bg.paste(starfield((W, H), density=400, seed=22), (0, 0),
                 starfield((W, H), density=400, seed=22))
    bg.paste(aurora_bands((W, H), palette), (0, 0), aurora_bands((W, H), palette))
    # Скала-холм под маяком
    rock = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    rd = ImageDraw.Draw(rock)
    rd.polygon(
        [(0, int(H * 0.82)), (int(W * 0.40), int(H * 0.74)),
         (int(W * 0.60), int(H * 0.74)), (W, int(H * 0.82)), (W, H), (0, H)],
        fill=(NAVY_DARK if theme == "dark" else (90, 110, 140)) + (240,),
    )
    bg.paste(rock, (0, 0), rock)
    stamp(bg, draw_lighthouse, 0.5, 0.56, scale=0.22, aspect=LH_LIGHTHOUSE,
          navy=NAVY_DARK if theme == "dark" else NAVY, coral=CORAL,
          body=(240, 235, 220) if theme == "light" else (210, 200, 180))
    return bg.convert("RGB")


def concept_keeper_cabin(theme):
    """Хранитель внутри маленького домика с тёплым окном, дождь."""
    if theme == "light":
        bg = vertical_gradient((W, H), (200, 215, 230), (170, 188, 210))
    else:
        bg = vertical_gradient((W, H), (10, 16, 30), (20, 28, 46))
    # Дом
    wall_color = (60, 70, 95) if theme == "dark" else (130, 145, 165)
    roof_color = (NAVY_DARK if theme == "dark" else NAVY)
    wall = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    wd = ImageDraw.Draw(wall)
    # Стена
    wd.rectangle([int(W * 0.15), int(H * 0.40), int(W * 0.85), int(H * 0.90)],
                 fill=wall_color + (255,))
    # Крыша
    wd.polygon(
        [(int(W * 0.10), int(H * 0.42)), (int(W * 0.50), int(H * 0.26)),
         (int(W * 0.90), int(H * 0.42))],
        fill=roof_color + (255,),
    )
    # Окно (тёплое)
    wd.rectangle([int(W * 0.38), int(H * 0.50), int(W * 0.62), int(H * 0.72)],
                 fill=(70, 50, 40, 255))
    wd.rectangle([int(W * 0.41), int(H * 0.53), int(W * 0.59), int(H * 0.69)],
                 fill=(230, 160, 60, 255))
    # Дверь под окном
    wd.rectangle([int(W * 0.45), int(H * 0.74), int(W * 0.55), int(H * 0.90)],
                 fill=roof_color + (255,))
    bg.paste(wall, (0, 0), wall)
    # Свечение от окна
    glow = radial_glow((W, H), (W // 2, int(H * 0.61)), int(H * 0.16),
                       (240, 170, 90), alpha=160)
    bg.paste(glow, (0, 0), glow)
    # Маленький keeper в окне (силуэт)
    stamp(bg, draw_keeper, 0.50, 0.66, scale=0.10, aspect=LH_KEEPER,
          coat=NAVY_DARK, scarf=NAVY_DARK, lantern=NAVY_DARK)
    # Дождь
    bg.paste(rain_streaks((W, H), count=180, seed=7), (0, 0),
             rain_streaks((W, H), count=180, seed=7))
    return bg.convert("RGB")


def concept_crew_shore(theme):
    """Все три маскота на берегу. В dark-варианте керпер виден за счёт
    тёплого ореола от поднятого фонаря."""
    if theme == "light":
        bg = vertical_gradient((W, H), (242, 224, 200), (200, 220, 232))
    else:
        bg = vertical_gradient((W, H), (8, 14, 30), (30, 22, 40))
    if theme == "dark":
        bg.paste(starfield((W, H), density=260, seed=33), (0, 0),
                 starfield((W, H), density=260, seed=33))
    # Берег
    shore = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shore)
    shore_color = (210, 180, 130) if theme == "light" else (40, 30, 50)
    sd.polygon([(0, int(H * 0.78)), (W, int(H * 0.76)), (W, H), (0, H)],
               fill=shore_color + (255,))
    bg.paste(shore, (0, 0), shore)
    # Дальний маяк
    stamp(bg, draw_lighthouse, 0.80, 0.55, scale=0.16, aspect=LH_LIGHTHOUSE,
          navy=NAVY_DARK if theme == "dark" else NAVY, coral=CORAL,
          body=(240, 235, 220) if theme == "light" else (210, 200, 180))
    # Луч маяка (мягкий glow)
    beam = radial_glow((W, H), (int(W * 0.80), int(H * 0.46)), int(H * 0.22),
                       CORAL, alpha=130)
    bg.paste(beam, (0, 0), beam)
    # Тёплый ореол от фонаря керпера (под керпером)
    keeper_glow = radial_glow((W, H), (int(W * 0.30), int(H * 0.62)),
                              int(H * 0.16), CORAL, alpha=190)
    bg.paste(keeper_glow, (0, 0), keeper_glow)
    # Keeper — в dark теме используем чуть светлее navy для контраста
    keeper_coat = (40, 60, 95) if theme == "dark" else NAVY
    stamp(bg, draw_keeper, 0.30, 0.78, scale=0.22, aspect=LH_KEEPER,
          coat=keeper_coat, scarf=CORAL, lantern=CORAL, lantern_up=True)
    # Крабик
    stamp(bg, draw_crab, 0.55, 0.92, scale=0.16, aspect=LH_CRAB, body=CORAL)
    return bg.convert("RGB")


def concept_mark_constellation(theme):
    """Звёзды складываются в силуэт маяка. Звёзды крупные, с halo-glow."""
    if theme == "light":
        bg = vertical_gradient((W, H), (220, 232, 250), (192, 215, 240))
    else:
        bg = vertical_gradient((W, H), (4, 8, 22), (10, 16, 38))
    bg.paste(starfield((W, H), density=500 if theme == "dark" else 180, seed=55),
             (0, 0),
             starfield((W, H), density=500 if theme == "dark" else 180, seed=55))
    # Силуэт маяка точками: повторяем форму lighthouse painter
    coords = [
        (0.500, 0.250),  # шпиль
        (0.440, 0.300), (0.560, 0.300),  # купол по краям
        (0.420, 0.345), (0.580, 0.345),  # фонарная комната края
        (0.420, 0.395), (0.580, 0.395),  # балкон края
        (0.405, 0.500), (0.595, 0.500),  # башня середина
        (0.385, 0.625), (0.615, 0.625),  # башня ниже
        (0.365, 0.760), (0.635, 0.760),  # башня основание
        (0.330, 0.840), (0.670, 0.840),  # постамент верх
    ]
    line_pairs = [
        (0, 1), (0, 2), (1, 3), (2, 4), (3, 4), (3, 5), (4, 6),
        (5, 7), (6, 8), (7, 8), (7, 9), (8, 10),
        (9, 11), (10, 12), (11, 12), (11, 13), (12, 14), (13, 14),
    ]
    star_color = (255, 215, 130) if theme == "dark" else (50, 80, 150)
    line_color = star_color
    # Соединяющие линии
    line_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ld = ImageDraw.Draw(line_layer)
    for a, b in line_pairs:
        x1, y1 = int(W * coords[a][0]), int(H * coords[a][1])
        x2, y2 = int(W * coords[b][0]), int(H * coords[b][1])
        ld.line([(x1, y1), (x2, y2)], fill=line_color + (110,), width=3)
    bg.paste(line_layer, (0, 0), line_layer)
    # Halo + сами звёзды
    for fx, fy in coords:
        x, y = int(W * fx), int(H * fy)
        # Halo
        halo = radial_glow((W, H), (x, y), 60, star_color, alpha=220)
        bg.paste(halo, (0, 0), halo)
    star_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(star_layer)
    for fx, fy in coords:
        x, y = int(W * fx), int(H * fy)
        r = 12
        sd.ellipse([x - r, y - r, x + r, y + r], fill=star_color + (255,))
    bg.paste(star_layer, (0, 0), star_layer)
    # Подпись огонька — маленькая coral точка в фонарной комнате
    sd2 = ImageDraw.Draw(bg.convert("RGBA"))
    bg = bg.convert("RGBA")
    coral_pt = radial_glow((W, H), (int(W * 0.5), int(H * 0.345)), 80,
                           CORAL, alpha=200)
    bg = Image.alpha_composite(bg, coral_pt)
    return bg.convert("RGB")


def concept_ocean_waves(theme):
    """Несколько слоёв набегающих волн в фирменной палитре + мягкий coral
    рассвет-полоса по горизонту."""
    if theme == "light":
        bg = vertical_gradient((W, H), (216, 230, 248), (244, 224, 200))
    else:
        bg = vertical_gradient((W, H), (8, 18, 38), (14, 50, 80))
    # Coral мягкий горизонт
    horizon = radial_glow((W, H), (W // 2, int(H * 0.48)), int(W * 0.6),
                          CORAL if theme == "light" else CORAL_DEEP, alpha=130)
    bg.paste(horizon, (0, 0), horizon)
    # Море
    sea = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sea)
    sea_color = (90, 140, 175) if theme == "light" else (16, 44, 78)
    sd.rectangle([0, int(H * 0.52), W, H], fill=sea_color + (255,))
    bg.paste(sea, (0, 0), sea)
    # Слои волн с разной фазой
    for i, (top, alpha, color) in enumerate([
        (0.54, 140, (255, 255, 255) if theme == "light" else (60, 110, 160)),
        (0.62, 130, (210, 230, 245) if theme == "light" else (50, 95, 145)),
        (0.72, 130, (180, 210, 235) if theme == "light" else (40, 80, 130)),
        (0.84, 140, (150, 190, 225) if theme == "light" else (30, 65, 115)),
    ]):
        layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ld = ImageDraw.Draw(layer)
        pts = []
        for x in range(0, W + 20, 20):
            wave = math.sin((x / W) * math.pi * (3 + i * 0.6) + i) * (H * 0.013)
            pts.append((x, int(H * top + wave)))
        pts.append((W, H))
        pts.append((0, H))
        ld.polygon(pts, fill=color + (alpha,))
        bg.paste(layer, (0, 0), layer)
    return bg.convert("RGB")


CONCEPTS = {
    "lighthouse-dawn": concept_lighthouse_dawn,
    "keeper-watch": concept_keeper_watch,
    "crab-shore": concept_crab_shore,
    "lighthouse-aurora": concept_lighthouse_aurora,
    "keeper-cabin": concept_keeper_cabin,
    "crew-shore": concept_crew_shore,
    "mark-constellation": concept_mark_constellation,
    "ocean-waves": concept_ocean_waves,
}


def main():
    OUT_WEB.mkdir(parents=True, exist_ok=True)
    OUT_MOBILE.mkdir(parents=True, exist_ok=True)
    for slug, fn in CONCEPTS.items():
        for theme in ("light", "dark"):
            img = fn(theme)
            # Лёгкая виньетка
            vm = vignette((W, H), strength=0.18 if theme == "light" else 0.35)
            base = img.convert("RGBA")
            overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            overlay.putalpha(vm.point(lambda v: 255 - v))
            base = Image.alpha_composite(base, overlay)
            out = base.convert("RGB")
            for target in (OUT_WEB, OUT_MOBILE):
                path = target / f"{slug}-{theme}.webp"
                out.save(path, "WEBP", quality=82, method=4)
                print(f"  ✓ {path.relative_to(ROOT)} ({path.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
