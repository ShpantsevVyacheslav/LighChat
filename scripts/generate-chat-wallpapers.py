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


# ---------------------------------------------------------------------------
# Telegram-style doodle patterns
# ---------------------------------------------------------------------------
#
# Концепты `doodle-*` — бесшовный фоновый паттерн из мелких фирменных иконок
# на фирменном градиенте. Стилистика — Telegram pattern wallpapers (повторы
# контурных силуэтов с разворотом / разными размерами), но иконки и палитра
# наши: маяк, штурвал, якорь, чайка, ракушка, волна, мини-маскоты LighChat,
# навигационные формулы и компас. Иконки рисуются контуром (stroke без fill)
# с низкой альфой — паттерн читается как фон, а не отвлекает от чата.


def _norm_pts(pts, cx, cy, size):
    return [(cx + x * size, cy + y * size) for x, y in pts]


def icon_lighthouse(d, cx, cy, size, color, alpha=180, width=3):
    """Мини-силуэт маяка (контур)."""
    s = size / 2
    rgba = color + (alpha,)
    # Постамент
    d.polygon(_norm_pts([(-1.0, 1.0), (1.0, 1.0), (0.85, 0.78), (-0.85, 0.78)],
                        cx, cy, s), outline=rgba, width=width)
    # Башня
    d.polygon(_norm_pts([(-0.55, 0.78), (0.55, 0.78), (0.40, -0.20), (-0.40, -0.20)],
                        cx, cy, s), outline=rgba, width=width)
    # Балкон
    d.line(_norm_pts([(-0.55, -0.20), (0.55, -0.20)], cx, cy, s),
           fill=rgba, width=width)
    # Фонарная комната
    d.rectangle([cx - s * 0.30, cy - s * 0.55, cx + s * 0.30, cy - s * 0.20],
                outline=rgba, width=width)
    # Купол + шпиль
    d.line(_norm_pts([(-0.30, -0.55), (0.30, -0.55)], cx, cy, s),
           fill=rgba, width=width)
    d.line(_norm_pts([(0.0, -0.55), (0.0, -0.95)], cx, cy, s),
           fill=rgba, width=width)
    # Лучи света
    for ang_deg in (-60, -30, 30, 60):
        ang = math.radians(ang_deg - 90)
        x2 = cx + math.cos(ang) * s * 0.85
        y2 = cy + math.sin(ang) * s * 0.85
        d.line([(cx, cy - s * 0.40), (x2, y2 - s * 0.20)], fill=rgba, width=width)


def icon_anchor(d, cx, cy, size, color, alpha=180, width=3):
    s = size / 2
    rgba = color + (alpha,)
    # Кольцо
    r = s * 0.18
    d.ellipse([cx - r, cy - s * 0.95, cx + r, cy - s * 0.60], outline=rgba, width=width)
    # Шток
    d.line([(cx, cy - s * 0.60), (cx, cy + s * 0.60)], fill=rgba, width=width)
    # Перекладина
    d.line([(cx - s * 0.50, cy - s * 0.40), (cx + s * 0.50, cy - s * 0.40)],
           fill=rgba, width=width)
    # Дуга-якорь
    d.arc([cx - s * 0.70, cy - s * 0.10, cx + s * 0.70, cy + s * 0.85],
          start=20, end=160, fill=rgba, width=width)
    # Жалa
    d.line([(cx - s * 0.65, cy + s * 0.50), (cx - s * 0.85, cy + s * 0.30)],
           fill=rgba, width=width)
    d.line([(cx + s * 0.65, cy + s * 0.50), (cx + s * 0.85, cy + s * 0.30)],
           fill=rgba, width=width)


def icon_wheel(d, cx, cy, size, color, alpha=180, width=3):
    s = size / 2
    rgba = color + (alpha,)
    # Внешнее кольцо
    d.ellipse([cx - s * 0.85, cy - s * 0.85, cx + s * 0.85, cy + s * 0.85],
              outline=rgba, width=width)
    # Внутреннее кольцо
    d.ellipse([cx - s * 0.30, cy - s * 0.30, cx + s * 0.30, cy + s * 0.30],
              outline=rgba, width=width)
    # 8 спиц с рукоятями
    for i in range(8):
        ang = math.radians(i * 45)
        x1 = cx + math.cos(ang) * s * 0.30
        y1 = cy + math.sin(ang) * s * 0.30
        x2 = cx + math.cos(ang) * s * 1.05
        y2 = cy + math.sin(ang) * s * 1.05
        d.line([(x1, y1), (x2, y2)], fill=rgba, width=width)
        # Рукоять-крестик
        x3 = cx + math.cos(ang) * s * 1.10
        y3 = cy + math.sin(ang) * s * 1.10
        d.ellipse([x3 - s * 0.08, y3 - s * 0.08, x3 + s * 0.08, y3 + s * 0.08],
                  outline=rgba, width=width)


def icon_seagull(d, cx, cy, size, color, alpha=180, width=3):
    s = size / 2
    rgba = color + (alpha,)
    # Две дуги — крылья (M-shape)
    d.arc([cx - s * 0.95, cy - s * 0.15, cx - s * 0.05, cy + s * 0.55],
          start=200, end=340, fill=rgba, width=width)
    d.arc([cx + s * 0.05, cy - s * 0.15, cx + s * 0.95, cy + s * 0.55],
          start=200, end=340, fill=rgba, width=width)


def icon_shell(d, cx, cy, size, color, alpha=180, width=3):
    s = size / 2
    rgba = color + (alpha,)
    # Полукруг-ракушка
    d.arc([cx - s * 0.85, cy - s * 0.30, cx + s * 0.85, cy + s * 1.40],
          start=180, end=360, fill=rgba, width=width)
    # Радиальные складки
    for ang_deg in (180, 200, 220, 240, 260, 280, 300, 320, 340, 360):
        ang = math.radians(ang_deg)
        x2 = cx + math.cos(ang) * s * 0.80
        y2 = cy + s * 0.55 + math.sin(ang) * s * 0.85
        d.line([(cx, cy + s * 0.55), (x2, y2)], fill=rgba, width=width)


def icon_compass(d, cx, cy, size, color, alpha=180, width=3):
    s = size / 2
    rgba = color + (alpha,)
    d.ellipse([cx - s * 0.90, cy - s * 0.90, cx + s * 0.90, cy + s * 0.90],
              outline=rgba, width=width)
    # Стрелка-роза
    d.polygon(_norm_pts([(0, -0.80), (0.18, 0), (0, 0.20), (-0.18, 0)], cx, cy, s),
              outline=rgba, width=width)
    d.polygon(_norm_pts([(0, 0.80), (0.18, 0), (0, -0.20), (-0.18, 0)], cx, cy, s),
              outline=rgba, width=width)
    # Кардиналы (точки N E S W)
    for ang_deg in (0, 90, 180, 270):
        ang = math.radians(ang_deg - 90)
        x = cx + math.cos(ang) * s * 0.78
        y = cy + math.sin(ang) * s * 0.78
        d.ellipse([x - s * 0.08, y - s * 0.08, x + s * 0.08, y + s * 0.08],
                  fill=rgba)


def icon_wave(d, cx, cy, size, color, alpha=180, width=3):
    s = size / 2
    rgba = color + (alpha,)
    pts = []
    for i in range(33):
        t = i / 32
        x = cx + (t - 0.5) * 2 * s * 0.95
        y = cy + math.sin(t * math.pi * 2) * s * 0.30
        pts.append((x, y))
    d.line(pts, fill=rgba, width=width)


def icon_knot(d, cx, cy, size, color, alpha=180, width=3):
    """Морской узел — две перекрещивающиеся петли."""
    s = size / 2
    rgba = color + (alpha,)
    d.arc([cx - s * 0.85, cy - s * 0.85, cx + s * 0.15, cy + s * 0.15],
          start=0, end=360, fill=rgba, width=width)
    d.arc([cx - s * 0.15, cy - s * 0.15, cx + s * 0.85, cy + s * 0.85],
          start=0, end=360, fill=rgba, width=width)
    d.arc([cx - s * 0.15, cy - s * 0.85, cx + s * 0.85, cy + s * 0.15],
          start=180, end=360, fill=rgba, width=width)
    d.arc([cx - s * 0.85, cy - s * 0.15, cx + s * 0.15, cy + s * 0.85],
          start=0, end=180, fill=rgba, width=width)


def icon_lifebuoy(d, cx, cy, size, color, alpha=180, width=3):
    s = size / 2
    rgba = color + (alpha,)
    d.ellipse([cx - s * 0.90, cy - s * 0.90, cx + s * 0.90, cy + s * 0.90],
              outline=rgba, width=width)
    d.ellipse([cx - s * 0.40, cy - s * 0.40, cx + s * 0.40, cy + s * 0.40],
              outline=rgba, width=width)
    # Крестики (4 ручки) на 0/90/180/270
    for ang_deg in (45, 135, 225, 315):
        ang = math.radians(ang_deg)
        x1 = cx + math.cos(ang) * s * 0.40
        y1 = cy + math.sin(ang) * s * 0.40
        x2 = cx + math.cos(ang) * s * 0.90
        y2 = cy + math.sin(ang) * s * 0.90
        d.line([(x1, y1), (x2, y2)], fill=rgba, width=width + 4)


def icon_keeper_mini(d, cx, cy, size, color, alpha=180, width=3):
    """Силуэт-керпер с фонарём (мини)."""
    s = size / 2
    rgba = color + (alpha,)
    # Голова
    d.ellipse([cx - s * 0.20, cy - s * 0.95, cx + s * 0.20, cy - s * 0.55],
              outline=rgba, width=width)
    # Шляпа
    d.line([(cx - s * 0.30, cy - s * 0.78), (cx + s * 0.30, cy - s * 0.78)],
           fill=rgba, width=width)
    d.rectangle([cx - s * 0.15, cy - s * 1.05, cx + s * 0.15, cy - s * 0.78],
                outline=rgba, width=width)
    # Пальто
    d.polygon(_norm_pts([(-0.40, -0.55), (0.40, -0.55), (0.50, 0.40), (-0.50, 0.40)],
                        cx, cy, s), outline=rgba, width=width)
    # Шарф
    d.line([(cx - s * 0.40, cy - s * 0.45), (cx + s * 0.40, cy - s * 0.45)],
           fill=rgba, width=width + 1)
    # Ноги
    d.line([(cx - s * 0.20, cy + s * 0.40), (cx - s * 0.20, cy + s * 0.95)],
           fill=rgba, width=width)
    d.line([(cx + s * 0.20, cy + s * 0.40), (cx + s * 0.20, cy + s * 0.95)],
           fill=rgba, width=width)
    # Поднятый фонарь (правая рука)
    d.line([(cx + s * 0.35, cy - s * 0.40), (cx + s * 0.65, cy - s * 0.85)],
           fill=rgba, width=width)
    d.rectangle([cx + s * 0.55, cy - s * 1.05, cx + s * 0.85, cy - s * 0.75],
                outline=rgba, width=width)


def icon_crab_mini(d, cx, cy, size, color, alpha=180, width=3):
    """Мини-крабик: широкое тело-полукруг + 2 пары клешней + 6 лапок + глазки."""
    s = size / 2
    rgba = color + (alpha,)
    # Тело — широкая «купольная» форма (полуэллипс)
    d.chord([cx - s * 0.65, cy - s * 0.45, cx + s * 0.65, cy + s * 0.35],
            start=180, end=360, outline=rgba, width=width)
    # Прямая нижняя кромка тела
    d.line([(cx - s * 0.65, cy - s * 0.05), (cx + s * 0.65, cy - s * 0.05)],
           fill=rgba, width=width)
    # Глаза с белыми точками внутри — две черные точки на куполе
    d.ellipse([cx - s * 0.25, cy - s * 0.30, cx - s * 0.10, cy - s * 0.15],
              outline=rgba, width=width)
    d.ellipse([cx + s * 0.10, cy - s * 0.30, cx + s * 0.25, cy - s * 0.15],
              outline=rgba, width=width)
    # Зрачки
    d.ellipse([cx - s * 0.20, cy - s * 0.26, cx - s * 0.15, cy - s * 0.20],
              fill=rgba)
    d.ellipse([cx + s * 0.15, cy - s * 0.26, cx + s * 0.20, cy - s * 0.20],
              fill=rgba)
    # Улыбка
    d.arc([cx - s * 0.18, cy - s * 0.10, cx + s * 0.18, cy + s * 0.05],
          start=0, end=180, fill=rgba, width=width)
    # Левая клешня — рука + клешня
    d.line([(cx - s * 0.65, cy - s * 0.10), (cx - s * 0.95, cy - s * 0.30)],
           fill=rgba, width=width + 1)
    d.ellipse([cx - s * 1.10, cy - s * 0.50, cx - s * 0.80, cy - s * 0.20],
              outline=rgba, width=width)
    d.line([(cx - s * 1.05, cy - s * 0.45), (cx - s * 0.95, cy - s * 0.30)],
           fill=rgba, width=width)
    # Правая клешня
    d.line([(cx + s * 0.65, cy - s * 0.10), (cx + s * 0.95, cy - s * 0.30)],
           fill=rgba, width=width + 1)
    d.ellipse([cx + s * 0.80, cy - s * 0.50, cx + s * 1.10, cy - s * 0.20],
              outline=rgba, width=width)
    d.line([(cx + s * 1.05, cy - s * 0.45), (cx + s * 0.95, cy - s * 0.30)],
           fill=rgba, width=width)
    # 3 пары лапок снизу — расходятся под углом
    for x_off, ang_off in ((-0.45, -25), (-0.25, -10), (-0.05, 5),
                            (0.05, -5), (0.25, 10), (0.45, 25)):
        x1 = cx + s * x_off
        y1 = cy - s * 0.05
        x2 = x1 + s * 0.18 * math.sin(math.radians(ang_off))
        y2 = y1 + s * 0.55
        d.line([(x1, y1), (x2, y2)], fill=rgba, width=width)


def icon_star4(d, cx, cy, size, color, alpha=180, width=3):
    """Четырёхконечная навигационная звезда (sparkle)."""
    s = size / 2
    rgba = color + (alpha,)
    d.polygon(_norm_pts([(0, -1.0), (0.25, -0.25), (1.0, 0), (0.25, 0.25),
                         (0, 1.0), (-0.25, 0.25), (-1.0, 0), (-0.25, -0.25)],
                        cx, cy, s), outline=rgba, width=width)


def render_text(text, font_size, color, alpha=180):
    """Рендер текста с минимальным паддингом — для формульных иконок."""
    from PIL import ImageFont
    try:
        font = ImageFont.truetype("/System/Library/Fonts/SFNSMono.ttf", font_size)
    except OSError:
        try:
            font = ImageFont.truetype("Menlo.ttc", font_size)
        except OSError:
            font = ImageFont.load_default()
    # Грубая оценка размера и сразу crop
    tmp = Image.new("RGBA", (font_size * len(text) + 20, font_size + 20),
                    (0, 0, 0, 0))
    td = ImageDraw.Draw(tmp)
    td.text((10, 10), text, fill=color + (alpha,), font=font)
    bbox = tmp.getbbox()
    return tmp.crop(bbox) if bbox else tmp


def doodle_pattern(size, icon_fns, color, alpha=180, density=0.85,
                   base=160, jitter=40, seed=1, width=3):
    """Размещает иконки квазислучайно по сетке.

    Каждый шаг сетки получает иконку с вероятностью `density`. Каждая иконка
    отрисовывается на отдельном RGBA-холсте (`size×2`), поворачивается и
    вкладывается в общий слой — так получается естественный «кайф паттерна»
    без артефактов поворота через ImageDraw.
    """
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    rng = random.Random(seed)
    w, h = size
    for gy in range(0, h + base, base):
        # Каждая нечётная строка смещена на полшага — telegram-style
        row_off = (base // 2) if (gy // base) % 2 else 0
        for gx in range(-base, w + base, base):
            if rng.random() > density:
                continue
            icon_fn = rng.choice(icon_fns)
            sz = rng.randint(int(base * 0.55), int(base * 0.90))
            angle = rng.randint(-30, 30)
            sub = Image.new("RGBA", (sz * 2, sz * 2), (0, 0, 0, 0))
            sd = ImageDraw.Draw(sub)
            icon_fn(sd, sz, sz, sz, color, alpha, width)
            if angle:
                sub = sub.rotate(angle, resample=Image.BICUBIC, expand=True)
            cx = gx + row_off + rng.randint(-jitter, jitter)
            cy = gy + rng.randint(-jitter, jitter)
            layer.paste(sub, (cx - sub.width // 2, cy - sub.height // 2), sub)
    return layer


def doodle_text_pattern(size, snippets, color, alpha=180, density=0.65,
                        base=200, font_size=44, jitter=50, seed=1):
    """Паттерн из коротких текстовых фрагментов — для doodle-formula."""
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    rng = random.Random(seed)
    w, h = size
    # Кэшируем рендер текста
    cache = {s: render_text(s, font_size, color, alpha) for s in snippets}
    for gy in range(-base, h + base, base):
        row_off = (base // 2) if (gy // base) % 2 else 0
        for gx in range(-base, w + base, base):
            if rng.random() > density:
                continue
            text = rng.choice(snippets)
            sub = cache[text]
            angle = rng.randint(-25, 25)
            if angle:
                sub_r = sub.rotate(angle, resample=Image.BICUBIC, expand=True)
            else:
                sub_r = sub
            cx = gx + row_off + rng.randint(-jitter, jitter)
            cy = gy + rng.randint(-jitter, jitter)
            layer.paste(sub_r, (cx - sub_r.width // 2, cy - sub_r.height // 2), sub_r)
    return layer


# --- Doodle concepts ---


MARINE_ICONS = [icon_lighthouse, icon_anchor, icon_wheel, icon_seagull,
                icon_shell, icon_compass, icon_wave, icon_knot,
                icon_lifebuoy, icon_star4]
STICKER_ICONS = [icon_keeper_mini, icon_crab_mini, icon_lighthouse,
                 icon_seagull, icon_star4]
FORMULA_SNIPPETS = [
    "N", "S", "E", "W", "NE", "SW", "045°", "180°", "270°", "360°",
    "v=d/t", "sin θ", "cos θ", "tan α", "λ=c/f", "Δh", "α₁+α₂",
    "lat 41°", "lon 12°", "knots", "kt", "nm", "≈", "Σ", "π", "∞",
    "12'34\"", "0600", "1200", "2400",
]


def concept_doodle_marine(theme):
    """Морской паттерн: маяк, штурвал, якорь, чайка, компас, ракушка, волна."""
    if theme == "light":
        bg = vertical_gradient((W, H), (218, 234, 244), (190, 215, 230))
        ink = (32, 52, 78)
        alpha = 70
    else:
        bg = vertical_gradient((W, H), (14, 28, 52), (22, 46, 76))
        ink = (210, 230, 250)
        alpha = 150
    pat = doodle_pattern((W, H), MARINE_ICONS, ink,
                        alpha=alpha, density=0.98, base=150,
                        jitter=40, seed=101, width=4)
    bg.paste(pat, (0, 0), pat)
    return bg.convert("RGB")


def concept_doodle_stickers(theme):
    """Мини-маскоты LighChat — keeper, crab, маяк, чайка, искра."""
    if theme == "light":
        bg = vertical_gradient((W, H), (252, 230, 200), (235, 218, 232))
        ink = (40, 30, 60)
        alpha = 100
    else:
        # Глубокий navy с coral-иконками — фирменный контраст
        bg = vertical_gradient((W, H), (12, 20, 40), (28, 18, 44))
        ink = (255, 180, 80)  # тёплый ярче coral для контраста
        alpha = 200
    pat = doodle_pattern((W, H), STICKER_ICONS, ink,
                        alpha=alpha, density=0.97, base=170,
                        jitter=45, seed=202, width=4)
    bg.paste(pat, (0, 0), pat)
    return bg.convert("RGB")


def concept_doodle_formula(theme):
    """Telegram-style: морские формулы, румбы, координаты, sin/cos."""
    if theme == "light":
        bg = vertical_gradient((W, H), (220, 230, 245), (200, 218, 236))
        ink = (28, 50, 80)
        alpha = 110
    else:
        # Тёмно-навy 'школьная доска' — как телеграмские формулы на чёрном
        bg = vertical_gradient((W, H), (16, 24, 42), (10, 18, 32))
        ink = (220, 235, 255)
        alpha = 180
    pat = doodle_text_pattern((W, H), FORMULA_SNIPPETS, ink,
                             alpha=alpha, density=0.95, base=170,
                             font_size=50, jitter=45, seed=303)
    bg.paste(pat, (0, 0), pat)
    # Координатная сетка чуть видимая
    grid = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grid)
    grid_step = 240
    grid_color = ink + (max(20, alpha // 4),)
    for x in range(0, W, grid_step):
        gd.line([(x, 0), (x, H)], fill=grid_color, width=1)
    for y in range(0, H, grid_step):
        gd.line([(0, y), (W, y)], fill=grid_color, width=1)
    bg.paste(grid, (0, 0), grid)
    return bg.convert("RGB")


# ---------------------------------------------------------------------------
# Neutral landscape concepts
# ---------------------------------------------------------------------------
#
# Эти концепты не привязаны к LighChat-маскотам — нейтральные пейзажи в
# фирменной цветовой палитре, чтобы у пользователя был выбор атмосферы:
# минималистичные горы, лесной рассвет, японский Хокусай, ветка сакуры.


def mountain_layer(size, base_y, peaks, color, alpha=255, jitter=0, seed=0):
    """Слой гор — массив треугольных пиков от левого до правого края."""
    w, h = size
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    rng = random.Random(seed)
    pts = [(0, h), (0, int(h * base_y))]
    for x_frac, height in peaks:
        x = int(w * x_frac)
        y_peak = int(h * (base_y - height) + (rng.uniform(-jitter, jitter) if jitter else 0))
        pts.append((x, y_peak))
    pts.extend([(w, int(h * base_y)), (w, h)])
    d.polygon(pts, fill=color + (alpha,))
    return layer


def draw_pine(d, cx, cy, size, color, alpha=255, layers=4):
    """Сосна — несколько горизонтальных треугольников и тонкий ствол."""
    rgba = color + (alpha,)
    s = size / 2
    d.rectangle([cx - s * 0.07, cy + s * 0.65, cx + s * 0.07, cy + s * 1.00],
                fill=rgba)
    for i in range(layers):
        t = i / max(layers - 1, 1)
        top_y = cy - s * (0.95 - t * 0.55)
        bot_y = cy - s * (0.55 - t * 0.45) if i < layers - 1 else cy + s * 0.65
        half = s * (0.18 + t * 0.45)
        d.polygon([(cx - half, bot_y), (cx + half, bot_y), (cx, top_y)],
                  fill=rgba)


def draw_deer(d, cx, cy, size, color, alpha=255):
    """Силуэт стоящего оленя в профиль (морда вправо), стиль иконки.

    `cx, cy` — точка центра между копытами (где земля), `size` —
    общая высота от копыт до кончиков рогов.
    """
    rgba = color + (alpha,)
    H_total = size  # полная высота
    # Анатомия по высоте:
    # 0.00 .. 0.40   — ноги (40% высоты)
    # 0.40 .. 0.55   — тело (15%)
    # 0.55 .. 0.78   — шея (23%)
    # 0.78 .. 0.88   — голова (10%)
    # 0.88 .. 1.00   — рога (12%)
    body_w = H_total * 0.55  # ширина тела
    body_h = H_total * 0.18
    body_top = cy - H_total * 0.60
    body_bot = body_top + body_h
    # Тело — закруглённый прямоугольник (rounded ellipse)
    d.rounded_rectangle(
        [cx - body_w / 2, body_top, cx + body_w / 2, body_bot],
        radius=int(body_h / 3), fill=rgba,
    )
    # 4 ноги (передние ближе к голове = справа, задние слева)
    leg_w = max(4, int(H_total * 0.035))
    leg_bot = cy
    for x_off in (-0.40, -0.22, 0.22, 0.40):
        x = cx + body_w * x_off
        d.rectangle([x - leg_w / 2, body_bot - body_h * 0.2,
                     x + leg_w / 2, leg_bot], fill=rgba)
    # Хвостик — короткий выступ слева
    d.polygon([(cx - body_w / 2, body_top + body_h * 0.2),
               (cx - body_w / 2 - H_total * 0.05, body_top - H_total * 0.02),
               (cx - body_w / 2, body_top + body_h * 0.5)], fill=rgba)
    # Шея — узкая наклонная трапеция вверх-вправо
    neck_w_bot = body_w * 0.22
    neck_w_top = body_w * 0.16
    neck_bot_x = cx + body_w * 0.32  # выходит из переда тела
    neck_top_x = cx + body_w * 0.42
    neck_top_y = body_top - H_total * 0.20
    d.polygon([
        (neck_bot_x - neck_w_bot / 2, body_top + body_h * 0.1),
        (neck_bot_x + neck_w_bot / 2, body_top + body_h * 0.1),
        (neck_top_x + neck_w_top / 2, neck_top_y),
        (neck_top_x - neck_w_top / 2, neck_top_y),
    ], fill=rgba)
    # Голова — удлинённый клин (морда вправо)
    head_cx = neck_top_x + H_total * 0.06
    head_cy = neck_top_y - H_total * 0.04
    head_w = H_total * 0.20
    head_h = H_total * 0.10
    d.ellipse([head_cx - head_w / 2, head_cy - head_h / 2,
               head_cx + head_w / 2, head_cy + head_h / 2], fill=rgba)
    # Морда (заострённый кончик справа)
    d.polygon([
        (head_cx + head_w / 2 - 4, head_cy - head_h * 0.25),
        (head_cx + head_w / 2 + H_total * 0.05, head_cy + head_h * 0.05),
        (head_cx + head_w / 2 - 4, head_cy + head_h * 0.40),
    ], fill=rgba)
    # Уши — 2 заострённых уха на макушке
    ear_h = H_total * 0.06
    for ear_x_off in (-head_w * 0.20, head_w * 0.15):
        ex = head_cx + ear_x_off
        d.polygon([(ex - H_total * 0.015, head_cy - head_h * 0.30),
                   (ex, head_cy - head_h * 0.30 - ear_h),
                   (ex + H_total * 0.020, head_cy - head_h * 0.30)],
                  fill=rgba)
    # Рога — 2 V-образные ветвистые формы, более органичные
    rack_w = max(4, int(H_total * 0.022))
    rack_top_y = head_cy - H_total * 0.18
    for side, base_x_off in [(-1, -head_w * 0.10), (1, head_w * 0.05)]:
        base_x = head_cx + base_x_off
        base_y = head_cy - head_h * 0.30
        # Главный стержень — изогнут наружу
        mid_x = base_x + side * H_total * 0.04
        mid_y = base_y - H_total * 0.08
        tip_x = base_x + side * H_total * 0.10
        tip_y = rack_top_y
        d.line([(base_x, base_y), (mid_x, mid_y), (tip_x, tip_y)],
               fill=rgba, width=rack_w)
        # Ответвление 1 (внутрь)
        d.line([(mid_x, mid_y),
                (mid_x - side * H_total * 0.025, mid_y - H_total * 0.06)],
               fill=rgba, width=rack_w)
        # Ответвление 2 (от верха наружу)
        d.line([(tip_x, tip_y),
                (tip_x + side * H_total * 0.04, tip_y - H_total * 0.02)],
               fill=rgba, width=rack_w)


def draw_fuji(size, snow=(245, 245, 250), body=(80, 95, 130), trim=(40, 55, 90)):
    """Mount Fuji — крупный треугольник с волнистой снежной шапкой."""
    w, h = size
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.polygon([(int(w * 0.15), h), (int(w * 0.50), int(h * 0.22)),
               (int(w * 0.85), h)], fill=body + (255,))
    snow_pts = [(int(w * 0.50), int(h * 0.22))]
    for (x_frac, y_frac) in [
        (0.40, 0.32), (0.36, 0.36), (0.32, 0.42), (0.28, 0.48),
        (0.34, 0.50), (0.38, 0.55), (0.46, 0.50),
        (0.50, 0.42), (0.54, 0.50), (0.62, 0.55), (0.66, 0.50),
        (0.62, 0.42), (0.68, 0.48), (0.72, 0.42), (0.66, 0.36),
        (0.60, 0.32),
    ]:
        snow_pts.append((int(w * x_frac), int(h * y_frac)))
    snow_pts.append((int(w * 0.50), int(h * 0.22)))
    d.polygon(snow_pts, fill=snow + (255,))
    d.line([(int(w * 0.15), h), (int(w * 0.50), int(h * 0.22))],
           fill=trim + (200,), width=max(3, int(w * 0.005)))
    d.line([(int(w * 0.50), int(h * 0.22)), (int(w * 0.85), h)],
           fill=trim + (200,), width=max(3, int(w * 0.005)))
    return layer


def draw_great_wave(size, deep=(40, 110, 175), foam=(245, 248, 255),
                    spray=(220, 235, 250)):
    """Стилизованная Хокусай-style волна.

    Занимает нижнюю треть холста: основное тело-полигон поднимается слева
    направо к гребню, гребень окантован пенной полосой, выше — облако
    мелких брызг. Без крупных «лап-пузырей» (они читались как пузыри
    мыла, а не пена).
    """
    w, h = size
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    # Профиль гребня — поднимается слева направо к большому горбу справа
    crest = [
        (-0.05, 0.78),
        (0.12, 0.74),
        (0.28, 0.70),
        (0.42, 0.66),
        (0.55, 0.62),
        (0.66, 0.58),
        (0.74, 0.54),
        (0.80, 0.50),
        (0.85, 0.48),
        (0.90, 0.50),
        (0.96, 0.55),
        (1.05, 0.62),
    ]
    body_pts = [(int(w * x), int(h * y)) for x, y in crest]
    body_pts.extend([(int(w * 1.05), int(h * 1.0)), (int(w * -0.05), int(h * 1.0))])
    d.polygon(body_pts, fill=deep + (255,))
    # Пенная полоса вдоль гребня — повторяет профиль
    foam_w = max(8, int(w * 0.012))
    for i in range(len(crest) - 1):
        d.line([(int(w * crest[i][0]), int(h * crest[i][1])),
                (int(w * crest[i + 1][0]), int(h * crest[i + 1][1]))],
               fill=foam + (255,), width=foam_w)
    # Внутренние эхо-волны (3 параллельные линии ниже гребня)
    for off, alpha_inner in [(0.05, 180), (0.10, 130), (0.16, 90)]:
        echo = [(int(w * x), int(h * (y + off))) for x, y in crest[1:-1]]
        d.line(echo, fill=foam + (alpha_inner,), width=max(4, int(w * 0.005)))
    # Брызги — концентрируются над пиком гребня (правая часть)
    rng = random.Random(7)
    for _ in range(120):
        x_frac = rng.uniform(0.20, 1.0)
        # Высота гребня в данной X (линейная аппроксимация)
        if x_frac < 0.85:
            crest_y = 0.78 - (x_frac - (-0.05)) / (0.85 - (-0.05)) * 0.30
        else:
            crest_y = 0.48 + (x_frac - 0.85) / 0.20 * 0.14
        y_offset = rng.uniform(0.005, 0.18)
        sx = int(w * x_frac)
        sy = int(h * (crest_y - y_offset))
        sr = rng.randint(int(w * 0.003), int(w * 0.010))
        a = int(255 * (1.0 - y_offset / 0.20))
        d.ellipse([sx - sr, sy - sr, sx + sr, sy + sr],
                  fill=spray + (max(60, a),))
    return layer


def draw_sakura_branch(size, branch=(60, 35, 30), blossom=(255, 195, 215),
                       petal_dark=(220, 130, 165)):
    """Ветка сакуры — толстая ветвь с разветвлениями + 5-лепестковые цветы."""
    w, h = size
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    main_pts = [
        (int(w * -0.05), int(h * 1.0)),
        (int(w * 0.05), int(h * 0.75)),
        (int(w * 0.20), int(h * 0.55)),
        (int(w * 0.40), int(h * 0.40)),
        (int(w * 0.60), int(h * 0.32)),
    ]
    for i in range(len(main_pts) - 1):
        d.line([main_pts[i], main_pts[i + 1]], fill=branch + (255,),
               width=max(8, int(w * 0.012)))
    sub_branches = [
        [(0.20, 0.55), (0.10, 0.35)],
        [(0.20, 0.55), (0.32, 0.32)],
        [(0.40, 0.40), (0.58, 0.18)],
        [(0.40, 0.40), (0.30, 0.20)],
        [(0.60, 0.32), (0.80, 0.22)],
        [(0.60, 0.32), (0.72, 0.10)],
    ]
    for branch_pts in sub_branches:
        pts = [(int(w * x), int(h * y)) for x, y in branch_pts]
        d.line(pts, fill=branch + (255,), width=max(5, int(w * 0.008)))
    flower_centers = [
        (0.05, 0.72), (0.10, 0.55), (0.18, 0.42), (0.22, 0.35),
        (0.28, 0.28), (0.32, 0.32), (0.36, 0.20), (0.42, 0.32),
        (0.48, 0.22), (0.55, 0.25), (0.58, 0.16), (0.65, 0.30),
        (0.70, 0.18), (0.75, 0.12), (0.80, 0.22), (0.45, 0.42),
        (0.52, 0.36), (0.62, 0.22), (0.30, 0.50),
    ]
    rng = random.Random(31)
    for cx_frac, cy_frac in flower_centers:
        cx = int(w * cx_frac) + rng.randint(-int(w * 0.015), int(w * 0.015))
        cy = int(h * cy_frac) + rng.randint(-int(h * 0.008), int(h * 0.008))
        r = int(w * (0.025 + rng.random() * 0.012))
        for k in range(5):
            ang = math.radians(k * 72 - 90)
            px = cx + math.cos(ang) * r * 0.7
            py = cy + math.sin(ang) * r * 0.7
            d.ellipse([px - r * 0.7, py - r * 0.7, px + r * 0.7, py + r * 0.7],
                      fill=blossom + (255,))
        d.ellipse([cx - r * 0.4, cy - r * 0.4, cx + r * 0.4, cy + r * 0.4],
                  fill=petal_dark + (255,))
    return layer


def falling_petals(size, color=(255, 195, 215), count=120, seed=42):
    """Падающие лепестки — мягкие овальные пятнышки разного размера."""
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    rng = random.Random(seed)
    w, h = size
    for _ in range(count):
        x = rng.randint(0, w)
        y = rng.randint(0, h)
        r = rng.randint(int(w * 0.005), int(w * 0.013))
        a = rng.randint(140, 230)
        sub = Image.new("RGBA", (r * 4, r * 4), (0, 0, 0, 0))
        sd = ImageDraw.Draw(sub)
        sd.ellipse([r, r * 1.5, r * 3, r * 2.5], fill=color + (a,))
        sub = sub.rotate(rng.randint(0, 180), resample=Image.BICUBIC)
        layer.paste(sub, (x - sub.width // 2, y - sub.height // 2), sub)
    return layer


def concept_mountains_mist(theme):
    """Минималистичные горные хребты в дымке + солнце/луна.

    Слои с разными базовыми линиями и пиками, охватывающими всю ширину
    холста (без скукоживания в центр). Туман — узкая мягкая полоса между
    дальними и ближними хребтами.
    """
    if theme == "light":
        bg = vertical_gradient((W, H), (250, 218, 188), (220, 232, 244))
        sun_color = (255, 195, 130)
        layers = [
            # Дальние горы (линия 0.66, низкие пики)
            (0.66, [(0.05, 0.06), (0.18, 0.10), (0.35, 0.07),
                    (0.52, 0.09), (0.68, 0.06), (0.84, 0.08), (0.97, 0.05)],
             (175, 190, 210), 220),
            # Средний хребет (линия 0.76, побольше)
            (0.78, [(0.04, 0.10), (0.20, 0.14), (0.38, 0.10),
                    (0.55, 0.16), (0.72, 0.11), (0.88, 0.13), (0.98, 0.09)],
             (130, 150, 180), 240),
            # Передний хребет (линия 0.92, чёткий рельеф)
            (0.92, [(0.0, 0.10), (0.12, 0.18), (0.28, 0.12),
                    (0.42, 0.20), (0.58, 0.14), (0.74, 0.22),
                    (0.88, 0.15), (1.0, 0.18)],
             (78, 100, 135), 255),
        ]
    else:
        bg = vertical_gradient((W, H), (10, 16, 32), (26, 18, 48))
        sun_color = (255, 215, 170)
        layers = [
            (0.66, [(0.05, 0.06), (0.18, 0.10), (0.35, 0.07),
                    (0.52, 0.09), (0.68, 0.06), (0.84, 0.08), (0.97, 0.05)],
             (40, 50, 80), 230),
            (0.78, [(0.04, 0.10), (0.20, 0.14), (0.38, 0.10),
                    (0.55, 0.16), (0.72, 0.11), (0.88, 0.13), (0.98, 0.09)],
             (24, 32, 58), 245),
            (0.92, [(0.0, 0.10), (0.12, 0.18), (0.28, 0.12),
                    (0.42, 0.20), (0.58, 0.14), (0.74, 0.22),
                    (0.88, 0.15), (1.0, 0.18)],
             (10, 18, 38), 255),
        ]
    sun = radial_glow((W, H), (int(W * 0.72), int(H * 0.30)), int(H * 0.16),
                      sun_color, alpha=200)
    bg.paste(sun, (0, 0), sun)
    if theme == "dark":
        bg.paste(starfield((W, H), density=180, seed=88), (0, 0),
                 starfield((W, H), density=180, seed=88))
    for base_y, peaks, color, alpha in layers:
        ml = mountain_layer((W, H), base_y, peaks, color, alpha=alpha, seed=1)
        bg.paste(ml, (0, 0), ml)
    # Только одна тонкая полоса дымки между дальними и средним хребтом
    mist = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    md = ImageDraw.Draw(mist)
    mc = (255, 255, 255) if theme == "light" else (90, 110, 150)
    md.rectangle([0, int(H * 0.66), W, int(H * 0.71)], fill=mc + (90,))
    mist = mist.filter(ImageFilter.GaussianBlur(radius=30))
    bg.paste(mist, (0, 0), mist)
    return bg.convert("RGB")


def concept_pine_deer(theme):
    """Сосновый лес: ряд силуэтных сосен + олень + рассветное небо."""
    if theme == "light":
        bg = vertical_gradient((W, H), (252, 215, 195), (215, 230, 240))
        ground_color = (185, 165, 130)
        forest_back = (90, 110, 95)
        forest_front = (45, 65, 55)
        deer_color = (50, 35, 30)
    else:
        bg = vertical_gradient((W, H), (10, 18, 38), (24, 30, 50))
        ground_color = (28, 22, 38)
        forest_back = (22, 36, 46)
        forest_front = (8, 14, 22)
        deer_color = (8, 14, 22)
    sun = radial_glow((W, H), (int(W * 0.55), int(H * 0.55)), int(H * 0.16),
                      (255, 200, 140) if theme == "light" else (220, 200, 240),
                      alpha=200)
    bg.paste(sun, (0, 0), sun)
    if theme == "dark":
        bg.paste(starfield((W, H), density=240, seed=51), (0, 0),
                 starfield((W, H), density=240, seed=51))
    ground = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(ground)
    gd.rectangle([0, int(H * 0.78), W, H], fill=ground_color + (255,))
    bg.paste(ground, (0, 0), ground)
    rng = random.Random(91)
    pine_back = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    pd = ImageDraw.Draw(pine_back)
    for _ in range(14):
        x = rng.randint(0, W)
        y = int(H * 0.72) + rng.randint(-30, 30)
        sz = rng.randint(int(W * 0.04), int(W * 0.08))
        draw_pine(pd, x, y, sz * 2, forest_back, alpha=220, layers=4)
    bg.paste(pine_back, (0, 0), pine_back)
    pine_front = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    pfd = ImageDraw.Draw(pine_front)
    for x_frac in (0.05, 0.12, 0.18, 0.78, 0.85, 0.95):
        x = int(W * x_frac)
        y = int(H * 0.78) + rng.randint(-15, 15)
        sz = rng.randint(int(W * 0.10), int(W * 0.18))
        draw_pine(pfd, x, y, sz * 2, forest_front, alpha=255, layers=5)
    bg.paste(pine_front, (0, 0), pine_front)
    deer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    dd = ImageDraw.Draw(deer)
    # Олень стоит на земле (cy=0.80*H между копытами), высота 0.26*H —
    # достаточно крупный, чтобы рога и пропорции читались
    draw_deer(dd, int(W * 0.42), int(H * 0.80), int(H * 0.26), deer_color,
              alpha=255)
    bg.paste(deer, (0, 0), deer)
    return bg.convert("RGB")


def concept_fuji_wave(theme):
    """Реалистичная Фудзияма + ветка сакуры на переднем плане.

    Композиция отсылает к классической фотографии Фудзи-сан: большая
    заснеженная гора по центру, тёмный лес у подножия, небо в дневной/
    закатной палитре, и крупная цветущая ветвь сакуры в верхнем правом
    углу как обрамление сцены.
    """
    if theme == "light":
        bg = vertical_gradient((W, H), (210, 230, 240), (235, 240, 232))
        fuji_body = (155, 165, 185)
        fuji_shadow = (110, 122, 145)
        fuji_snow = (252, 252, 254)
        fuji_snow_dim = (215, 222, 235)
        fuji_erosion = (90, 100, 130)
        forest_back = (95, 120, 95)
        forest_front = (40, 65, 50)
        cloud_color = (255, 255, 255)
        sakura_branch = (95, 50, 40)
        sakura_blossom = (255, 175, 200)
        sakura_dark = (220, 130, 165)
    else:
        bg = vertical_gradient((W, H), (12, 22, 42), (22, 30, 50))
        fuji_body = (60, 75, 110)
        fuji_shadow = (32, 42, 70)
        fuji_snow = (215, 225, 245)
        fuji_snow_dim = (155, 170, 195)
        fuji_erosion = (15, 25, 50)
        forest_back = (28, 42, 38)
        forest_front = (10, 18, 22)
        cloud_color = (140, 160, 195)
        sakura_branch = (40, 25, 30)
        sakura_blossom = (235, 150, 185)
        sakura_dark = (185, 100, 145)
    # Тонкая дымка вокруг подножия — как утренний туман на референсе
    haze = radial_glow((W, H), (int(W * 0.50), int(H * 0.55)), int(W * 0.55),
                       cloud_color, alpha=110)
    bg.paste(haze, (0, 0), haze)
    # Сама Фудзи — крупная, занимает верх 60% высоты, 90% ширины
    fuji_size = (int(W * 0.95), int(H * 0.65))
    fuji_layer = draw_fuji_natural(fuji_size, body=fuji_body,
                                    shadow=fuji_shadow, snow=fuji_snow,
                                    snow_dim=fuji_snow_dim,
                                    erosion=fuji_erosion)
    bg.paste(fuji_layer,
             (int(W * 0.50 - fuji_size[0] / 2), int(H * 0.10)),
             fuji_layer)
    # Лес у подножия — два яруса силуэтов
    rng = random.Random(404)
    pine_back = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    pbd = ImageDraw.Draw(pine_back)
    for _ in range(22):
        x = rng.randint(0, W)
        y = int(H * 0.66) + rng.randint(-15, 15)
        sz = rng.randint(int(W * 0.035), int(W * 0.060))
        draw_pine(pbd, x, y, sz * 2, forest_back, alpha=215, layers=4)
    bg.paste(pine_back, (0, 0), pine_back)
    pine_front = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    pfd = ImageDraw.Draw(pine_front)
    for x_frac in (0.02, 0.10, 0.18, 0.26, 0.36, 0.45, 0.55, 0.65, 0.75,
                    0.83, 0.92, 0.98):
        x = int(W * x_frac) + rng.randint(-12, 12)
        y = int(H * 0.78) + rng.randint(-12, 12)
        sz = rng.randint(int(W * 0.07), int(W * 0.12))
        draw_pine(pfd, x, y, sz * 2, forest_front, alpha=255, layers=5)
    bg.paste(pine_front, (0, 0), pine_front)
    # Тёмная "земля" в самом низу — лес уходит за нижний край
    ground = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(ground)
    gd.rectangle([0, int(H * 0.86), W, H], fill=forest_front + (255,))
    bg.paste(ground, (0, 0), ground)
    # Большая ветвь сакуры — отзеркаленная draw_sakura_branch (исходит
    # из правого верхнего угла, склоняется к центру)
    sakura_layer = draw_sakura_branch((W, H), branch=sakura_branch,
                                       blossom=sakura_blossom,
                                       petal_dark=sakura_dark)
    sakura_layer = sakura_layer.transpose(Image.FLIP_LEFT_RIGHT)
    # Отрегулируем непрозрачность — чтобы ветвь не «съедала» Фудзи слишком
    rmask = sakura_layer.split()[-1].point(lambda v: int(v * 0.92))
    sakura_layer.putalpha(rmask)
    bg.paste(sakura_layer, (0, 0), sakura_layer)
    return bg.convert("RGB")


def draw_fuji_natural(size, body=(95, 110, 145), shadow=(60, 75, 110),
                       snow=(248, 248, 252), snow_dim=(210, 220, 235),
                       erosion=(50, 60, 90)):
    """Натуральная Фудзияма: вогнутые склоны + плоская вершина (кратер) +
    непрерывная снежная шапка с эрозийными «языками» по склонам.

    Силуэт построен так, чтобы повторить характерный профиль реальной
    Фудзи-сан: широкое основание, плавно крутеющие к вершине склоны
    (вогнутая кривая), и плоский верх — кальдера. Снег покрывает
    верхнюю треть как единая шапка, без видимого «шва» по центру.
    """
    w, h = size
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    # Силуэт Фудзи — вогнутый конус с широким основанием и плоской вершиной.
    # Точки расставлены так, чтобы средняя часть склонов «выгибалась» вниз
    # (как у настоящего вулканического конуса), а не была прямой линией.
    body_pts = [
        (int(w * -0.02), h),                     # левая база (за край холста)
        (int(w * 0.04), int(h * 0.95)),          # подножие лево (пологое)
        (int(w * 0.12), int(h * 0.86)),          # подъём начинается
        (int(w * 0.22), int(h * 0.72)),          # склон лево-низ
        (int(w * 0.30), int(h * 0.58)),          # склон лево-середина
        (int(w * 0.36), int(h * 0.46)),          # склон лево-верх (выпрямление)
        (int(w * 0.41), int(h * 0.34)),          # подход к вершине лево
        (int(w * 0.44), int(h * 0.24)),          # последний крутой участок
        (int(w * 0.46), int(h * 0.18)),          # вершина лево (плоская)
        (int(w * 0.54), int(h * 0.18)),          # вершина право (плоская)
        (int(w * 0.56), int(h * 0.24)),          # последний крутой участок
        (int(w * 0.59), int(h * 0.34)),          # подход к вершине право
        (int(w * 0.64), int(h * 0.46)),          # склон право-верх
        (int(w * 0.70), int(h * 0.58)),          # склон право-середина
        (int(w * 0.78), int(h * 0.72)),          # склон право-низ
        (int(w * 0.88), int(h * 0.86)),          # подножие право
        (int(w * 0.96), int(h * 0.95)),          # пологое
        (int(w * 1.02), h),                      # правая база (за край холста)
    ]
    d.polygon(body_pts, fill=body + (255,))
    # Снежная шапка — широкая «чаша», следующая за расширяющимся
    # профилем горы; покрывает верхнюю треть. Многоточечный полигон
    # повторяет body_pts на верхнем участке, чтобы снег ровно лежал
    # на склонах без «башни».
    snow_cap = [
        (int(w * 0.46), int(h * 0.18)),    # верх лево
        (int(w * 0.54), int(h * 0.18)),    # верх право
        (int(w * 0.56), int(h * 0.24)),
        (int(w * 0.59), int(h * 0.34)),
        (int(w * 0.625), int(h * 0.42)),   # низ право
        (int(w * 0.375), int(h * 0.42)),   # низ лево
        (int(w * 0.41), int(h * 0.34)),
        (int(w * 0.44), int(h * 0.24)),
    ]
    d.polygon(snow_cap, fill=snow + (255,))
    # Языки снега — спускаются ниже основной шапки по бороздам эрозии
    snow_tongues = [
        # (top_x_left, top_x_right, top_y, tip_x, tip_y)
        (0.555, 0.620, 0.41, 0.585, 0.55),   # правый главный
        (0.490, 0.555, 0.41, 0.520, 0.50),   # правый внутренний
        (0.605, 0.640, 0.41, 0.640, 0.50),   # правый внешний
        (0.380, 0.445, 0.41, 0.415, 0.55),   # левый главный
        (0.445, 0.510, 0.41, 0.480, 0.50),   # левый внутренний
        (0.360, 0.395, 0.41, 0.360, 0.50),   # левый внешний
    ]
    for x_l, x_r, y_top, x_tip, y_tip in snow_tongues:
        d.polygon([
            (int(w * x_l), int(h * y_top)),
            (int(w * x_r), int(h * y_top)),
            (int(w * x_tip), int(h * y_tip)),
        ], fill=snow + (255,))
    # Лёгкая тень на правой стороне снега для объёма (мягкая, без линии)
    snow_shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    ssd = ImageDraw.Draw(snow_shadow)
    ssd.polygon([
        (int(w * 0.50), int(h * 0.18)),
        (int(w * 0.54), int(h * 0.18)),
        (int(w * 0.59), int(h * 0.32)),
        (int(w * 0.50), int(h * 0.32)),
    ], fill=snow_dim + (60,))
    snow_shadow = snow_shadow.filter(ImageFilter.GaussianBlur(radius=20))
    layer = Image.alpha_composite(layer, snow_shadow)
    d = ImageDraw.Draw(layer)
    # Эрозийные борозды на тёмной части склона (ниже снега)
    erosion_w = max(2, int(w * 0.003))
    for top_x, top_y, bot_x, bot_y in [
        # Правые
        (0.59, 0.42, 0.72, 0.65),
        (0.61, 0.45, 0.74, 0.65),
        (0.63, 0.48, 0.76, 0.68),
        (0.65, 0.52, 0.79, 0.72),
        (0.68, 0.58, 0.83, 0.78),
        # Левые (зеркально)
        (0.41, 0.42, 0.28, 0.65),
        (0.39, 0.45, 0.26, 0.65),
        (0.37, 0.48, 0.24, 0.68),
        (0.35, 0.52, 0.21, 0.72),
        (0.32, 0.58, 0.17, 0.78),
    ]:
        d.line([(int(w * top_x), int(h * top_y)),
                (int(w * bot_x), int(h * bot_y))],
               fill=erosion + (110,), width=erosion_w)
    return layer


def concept_fuji_natural(theme):
    """Натуральная Фудзияма: реалистичная гора + озеро/туман + мини-сосны.

    Без стилизованной волны. Рассветное небо, мягкое солнце, отражение
    Фудзи в озере на нижней четверти, тонкий туман на горизонте, мелкие
    силуэты сосен по бокам.
    """
    if theme == "light":
        bg = vertical_gradient((W, H), (252, 215, 195), (220, 232, 244))
        sun_color = (255, 195, 130)
        fuji_body = (105, 120, 155)
        fuji_shadow = (70, 85, 120)
        fuji_snow = (250, 250, 254)
        fuji_snow_dim = (215, 222, 238)
        fuji_erosion = (55, 65, 95)
        lake = (155, 180, 205)
        lake_reflect = (130, 155, 190)
        pine_color = (45, 65, 60)
    else:
        bg = vertical_gradient((W, H), (8, 14, 30), (24, 30, 56))
        sun_color = (240, 215, 250)  # лунный
        fuji_body = (52, 65, 100)
        fuji_shadow = (28, 38, 65)
        fuji_snow = (200, 215, 240)
        fuji_snow_dim = (140, 155, 185)
        fuji_erosion = (12, 20, 42)
        lake = (12, 22, 50)
        lake_reflect = (28, 40, 70)
        pine_color = (8, 16, 30)
    # Солнце/луна слева от пика
    sun = radial_glow((W, H), (int(W * 0.32), int(H * 0.22)), int(H * 0.13),
                      sun_color, alpha=200)
    bg.paste(sun, (0, 0), sun)
    if theme == "dark":
        bg.paste(starfield((W, H), density=220, seed=66), (0, 0),
                 starfield((W, H), density=220, seed=66))
    # Дальние холмы за Фудзи
    hills_back = mountain_layer(
        (W, H), 0.62,
        [(0.0, 0.04), (0.15, 0.05), (0.30, 0.03), (0.45, 0.06),
         (0.55, 0.05), (0.70, 0.04), (0.85, 0.06), (1.0, 0.04)],
        (170, 185, 210) if theme == "light" else (45, 55, 90),
        alpha=200, seed=2,
    )
    bg.paste(hills_back, (0, 0), hills_back)
    # Горизонт — тонкая полоса тумана прямо под Фудзи
    mist = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    md = ImageDraw.Draw(mist)
    mc = (255, 255, 255) if theme == "light" else (90, 110, 150)
    md.rectangle([0, int(H * 0.66), W, int(H * 0.71)], fill=mc + (100,))
    mist = mist.filter(ImageFilter.GaussianBlur(radius=35))
    bg.paste(mist, (0, 0), mist)
    # Сама Фудзи — компактная по центру, занимает 70% ширины и 56% высоты
    fuji_size = (int(W * 0.85), int(H * 0.58))
    fuji_layer = draw_fuji_natural(fuji_size, body=fuji_body, shadow=fuji_shadow,
                                    snow=fuji_snow, snow_dim=fuji_snow_dim,
                                    erosion=fuji_erosion)
    bg.paste(fuji_layer,
             (int(W * 0.50 - fuji_size[0] / 2), int(H * 0.16)),
             fuji_layer)
    # Озеро (нижняя четверть)
    lake_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ld = ImageDraw.Draw(lake_layer)
    ld.rectangle([0, int(H * 0.78), W, H], fill=lake + (255,))
    bg.paste(lake_layer, (0, 0), lake_layer)
    # Отражение Фудзи в озере — перевёрнутая полу-прозрачная копия
    fuji_reflect = fuji_layer.transpose(Image.FLIP_TOP_BOTTOM)
    # Уменьшим высоту отражения
    rh = int(fuji_size[1] * 0.4)
    fuji_reflect = fuji_reflect.resize((fuji_size[0], rh),
                                        resample=Image.BICUBIC)
    # Применим прозрачность
    rmask = fuji_reflect.split()[-1].point(lambda v: int(v * 0.45))
    fuji_reflect.putalpha(rmask)
    bg.paste(fuji_reflect,
             (int(W * 0.50 - fuji_size[0] / 2), int(H * 0.78)),
             fuji_reflect)
    # Мягкая горизонтальная "рябь" поверх отражения
    for y_frac in (0.82, 0.86, 0.90, 0.94, 0.98):
        ripple = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        rd = ImageDraw.Draw(ripple)
        rd.line([(0, int(H * y_frac)), (W, int(H * y_frac))],
                fill=lake_reflect + (90,), width=2)
        bg.paste(ripple, (0, 0), ripple)
    # Силуэты сосен по бокам у воды
    pine_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    pld = ImageDraw.Draw(pine_layer)
    for x_frac in (0.04, 0.10, 0.92, 0.98):
        x = int(W * x_frac)
        y = int(H * 0.78)
        sz = int(W * 0.06)
        draw_pine(pld, x, y, sz * 2, pine_color, alpha=255, layers=4)
    bg.paste(pine_layer, (0, 0), pine_layer)
    return bg.convert("RGB")



def concept_sakura_branch(theme):
    """Ветка сакуры с цветами и падающими лепестками."""
    if theme == "light":
        bg = vertical_gradient((W, H), (255, 235, 240), (235, 232, 250))
        branch = (95, 50, 40)
        blossom = (255, 195, 215)
        petal_dark = (225, 130, 165)
    else:
        bg = vertical_gradient((W, H), (28, 14, 36), (50, 28, 58))
        branch = (60, 40, 50)
        blossom = (255, 175, 205)
        petal_dark = (210, 110, 150)
    moon = radial_glow((W, H), (int(W * 0.85), int(H * 0.15)), int(H * 0.12),
                       (255, 235, 230) if theme == "light"
                                       else (240, 210, 235), alpha=200)
    bg.paste(moon, (0, 0), moon)
    branch_layer = draw_sakura_branch((W, H), branch=branch, blossom=blossom,
                                       petal_dark=petal_dark)
    bg.paste(branch_layer, (0, 0), branch_layer)
    petals = falling_petals((W, H), color=blossom, count=140, seed=42)
    bg.paste(petals, (0, 0), petals)
    return bg.convert("RGB")


# ---------------------------------------------------------------------------
# Mood concepts (extra set 2)
# ---------------------------------------------------------------------------


def concept_misty_forest(theme):
    """Туманный сосновый лес — несколько слоёв деревьев со взвешенным
    туманом между ними. Передние стволы тёмные и чёткие, дальние —
    блёклые и сливаются с дымкой."""
    if theme == "light":
        bg = vertical_gradient((W, H), (220, 222, 220), (180, 195, 195))
        far = (155, 175, 175)
        mid = (95, 120, 115)
        near = (40, 58, 52)
        mist_color = (245, 245, 240)
    else:
        bg = vertical_gradient((W, H), (10, 18, 28), (24, 36, 42))
        far = (40, 55, 65)
        mid = (22, 32, 40)
        near = (8, 14, 20)
        mist_color = (110, 130, 140)
    rng = random.Random(33)
    # Дальний план — мелкие сосны через всю ширину, рассеянная дымка
    far_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    fd = ImageDraw.Draw(far_layer)
    for _ in range(28):
        x = rng.randint(-30, W + 30)
        y = int(H * 0.58) + rng.randint(-30, 40)
        sz = rng.randint(int(W * 0.030), int(W * 0.055))
        draw_pine(fd, x, y, sz * 2, far, alpha=200, layers=4)
    bg.paste(far_layer, (0, 0), far_layer)
    # Дымка-полоса между планами
    for y_frac, alpha, blur in [
        (0.50, 130, 60),
        (0.62, 110, 50),
        (0.74, 90, 40),
    ]:
        mist = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        md = ImageDraw.Draw(mist)
        md.rectangle([0, int(H * y_frac), W, int(H * (y_frac + 0.06))],
                     fill=mist_color + (alpha,))
        mist = mist.filter(ImageFilter.GaussianBlur(radius=blur))
        bg.paste(mist, (0, 0), mist)
    # Средний план — побольше сосны, ещё в тумане
    mid_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    mdr = ImageDraw.Draw(mid_layer)
    for _ in range(14):
        x = rng.randint(-30, W + 30)
        y = int(H * 0.74) + rng.randint(-20, 30)
        sz = rng.randint(int(W * 0.06), int(W * 0.10))
        draw_pine(mdr, x, y, sz * 2, mid, alpha=235, layers=5)
    bg.paste(mid_layer, (0, 0), mid_layer)
    # Передний план — крупные тёмные сосны на земле
    near_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    nd = ImageDraw.Draw(near_layer)
    for x_frac in (0.05, 0.15, 0.30, 0.55, 0.78, 0.92):
        x = int(W * x_frac) + rng.randint(-10, 10)
        y = int(H * 0.92) + rng.randint(-10, 10)
        sz = rng.randint(int(W * 0.13), int(W * 0.20))
        draw_pine(nd, x, y, sz * 2, near, alpha=255, layers=6)
    bg.paste(near_layer, (0, 0), near_layer)
    return bg.convert("RGB")


def concept_autumn_leaves(theme):
    """Осенние листья на тёплом градиенте. Падающие листья трёх оттенков
    (золото / охра / бордо) разного размера и поворота."""
    if theme == "light":
        bg = vertical_gradient((W, H), (252, 220, 175), (244, 195, 150))
        leaf_palette = [
            (220, 145, 50),    # охра
            (240, 180, 80),    # золото
            (175, 70, 40),     # бордо
            (200, 105, 50),    # рыжий
        ]
        sun_color = (255, 220, 160)
    else:
        bg = vertical_gradient((W, H), (40, 22, 18), (60, 35, 22))
        leaf_palette = [
            (200, 110, 50),
            (240, 165, 70),
            (175, 60, 35),
            (190, 90, 45),
        ]
        sun_color = (255, 180, 110)
    sun = radial_glow((W, H), (int(W * 0.30), int(H * 0.22)), int(H * 0.16),
                      sun_color, alpha=170)
    bg.paste(sun, (0, 0), sun)
    # Слой листьев — каждый лист это вытянутый овал с прожилкой,
    # повёрнутый под случайным углом
    rng = random.Random(57)
    for _ in range(160):
        x = rng.randint(0, W)
        y = rng.randint(0, H)
        sz = rng.randint(int(W * 0.018), int(W * 0.045))
        color = rng.choice(leaf_palette)
        alpha = rng.randint(170, 240)
        leaf = Image.new("RGBA", (sz * 4, sz * 4), (0, 0, 0, 0))
        ld = ImageDraw.Draw(leaf)
        # Овал-лист
        ld.ellipse([sz * 0.5, sz * 1.4, sz * 3.5, sz * 2.6],
                   fill=color + (alpha,))
        # Тёмная прожилка-стебелёк
        stem = (color[0] // 2, color[1] // 2, color[2] // 2)
        ld.line([(sz * 0.6, sz * 2.0), (sz * 3.4, sz * 2.0)],
                fill=stem + (alpha,), width=max(1, int(sz * 0.08)))
        leaf = leaf.rotate(rng.randint(0, 360), resample=Image.BICUBIC,
                           expand=True)
        bg.paste(leaf, (x - leaf.width // 2, y - leaf.height // 2), leaf)
    return bg.convert("RGB")


def concept_galaxy_nebula(theme):
    """Космическая туманность: облака радиальных glow + плотное звёздное
    поле + 3-5 ярких звёзд с halo."""
    if theme == "light":
        bg = vertical_gradient((W, H), (210, 215, 235), (180, 195, 222))
        nebula_palette = [
            ((255, 195, 220), 130),   # розовая
            ((180, 200, 240), 130),   # голубая
            ((220, 200, 240), 110),   # фиолетовая
        ]
        star_color = (90, 110, 150)
    else:
        bg = vertical_gradient((W, H), (4, 6, 18), (12, 10, 30))
        nebula_palette = [
            ((180, 100, 200), 230),   # фиолетовая
            ((80, 200, 230), 200),    # бирюзовая
            ((230, 130, 180), 210),   # розовая
            ((100, 130, 220), 190),   # синяя
        ]
        star_color = (255, 255, 255)
    rng = random.Random(73)
    # Туманность — несколько крупных размытых пятен в верхней половине
    for cx_frac, cy_frac, r_frac, palette_idx in [
        (0.22, 0.20, 0.30, 0),
        (0.65, 0.32, 0.36, 1),
        (0.78, 0.18, 0.22, 2),
        (0.45, 0.45, 0.28, min(3, len(nebula_palette) - 1)),
        (0.15, 0.50, 0.20, 0),
    ]:
        color, alpha = nebula_palette[palette_idx % len(nebula_palette)]
        glow = radial_glow((W, H),
                           (int(W * cx_frac), int(H * cy_frac)),
                           int(H * r_frac), color, alpha=alpha)
        bg.paste(glow, (0, 0), glow)
    # Плотное звёздное поле
    bg.paste(starfield((W, H), density=600 if theme == "dark" else 220,
                       color=star_color, seed=88),
             (0, 0),
             starfield((W, H), density=600 if theme == "dark" else 220,
                       color=star_color, seed=88))
    # 5 ярких звёзд с halo
    for _ in range(5):
        cx = rng.randint(int(W * 0.10), int(W * 0.90))
        cy = rng.randint(int(H * 0.05), int(H * 0.85))
        halo = radial_glow((W, H), (cx, cy), 70,
                           (255, 240, 220) if theme == "dark"
                                           else (240, 220, 180),
                           alpha=220)
        bg.paste(halo, (0, 0), halo)
        star = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        sd = ImageDraw.Draw(star)
        r = 8
        sd.ellipse([cx - r, cy - r, cx + r, cy + r],
                   fill=star_color + (255,))
        bg.paste(star, (0, 0), star)
    return bg.convert("RGB")


def concept_rain_bokeh(theme):
    """Ночной город сквозь капли дождя: размытые круглые «огни» города
    в качестве боке + диагональные полосы дождя."""
    if theme == "light":
        bg = vertical_gradient((W, H), (190, 200, 220), (160, 175, 200))
        bokeh_palette = [
            (255, 215, 150),   # тёплый
            (200, 215, 240),   # холодный
            (240, 195, 195),   # розовый
        ]
        rain_color = (90, 110, 150)
    else:
        bg = vertical_gradient((W, H), (8, 14, 30), (16, 22, 44))
        bokeh_palette = [
            (255, 195, 120),   # янтарный фонарь
            (120, 200, 255),   # неоново-голубой
            (255, 130, 180),   # розовый неон
            (160, 240, 200),   # мятный
        ]
        rain_color = (180, 200, 240)
    rng = random.Random(91)
    # Боке-огни — крупные размытые круги разной яркости
    for _ in range(35):
        cx = rng.randint(0, W)
        cy = rng.randint(0, H)
        r = rng.randint(int(W * 0.04), int(W * 0.10))
        color = rng.choice(bokeh_palette)
        alpha = rng.randint(100, 200) if theme == "dark" else rng.randint(70, 140)
        bokeh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        bd = ImageDraw.Draw(bokeh)
        bd.ellipse([cx - r, cy - r, cx + r, cy + r],
                   fill=color + (alpha,))
        bokeh = bokeh.filter(ImageFilter.GaussianBlur(radius=r * 0.5))
        bg.paste(bokeh, (0, 0), bokeh)
    # Капли дождя — диагональные штрихи
    bg.paste(rain_streaks((W, H), color=rain_color, count=240, seed=12),
             (0, 0),
             rain_streaks((W, H), color=rain_color, count=240, seed=12))
    # Дополнительные мелкие чёткие капли (как на стекле)
    drops = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    dd = ImageDraw.Draw(drops)
    drop_color = (255, 255, 255) if theme == "dark" else (255, 255, 255)
    for _ in range(80):
        x = rng.randint(0, W)
        y = rng.randint(0, H)
        r = rng.randint(int(W * 0.004), int(W * 0.010))
        dd.ellipse([x - r, y - r, x + r, y + r],
                   outline=drop_color + (180,), width=2)
    bg.paste(drops, (0, 0), drops)
    return bg.convert("RGB")


def concept_bamboo_zen(theme):
    """Бамбуковый лес — вертикальные стебли с узлами и листьями + камни
    у основания. Минимализм в духе японского дзен."""
    if theme == "light":
        bg = vertical_gradient((W, H), (235, 240, 220), (195, 215, 195))
        cane_color = (110, 145, 90)
        cane_dark = (75, 100, 60)
        leaf_color = (90, 130, 80)
        stone_color = (130, 130, 125)
        ground_color = (200, 210, 195)
    else:
        bg = vertical_gradient((W, H), (12, 22, 16), (24, 38, 30))
        cane_color = (60, 90, 60)
        cane_dark = (30, 50, 35)
        leaf_color = (50, 90, 65)
        stone_color = (40, 50, 50)
        ground_color = (18, 28, 22)
    # Земля
    ground = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(ground)
    gd.rectangle([0, int(H * 0.86), W, H], fill=ground_color + (255,))
    bg.paste(ground, (0, 0), ground)
    # Камни (полусферы)
    rng = random.Random(19)
    stones = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(stones)
    for x_frac, y_frac, w_frac in [
        (0.12, 0.92, 0.10),
        (0.30, 0.94, 0.08),
        (0.50, 0.93, 0.12),
        (0.72, 0.95, 0.07),
        (0.88, 0.92, 0.09),
    ]:
        cx = int(W * x_frac)
        cy = int(H * y_frac)
        rw = int(W * w_frac)
        rh = int(rw * 0.55)
        sd.chord([cx - rw, cy - rh, cx + rw, cy + rh],
                 start=180, end=360, fill=stone_color + (255,))
    bg.paste(stones, (0, 0), stones)

    # Стебли бамбука — вертикальные полосы с узлами и листьями
    def draw_cane(layer_img, x, base_y, cane_h, cane_w, alpha=255):
        d = ImageDraw.Draw(layer_img)
        d.rectangle([x - cane_w / 2, base_y - cane_h,
                      x + cane_w / 2, base_y],
                    fill=cane_color + (alpha,))
        node_spacing = max(80, cane_h // 8)
        node = base_y - node_spacing
        while node > base_y - cane_h:
            d.rectangle([x - cane_w / 2 - 2, node - 4,
                          x + cane_w / 2 + 2, node + 4],
                        fill=cane_dark + (alpha,))
            # Листочки — отдельные RGBA-слои с поворотом, paste на layer_img
            for side in (-1, 1):
                lx = x + side * cane_w * 1.2
                ly = node - 10
                lw = cane_w * 2.5
                lh = cane_w * 0.6
                leaf_img = Image.new("RGBA",
                                     (int(lw * 2), int(lw * 2)),
                                     (0, 0, 0, 0))
                ld = ImageDraw.Draw(leaf_img)
                ld.ellipse([0, lw - lh / 2, lw, lw + lh / 2],
                           fill=leaf_color + (alpha,))
                leaf_img = leaf_img.rotate(
                    side * rng.randint(20, 45), resample=Image.BICUBIC,
                    expand=True,
                )
                layer_img.paste(leaf_img,
                                (int(lx - leaf_img.width / 2),
                                 int(ly - leaf_img.height / 2)),
                                leaf_img)
            node -= node_spacing

    cane_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for x_frac, h_frac, w_frac, alpha in [
        (0.08, 0.95, 0.022, 245),
        (0.20, 0.85, 0.018, 230),
        (0.32, 0.92, 0.025, 250),
        (0.46, 0.78, 0.020, 220),
        (0.60, 0.90, 0.024, 245),
        (0.72, 0.82, 0.018, 225),
        (0.86, 0.93, 0.022, 245),
        (0.95, 0.80, 0.018, 220),
    ]:
        x = int(W * x_frac)
        cane_h = int(H * h_frac)
        cane_w = int(W * w_frac)
        draw_cane(cane_layer, x, int(H * 0.86), cane_h, cane_w, alpha=alpha)
    bg.paste(cane_layer, (0, 0), cane_layer)
    return bg.convert("RGB")


# ---------------------------------------------------------------------------
# Mood concepts (extra set 3)
# ---------------------------------------------------------------------------


def concept_arctic_aurora(theme):
    """Северное сияние над снежной равниной + звёзды."""
    if theme == "light":
        bg = vertical_gradient((W, H), (215, 230, 245), (235, 240, 245))
        snow_color = (240, 245, 250)
        snow_shadow = (200, 215, 232)
        aurora_palette = [(140, 220, 200), (170, 200, 240), (210, 180, 230)]
        star_color = (90, 110, 150)
        density = 80
    else:
        bg = vertical_gradient((W, H), (4, 8, 22), (10, 18, 38))
        snow_color = (210, 225, 245)
        snow_shadow = (90, 110, 140)
        aurora_palette = [(80, 230, 170), (110, 170, 240), (200, 130, 230)]
        star_color = (255, 255, 255)
        density = 380
    bg.paste(starfield((W, H), density=density, color=star_color, seed=44),
             (0, 0),
             starfield((W, H), density=density, color=star_color, seed=44))
    # Полосы сияния — диагональные мягкие "ленты" разных цветов
    bg.paste(aurora_bands((W, H), aurora_palette), (0, 0),
             aurora_bands((W, H), aurora_palette))
    # Снежная равнина — заснеженные холмы с тенями
    snow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(snow)
    sd.polygon([(0, int(H * 0.78)),
                (int(W * 0.25), int(H * 0.72)),
                (int(W * 0.55), int(H * 0.76)),
                (int(W * 0.85), int(H * 0.70)),
                (W, int(H * 0.78)),
                (W, H), (0, H)], fill=snow_color + (255,))
    # Тени складок снега
    for x_frac, y_frac, w_frac, h_frac in [
        (0.10, 0.84, 0.20, 0.04),
        (0.35, 0.82, 0.25, 0.05),
        (0.60, 0.86, 0.18, 0.04),
        (0.78, 0.82, 0.22, 0.05),
    ]:
        sd.ellipse([int(W * x_frac), int(H * y_frac),
                    int(W * (x_frac + w_frac)),
                    int(H * (y_frac + h_frac))],
                   fill=snow_shadow + (180,))
    bg.paste(snow, (0, 0), snow)
    return bg.convert("RGB")


def concept_desert_dunes(theme):
    """Песчаные дюны под закатным или ночным небом."""
    if theme == "light":
        bg = vertical_gradient((W, H), (252, 195, 130), (252, 220, 175))
        sun_color = (255, 235, 175)
        dune_palette = [
            (240, 195, 140),
            (220, 165, 110),
            (190, 135, 85),
            (155, 100, 65),
        ]
    else:
        bg = vertical_gradient((W, H), (12, 18, 38), (32, 24, 50))
        sun_color = (240, 215, 255)
        dune_palette = [
            (50, 38, 60),
            (35, 25, 50),
            (20, 14, 36),
            (10, 6, 22),
        ]
    sun = radial_glow((W, H), (int(W * 0.50), int(H * 0.42)), int(H * 0.18),
                      sun_color, alpha=210)
    bg.paste(sun, (0, 0), sun)
    if theme == "dark":
        bg.paste(starfield((W, H), density=180, seed=22), (0, 0),
                 starfield((W, H), density=180, seed=22))
    # Дюны — несколько изогнутых полигонов с разной высотой и цветом
    rng = random.Random(7)
    for i, (base_y, color) in enumerate([
        (0.55, dune_palette[0]),
        (0.65, dune_palette[1]),
        (0.78, dune_palette[2]),
        (0.92, dune_palette[3]),
    ]):
        layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ld = ImageDraw.Draw(layer)
        # Извилистая верхняя кромка дюны
        pts = [(0, H), (0, int(H * base_y))]
        x = 0
        while x <= W:
            x += rng.randint(80, 180)
            offset = rng.uniform(-0.04, 0.04)
            pts.append((x, int(H * (base_y + offset))))
        pts.extend([(W, int(H * base_y)), (W, H)])
        ld.polygon(pts, fill=color + (255,))
        bg.paste(layer, (0, 0), layer)
    return bg.convert("RGB")


def concept_city_skyline(theme):
    """Силуэт ночного города — здания с окнами-огнями + луна."""
    if theme == "light":
        bg = vertical_gradient((W, H), (245, 225, 195), (215, 220, 235))
        moon_color = (255, 235, 200)
        building_back = (140, 145, 165)
        building_front = (75, 80, 100)
        window_color = (255, 215, 130)
    else:
        bg = vertical_gradient((W, H), (10, 14, 32), (22, 22, 50))
        moon_color = (240, 235, 255)
        building_back = (28, 32, 56)
        building_front = (10, 14, 28)
        window_color = (255, 200, 110)
    moon = radial_glow((W, H), (int(W * 0.78), int(H * 0.20)), int(H * 0.10),
                       moon_color, alpha=230)
    bg.paste(moon, (0, 0), moon)
    if theme == "dark":
        bg.paste(starfield((W, H), density=160, seed=99), (0, 0),
                 starfield((W, H), density=160, seed=99))
    # Дальний план зданий — ниже, бледнее
    rng = random.Random(2)
    back_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bd = ImageDraw.Draw(back_layer)
    x = 0
    while x < W:
        bw = rng.randint(int(W * 0.05), int(W * 0.10))
        bh = rng.randint(int(H * 0.10), int(H * 0.22))
        bd.rectangle([x, int(H * 0.70) - bh, x + bw, int(H * 0.70)],
                     fill=building_back + (220,))
        x += bw + rng.randint(-4, 8)
    bg.paste(back_layer, (0, 0), back_layer)
    # Передний план — выше, темнее, с окнами
    front_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    fd = ImageDraw.Draw(front_layer)
    x = 0
    while x < W:
        bw = rng.randint(int(W * 0.07), int(W * 0.16))
        bh = rng.randint(int(H * 0.18), int(H * 0.40))
        top_y = int(H * 0.90) - bh
        fd.rectangle([x, top_y, x + bw, int(H * 0.95)],
                     fill=building_front + (255,))
        # Окна — сетка маленьких квадратиков
        win_size = max(4, int(W * 0.008))
        win_gap = max(8, int(W * 0.018))
        wy = top_y + win_gap
        while wy < int(H * 0.90):
            wx = x + win_gap
            while wx + win_size < x + bw:
                if rng.random() > 0.35:
                    a = rng.randint(160, 240)
                    fd.rectangle([wx, wy, wx + win_size, wy + win_size],
                                 fill=window_color + (a,))
                wx += win_gap
            wy += win_gap
        x += bw + rng.randint(-2, 6)
    bg.paste(front_layer, (0, 0), front_layer)
    # Земля
    ground = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(ground)
    gd.rectangle([0, int(H * 0.93), W, H], fill=building_front + (255,))
    bg.paste(ground, (0, 0), ground)
    return bg.convert("RGB")


def concept_neon_grid(theme):
    """Synthwave-style: фиолетово-розовый горизонт с неоновой сеткой
    + солнце с горизонтальными линиями."""
    if theme == "light":
        bg = vertical_gradient((W, H), (250, 220, 230), (220, 195, 235))
        sun_palette = [(255, 130, 180), (255, 195, 165)]
        grid_color = (220, 110, 180)
        grid_alpha = 130
    else:
        bg = vertical_gradient((W, H), (16, 4, 36), (8, 6, 26))
        sun_palette = [(255, 100, 170), (255, 200, 120)]
        grid_color = (255, 90, 200)
        grid_alpha = 200
    # Двуцветное «солнце»: верхняя половина одного цвета, нижняя — другого
    sun_cx = int(W * 0.50)
    sun_cy = int(H * 0.50)
    sun_r = int(H * 0.18)
    # Halo
    halo = radial_glow((W, H), (sun_cx, sun_cy), int(sun_r * 1.5),
                       sun_palette[0], alpha=210)
    bg.paste(halo, (0, 0), halo)
    sun_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sun_layer)
    # Верхняя половина круга — pinky
    sd.chord([sun_cx - sun_r, sun_cy - sun_r,
              sun_cx + sun_r, sun_cy + sun_r],
             start=180, end=360, fill=sun_palette[0] + (255,))
    # Нижняя — orange
    sd.chord([sun_cx - sun_r, sun_cy - sun_r,
              sun_cx + sun_r, sun_cy + sun_r],
             start=0, end=180, fill=sun_palette[1] + (255,))
    # Горизонтальные «полосы» в нижней половине солнца — эффект ретро
    band_count = 8
    for i in range(band_count):
        y = sun_cy + int(i * sun_r / band_count) + 4
        if y > sun_cy + sun_r:
            break
        thickness = max(2, sun_r // 30)
        sd.rectangle([sun_cx - sun_r, y, sun_cx + sun_r, y + thickness],
                     fill=bg.getpixel((sun_cx, y))[:3] + (255,))
    bg.paste(sun_layer, (0, 0), sun_layer)
    # Сетка перспективы — горизонтальные линии и сходящиеся вертикальные
    grid = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grid)
    horizon = int(H * 0.62)
    # Горизонтальные линии — становятся плотнее ближе к камере
    for k in range(1, 16):
        # Параметр t от 0 (горизонт) до 1 (низ)
        t = (k / 15) ** 1.6
        y = horizon + int((H - horizon) * t)
        gd.line([(0, y), (W, y)],
                fill=grid_color + (grid_alpha,),
                width=max(2, int(H * 0.0025)))
    # Вертикальные линии — сходятся к центру горизонта
    vp_x = W // 2
    for x_frac in [-1.0, -0.7, -0.45, -0.25, -0.1, 0.0, 0.1, 0.25, 0.45,
                    0.7, 1.0]:
        bx = int(W * (0.5 + x_frac))
        gd.line([(bx, H), (vp_x, horizon)],
                fill=grid_color + (grid_alpha,),
                width=max(2, int(H * 0.002)))
    bg.paste(grid, (0, 0), grid)
    return bg.convert("RGB")


def concept_lavender_field(theme):
    """Поле лаванды — горизонтальные ряды лиловых «полос» уходят вдаль,
    вверху мягкий закат."""
    if theme == "light":
        bg = vertical_gradient((W, H), (252, 215, 205), (220, 200, 230))
        sun_color = (255, 215, 180)
        rows = [
            (180, 150, 195),
            (160, 125, 180),
            (135, 100, 160),
            (110, 80, 140),
            (90, 65, 120),
            (70, 50, 100),
        ]
        path_color = (235, 220, 230)
    else:
        bg = vertical_gradient((W, H), (12, 14, 30), (24, 16, 38))
        sun_color = (240, 200, 230)
        rows = [
            (90, 70, 130),
            (75, 55, 115),
            (60, 45, 100),
            (45, 35, 85),
            (30, 22, 65),
            (18, 14, 48),
        ]
        path_color = (40, 30, 55)
    sun = radial_glow((W, H), (int(W * 0.30), int(H * 0.25)), int(H * 0.16),
                      sun_color, alpha=200)
    bg.paste(sun, (0, 0), sun)
    if theme == "dark":
        bg.paste(starfield((W, H), density=140, seed=33), (0, 0),
                 starfield((W, H), density=140, seed=33))
    # Поле — несколько горизонтальных полос разной высоты и оттенка
    base_y = 0.50
    for i, color in enumerate(rows):
        t = i / max(len(rows) - 1, 1)
        top = base_y + t * (1 - base_y)
        bot = top + 0.10 + t * 0.05
        # Изогнутая верхняя кромка — небольшая волна
        layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ld = ImageDraw.Draw(layer)
        pts = [(0, H)]
        for x in range(0, W + 30, 30):
            wave = math.sin((x / W) * math.pi * (2 + i * 0.5)) * (H * 0.005)
            pts.append((x, int(H * top + wave)))
        pts.extend([(W, int(H * top)), (W, H)])
        ld.polygon(pts, fill=color + (255,))
        bg.paste(layer, (0, 0), layer)
        # Точки-кустики — мелкая текстура поверх каждого ряда
        rng = random.Random(101 + i)
        dots = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        dd = ImageDraw.Draw(dots)
        for _ in range(int(60 + i * 30)):
            dx = rng.randint(0, W)
            dy = int(H * top) + rng.randint(int(H * 0.005),
                                             int(H * (bot - top) * 0.9))
            r = rng.randint(2, max(3, int(W * 0.005)))
            shade = (max(0, color[0] - 30),
                     max(0, color[1] - 30),
                     max(0, color[2] - 25))
            dd.ellipse([dx - r, dy - r, dx + r, dy + r],
                       fill=shade + (200,))
        bg.paste(dots, (0, 0), dots)
    # Светлая дорожка по диагонали — ведёт от низа-центра к горизонту
    path = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    pd = ImageDraw.Draw(path)
    pd.polygon([(int(W * 0.45), int(H * 0.55)),
                (int(W * 0.55), int(H * 0.55)),
                (int(W * 0.78), H),
                (int(W * 0.22), H)], fill=path_color + (180,))
    bg.paste(path, (0, 0), path)
    return bg.convert("RGB")


# ---------------------------------------------------------------------------
# Cute-animal concepts (extra set 4)
# ---------------------------------------------------------------------------


def draw_kitten(d, cx, cy, size, body_color, ear_inner, eye_color,
                pupil_color):
    """Сидящий котёнок в профиль (вид прямо). cx,cy — центр головы."""
    s = size / 2
    # Тело — яйцо (овал ниже головы)
    d.ellipse([cx - s * 0.85, cy + s * 0.50, cx + s * 0.85, cy + s * 1.85],
              fill=body_color)
    # Голова — круг
    d.ellipse([cx - s * 0.75, cy - s * 0.65, cx + s * 0.75, cy + s * 0.65],
              fill=body_color)
    # Уши — два треугольника
    d.polygon([(cx - s * 0.65, cy - s * 0.40),
               (cx - s * 0.45, cy - s * 1.05),
               (cx - s * 0.20, cy - s * 0.55)], fill=body_color)
    d.polygon([(cx + s * 0.20, cy - s * 0.55),
               (cx + s * 0.45, cy - s * 1.05),
               (cx + s * 0.65, cy - s * 0.40)], fill=body_color)
    # Внутренности ушей (розовое)
    d.polygon([(cx - s * 0.55, cy - s * 0.45),
               (cx - s * 0.45, cy - s * 0.85),
               (cx - s * 0.30, cy - s * 0.50)], fill=ear_inner)
    d.polygon([(cx + s * 0.30, cy - s * 0.50),
               (cx + s * 0.45, cy - s * 0.85),
               (cx + s * 0.55, cy - s * 0.45)], fill=ear_inner)
    # Глаза — большие овалы
    d.ellipse([cx - s * 0.36, cy - s * 0.10, cx - s * 0.16, cy + s * 0.18],
              fill=eye_color)
    d.ellipse([cx + s * 0.16, cy - s * 0.10, cx + s * 0.36, cy + s * 0.18],
              fill=eye_color)
    # Зрачки
    d.ellipse([cx - s * 0.31, cy - s * 0.05, cx - s * 0.21, cy + s * 0.13],
              fill=pupil_color)
    d.ellipse([cx + s * 0.21, cy - s * 0.05, cx + s * 0.31, cy + s * 0.13],
              fill=pupil_color)
    # Носик-сердечко
    d.polygon([(cx - s * 0.06, cy + s * 0.28),
               (cx + s * 0.06, cy + s * 0.28),
               (cx, cy + s * 0.42)], fill=ear_inner)
    # Усы
    whisker_w = max(2, int(s * 0.04))
    for y_off in (0.30, 0.36, 0.42):
        d.line([(cx - s * 0.40, cy + s * y_off),
                (cx - s * 0.85, cy + s * (y_off - 0.05))],
               fill=pupil_color, width=whisker_w)
        d.line([(cx + s * 0.40, cy + s * y_off),
                (cx + s * 0.85, cy + s * (y_off - 0.05))],
               fill=pupil_color, width=whisker_w)
    # Хвост — кривая сбоку
    d.ellipse([cx + s * 0.65, cy + s * 1.20, cx + s * 1.30, cy + s * 1.55],
              fill=body_color)
    d.ellipse([cx + s * 1.10, cy + s * 0.70, cx + s * 1.40, cy + s * 1.40],
              fill=body_color)


def draw_fox(d, cx, cy, size, body_color, belly_color, eye_color):
    """Сидящая лиса фронтально. cx,cy — центр головы."""
    s = size / 2
    # Тело — груша
    d.ellipse([cx - s * 0.65, cy + s * 0.40, cx + s * 0.65, cy + s * 1.65],
              fill=body_color)
    # Белый «фартук» на груди
    d.ellipse([cx - s * 0.35, cy + s * 0.60, cx + s * 0.35, cy + s * 1.50],
              fill=belly_color)
    # Голова — большой треугольник вниз
    d.polygon([(cx - s * 0.85, cy - s * 0.40),
               (cx + s * 0.85, cy - s * 0.40),
               (cx, cy + s * 0.65)], fill=body_color)
    # Белая отметина на морде
    d.polygon([(cx - s * 0.30, cy + s * 0.05),
               (cx + s * 0.30, cy + s * 0.05),
               (cx, cy + s * 0.65)], fill=belly_color)
    # Уши
    d.polygon([(cx - s * 0.85, cy - s * 0.40),
               (cx - s * 0.55, cy - s * 1.05),
               (cx - s * 0.30, cy - s * 0.45)], fill=body_color)
    d.polygon([(cx + s * 0.30, cy - s * 0.45),
               (cx + s * 0.55, cy - s * 1.05),
               (cx + s * 0.85, cy - s * 0.40)], fill=body_color)
    # Тёмные кончики ушей
    d.polygon([(cx - s * 0.70, cy - s * 0.62),
               (cx - s * 0.55, cy - s * 1.05),
               (cx - s * 0.42, cy - s * 0.58)], fill=eye_color)
    d.polygon([(cx + s * 0.42, cy - s * 0.58),
               (cx + s * 0.55, cy - s * 1.05),
               (cx + s * 0.70, cy - s * 0.62)], fill=eye_color)
    # Глаза-точки
    d.ellipse([cx - s * 0.36, cy - s * 0.10, cx - s * 0.18, cy + s * 0.10],
              fill=eye_color)
    d.ellipse([cx + s * 0.18, cy - s * 0.10, cx + s * 0.36, cy + s * 0.10],
              fill=eye_color)
    # Носик-точка
    d.ellipse([cx - s * 0.07, cy + s * 0.42, cx + s * 0.07, cy + s * 0.55],
              fill=eye_color)
    # Лапки в нижней части тела
    d.ellipse([cx - s * 0.35, cy + s * 1.50, cx - s * 0.10, cy + s * 1.75],
              fill=body_color)
    d.ellipse([cx + s * 0.10, cy + s * 1.50, cx + s * 0.35, cy + s * 1.75],
              fill=body_color)
    # Хвост (большой пушистый сбоку)
    d.ellipse([cx + s * 0.50, cy + s * 0.80, cx + s * 1.40, cy + s * 1.65],
              fill=body_color)
    # Белый кончик хвоста
    d.ellipse([cx + s * 1.15, cy + s * 0.85, cx + s * 1.45, cy + s * 1.20],
              fill=belly_color)


def draw_panda(d, cx, cy, size, body_color, dark_color, eye_white):
    """Панда фронтально сидит. cx,cy — центр головы."""
    s = size / 2
    # Тело
    d.ellipse([cx - s * 0.85, cy + s * 0.50, cx + s * 0.85, cy + s * 1.95],
              fill=body_color)
    # Чёрные лапки
    d.ellipse([cx - s * 0.95, cy + s * 0.85, cx - s * 0.40, cy + s * 1.40],
              fill=dark_color)
    d.ellipse([cx + s * 0.40, cy + s * 0.85, cx + s * 0.95, cy + s * 1.40],
              fill=dark_color)
    # Чёрные нижние лапки
    d.ellipse([cx - s * 0.55, cy + s * 1.65, cx - s * 0.05, cy + s * 2.00],
              fill=dark_color)
    d.ellipse([cx + s * 0.05, cy + s * 1.65, cx + s * 0.55, cy + s * 2.00],
              fill=dark_color)
    # Голова
    d.ellipse([cx - s * 0.95, cy - s * 0.85, cx + s * 0.95, cy + s * 0.85],
              fill=body_color)
    # Уши — два чёрных круга наверху
    d.ellipse([cx - s * 0.95, cy - s * 1.10, cx - s * 0.55, cy - s * 0.65],
              fill=dark_color)
    d.ellipse([cx + s * 0.55, cy - s * 1.10, cx + s * 0.95, cy - s * 0.65],
              fill=dark_color)
    # Чёрные «маски» вокруг глаз
    d.ellipse([cx - s * 0.55, cy - s * 0.30, cx - s * 0.10, cy + s * 0.20],
              fill=dark_color)
    d.ellipse([cx + s * 0.10, cy - s * 0.30, cx + s * 0.55, cy + s * 0.20],
              fill=dark_color)
    # Белки и зрачки
    d.ellipse([cx - s * 0.42, cy - s * 0.15, cx - s * 0.22, cy + s * 0.05],
              fill=eye_white)
    d.ellipse([cx + s * 0.22, cy - s * 0.15, cx + s * 0.42, cy + s * 0.05],
              fill=eye_white)
    d.ellipse([cx - s * 0.36, cy - s * 0.08, cx - s * 0.28, cy + s * 0.00],
              fill=dark_color)
    d.ellipse([cx + s * 0.28, cy - s * 0.08, cx + s * 0.36, cy + s * 0.00],
              fill=dark_color)
    # Носик-сердечко
    d.polygon([(cx - s * 0.10, cy + s * 0.30),
               (cx + s * 0.10, cy + s * 0.30),
               (cx, cy + s * 0.45)], fill=dark_color)


def draw_owl(d, cx, cy, size, body_color, belly_color, eye_white,
             pupil_color):
    """Сова фронтально на ветке. cx,cy — центр тела."""
    s = size / 2
    # Тело-капля
    d.ellipse([cx - s * 0.85, cy - s * 0.85, cx + s * 0.85, cy + s * 1.05],
              fill=body_color)
    # Светлое брюшко
    d.ellipse([cx - s * 0.55, cy - s * 0.10, cx + s * 0.55, cy + s * 0.95],
              fill=belly_color)
    # Перья на груди — мелкие дуги
    for ry, rx in [(0.10, 0.40), (0.40, 0.50), (0.70, 0.55)]:
        d.arc([cx - s * rx, cy + s * (ry - 0.10),
               cx + s * rx, cy + s * (ry + 0.20)],
              start=0, end=180, fill=body_color,
              width=max(2, int(s * 0.05)))
    # Уши-кисточки
    d.polygon([(cx - s * 0.65, cy - s * 0.65),
               (cx - s * 0.40, cy - s * 1.10),
               (cx - s * 0.20, cy - s * 0.55)], fill=body_color)
    d.polygon([(cx + s * 0.20, cy - s * 0.55),
               (cx + s * 0.40, cy - s * 1.10),
               (cx + s * 0.65, cy - s * 0.65)], fill=body_color)
    # Глаза — большие
    d.ellipse([cx - s * 0.55, cy - s * 0.55, cx - s * 0.10, cy - s * 0.10],
              fill=eye_white)
    d.ellipse([cx + s * 0.10, cy - s * 0.55, cx + s * 0.55, cy - s * 0.10],
              fill=eye_white)
    # Зрачки
    d.ellipse([cx - s * 0.42, cy - s * 0.42, cx - s * 0.22, cy - s * 0.22],
              fill=pupil_color)
    d.ellipse([cx + s * 0.22, cy - s * 0.42, cx + s * 0.42, cy - s * 0.22],
              fill=pupil_color)
    # Блики в глазах
    d.ellipse([cx - s * 0.36, cy - s * 0.40, cx - s * 0.30, cy - s * 0.34],
              fill=eye_white)
    d.ellipse([cx + s * 0.30, cy - s * 0.40, cx + s * 0.36, cy - s * 0.34],
              fill=eye_white)
    # Клюв-треугольник
    d.polygon([(cx - s * 0.08, cy - s * 0.10),
               (cx + s * 0.08, cy - s * 0.10),
               (cx, cy + s * 0.10)], fill=(225, 165, 65))
    # Лапки внизу
    d.line([(cx - s * 0.30, cy + s * 1.05), (cx - s * 0.30, cy + s * 1.20)],
           fill=(225, 165, 65), width=max(2, int(s * 0.06)))
    d.line([(cx + s * 0.30, cy + s * 1.05), (cx + s * 0.30, cy + s * 1.20)],
           fill=(225, 165, 65), width=max(2, int(s * 0.06)))


def draw_bunny(d, cx, cy, size, body_color, ear_inner, eye_color):
    """Кролик фронтально сидит. cx,cy — центр головы."""
    s = size / 2
    # Длинные уши — два узких овала вверху
    d.ellipse([cx - s * 0.40, cy - s * 1.50, cx - s * 0.18, cy - s * 0.30],
              fill=body_color)
    d.ellipse([cx + s * 0.18, cy - s * 1.50, cx + s * 0.40, cy - s * 0.30],
              fill=body_color)
    # Розовая внутренняя часть ушей
    d.ellipse([cx - s * 0.34, cy - s * 1.35, cx - s * 0.24, cy - s * 0.45],
              fill=ear_inner)
    d.ellipse([cx + s * 0.24, cy - s * 1.35, cx + s * 0.34, cy - s * 0.45],
              fill=ear_inner)
    # Голова — круг
    d.ellipse([cx - s * 0.65, cy - s * 0.45, cx + s * 0.65, cy + s * 0.65],
              fill=body_color)
    # Тело
    d.ellipse([cx - s * 0.75, cy + s * 0.45, cx + s * 0.75, cy + s * 1.65],
              fill=body_color)
    # Глаза
    d.ellipse([cx - s * 0.32, cy - s * 0.10, cx - s * 0.18, cy + s * 0.06],
              fill=eye_color)
    d.ellipse([cx + s * 0.18, cy - s * 0.10, cx + s * 0.32, cy + s * 0.06],
              fill=eye_color)
    # Носик
    d.polygon([(cx - s * 0.06, cy + s * 0.20),
               (cx + s * 0.06, cy + s * 0.20),
               (cx, cy + s * 0.30)], fill=ear_inner)
    # Лапки
    d.ellipse([cx - s * 0.55, cy + s * 1.40, cx - s * 0.10, cy + s * 1.75],
              fill=body_color)
    d.ellipse([cx + s * 0.10, cy + s * 1.40, cx + s * 0.55, cy + s * 1.75],
              fill=body_color)
    # Усы
    whisker_w = max(2, int(s * 0.04))
    for y_off in (0.18, 0.26):
        d.line([(cx - s * 0.20, cy + s * y_off),
                (cx - s * 0.60, cy + s * (y_off + 0.04))],
               fill=eye_color, width=whisker_w)
        d.line([(cx + s * 0.20, cy + s * y_off),
                (cx + s * 0.60, cy + s * (y_off + 0.04))],
               fill=eye_color, width=whisker_w)


def concept_kitten_yarn(theme):
    """Серый котёнок с клубком ниток на тёплом фоне."""
    if theme == "light":
        bg = vertical_gradient((W, H), (252, 232, 215), (240, 215, 220))
        body = (155, 155, 160)
        ear_inner = (245, 175, 195)
        eye_color = (200, 220, 100)
        pupil = (40, 40, 50)
        yarn = (235, 130, 145)
    else:
        bg = vertical_gradient((W, H), (18, 22, 38), (32, 28, 50))
        body = (90, 95, 115)
        ear_inner = (220, 140, 175)
        eye_color = (220, 230, 130)
        pupil = (15, 18, 30)
        yarn = (220, 110, 145)
    if theme == "dark":
        bg.paste(starfield((W, H), density=120, seed=8), (0, 0),
                 starfield((W, H), density=120, seed=8))
    # Котёнок — крупно по центру
    cat = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    cd = ImageDraw.Draw(cat)
    draw_kitten(cd, int(W * 0.50), int(H * 0.40), int(W * 0.55),
                body + (255,), ear_inner + (255,),
                eye_color + (255,), pupil + (255,))
    bg.paste(cat, (0, 0), cat)
    # Клубок ниток — большой круг в нижнем правом
    yarn_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    yd = ImageDraw.Draw(yarn_layer)
    yc = (int(W * 0.72), int(H * 0.78))
    yr = int(W * 0.13)
    yd.ellipse([yc[0] - yr, yc[1] - yr, yc[0] + yr, yc[1] + yr],
               fill=yarn + (255,))
    # Линии-обмотки
    line_w = max(3, int(yr * 0.06))
    yarn_dark = (max(0, yarn[0] - 40), max(0, yarn[1] - 40),
                 max(0, yarn[2] - 40))
    for ang_deg in range(-60, 60, 12):
        ang = math.radians(ang_deg)
        x1 = yc[0] + math.cos(ang) * yr * 0.95
        y1 = yc[1] + math.sin(ang) * yr * 0.95
        x2 = yc[0] - math.cos(ang) * yr * 0.95
        y2 = yc[1] - math.sin(ang) * yr * 0.95
        yd.line([(x1, y1), (x2, y2)], fill=yarn_dark + (200,), width=line_w)
    # Свисающая нитка к котёнку
    yd.line([(yc[0] - yr, yc[1] - yr * 0.2),
             (int(W * 0.55), int(H * 0.62))],
            fill=yarn_dark + (220,), width=line_w)
    bg.paste(yarn_layer, (0, 0), yarn_layer)
    return bg.convert("RGB")


def concept_cute_fox(theme):
    """Лиса в траве/снегу."""
    if theme == "light":
        bg = vertical_gradient((W, H), (252, 218, 195), (220, 230, 215))
        body = (220, 110, 60)
        belly = (252, 248, 240)
        eye = (40, 35, 50)
        ground_color = (180, 200, 170)
    else:
        bg = vertical_gradient((W, H), (10, 18, 36), (26, 32, 50))
        body = (190, 95, 55)
        belly = (220, 215, 200)
        eye = (10, 14, 28)
        ground_color = (28, 36, 50)
    sun = radial_glow((W, H), (int(W * 0.30), int(H * 0.20)), int(H * 0.13),
                      (255, 215, 160) if theme == "light"
                                       else (240, 215, 250),
                      alpha=200)
    bg.paste(sun, (0, 0), sun)
    if theme == "dark":
        bg.paste(starfield((W, H), density=180, seed=14), (0, 0),
                 starfield((W, H), density=180, seed=14))
    # Земля/снег
    ground = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(ground)
    gd.polygon([(0, int(H * 0.78)),
                (int(W * 0.30), int(H * 0.74)),
                (int(W * 0.65), int(H * 0.77)),
                (W, int(H * 0.74)),
                (W, H), (0, H)], fill=ground_color + (255,))
    bg.paste(ground, (0, 0), ground)
    # Дальние ёлки (мелкие)
    rng = random.Random(57)
    pines = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    pd = ImageDraw.Draw(pines)
    forest_color = (60, 95, 70) if theme == "light" else (16, 28, 30)
    for _ in range(8):
        x = rng.randint(0, W)
        y = int(H * 0.68) + rng.randint(-10, 15)
        sz = rng.randint(int(W * 0.04), int(W * 0.08))
        draw_pine(pd, x, y, sz * 2, forest_color, alpha=235, layers=4)
    bg.paste(pines, (0, 0), pines)
    # Лиса крупно по центру-низу
    fox = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    fd = ImageDraw.Draw(fox)
    draw_fox(fd, int(W * 0.50), int(H * 0.55), int(W * 0.50),
             body + (255,), belly + (255,), eye + (255,))
    bg.paste(fox, (0, 0), fox)
    return bg.convert("RGB")


def concept_panda_bamboo(theme):
    """Панда среди бамбукового леса.

    Бамбук рисуется в три плана: дальний размытый «лес» (много стеблей с
    низкой alpha по всему полотну), передние стебли по краям рамки, узлы
    с тенью. Для dark-варианта «чёрные» части панды осветлены до средне-
    серых, чтобы не сливаться с тёмным фоном.
    """
    if theme == "light":
        bg = vertical_gradient((W, H), (235, 245, 220), (215, 230, 195))
        body = (252, 252, 252)
        dark = (28, 30, 40)
        eye_white = (255, 255, 255)
        cane_color = (115, 150, 95)
        far_cane = (170, 195, 145)
        haze = (255, 255, 255)
    else:
        # Чуть посветлее фон, чтобы был контраст со средне-серыми «чёрными»
        # частями панды.
        bg = vertical_gradient((W, H), (28, 46, 32), (44, 62, 44))
        body = (235, 235, 235)
        dark = (50, 55, 65)
        eye_white = (250, 250, 250)
        cane_color = (90, 130, 80)
        far_cane = (60, 95, 60)
        haze = (140, 175, 130)
    # Дальний план — много стеблей по всему полотну с низкой alpha
    rng = random.Random(303)
    far_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    fd = ImageDraw.Draw(far_layer)
    for _ in range(14):
        x = rng.randint(0, W)
        cw = rng.randint(int(W * 0.010), int(W * 0.018))
        a = rng.randint(70, 130)
        fd.rectangle([x - cw // 2, 0, x + cw // 2, H],
                     fill=far_cane + (a,))
        # Узлы дальних стеблей
        node_step = int(H * 0.10)
        for ny in range(int(H * 0.05), H, node_step):
            fd.rectangle([x - cw // 2 - 1, ny - 3, x + cw // 2 + 1, ny + 3],
                         fill=(max(0, far_cane[0] - 25),
                               max(0, far_cane[1] - 25),
                               max(0, far_cane[2] - 25)) + (a,))
    far_layer = far_layer.filter(ImageFilter.GaussianBlur(radius=4))
    bg.paste(far_layer, (0, 0), far_layer)
    # Туманная вертикальная полоса в центре — подложка под панду,
    # отделяет её от заднего плана и подсвечивает силуэт
    haze_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    hd = ImageDraw.Draw(haze_layer)
    hd.ellipse([int(W * 0.18), int(H * 0.22),
                int(W * 0.82), int(H * 0.78)],
               fill=haze + (90 if theme == "dark" else 120,))
    haze_layer = haze_layer.filter(ImageFilter.GaussianBlur(radius=80))
    bg.paste(haze_layer, (0, 0), haze_layer)
    # Передние стебли — по краям рамки + 2 в средне-фронтальной зоне
    for x_frac, alpha, cw_frac in [
        (0.04, 235, 0.024), (0.11, 215, 0.022),
        (0.30, 200, 0.020),
        (0.70, 200, 0.020),
        (0.89, 215, 0.022), (0.96, 235, 0.024),
    ]:
        cane_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        cd = ImageDraw.Draw(cane_layer)
        x = int(W * x_frac)
        cw = int(W * cw_frac)
        cd.rectangle([x - cw // 2, 0, x + cw // 2, H],
                     fill=cane_color + (alpha,))
        # Узлы
        for ny in range(int(H * 0.05), H, int(H * 0.10)):
            cd.rectangle([x - cw // 2 - 2, ny - 4,
                          x + cw // 2 + 2, ny + 4],
                         fill=(max(0, cane_color[0] - 40),
                               max(0, cane_color[1] - 40),
                               max(0, cane_color[2] - 40)) + (alpha,))
        bg.paste(cane_layer, (0, 0), cane_layer)
    # Панда крупно по центру
    panda = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    pd = ImageDraw.Draw(panda)
    draw_panda(pd, int(W * 0.50), int(H * 0.42), int(W * 0.50),
               body + (255,), dark + (255,), eye_white + (255,))
    bg.paste(panda, (0, 0), panda)
    return bg.convert("RGB")


def concept_owl_night(theme):
    """Сова на ветке + луна + звёзды."""
    if theme == "light":
        bg = vertical_gradient((W, H), (200, 215, 235), (215, 220, 240))
        moon_color = (255, 245, 220)
        body = (140, 105, 80)
        belly = (230, 210, 175)
        eye_white = (252, 252, 252)
        pupil = (28, 30, 50)
        branch_color = (75, 50, 35)
    else:
        bg = vertical_gradient((W, H), (8, 14, 30), (16, 22, 42))
        moon_color = (250, 245, 230)
        body = (75, 55, 45)
        belly = (170, 145, 110)
        eye_white = (250, 250, 250)
        pupil = (12, 14, 28)
        branch_color = (35, 22, 18)
    # Луна — большой круг
    moon_glow = radial_glow((W, H), (int(W * 0.78), int(H * 0.22)),
                             int(H * 0.10), moon_color, alpha=220)
    bg.paste(moon_glow, (0, 0), moon_glow)
    moon = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    md = ImageDraw.Draw(moon)
    mr = int(H * 0.07)
    md.ellipse([int(W * 0.78) - mr, int(H * 0.22) - mr,
                int(W * 0.78) + mr, int(H * 0.22) + mr],
               fill=moon_color + (255,))
    bg.paste(moon, (0, 0), moon)
    if theme == "dark":
        bg.paste(starfield((W, H), density=240, seed=22), (0, 0),
                 starfield((W, H), density=240, seed=22))
    # Ветка под совой
    branch = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bd = ImageDraw.Draw(branch)
    bd.line([(int(W * 0.05), int(H * 0.74)),
             (int(W * 0.95), int(H * 0.78))],
            fill=branch_color + (255,), width=int(W * 0.024))
    # Маленькие веточки
    for x_frac, dy in [(0.20, -0.06), (0.40, -0.05), (0.70, -0.07)]:
        bd.line([(int(W * x_frac), int(H * (0.74 + dy * 0.25))),
                 (int(W * (x_frac + 0.05)), int(H * (0.74 + dy)))],
                fill=branch_color + (255,), width=int(W * 0.012))
    bg.paste(branch, (0, 0), branch)
    # Сова на ветке (центр)
    owl = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    od = ImageDraw.Draw(owl)
    draw_owl(od, int(W * 0.50), int(H * 0.55), int(W * 0.42),
             body + (255,), belly + (255,), eye_white + (255,),
             pupil + (255,))
    bg.paste(owl, (0, 0), owl)
    return bg.convert("RGB")


def concept_bunny_meadow(theme):
    """Кролик на лугу с цветами."""
    if theme == "light":
        bg = vertical_gradient((W, H), (215, 232, 245), (200, 230, 195))
        body = (252, 245, 235)
        ear_inner = (250, 175, 195)
        eye = (40, 35, 50)
        grass_color = (135, 180, 110)
        flower_palette = [(255, 200, 100), (255, 130, 165), (160, 195, 245)]
        sun_color = (255, 230, 175)
    else:
        bg = vertical_gradient((W, H), (12, 20, 36), (24, 36, 38))
        body = (220, 215, 205)
        ear_inner = (215, 140, 165)
        eye = (12, 14, 28)
        grass_color = (35, 60, 45)
        flower_palette = [(220, 175, 110), (220, 120, 155), (130, 165, 215)]
        sun_color = (240, 215, 250)
    sun = radial_glow((W, H), (int(W * 0.78), int(H * 0.20)), int(H * 0.13),
                      sun_color, alpha=200)
    bg.paste(sun, (0, 0), sun)
    if theme == "dark":
        bg.paste(starfield((W, H), density=160, seed=99), (0, 0),
                 starfield((W, H), density=160, seed=99))
    # Луг
    grass = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grass)
    gd.polygon([(0, int(H * 0.72)),
                (int(W * 0.30), int(H * 0.68)),
                (int(W * 0.60), int(H * 0.71)),
                (W, int(H * 0.68)),
                (W, H), (0, H)], fill=grass_color + (255,))
    bg.paste(grass, (0, 0), grass)
    # Цветы — 5-лепестковые, разбросаны по лугу
    flowers = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    fd = ImageDraw.Draw(flowers)
    rng = random.Random(33)
    for _ in range(45):
        cx = rng.randint(0, W)
        cy = rng.randint(int(H * 0.72), H)
        color = rng.choice(flower_palette)
        r = rng.randint(int(W * 0.012), int(W * 0.022))
        # 5 лепестков
        for k in range(5):
            ang = math.radians(k * 72 - 90)
            px = cx + math.cos(ang) * r * 0.7
            py = cy + math.sin(ang) * r * 0.7
            fd.ellipse([px - r * 0.6, py - r * 0.6,
                        px + r * 0.6, py + r * 0.6],
                       fill=color + (220,))
        # Серединка
        fd.ellipse([cx - r * 0.4, cy - r * 0.4,
                    cx + r * 0.4, cy + r * 0.4],
                   fill=(255, 235, 130, 240))
    bg.paste(flowers, (0, 0), flowers)
    # Кролик
    bunny = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bnd = ImageDraw.Draw(bunny)
    draw_bunny(bnd, int(W * 0.50), int(H * 0.42), int(W * 0.40),
               body + (255,), ear_inner + (255,), eye + (255,))
    bg.paste(bunny, (0, 0), bunny)
    return bg.convert("RGB")


# ---------------------------------------------------------------------------
# 3D-style concepts (extra set 5)
# ---------------------------------------------------------------------------
#
# «3D-обои» здесь — это не настоящий рейтрейсинг, а имитация объёма
# через слой-шейдинг: базовый цвет + размытый highlight сверху-слева +
# размытая ambient-тень снизу-справа + drop-shadow под объектом. Этого
# хватает, чтобы плоские формы читались как объёмные сферы / цилиндры.


def shaded_sphere(size, base_color, highlight=(255, 255, 255),
                  shadow_dark=None, light_pos=(0.32, 0.30),
                  highlight_alpha=190, shadow_alpha=180):
    """Сфера с псевдо-3D shading: базовый круг, размытый highlight в
    `light_pos` (доли диаметра, 0..1) и размытая ambient-тень с
    противоположной стороны. Возвращает RGBA-Image размером `size`."""
    w, h = size
    if shadow_dark is None:
        shadow_dark = (
            max(0, base_color[0] - 60),
            max(0, base_color[1] - 60),
            max(0, base_color[2] - 60),
        )
    # Базовый круг
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse([0, 0, w - 1, h - 1], fill=base_color + (255,))
    # Sphere mask — для clipping highlight/shadow в пределах круга
    sphere_mask = Image.new("L", size, 0)
    smd = ImageDraw.Draw(sphere_mask)
    smd.ellipse([0, 0, w - 1, h - 1], fill=255)
    # Ambient shadow — большое пятно снизу-справа
    sh = Image.new("RGBA", size, (0, 0, 0, 0))
    shd = ImageDraw.Draw(sh)
    sx = int(w * (1 - light_pos[0] + 0.1))
    sy = int(h * (1 - light_pos[1] + 0.1))
    shd.ellipse([sx - w // 2, sy - h // 2, sx + w // 2, sy + h // 2],
                fill=shadow_dark + (shadow_alpha,))
    sh = sh.filter(ImageFilter.GaussianBlur(radius=max(8, w // 8)))
    sh.putalpha(_mul_alpha(sh.split()[-1], sphere_mask))
    layer = Image.alpha_composite(layer, sh)
    # Highlight — небольшое яркое пятно сверху-слева
    hl = Image.new("RGBA", size, (0, 0, 0, 0))
    hld = ImageDraw.Draw(hl)
    hx = int(w * light_pos[0])
    hy = int(h * light_pos[1])
    hr = int(min(w, h) * 0.18)
    hld.ellipse([hx - hr, hy - hr, hx + hr, hy + hr],
                fill=highlight + (highlight_alpha,))
    hl = hl.filter(ImageFilter.GaussianBlur(radius=max(6, hr // 2)))
    hl.putalpha(_mul_alpha(hl.split()[-1], sphere_mask))
    layer = Image.alpha_composite(layer, hl)
    # Тонкий specular — маленькая яркая «капля»
    spec = Image.new("RGBA", size, (0, 0, 0, 0))
    spd = ImageDraw.Draw(spec)
    spr = max(3, int(min(w, h) * 0.05))
    spd.ellipse([hx - spr, hy - spr, hx + spr, hy + spr],
                fill=(255, 255, 255, 240))
    spec = spec.filter(ImageFilter.GaussianBlur(radius=max(2, spr // 3)))
    spec.putalpha(_mul_alpha(spec.split()[-1], sphere_mask))
    layer = Image.alpha_composite(layer, spec)
    return layer


def _mul_alpha(a, b):
    """Поэлементное умножение двух L-каналов как масок (0..255 × 0..255)."""
    pa = a.load()
    pb = b.load()
    out = Image.new("L", a.size, 0)
    po = out.load()
    for y in range(a.size[1]):
        for x in range(a.size[0]):
            po[x, y] = (pa[x, y] * pb[x, y]) // 255
    return out


def drop_shadow_for(layer, offset=(0, 12), blur=18, alpha=150):
    """Возвращает RGBA-Image той же геометрии, что и `layer`, но с
    размытой тенью под формой (берётся alpha канал layer как маска)."""
    w, h = layer.size
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    a = layer.split()[-1].point(lambda v: int(v * alpha / 255))
    shadow.paste(Image.new("RGBA", (w, h), (0, 0, 0, 255)),
                 (offset[0], offset[1]), a)
    return shadow.filter(ImageFilter.GaussianBlur(radius=blur))


def draw_planet_3d(size, base, light_pos=(0.30, 0.28),
                    bands=None, ring=None, ring_color=None):
    """Объёмная планета: shaded_sphere + опциональные горизонтальные
    полосы (Юпитер) и кольцо (Сатурн)."""
    w, h = size
    # bands шире чем sphere, чтобы можно было кадрировать после
    layer = shaded_sphere(size, base, light_pos=light_pos)
    if bands:
        # Полосы — горизонтальные полупрозрачные линии разной плотности
        bd_layer = Image.new("RGBA", size, (0, 0, 0, 0))
        bd = ImageDraw.Draw(bd_layer)
        for y_frac, h_frac, color, alpha in bands:
            y = int(h * y_frac)
            bh = max(2, int(h * h_frac))
            bd.rectangle([0, y, w, y + bh], fill=color + (alpha,))
        # Замаскировать в круг
        sphere_mask = Image.new("L", size, 0)
        smd = ImageDraw.Draw(sphere_mask)
        smd.ellipse([0, 0, w - 1, h - 1], fill=255)
        bd_layer.putalpha(_mul_alpha(bd_layer.split()[-1], sphere_mask))
        bd_layer = bd_layer.filter(ImageFilter.GaussianBlur(radius=2))
        layer = Image.alpha_composite(layer, bd_layer)
    if ring is not None:
        # Кольцо — эллипс шире планеты, тоньше по высоте
        rw, rh = int(w * 1.7), int(h * 0.4)
        ring_layer = Image.new("RGBA", (rw, rh), (0, 0, 0, 0))
        rd = ImageDraw.Draw(ring_layer)
        rd.ellipse([0, 0, rw - 1, rh - 1],
                   outline=(ring_color or (200, 175, 130)) + (220,),
                   width=max(6, h // 30))
        # Внутренняя тонкая линия
        rd.ellipse([int(rw * 0.08), int(rh * 0.18),
                    int(rw * 0.92), int(rh * 0.82)],
                   outline=(ring_color or (180, 155, 110)) + (180,),
                   width=max(3, h // 60))
        # Наложить кольцо так, чтобы заднее (верхнее) полукольцо было ЗА
        # планетой, а переднее (нижнее) — ПЕРЕД ней.
        # Заднее: только верхняя половина ring_layer.
        ring_back = ring_layer.crop((0, 0, rw, rh // 2))
        ring_front = ring_layer.crop((0, rh // 2, rw, rh))
        out = Image.new("RGBA", (rw, h + rh), (0, 0, 0, 0))
        # Верхняя половина кольца
        out.paste(ring_back,
                  ((rw - rw) // 2, (h + rh) // 2 - rh // 2),
                  ring_back)
        # Планета по центру
        out.paste(layer, ((rw - w) // 2, rh // 2), layer)
        # Нижняя половина кольца
        out.paste(ring_front,
                  ((rw - rw) // 2, (h + rh) // 2),
                  ring_front)
        return out
    return layer


def concept_lighthouse_3d(theme):
    """Объёмный маяк на скале: сама башня с боковой тенью, drop-shadow
    под скалой, мощный конический луч прожектора в небо."""
    if theme == "light":
        bg = vertical_gradient((W, H), (250, 218, 188), (200, 220, 240))
        rock_color = (60, 75, 110)
        body_color = (245, 240, 230)
        coral = CORAL
        beam_color = (255, 220, 150)
        sea_color = (90, 140, 175)
    else:
        bg = vertical_gradient((W, H), (8, 14, 30), (18, 26, 50))
        rock_color = (12, 22, 40)
        body_color = (220, 200, 175)
        coral = CORAL
        beam_color = (255, 200, 130)
        sea_color = (16, 44, 78)
    # Звёзды (dark)
    if theme == "dark":
        bg.paste(starfield((W, H), density=180, seed=33), (0, 0),
                 starfield((W, H), density=180, seed=33))
    # Мощный луч прожектора — большой треугольник с blur
    beam = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bd = ImageDraw.Draw(beam)
    beam_origin = (int(W * 0.50), int(H * 0.32))
    bd.polygon([
        beam_origin,
        (int(W * -0.25), int(H * -0.05)),
        (int(W * 1.25), int(H * -0.05)),
    ], fill=beam_color + (130,))
    beam = beam.filter(ImageFilter.GaussianBlur(radius=80))
    bg.paste(beam, (0, 0), beam)
    # Море
    sea = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sea)
    sd.rectangle([0, int(H * 0.66), W, H], fill=sea_color + (255,))
    bg.paste(sea, (0, 0), sea)
    # Блики на воде — несколько светлых горизонтальных штрихов
    glints = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glints)
    glint_color = (255, 230, 170) if theme == "light" else (200, 220, 250)
    rng = random.Random(7)
    for _ in range(40):
        gx = rng.randint(0, W)
        gy = rng.randint(int(H * 0.68), int(H * 0.92))
        gw = rng.randint(40, 120)
        gd.line([(gx, gy), (gx + gw, gy)],
                fill=glint_color + (rng.randint(80, 160),), width=2)
    glints = glints.filter(ImageFilter.GaussianBlur(radius=2))
    bg.paste(glints, (0, 0), glints)
    # Скала со shading
    rock_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    rd = ImageDraw.Draw(rock_layer)
    rd.polygon([
        (int(W * 0.25), int(H * 0.74)),
        (int(W * 0.40), int(H * 0.65)),
        (int(W * 0.60), int(H * 0.65)),
        (int(W * 0.78), int(H * 0.74)),
        (int(W * 0.85), int(H * 0.84)),
        (int(W * 0.15), int(H * 0.84)),
    ], fill=rock_color + (255,))
    # Тень слева у скалы
    rock_shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    rsd = ImageDraw.Draw(rock_shadow)
    dark_rock = (max(0, rock_color[0] - 25), max(0, rock_color[1] - 25),
                 max(0, rock_color[2] - 25))
    rsd.polygon([
        (int(W * 0.40), int(H * 0.65)),
        (int(W * 0.50), int(H * 0.66)),
        (int(W * 0.42), int(H * 0.84)),
        (int(W * 0.15), int(H * 0.84)),
        (int(W * 0.25), int(H * 0.74)),
    ], fill=dark_rock + (200,))
    rock_shadow = rock_shadow.filter(ImageFilter.GaussianBlur(radius=20))
    rock_layer = Image.alpha_composite(rock_layer, rock_shadow)
    bg.paste(rock_layer, (0, 0), rock_layer)
    # Маяк (используем существующий draw_lighthouse) + drop shadow под ним
    lh_w = int(W * 0.30)
    lh_h = int(lh_w * LH_LIGHTHOUSE)
    lh = draw_lighthouse((lh_w, lh_h), navy=NAVY_DARK, coral=coral,
                         body=body_color)
    # Боковая тень — копия маяка с тёмным фоном и сильным offset
    lh_shadow = drop_shadow_for(lh, offset=(20, 10), blur=18, alpha=160)
    bg.paste(lh_shadow,
             (int(W * 0.50 - lh_w / 2) + 4, int(H * 0.66) - lh_h + 8),
             lh_shadow)
    bg.paste(lh, (int(W * 0.50 - lh_w / 2), int(H * 0.66) - lh_h), lh)
    # Coral glow вокруг фонарной комнаты — символ света
    lamp_glow = radial_glow(
        (W, H),
        (int(W * 0.50), int(H * 0.66) - int(lh_h * 0.715)),
        int(H * 0.10), CORAL, alpha=200,
    )
    bg.paste(lamp_glow, (0, 0), lamp_glow)
    return bg.convert("RGB")


def concept_crab_3d(theme):
    """Объёмный крабик на песке: круглое тело со shading, тень, песок
    с текстурой-«крупой»."""
    if theme == "light":
        bg = vertical_gradient((W, H), (245, 220, 195), (220, 230, 235))
        sand_color = (235, 210, 165)
        sand_dark = (200, 175, 130)
        body_base = (240, 130, 50)
        eye_white = (255, 255, 255)
        pupil = (28, 30, 50)
    else:
        bg = vertical_gradient((W, H), (10, 18, 36), (22, 28, 50))
        sand_color = (40, 34, 50)
        sand_dark = (22, 18, 32)
        body_base = (220, 110, 50)
        eye_white = (240, 240, 240)
        pupil = (10, 14, 28)
    if theme == "dark":
        bg.paste(starfield((W, H), density=140, seed=12), (0, 0),
                 starfield((W, H), density=140, seed=12))
    # Песок (нижняя половина)
    sand_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sld = ImageDraw.Draw(sand_layer)
    sld.rectangle([0, int(H * 0.55), W, H], fill=sand_color + (255,))
    bg.paste(sand_layer, (0, 0), sand_layer)
    # Текстура песка — мелкие тёмные точки
    grain = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grain)
    rng = random.Random(57)
    for _ in range(800):
        gx = rng.randint(0, W)
        gy = rng.randint(int(H * 0.55), H)
        gd.ellipse([gx - 2, gy - 2, gx + 2, gy + 2],
                   fill=sand_dark + (90,))
    bg.paste(grain, (0, 0), grain)
    # Размер крабика по центру
    crab_w = int(W * 0.50)
    crab_h = int(crab_w * 0.85)
    crab_cx = int(W * 0.50)
    crab_cy = int(H * 0.62)
    # Тень под крабом — тёмный овал на песке
    shadow_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    shd = ImageDraw.Draw(shadow_layer)
    shd.ellipse([crab_cx - crab_w // 2 - 20, crab_cy + crab_h // 4,
                 crab_cx + crab_w // 2 + 20, crab_cy + crab_h // 2 + 30],
                fill=(0, 0, 0, 130))
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(radius=22))
    bg.paste(shadow_layer, (0, 0), shadow_layer)
    # Тело — объёмная сфера-полусфера (купол)
    body_size = (crab_w, crab_h)
    body = shaded_sphere(body_size, body_base, light_pos=(0.32, 0.28))
    # Только верхняя половина тела (купол)
    body_top = body.crop((0, 0, crab_w, crab_h // 2 + crab_h // 8))
    bg.paste(body_top,
             (crab_cx - crab_w // 2, crab_cy - crab_h // 2),
             body_top)
    # Линия рта снизу купола (полоса для контура)
    mouth = ImageDraw.Draw(bg.convert("RGBA"))
    bg = bg.convert("RGBA")
    md = ImageDraw.Draw(bg)
    md.arc([crab_cx - crab_w // 2 + 10,
            crab_cy - 5,
            crab_cx + crab_w // 2 - 10,
            crab_cy + crab_h // 4],
           start=180, end=360,
           fill=(max(0, body_base[0] - 80),
                 max(0, body_base[1] - 50),
                 max(0, body_base[2] - 30), 200),
           width=4)
    # Клешни — два маленьких объёмных шара по сторонам
    claw_size = int(crab_w * 0.35)
    for side in (-1, 1):
        claw = shaded_sphere((claw_size, claw_size), body_base,
                             light_pos=(0.32 if side > 0 else 0.55, 0.28))
        cx_pos = crab_cx + side * (crab_w // 2 + claw_size // 5)
        cy_pos = crab_cy - claw_size // 4
        # Тень под клешнёй
        cs = drop_shadow_for(claw, offset=(0, 8), blur=10, alpha=140)
        bg.paste(cs,
                 (cx_pos - claw_size // 2, cy_pos - claw_size // 2),
                 cs)
        bg.paste(claw,
                 (cx_pos - claw_size // 2, cy_pos - claw_size // 2),
                 claw)
        # «Защип» клешни — небольшой треугольник к крабу
        d2 = ImageDraw.Draw(bg)
        d2.polygon([
            (cx_pos - side * claw_size // 2, cy_pos),
            (cx_pos + side * claw_size // 4, cy_pos - claw_size // 5),
            (cx_pos + side * claw_size // 4, cy_pos + claw_size // 5),
        ], fill=(max(0, body_base[0] - 30),
                 max(0, body_base[1] - 20),
                 max(0, body_base[2] - 10), 255))
    # Лапки — 3 пары снизу из-под купола
    leg_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ld = ImageDraw.Draw(leg_layer)
    leg_color = (max(0, body_base[0] - 20), max(0, body_base[1] - 10),
                 max(0, body_base[2] - 5))
    leg_top_y = crab_cy + crab_h // 8
    for side in (-1, 1):
        for i, x_off_frac in enumerate((0.10, 0.22, 0.34)):
            x_top = crab_cx + side * int(crab_w * x_off_frac)
            x_bot = x_top + side * int(crab_w * 0.10)
            y_bot = leg_top_y + int(crab_h * 0.30 + i * crab_h * 0.05)
            ld.line([(x_top, leg_top_y), (x_bot, y_bot)],
                    fill=leg_color + (255,), width=int(crab_w * 0.025))
    bg.paste(leg_layer, (0, 0), leg_layer)
    # Глаза — два белых кружка с тёмным зрачком на куполе
    eye_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ed = ImageDraw.Draw(eye_layer)
    eye_r = int(crab_w * 0.05)
    for side in (-1, 1):
        ex = crab_cx + side * int(crab_w * 0.13)
        ey = crab_cy - int(crab_h * 0.15)
        # Стебелёк
        ed.line([(ex, ey + eye_r), (ex, ey + eye_r * 3)],
                fill=leg_color + (255,), width=max(2, eye_r // 4))
        # Глаз
        ed.ellipse([ex - eye_r, ey - eye_r, ex + eye_r, ey + eye_r],
                   fill=eye_white + (255,))
        # Зрачок
        ed.ellipse([ex - eye_r // 2, ey - eye_r // 2,
                    ex + eye_r // 2, ey + eye_r // 2],
                   fill=pupil + (255,))
        # Блик
        ed.ellipse([ex - eye_r // 3, ey - eye_r // 2,
                    ex - eye_r // 6, ey - eye_r // 4],
                   fill=(255, 255, 255, 220))
    bg.paste(eye_layer, (0, 0), eye_layer)
    return bg.convert("RGB")


def concept_cosmos_3d(theme):
    """Объёмный космос: большая газовая планета с полосами и кольцом,
    маленький спутник, туманность, звёзды."""
    if theme == "light":
        bg = vertical_gradient((W, H), (210, 220, 240), (180, 200, 232))
        nebula = [((255, 200, 220), 110), ((200, 220, 255), 90)]
        planet_base = (255, 165, 90)
        bands = [
            (0.20, 0.04, (210, 130, 70), 130),
            (0.32, 0.05, (220, 150, 90), 110),
            (0.45, 0.04, (180, 100, 50), 140),
            (0.58, 0.06, (240, 180, 110), 100),
            (0.72, 0.04, (200, 120, 60), 130),
            (0.84, 0.05, (220, 140, 80), 110),
        ]
        ring_color = (215, 195, 155)
        moon_base = (215, 220, 230)
        star_color = (60, 70, 100)
        density = 240
    else:
        bg = vertical_gradient((W, H), (4, 6, 18), (10, 8, 32))
        nebula = [((180, 100, 200), 220), ((80, 200, 230), 180),
                   ((220, 130, 180), 200)]
        planet_base = (240, 150, 80)
        bands = [
            (0.20, 0.04, (200, 110, 60), 160),
            (0.32, 0.05, (220, 140, 80), 140),
            (0.45, 0.04, (170, 80, 40), 170),
            (0.58, 0.06, (235, 170, 100), 130),
            (0.72, 0.04, (190, 100, 50), 160),
            (0.84, 0.05, (215, 130, 70), 140),
        ]
        ring_color = (210, 185, 140)
        moon_base = (200, 205, 215)
        star_color = (255, 255, 255)
        density = 600
    # Туманность — несколько крупных пятен
    rng = random.Random(91)
    for cx_frac, cy_frac, r_frac, palette_idx in [
        (0.25, 0.22, 0.32, 0),
        (0.78, 0.18, 0.26, min(1, len(nebula) - 1)),
        (0.55, 0.40, 0.30, min(2, len(nebula) - 1) if len(nebula) > 2 else 0),
    ]:
        color, alpha = nebula[palette_idx % len(nebula)]
        glow = radial_glow((W, H),
                           (int(W * cx_frac), int(H * cy_frac)),
                           int(H * r_frac), color, alpha=alpha)
        bg.paste(glow, (0, 0), glow)
    # Звёзды
    bg.paste(starfield((W, H), density=density, color=star_color, seed=33),
             (0, 0),
             starfield((W, H), density=density, color=star_color, seed=33))
    # Большая планета с полосами и кольцом
    planet_d = int(W * 0.55)
    planet = draw_planet_3d((planet_d, planet_d), planet_base,
                             light_pos=(0.30, 0.28),
                             bands=bands, ring=True,
                             ring_color=ring_color)
    # planet с кольцом возвращает image шире чем planet_d (rw=1.7×)
    pw, ph = planet.size
    bg.paste(planet,
             (int(W * 0.55 - pw / 2), int(H * 0.50 - ph / 2)),
             planet)
    # Спутник — маленькая луна слева снизу
    moon_d = int(W * 0.14)
    moon = shaded_sphere((moon_d, moon_d), moon_base,
                          light_pos=(0.30, 0.28))
    moon_shadow = drop_shadow_for(moon, offset=(0, 10), blur=12, alpha=140)
    bg.paste(moon_shadow, (int(W * 0.18), int(H * 0.78)), moon_shadow)
    bg.paste(moon, (int(W * 0.18), int(H * 0.78)), moon)
    # Несколько крошечных астероидов справа
    rng2 = random.Random(202)
    for _ in range(7):
        ax = rng2.randint(int(W * 0.05), int(W * 0.95))
        ay = rng2.randint(int(H * 0.85), int(H * 0.98))
        ar = rng2.randint(int(W * 0.008), int(W * 0.018))
        asteroid = shaded_sphere((ar * 2, ar * 2), (140, 130, 120),
                                  light_pos=(0.30, 0.30))
        bg.paste(asteroid, (ax - ar, ay - ar), asteroid)
    return bg.convert("RGB")


def concept_ocean_3d(theme):
    """Объёмная морская волна: несколько слоёв с глубиной, пенный
    гребень, брызги, маяк вдалеке."""
    if theme == "light":
        bg = vertical_gradient((W, H), (215, 232, 248), (180, 210, 230))
        deep = (35, 105, 160)
        mid = (60, 145, 195)
        light = (130, 195, 235)
        foam = (250, 252, 255)
        sky_warm = (255, 220, 175)
        lh_navy = NAVY
        lh_body = (245, 240, 230)
    else:
        bg = vertical_gradient((W, H), (8, 18, 38), (12, 30, 60))
        deep = (10, 36, 70)
        mid = (24, 70, 120)
        light = (60, 130, 185)
        foam = (200, 230, 245)
        sky_warm = (255, 200, 130)
        lh_navy = NAVY_DARK
        lh_body = (220, 200, 175)
    # Тёплый рассвет в небе
    sun = radial_glow((W, H), (int(W * 0.72), int(H * 0.20)), int(H * 0.15),
                      sky_warm, alpha=200)
    bg.paste(sun, (0, 0), sun)
    # Маяк вдалеке (мини)
    lh_w = int(W * 0.06)
    lh_h = int(lh_w * LH_LIGHTHOUSE)
    lh = draw_lighthouse((lh_w, lh_h), navy=lh_navy, coral=CORAL,
                         body=lh_body)
    bg.paste(lh, (int(W * 0.18), int(H * 0.40) - lh_h), lh)
    # Глубокий слой воды (дальний горизонт)
    horizon = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    hd = ImageDraw.Draw(horizon)
    hd.rectangle([0, int(H * 0.40), W, H], fill=deep + (255,))
    bg.paste(horizon, (0, 0), horizon)
    # 3 слоя волн с увеличивающейся глубиной (front к нижу)
    for i, (top_y, color, fade) in enumerate([
        (0.46, mid, 220),
        (0.58, light, 230),
        (0.72, mid, 245),
    ]):
        layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ld = ImageDraw.Draw(layer)
        pts = []
        for x in range(0, W + 30, 30):
            wave = math.sin((x / W) * math.pi * (3 + i * 1.0) + i) \
                   * (H * 0.012)
            pts.append((x, int(H * top_y + wave)))
        pts.extend([(W, H), (0, H)])
        ld.polygon(pts, fill=color + (fade,))
        bg.paste(layer, (0, 0), layer)
    # Большая 3D-волна на переднем плане — глянцевая, с пеной
    big_wave = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bwd = ImageDraw.Draw(big_wave)
    crest = [
        (-0.05, 0.86),
        (0.10, 0.80),
        (0.25, 0.74),
        (0.42, 0.68),
        (0.60, 0.62),
        (0.74, 0.56),
        (0.84, 0.50),
        (0.92, 0.48),
        (1.02, 0.52),
    ]
    body_pts = [(int(W * x), int(H * y)) for x, y in crest]
    body_pts.extend([(int(W * 1.05), int(H)), (int(W * -0.05), int(H))])
    bwd.polygon(body_pts, fill=deep + (255,))
    # Глянцевый highlight на гребне (полосой)
    for off, alpha in [(0.01, 230), (0.04, 170), (0.08, 110), (0.13, 70)]:
        line_pts = [(int(W * x), int(H * (y + off))) for x, y in crest[1:-1]]
        bwd.line(line_pts, fill=foam + (alpha,),
                 width=max(4, int(W * 0.005)))
    # Пенный гребень (толстая белая полоса)
    crest_pts = [(int(W * x), int(H * y)) for x, y in crest]
    bwd.line(crest_pts, fill=foam + (255,), width=max(8, int(W * 0.012)))
    bg.paste(big_wave, (0, 0), big_wave)
    # Брызги над пенным гребнем
    spray = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    spd = ImageDraw.Draw(spray)
    rng = random.Random(11)
    for _ in range(120):
        x_frac = rng.uniform(0.20, 1.0)
        # crest_y по линейной интерполяции
        crest_y = 0.86 - (x_frac - (-0.05)) / (0.92 + 0.05) * (0.86 - 0.48)
        y_off = rng.uniform(0.005, 0.16)
        sx = int(W * x_frac)
        sy = int(H * (crest_y - y_off))
        sr = rng.randint(int(W * 0.003), int(W * 0.010))
        a = int(255 * (1.0 - y_off / 0.18))
        spd.ellipse([sx - sr, sy - sr, sx + sr, sy + sr],
                    fill=foam + (max(60, a),))
    bg.paste(spray, (0, 0), spray)
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
    "doodle-marine": concept_doodle_marine,
    "doodle-stickers": concept_doodle_stickers,
    "doodle-formula": concept_doodle_formula,
    "mountains-mist": concept_mountains_mist,
    "pine-deer": concept_pine_deer,
    "fuji-wave": concept_fuji_wave,
    "fuji-natural": concept_fuji_natural,
    "sakura-branch": concept_sakura_branch,
    "misty-forest": concept_misty_forest,
    "autumn-leaves": concept_autumn_leaves,
    "galaxy-nebula": concept_galaxy_nebula,
    "rain-bokeh": concept_rain_bokeh,
    "bamboo-zen": concept_bamboo_zen,
    "arctic-aurora": concept_arctic_aurora,
    "desert-dunes": concept_desert_dunes,
    "city-skyline": concept_city_skyline,
    "neon-grid": concept_neon_grid,
    "lavender-field": concept_lavender_field,
    "kitten-yarn": concept_kitten_yarn,
    "cute-fox": concept_cute_fox,
    "panda-bamboo": concept_panda_bamboo,
    "owl-night": concept_owl_night,
    "bunny-meadow": concept_bunny_meadow,
    "lighthouse-3d": concept_lighthouse_3d,
    "crab-3d": concept_crab_3d,
    "cosmos-3d": concept_cosmos_3d,
    "ocean-3d": concept_ocean_3d,
}


def main():
    OUT_WEB.mkdir(parents=True, exist_ok=True)
    OUT_MOBILE.mkdir(parents=True, exist_ok=True)
    for slug, fn in CONCEPTS.items():
        is_doodle = slug.startswith("doodle-")
        for theme in ("light", "dark"):
            img = fn(theme)
            if is_doodle:
                # Doodle-паттерны должны быть равномерны по плотности —
                # виньетка съедает иконки по краям и читается как баг.
                out = img
            else:
                # Лёгкая виньетка для сюжетных концептов
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
