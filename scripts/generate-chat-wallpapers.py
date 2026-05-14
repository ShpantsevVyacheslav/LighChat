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
                        alpha=alpha, density=0.88, base=200,
                        jitter=50, seed=101, width=4)
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
                        alpha=alpha, density=0.85, base=220,
                        jitter=55, seed=202, width=4)
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
                             alpha=alpha, density=0.72, base=220,
                             font_size=56, jitter=60, seed=303)
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
