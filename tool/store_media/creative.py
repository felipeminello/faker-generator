"""Draws the App Store creative assets (iOS 27's product page header and
search result) in assets/store_media/creative/ (ignored by git):

- universal_5244x2950.png: one 16:9 image for both placements;
- header_3840x1646.png: the 21:9 product page header;
- search_3840x2560.png: the 3:2 search result, with the app on an iPhone
  next to the header's card. Needs capture.py's iPhone screenshots
  (build/store_media/iphone/), and is skipped without them.

Apple crops these differently on every device, so what matters sits inside
the safe areas of its templates; the floating CPFs and CNPJs around them
are decoration that can be cut. The images have no alpha channel, which the
App Store rejects.

Needs Pillow: python tool/store_media/creative.py
"""

import math
import pathlib
import random

from PIL import Image, ImageDraw, ImageFilter, ImageFont

from compose import (BOTTOM, DEVICES, GLOW, OUT, SHADOW, SOURCE, TOP, font,
                     framed, load_screen)

MONO = '/System/Library/Fonts/SFNSMono.ttf'

# Inside the icon's card.
INK = (30, 27, 46)
VIOLET = (109, 40, 217)
MUTED = (107, 101, 128)
YELLOW = (251, 191, 36)
VALID = (74, 222, 128)
INVALID = (248, 113, 113)

PHRASE = 'Pronto para o novo CNPJ'
# The Receita Federal's example of an alphanumeric CNPJ.
EXAMPLE = '12.ABC.345/01DE-35'

# Safe areas as (left, top, width, height), measured on Apple's templates.
UNIVERSAL = ((5244, 2950), (1921, 660, 1402, 962))
HEADER = ((3840, 1646), (1097, 493, 1646, 661))
SEARCH = ((3840, 2560), (836, 765, 2168, 1030))
# The hero (phrase and card) at scale 1, rotation included.
HERO = (1290, 790)
SEARCH_SCREEN = '06_validar_lista'


# --- Documents ---------------------------------------------------------------

def cpf_digits(base):
    digits = [int(c) for c in base]
    for size in (9, 10):
        total = sum(d * (size + 1 - i) for i, d in enumerate(digits[:size]))
        digits.append(0 if total % 11 < 2 else 11 - total % 11)
    return ''.join(map(str, digits))


def cnpj_digits(base):
    """The Receita Federal's rule: each character counts as its ASCII code
    minus 48, so numeric CNPJs keep their old check digits."""
    values = [ord(c) - 48 for c in base]
    for weights in ([5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2],
                    [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]):
        total = sum(v * w for v, w in zip(values, weights))
        values.append(0 if total % 11 < 2 else 11 - total % 11)
    return base + ''.join(str(v) for v in values[12:])


assert cnpj_digits('12ABC34501DE') == '12ABC34501DE35'


def cpf(rng):
    c = cpf_digits(''.join(rng.choice('0123456789') for _ in range(9)))
    return f'{c[:3]}.{c[3:6]}.{c[6:9]}-{c[9:]}'


def cnpj(rng, letters):
    alphabet = '0123456789' + ('ABCDEFGHIJKLMNOPQRSTUVWXYZ' if letters else '')
    root = ''.join(rng.choice(alphabet) for _ in range(8))
    order = '0001' if rng.random() < 0.6 else ''.join(
        rng.choice(alphabet) for _ in range(4))
    c = cnpj_digits(root + order)
    return f'{c[:2]}.{c[2:5]}.{c[5:8]}/{c[8:12]}-{c[12:]}'


def broken(value):
    """[value] with a wrong last check digit."""
    return value[:-1] + str((int(value[-1]) + 1) % 10)


# --- Drawing -----------------------------------------------------------------

def mono(size, weight=500):
    f = ImageFont.truetype(MONO, size)
    f.set_variation_by_axes([weight])
    return f


def background(size, center):
    """The screenshots' violet, lit from behind the hero."""
    width, height = size
    # Darker towards the bottom right: a vertical ramp turned 30°, on a
    # square large enough for the canvas to fit in it after the turn.
    side = width + height
    ramp = Image.linear_gradient('L').resize((side, side))
    ramp = ramp.rotate(30, resample=Image.BICUBIC).crop(
        ((side - width) // 2, (side - height) // 2,
         (side + width) // 2, (side + height) // 2))
    image = Image.composite(Image.new('RGB', size, BOTTOM),
                            Image.new('RGB', size, TOP), ramp)
    glow = Image.new('L', size, 0)
    rx, ry = width * 0.42, height * 0.5
    ImageDraw.Draw(glow).ellipse(
        (center[0] - rx, center[1] - ry, center[0] + rx, center[1] + ry),
        fill=120)
    glow = glow.filter(ImageFilter.GaussianBlur(min(size) // 6))
    return Image.composite(Image.new('RGB', size, GLOW), image, glow)


def check(draw, box, color):
    """A filled circle with a check mark in [box]."""
    left, top, right, bottom = box
    d = right - left
    draw.ellipse(box, fill=color)
    draw.line([(left + d * 0.28, top + d * 0.52),
               (left + d * 0.44, top + d * 0.68),
               (left + d * 0.74, top + d * 0.36)],
              fill=INK + (color[3],) if len(color) == 4 else INK,
              width=max(2, round(d * 0.11)), joint='curve')


def cross(draw, box, color):
    """A filled circle with an exclamation mark in [box]."""
    left, top, right, bottom = box
    d = right - left
    draw.ellipse(box, fill=color)
    white = (255, 255, 255, color[3]) if len(color) == 4 else 'white'
    w = max(2, round(d * 0.11))
    cx = left + d / 2
    draw.line([(cx, top + d * 0.24), (cx, top + d * 0.58)], fill=white,
              width=w)
    draw.ellipse((cx - w * 0.6, top + d * 0.7, cx + w * 0.6,
                  top + d * 0.7 + w * 1.2), fill=white)


def chip(text, valid, unit, alpha):
    """A translucent pill holding [text], with its validation mark."""
    f = mono(round(46 * unit))
    pad, mark = round(26 * unit), round(40 * unit)
    text_width = f.getlength(text)
    height = round(84 * unit)
    width = round(pad + mark + pad * 0.7 + text_width + pad * 1.2)
    image = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((0, 0, width - 1, height - 1), height // 2,
                           fill=(255, 255, 255, round(34 * alpha)),
                           outline=(255, 255, 255, round(70 * alpha)),
                           width=max(1, round(2 * unit)))
    top = (height - mark) // 2
    (check if valid else cross)(
        draw, (pad, top, pad + mark, top + mark),
        (VALID if valid else INVALID) + (round(235 * alpha),))
    draw.text((pad + mark + pad * 0.7, height / 2), text, font=f,
              fill=(255, 255, 255, round(225 * alpha)), anchor='lm')
    return image


def scatter(image, keep_out, unit, seed):
    """Floats CPFs and CNPJs over [image], away from the [keep_out] box,
    fading towards the edges."""
    rng = random.Random(seed)
    width, height = image.size
    cx, cy = (keep_out[0] + keep_out[2]) / 2, (keep_out[1] + keep_out[3]) / 2
    row = round(200 * unit)
    layer = Image.new('RGBA', image.size, (0, 0, 0, 0))
    y = rng.randint(-row // 2, 0)
    while y < height:
        x = -rng.randint(0, round(300 * unit))
        while x < width:
            kind = rng.random()
            value = (cpf(rng) if kind < 0.35 else
                     cnpj(rng, letters=kind > 0.55))
            valid = rng.random() > 0.18
            if not valid:
                value = broken(value)
            # Far from the hero, the pills fade out.
            distance = math.hypot((x - cx) / (width / 2),
                                  (y - cy) / (height / 2))
            alpha = max(0.2, 0.9 - 0.7 * distance)
            pill = chip(value, valid, unit, alpha)
            box = (x, y, x + pill.width, y + pill.height)
            # Some gaps, so they read as a texture rather than a table.
            if rng.random() > 0.3 and not (
                    box[2] > keep_out[0] and box[0] < keep_out[2] and
                    box[3] > keep_out[1] and box[1] < keep_out[3]):
                layer.alpha_composite(pill, (x, y))
            x += pill.width + rng.randint(round(160 * unit), round(420 * unit))
        y += row + rng.randint(0, round(30 * unit))
    image.paste(layer, (0, 0), layer)


def sparkle(draw, center, radius, color):
    """The icon's four-pointed star: an astroid."""
    cx, cy = center
    points = []
    for step in range(120):
        t = 2 * math.pi * step / 120
        points.append((cx + radius * math.cos(t) ** 3,
                       cy + radius * math.sin(t) ** 3))
    draw.polygon(points, fill=color)


def card(unit):
    """The icon's white card, holding the example CNPJ with its letters in
    violet and the validator's verdict."""
    width, height = round(1180 * unit), round(500 * unit)
    pad = round(64 * unit)
    image = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((0, 0, width - 1, height - 1), round(64 * unit),
                           fill='white')

    label = font(round(44 * unit), 600, 28)
    label_text = 'CNPJ alfanumérico'
    lw = label.getlength(label_text)
    lh = round(76 * unit)
    draw.rounded_rectangle((pad, pad, pad + lw + lh, pad + lh), lh // 2,
                           fill=(237, 233, 254))
    draw.text((pad + lh / 2, pad + lh / 2), label_text, font=label,
              fill=VIOLET, anchor='lm')

    # The widest monospaced size that fits.
    size = round(120 * unit)
    while mono(size, 700).getlength(EXAMPLE) > width - 2 * pad:
        size -= 1
    f = mono(size, 700)
    advance = f.getlength('0')
    y = round(height * 0.55)
    for index, c in enumerate(EXAMPLE):
        draw.text((pad + index * advance, y), c, font=f,
                  fill=VIOLET if c.isalpha() else INK, anchor='lm')

    mark = round(56 * unit)
    top = height - pad - mark
    check(draw, (pad, top, pad + mark, top + mark), (34, 197, 94))
    verdict = font(round(46 * unit), 600, 28)
    draw.text((pad + mark + round(22 * unit), top + mark / 2), 'Válido',
              font=verdict, fill=INK, anchor='lm')
    note = font(round(40 * unit), 500, 28)
    draw.text((width - pad, top + mark / 2), 'Filial 01DE', font=note,
              fill=MUTED, anchor='rm')
    return image


def hero(unit):
    """[PHRASE] over the card, tilted like the icon's, with its sparkles.
    What must be seen fits in HERO × [unit]; the image has [pad] more on
    every side for the shadow and the sparkles: (image, pad)."""
    pad = round(160 * unit)
    width, height = round(HERO[0] * unit), round(HERO[1] * unit)
    image = Image.new('RGBA', (width + 2 * pad, height + 2 * pad),
                      (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    phrase = font(round(100 * unit), 700, 96)
    draw.text((pad + width / 2, pad), PHRASE, font=phrase, fill='white',
              anchor='ma')
    phrase_bottom = draw.textbbox((pad + width / 2, pad), PHRASE,
                                  font=phrase, anchor='ma')[3]

    plain = card(unit)
    tilted = plain.rotate(-4, resample=Image.BICUBIC, expand=True)
    left = pad + (width - tilted.width) // 2
    top = phrase_bottom + round(64 * unit)
    shadow = Image.new('L', image.size, 0)
    shadow.paste(tilted.getchannel('A').point(lambda a: a * 150 // 255),
                 (left, top + round(36 * unit)))
    shadow = shadow.filter(ImageFilter.GaussianBlur(round(40 * unit)))
    image.paste(Image.new('RGBA', image.size, SHADOW + (255,)), (0, 0),
                shadow)
    image.alpha_composite(tilted, (left, top))
    # Over the card's top right corner, which the turn moves down by
    # width × sin 4°, as on the icon.
    corner = (left + tilted.width - round(36 * unit),
              top + round(plain.width * math.sin(math.radians(4))))
    sparkle(draw, corner, round(110 * unit), YELLOW)
    sparkle(draw, (corner[0] + round(100 * unit), corner[1] + round(140 * unit)),
            round(48 * unit), YELLOW)
    return image, pad


def inside(safe, size):
    """[size] centered in the [safe] box: (left, top)."""
    left, top, width, height = safe
    return (left + (width - size[0]) // 2, top + (height - size[1]) // 2)


def poster(canvas, safe, seed):
    """The hero alone in the safe area, over floating documents."""
    unit = min(safe[2] / HERO[0], safe[3] / HERO[1])
    art, pad = hero(unit)
    size = (art.width - 2 * pad, art.height - 2 * pad)
    left, top = inside(safe, size)
    image = background(canvas, (left + size[0] / 2, top + size[1] / 2))
    margin = round(90 * unit)
    scatter(image, (left - margin, top - margin, left + size[0] + margin,
                    top + size[1] + margin), unit, seed)
    image.paste(art, (left - pad, top - pad), art)
    return image


def search():
    """The hero and the validator on an iPhone, side by side. The phone is
    taller than the safe area, so that its screen can be read: only its
    status bar and bottom bar may be cut."""
    canvas, safe = SEARCH
    device = DEVICES['iphone']
    screen, mask = load_screen(device, SEARCH_SCREEN, None)
    phone, radius = framed(device, screen, mask)
    scale = safe[3] * 1.45 / phone.height
    phone = phone.resize((round(phone.width * scale),
                          round(phone.height * scale)), Image.LANCZOS)
    radius = round(radius * scale)
    gap = round(safe[2] * 0.06)
    unit = min((safe[2] - phone.width - gap) / HERO[0], safe[3] / HERO[1])
    art, pad = hero(unit)
    art_width, art_height = art.width - 2 * pad, art.height - 2 * pad
    group = art_width + gap + phone.width
    left = safe[0] + (safe[2] - group) // 2
    art_top = safe[1] + (safe[3] - art_height) // 2
    phone_left = left + art_width + gap
    phone_top = safe[1] + (safe[3] - phone.height) // 2

    image = background(canvas, (safe[0] + safe[2] / 2, safe[1] + safe[3] / 2))
    margin = round(90 * unit)
    scatter(image, (left - margin, phone_top - margin,
                    phone_left + phone.width + margin,
                    phone_top + phone.height + margin), unit, seed=3)
    shadow = Image.new('L', canvas, 0)
    ImageDraw.Draw(shadow).rounded_rectangle(
        (phone_left + 10, phone_top + 40, phone_left + phone.width - 10,
         phone_top + phone.height + 20), radius, fill=150)
    shadow = shadow.filter(ImageFilter.GaussianBlur(45))
    image = Image.composite(Image.new('RGB', canvas, SHADOW), image, shadow)
    image.paste(art, (left - pad, art_top - pad), art)
    image.paste(phone, (phone_left, phone_top), phone)
    return image


def main():
    out = OUT / 'creative'
    out.mkdir(parents=True, exist_ok=True)
    for name, (canvas, safe), seed in (('universal', UNIVERSAL, 1),
                                       ('header', HEADER, 2)):
        path = out / f'{name}_{canvas[0]}x{canvas[1]}.png'
        poster(canvas, safe, seed).convert('RGB').save(path)
        print(path.relative_to(OUT.parent.parent))
    if (SOURCE / 'iphone' / 'raw' / f'{SEARCH_SCREEN}.png').exists():
        path = out / f'search_{SEARCH[0][0]}x{SEARCH[0][1]}.png'
        search().convert('RGB').save(path)
        print(path.relative_to(OUT.parent.parent))
    else:
        print(f'search: skipped, no iphone/{SEARCH_SCREEN} — run capture.py')


if __name__ == '__main__':
    main()
