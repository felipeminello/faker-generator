"""Gera os arquivos-fonte do icone do Fake Generator.

Execute a partir da raiz do projeto:

    python tool/generate_icon.py

Os PNGs gerados em `assets/icon/` sao a fonte usada pelo `flutter_launcher_icons`
(veja a secao `flutter_launcher_icons` do `pubspec.yaml`). Depois de alterar este
script, rode:

    dart run flutter_launcher_icons

Conceito: um cartao de identificacao (UUID / CPF / CNPJ) com um brilho de
"gerado agora", sobre um gradiente roxo alinhado ao tema Material do app
(seed `Colors.deepPurple`).

Requer Python 3 com Pillow e numpy (`pip install pillow numpy`).
"""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

# Espaco de coordenadas logico do desenho: 1024x1024 unidades.
UNIT = 1024
# Fator de supersampling; tudo e desenhado ampliado e reduzido com LANCZOS.
SS = 4

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "assets" / "icon"
WINDOWS_ICO = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
LINUX_ICON_DIR = ROOT / "linux" / "packaging" / "icons" / "hicolor"
LINUX_APP_ID = "br.dev.minello.fake_generator"

# Lado do glifo (em unidades logicas) nas camadas do icone adaptativo do Android.
#
# O ic_launcher.xml gerado pelo flutter_launcher_icons envolve as camadas num
# <inset android:inset="16%">, ou seja, o PNG e desenhado nos 68% centrais da
# camada. Como a zona segura do Android e ~66% da camada, o glifo precisa sair
# daqui maior que a zona segura: 820/1024 * 0.68 = ~55% da camada, bem dentro da
# mascara (circulo, squircle, etc.) sem ficar pequeno demais.
ADAPTIVE_GLYPH_BOX = 820

# Tamanhos embutidos no .ico do Windows (barra de tarefas, Explorer, atalhos).
ICO_SIZES = (16, 24, 32, 48, 64, 128, 256)
# Tamanhos do tema de ícones do Linux (freedesktop hicolor).
LINUX_SIZES = (16, 32, 48, 64, 128, 256, 512)

BG_TOP = (0x8B, 0x5C, 0xF6)      # violeta claro
BG_BOTTOM = (0x4C, 0x1D, 0x95)   # violeta escuro
CARD = (0xFF, 0xFF, 0xFF)
INK_STRONG = (0x6D, 0x28, 0xD9)  # avatar e barra principal
INK_SOFT = (0xC4, 0xB5, 0xFD)    # barras secundarias
SPARK = (0xFB, 0xBF, 0x24)       # ambar do brilho

CARD_TILT = -8  # graus


def _px(value: float) -> float:
    """Converte unidades logicas para pixels do canvas ampliado."""
    return value * SS


def _new_layer() -> Image.Image:
    return Image.new("RGBA", (UNIT * SS, UNIT * SS), (0, 0, 0, 0))


def _rrect(draw, box, radius, fill=None, outline=None, width=0):
    draw.rounded_rectangle(
        [_px(box[0]), _px(box[1]), _px(box[2]), _px(box[3])],
        radius=_px(radius),
        fill=fill,
        outline=outline,
        width=int(_px(width)),
    )


def _star_points(cx, cy, radius, sharpness=2.8, steps=240):
    """Brilho de 4 pontas (curva tipo astroide)."""
    points = []
    for i in range(steps):
        theta = 2 * math.pi * i / steps
        cos_t, sin_t = math.cos(theta), math.sin(theta)
        x = cx + radius * math.copysign(abs(cos_t) ** sharpness, cos_t)
        y = cy + radius * math.copysign(abs(sin_t) ** sharpness, sin_t)
        points.append((_px(x), _px(y)))
    return points


def _draw_card_contents(draw, mono):
    """Avatar + linhas de texto dentro do cartao."""
    strong = (0xFF, 0xFF, 0xFF, 0xFF) if mono else (*INK_STRONG, 0xFF)
    soft = (0xFF, 0xFF, 0xFF, 0xFF) if mono else (*INK_SOFT, 0xFF)

    # Avatar.
    draw.ellipse([_px(272), _px(360), _px(400), _px(488)], fill=strong)
    # Linhas ao lado do avatar.
    _rrect(draw, (440, 386, 744, 424), 19, fill=strong)
    _rrect(draw, (440, 450, 664, 488), 19, fill=soft)
    # Linhas inferiores.
    _rrect(draw, (272, 556, 752, 596), 20, fill=soft)
    _rrect(draw, (272, 622, 608, 662), 20, fill=soft)


def render_glyph(mono=False, shadow=True):
    """Desenha o cartao inclinado + brilho num canvas transparente."""
    card_layer = _new_layer()
    card_draw = ImageDraw.Draw(card_layer)

    if mono:
        # Silhueta: contorno do cartao + conteudo cheio, tudo em branco.
        _rrect(card_draw, (212, 300, 812, 724), 56,
               outline=(255, 255, 255, 255), width=38)
    else:
        _rrect(card_draw, (212, 300, 812, 724), 56, fill=(*CARD, 0xFF))
    _draw_card_contents(card_draw, mono)

    card_layer = card_layer.rotate(
        CARD_TILT, resample=Image.BICUBIC, center=(_px(512), _px(512))
    )

    glyph = _new_layer()
    if shadow and not mono:
        alpha = card_layer.getchannel("A")
        shadow_layer = Image.new("RGBA", card_layer.size, (0x2E, 0x10, 0x65, 0xFF))
        shadow_layer.putalpha(alpha.point(lambda a: int(a * 0.45)))
        shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(_px(14)))
        glyph.alpha_composite(shadow_layer, (0, int(_px(18))))

    glyph.alpha_composite(card_layer)

    # Brilho sobre o canto superior direito do cartao.
    spark_draw = ImageDraw.Draw(glyph)
    spark_color = (0xFF, 0xFF, 0xFF, 0xFF) if mono else (*SPARK, 0xFF)
    spark_draw.polygon(_star_points(806, 292, 132), fill=spark_color)
    spark_draw.polygon(_star_points(888, 424, 54), fill=spark_color)

    return glyph


def render_background(rounded):
    """Gradiente diagonal, com ou sem cantos arredondados."""
    size = UNIT * SS
    y, x = np.mgrid[0:size, 0:size].astype(np.float32)
    t = np.clip((x * 0.45 + y * 0.55) / (size - 1), 0.0, 1.0)

    bg = np.stack([BG_TOP[i] + (BG_BOTTOM[i] - BG_TOP[i]) * t for i in range(3)],
                  axis=-1)

    # Realce radial suave no canto superior esquerdo.
    dist = np.sqrt((x / size - 0.18) ** 2 + (y / size - 0.12) ** 2)
    glow = np.clip(1.0 - dist / 0.85, 0.0, 1.0) ** 2 * 42.0
    bg = np.clip(bg + glow[..., None], 0, 255).astype(np.uint8)

    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    image.paste(Image.fromarray(bg, "RGB"), (0, 0))

    if rounded:
        mask = Image.new("L", (size, size), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            [0, 0, size - 1, size - 1], radius=_px(224), fill=255
        )
        image.putalpha(mask)
    else:
        image.putalpha(255)
    return image


def _downscale(image, size=UNIT):
    return image.resize((size, size), Image.LANCZOS)


def _fit_glyph(glyph, target_box):
    """Centraliza o glifo num canvas 1024 ocupando no maximo `target_box` unidades."""
    cropped = glyph.crop(glyph.getbbox())
    scale = _px(target_box) / max(cropped.size)
    cropped = cropped.resize(
        (max(1, round(cropped.width * scale)), max(1, round(cropped.height * scale))),
        Image.LANCZOS,
    )

    canvas = _new_layer()
    canvas.alpha_composite(
        cropped,
        ((canvas.width - cropped.width) // 2, (canvas.height - cropped.height) // 2),
    )
    return canvas


def save(image, name, flatten_on=None):
    out = _downscale(image)
    if flatten_on is not None:
        base = Image.new("RGB", out.size, flatten_on)
        base.paste(out, mask=out.getchannel("A"))
        out = base
    out.save(OUT_DIR / name)
    print("  assets/icon/{}  ({}, {}x{})".format(name, out.mode, *out.size))


def write_windows_ico(rounded):
    """Escreve o .ico do runner do Windows com todos os tamanhos embutidos.

    O flutter_launcher_icons grava um .ico com um unico quadro de 256px; embutir
    os tamanhos pequenos deixa o icone mais nitido na barra de tarefas e no
    Explorer. Por isso o Windows nao aparece na secao `flutter_launcher_icons`
    do pubspec.yaml.
    """
    base = _downscale(rounded)
    frames = [base.resize((s, s), Image.LANCZOS) for s in ICO_SIZES]
    WINDOWS_ICO.parent.mkdir(parents=True, exist_ok=True)
    frames[-1].save(WINDOWS_ICO, format="ICO",
                    sizes=[(s, s) for s in ICO_SIZES],
                    append_images=frames[:-1])
    print("  windows/runner/resources/app_icon.ico  ({})".format(
        ", ".join("{0}x{0}".format(s) for s in ICO_SIZES)))


def write_linux_icons(rounded):
    """Escreve o tema de icones freedesktop usado no empacotamento do Linux."""
    base = _downscale(rounded)
    for size in LINUX_SIZES:
        target = LINUX_ICON_DIR / "{0}x{0}".format(size) / "apps"
        target.mkdir(parents=True, exist_ok=True)
        base.resize((size, size), Image.LANCZOS).save(
            target / "{}.png".format(LINUX_APP_ID)
        )
    print("  linux/packaging/icons/hicolor/<tamanho>/apps/{}.png  ({})".format(
        LINUX_APP_ID, ", ".join(str(s) for s in LINUX_SIZES)))


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    print("Gerando icones em assets/icon/ ...")

    glyph = render_glyph()

    # Icone completo, cantos arredondados (Windows .ico, Linux, fallback geral).
    rounded = render_background(rounded=True)
    rounded.alpha_composite(glyph)
    save(rounded, "app_icon.png")

    # iOS: quadrado cheio e sem alfa - o proprio iOS aplica a mascara.
    square = render_background(rounded=False)
    square.alpha_composite(glyph)
    save(square, "app_icon_ios.png", flatten_on=BG_BOTTOM)

    # macOS: corpo do icone em 824/1024 da tela, conforme a grade da Apple.
    body = _downscale(rounded, 824)
    macos = Image.new("RGBA", (UNIT, UNIT), (0, 0, 0, 0))
    macos.alpha_composite(body, ((UNIT - body.width) // 2, (UNIT - body.height) // 2))
    macos.save(OUT_DIR / "app_icon_macos.png")
    print("  assets/icon/app_icon_macos.png  (RGBA, 1024x1024)")

    # Android adaptativo: fundo quadrado + primeiro plano dentro da zona segura.
    save(render_background(rounded=False), "app_icon_background.png")
    save(_fit_glyph(glyph, ADAPTIVE_GLYPH_BOX), "app_icon_foreground.png")
    save(_fit_glyph(render_glyph(mono=True, shadow=False), ADAPTIVE_GLYPH_BOX),
         "app_icon_monochrome.png")

    # Plataformas que o flutter_launcher_icons nao cobre bem sao escritas aqui.
    write_windows_ico(rounded)
    write_linux_icons(rounded)

    print("Pronto. Rode `dart run flutter_launcher_icons` para propagar para "
          "Android, iOS e macOS.")


if __name__ == "__main__":
    main()
