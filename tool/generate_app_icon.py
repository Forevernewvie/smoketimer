#!/usr/bin/env python3
"""
Generate simple launcher icons used by flutter_launcher_icons.

Design goals:
- Premium minimal icon, readable at small sizes
- Uses the app's primary blue (#2563EB) and simple cigarette motif
- No text, no smoke; controlled ember glow only
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageOps


SIZE = 1024
BLUE = (0x25, 0x63, 0xEB, 0xFF)  # #2563EB
BLUE_EDGE = (0x1D, 0x4E, 0xD8, 0xFF)  # #1D4ED8 (subtle edge gradient)

PAPER = (0xF8, 0xFA, 0xFC, 0xFF)  # off-white w/ tiny cool tint
FILTER = (0xF4, 0xC7, 0x8B, 0xFF)  # #F4C78B
STRIPE = (0xD8, 0xA3, 0x5E, 0xFF)  # #D8A35E

EMBER_RED = (0xEF, 0x44, 0x44, 0xFF)  # #EF4444
EMBER_ORANGE = (0xF9, 0x73, 0x16, 0xFF)  # #F97316
HIGHLIGHT = (0xFF, 0xFF, 0xFF, 0x22)


def _make_background() -> Image.Image:
  center = Image.new("RGBA", (SIZE, SIZE), BLUE)
  edge = Image.new("RGBA", (SIZE, SIZE), BLUE_EDGE)
  mask = Image.radial_gradient("L").resize((SIZE, SIZE))

  # Make it ultra-subtle by compressing the mask range.
  mask = mask.point(lambda p: int(p * 0.45))
  return Image.composite(edge, center, mask)


def _radial_color_disc(
  size: int,
  *,
  inner: tuple[int, int, int, int],
  outer: tuple[int, int, int, int],
  alpha: int = 255,
) -> Image.Image:
  """Disc with red->orange color gradient. Alpha is controlled by circle mask."""
  mask = Image.radial_gradient("L").resize((size, size))
  img_outer = Image.new("RGBA", (size, size), outer)
  img_inner = Image.new("RGBA", (size, size), inner)
  grad = Image.composite(img_outer, img_inner, mask)  # inner at center

  a = Image.new("L", (size, size), 0)
  ad = ImageDraw.Draw(a)
  ad.ellipse((0, 0, size - 1, size - 1), fill=alpha)
  grad.putalpha(a)
  return grad


def _draw_cigarette_layer(*, scale: float = 1.0) -> Image.Image:
  layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
  draw = ImageDraw.Draw(layer)

  cx = SIZE / 2
  cy = SIZE / 2

  cig_w = int(620 * scale)
  cig_h = int(136 * scale)
  r = cig_h // 2

  x0 = int(cx - cig_w / 2)
  y0 = int(cy - cig_h / 2)
  x1 = x0 + cig_w
  y1 = y0 + cig_h

  # Base paper pill
  draw.rounded_rectangle((x0, y0, x1, y1), radius=r, fill=PAPER)

  # Filter (flat join on the right; rounded on the left)
  filter_w = int(cig_w * 0.25)
  draw.rectangle((x0, y0, x0 + filter_w, y1), fill=FILTER)
  draw.ellipse((x0, y0, x0 + cig_h, y1), fill=FILTER)

  # Filter stripes (3)
  stripe_w = max(10, int(cig_w * 0.018))
  stripe_h_pad = int(cig_h * 0.18)
  stripe_gap = int(stripe_w * 1.35)
  sx = x0 + int(cig_h * 0.40)
  for _ in range(3):
    draw.rectangle(
      (sx, y0 + stripe_h_pad, sx + stripe_w, y1 - stripe_h_pad),
      fill=STRIPE,
    )
    sx += stripe_w + stripe_gap

  # Subtle highlight strip on paper (optional shading)
  hl_x0 = x0 + filter_w + int(cig_h * 0.10)
  hl_x1 = x1 - int(cig_h * 0.18)
  hl_y0 = y0 + int(cig_h * 0.12)
  hl_y1 = y0 + int(cig_h * 0.34)
  draw.rounded_rectangle(
    (hl_x0, hl_y0, hl_x1, hl_y1),
    radius=int(cig_h * 0.16),
    fill=HIGHLIGHT,
  )

  # Ember (tight gradient + faint halo confined near tip only)
  ember_cx = x1 - int(cig_h * 0.10)
  ember_cy = (y0 + y1) // 2

  # Halo: small, soft, local blur only
  halo = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
  hd = ImageDraw.Draw(halo)
  halo_r = int(cig_h * 0.48)
  hd.ellipse(
    (
      ember_cx - halo_r,
      ember_cy - halo_r,
      ember_cx + halo_r,
      ember_cy + halo_r,
    ),
    fill=(EMBER_ORANGE[0], EMBER_ORANGE[1], EMBER_ORANGE[2], 90),
  )
  halo = halo.filter(ImageFilter.GaussianBlur(radius=max(1, int(cig_h * 0.08))))
  layer = Image.alpha_composite(layer, halo)

  disc = _radial_color_disc(
    int(cig_h * 0.92),
    inner=EMBER_RED,
    outer=EMBER_ORANGE,
  )
  disc_x = int(ember_cx - disc.size[0] / 2)
  disc_y = int(ember_cy - disc.size[1] / 2)
  layer.paste(disc, (disc_x, disc_y), disc)

  return layer


def _save_png(img: Image.Image, path: Path) -> None:
  path.parent.mkdir(parents=True, exist_ok=True)
  img.save(path, format="PNG", optimize=True)


def main() -> None:
  root = Path(__file__).resolve().parents[1]
  out_dir = root / "assets" / "icon"

  # Full icon (for iOS and legacy Android)
  full = _make_background()
  cigarette = _draw_cigarette_layer(scale=1.0).rotate(
    12,
    resample=Image.Resampling.BICUBIC,
    expand=False,
    center=(SIZE / 2, SIZE / 2),
    fillcolor=(0, 0, 0, 0),
  )
  full = Image.alpha_composite(full, cigarette)
  _save_png(full, out_dir / "app_icon.png")

  # Adaptive icon foreground (transparent background)
  fg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
  fg_cigarette = _draw_cigarette_layer(scale=0.96).rotate(
    12,
    resample=Image.Resampling.BICUBIC,
    expand=False,
    center=(SIZE / 2, SIZE / 2),
    fillcolor=(0, 0, 0, 0),
  )
  fg = Image.alpha_composite(fg, fg_cigarette)
  _save_png(fg, out_dir / "app_icon_foreground.png")

  print(f"Wrote: {out_dir / 'app_icon.png'}")
  print(f"Wrote: {out_dir / 'app_icon_foreground.png'}")


if __name__ == "__main__":
  main()
