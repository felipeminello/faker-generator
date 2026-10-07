"""Turns what capture.py saved in build/store_media/<device>/ into App Store
screenshots, in build/store_media/out/ (outside git, like the rest of build/):

- ios-1284x2778/: 1284 × 2778 PNGs (RGB), with a caption and a device frame;
- ipad-2064x2752/: 2064 × 2752 PNGs, the same way;
- macos-2880x1800/: 2880 × 1800 PNGs, with the app in a window.

Needs Pillow: python tool/store_media/compose.py [iphone|ipad|mac ...]
(every device that was captured, by default).
"""

import dataclasses
import pathlib
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = pathlib.Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'build' / 'store_media'
OUT = SOURCE / 'out'

FONT = '/System/Library/Fonts/SFNS.ttf'


@dataclasses.dataclass
class Device:
    key: str
    name: str
    folder: str
    size: tuple
    screen_width: int
    bezel: int
    title_size: int
    subtitle_size: int
    bottom_margin: int
    # iPadOS draws a window resize handle inside this box, which full screen
    # apps don't have; its shape is taken from [handle_reference], a capture
    # with a plain background there. None when there is nothing to erase.
    handle: tuple = None
    handle_reference: str = None


MAC_SIZE = (2880, 1800)
MAC_TITLE_BAR = 56

DEVICES = {
    'iphone': Device('iphone', 'iPhone', 'ios-1284x2778', (1284, 2778),
                     screen_width=924, bezel=26, title_size=104,
                     subtitle_size=50, bottom_margin=110),
    'ipad': Device('ipad', 'iPad', 'ipad-2064x2752', (2064, 2752),
                   screen_width=1440, bezel=38, title_size=140,
                   subtitle_size=66, bottom_margin=120,
                   handle=(2004, 2692, 2058, 2748),
                   handle_reference='05_uuid'),
}

# In App Store order: captured screen, headline, subtitle.
SCREENSHOTS = [
    ('01_cpf', 'CPF válido\npara seus testes',
     'Em lote, por estado, exportado em CSV ou JSON'),
    ('02_cnpj', 'CNPJ numérico\ne alfanumérico',
     'O novo formato da Receita Federal'),
    ('03_validar', 'Valide listas\nde CPF e CNPJ',
     'Aponta o erro e mostra o valor certo'),
    ('04_cron', 'Cron explicado\nem português',
     'E as próximas execuções, enquanto digita'),
    ('05_uuid', 'UUID v4\nem um toque',
     'Identificadores aleatórios, prontos para copiar'),
]

# The icon's violet.
TOP, BOTTOM = (139, 92, 246), (60, 22, 120)
GLOW = (196, 181, 253)
SHADOW = (24, 8, 52)
SUBTITLE = (237, 233, 254)


def font(size, weight, optical):
    f = ImageFont.truetype(FONT, size)
    # Axes: width, optical size, grade, weight.
    f.set_variation_by_axes([100, optical, 400, weight])
    return f


def background(size):
    width, height = size
    gradient = Image.linear_gradient('L').resize(size)
    image = Image.composite(Image.new('RGB', size, BOTTOM),
                            Image.new('RGB', size, TOP), gradient)
    # Soft light behind the caption.
    glow = Image.new('L', size, 0)
    ImageDraw.Draw(glow).ellipse(
        (-width * 0.3, -height * 0.25, width * 1.3, height * 0.3), fill=90)
    glow = glow.filter(ImageFilter.GaussianBlur(160))
    return Image.composite(Image.new('RGB', size, GLOW), image, glow)


def caption(image, top, headline, subtitle, title_font, subtitle_font,
            spacing, gap):
    """Centers [headline] and [subtitle] in the space above [top]."""
    width = image.width
    draw = ImageDraw.Draw(image)
    title_box = draw.multiline_textbbox((0, 0), headline, font=title_font,
                                        spacing=spacing, align='center')
    subtitle_box = draw.textbbox((0, 0), subtitle, font=subtitle_font)
    for box, text in ((title_box, headline), (subtitle_box, subtitle)):
        if box[2] - box[0] > width * 0.92:
            raise SystemExit(f'Too wide for {width}px: {text!r}')
    block = (title_box[3] - title_box[1]) + gap + (
        subtitle_box[3] - subtitle_box[1])
    y = (top - block) // 2 + 10
    draw.multiline_text((width // 2, y - title_box[1]), headline,
                        font=title_font, fill='white', anchor='ma',
                        spacing=spacing, align='center')
    y += title_box[3] - title_box[1] + gap
    draw.text((width // 2, y - subtitle_box[1]), subtitle,
              font=subtitle_font, fill=SUBTITLE, anchor='ma')


def load_screen(device, name, handle):
    """The captured screen, as RGB, and the display's shape as a mask."""
    screen = Image.open(SOURCE / device.key / 'raw' / f'{name}.png')
    screen = screen.convert('RGB')
    if handle:
        erase(screen, handle)
    mask = Image.open(SOURCE / device.key / 'masked' / f'{name}.png')
    return screen, mask.getchannel('A')


def handle_pixels(device):
    """The resize handle's pixels, with a margin for its antialiasing."""
    reference = Image.open(
        SOURCE / device.key / 'raw' / f'{device.handle_reference}.png',
    ).convert('RGB')
    left, top, right, bottom = device.handle
    plain = reference.getpixel((left, top))
    found = [(x, y) for x in range(left, right) for y in range(top, bottom)
             if sum(abs(a - b) for a, b in
                    zip(reference.getpixel((x, y)), plain)) > 6]
    return sorted({(x + dx, y + dy) for x, y in found
                   for dx in range(-2, 3) for dy in range(-2, 3)})


def erase(image, pixels):
    """Fills [pixels] from their surroundings, by repeatedly averaging each
    one's neighbors, which carries the soft shadows around them through."""
    image_pixels = image.load()
    # In floats: rounding every step would stall short of the background.
    values = {pixel: image_pixels[pixel] for pixel in pixels}

    def value(pixel):
        return values[pixel] if pixel in values else image_pixels[pixel]

    for _ in range(500):
        for x, y in pixels:
            neighbors = (value((x - 1, y)), value((x + 1, y)),
                         value((x, y - 1)), value((x, y + 1)))
            values[x, y] = tuple(sum(c) / 4 for c in zip(*neighbors))
    for pixel, color in values.items():
        image_pixels[pixel] = tuple(round(c) for c in color)


def framed(device, screen, mask):
    """[screen] inside a device frame shaped after [mask]."""
    width = device.screen_width
    scale = width / screen.width
    size = (width, round(screen.height * scale))
    screen = screen.convert('RGBA').resize(size, Image.LANCZOS)
    screen.putalpha(mask.resize(size, Image.LANCZOS))
    # Corners are rounder than a circle: the mask reaches the top edge a
    # little further in than the matching radius.
    corner = next(x for x in range(mask.width) if mask.getpixel((x, 0)) > 128)
    radius = round(corner * 0.89 * scale)
    bezel = device.bezel
    outer = (size[0] + 2 * bezel, size[1] + 2 * bezel)
    frame = Image.new('RGBA', outer, (0, 0, 0, 0))
    draw = ImageDraw.Draw(frame)
    draw.rounded_rectangle((0, 0, outer[0] - 1, outer[1] - 1),
                           radius + bezel, fill=(58, 58, 70, 255))
    draw.rounded_rectangle((4, 4, outer[0] - 5, outer[1] - 5),
                           radius + bezel - 4, fill=(10, 10, 14, 255))
    frame.alpha_composite(screen, (bezel, bezel))
    return frame, radius + bezel


def screenshot(device, screen, mask, headline, subtitle):
    size = device.size
    width, height = size
    image = background(size)

    frame, radius = framed(device, screen, mask)
    top = height - device.bottom_margin - frame.height
    left = (width - frame.width) // 2

    shadow = Image.new('L', size, 0)
    ImageDraw.Draw(shadow).rounded_rectangle(
        (left + 10, top + 40, left + frame.width - 10,
         top + frame.height + 20), radius, fill=150)
    shadow = shadow.filter(ImageFilter.GaussianBlur(45))
    image = Image.composite(Image.new('RGB', size, SHADOW), image, shadow)
    image.paste(frame, (left, top), frame)

    caption(image, top, headline, subtitle,
            font(device.title_size, 700, 96),
            font(device.subtitle_size, 500, 28),
            spacing=round(device.title_size * 0.17),
            gap=round(device.title_size * 0.35))
    return image


def mac_window(screen):
    """[screen], the app's content, under a macOS title bar."""
    width, height = screen.width, screen.height + MAC_TITLE_BAR
    radius = 28
    bar, line, text = (236, 236, 238), (206, 206, 210), (96, 96, 102)
    window = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(window)
    draw.rectangle((0, 0, width, MAC_TITLE_BAR), fill=bar)
    draw.line((0, MAC_TITLE_BAR - 1, width, MAC_TITLE_BAR - 1), fill=line,
              width=2)
    for index, color in enumerate(((255, 95, 87), (254, 188, 46),
                                   (40, 200, 64))):
        x = 36 + index * 40
        draw.ellipse((x - 13, MAC_TITLE_BAR // 2 - 13,
                      x + 13, MAC_TITLE_BAR // 2 + 13), fill=color)
    title = font(26, 600, 28)
    draw.text((width // 2, MAC_TITLE_BAR // 2), 'Massa de Teste',
              font=title, fill=text, anchor='mm')
    window.paste(screen.convert('RGBA'), (0, MAC_TITLE_BAR))
    mask = Image.new('L', window.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, width - 1, height - 1),
                                           radius, fill=255)
    window.putalpha(mask)
    return window, radius


def mac_screenshot(screen, headline, subtitle):
    size = MAC_SIZE
    width, height = size
    image = background(size)
    window, radius = mac_window(screen)
    left, top = (width - window.width) // 2, height - 84 - window.height

    shadow = Image.new('L', size, 0)
    ImageDraw.Draw(shadow).rounded_rectangle(
        (left + 20, top + 50, left + window.width - 20,
         top + window.height + 30), radius, fill=170)
    shadow = shadow.filter(ImageFilter.GaussianBlur(50))
    image = Image.composite(Image.new('RGB', size, SHADOW), image, shadow)
    # A hairline around the window, as macOS draws.
    edge = Image.new('RGBA', size, (0, 0, 0, 0))
    ImageDraw.Draw(edge).rounded_rectangle(
        (left - 2, top - 2, left + window.width + 1, top + window.height + 1),
        radius + 2, outline=(255, 255, 255, 60), width=2)
    image.paste(edge, (0, 0), edge)
    image.paste(window, (left, top), window)

    caption(image, top, headline, subtitle, font(110, 700, 96),
            font(54, 500, 28), spacing=19, gap=38)
    return image


def compose_mac():
    out = OUT / 'macos-2880x1800'
    out.mkdir(parents=True, exist_ok=True)
    for name, headline, subtitle in SCREENSHOTS:
        screen = Image.open(SOURCE / 'mac' / 'raw' / f'{name}.png')
        mac_screenshot(screen.convert('RGB'), headline.replace('\n', ' '),
                       subtitle).save(out / f'{name}.png')
        print(f'macos-2880x1800/{name}.png')


def compose(key):
    if key == 'mac':
        return compose_mac()
    device = DEVICES[key]
    out = OUT / device.folder
    out.mkdir(parents=True, exist_ok=True)
    handle = handle_pixels(device) if device.handle else None

    for name, headline, subtitle in SCREENSHOTS:
        screen, mask = load_screen(device, name, handle)
        screenshot(device, screen, mask, headline, subtitle).save(
            out / f'{name}.png')
        print(f'{device.folder}/{name}.png')


def main():
    keys = sys.argv[1:] or [key for key in [*DEVICES, 'mac']
                            if (SOURCE / key / 'raw').exists()]
    for key in keys:
        compose(key)


if __name__ == '__main__':
    main()
