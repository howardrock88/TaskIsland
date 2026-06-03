#!/usr/bin/env python3
from __future__ import annotations

import os
import subprocess
from collections import deque
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "posters"
SCREENSHOTS = ROOT / "assets" / "screenshots"
UI_SNAPSHOTS = ROOT / "assets" / "ui-snapshots"
ICON = ROOT / "Resources" / "AppIcon.png"

FONT_CANDIDATES = [
    "/System/Library/Fonts/Hiragino Sans GB.ttc",
    "/System/Library/Fonts/PingFang.ttc",
    "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
    "/System/Library/Fonts/Helvetica.ttc",
]


def font(size: int, weight: str = "regular") -> ImageFont.FreeTypeFont:
    for path in FONT_CANDIDATES:
        try:
            return ImageFont.truetype(path, size=size)
        except OSError:
            continue
    return ImageFont.load_default()


def lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    w, h = size
    img = Image.new("RGB", size)
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(h - 1, 1)
        color = tuple(lerp(top[i], bottom[i], t) for i in range(3))
        draw.line([(0, y), (w, y)], fill=color)
    return img.convert("RGBA")


def multistop_gradient(size: tuple[int, int], stops: list[tuple[float, tuple[int, int, int]]]) -> Image.Image:
    w, h = size
    img = Image.new("RGB", size)
    draw = ImageDraw.Draw(img)
    stops = sorted(stops, key=lambda item: item[0])

    for y in range(h):
        t = y / max(h - 1, 1)
        lower = stops[0]
        upper = stops[-1]
        for index in range(len(stops) - 1):
            if stops[index][0] <= t <= stops[index + 1][0]:
                lower = stops[index]
                upper = stops[index + 1]
                break

        span = max(upper[0] - lower[0], 0.001)
        local_t = min(max((t - lower[0]) / span, 0), 1)
        color = tuple(lerp(lower[1][i], upper[1][i], local_t) for i in range(3))
        draw.line([(0, y), (w, y)], fill=color)

    return img.convert("RGBA")


def poster_background(size: tuple[int, int]) -> Image.Image:
    return multistop_gradient(
        size,
        [
            (0.00, (211, 247, 245)),
            (0.22, (190, 241, 237)),
            (0.56, (51, 139, 137)),
            (1.00, (9, 45, 59)),
        ],
    )


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def paste_glass(
    base: Image.Image,
    xy: tuple[int, int],
    size: tuple[int, int],
    radius: int,
    tint: tuple[int, int, int, int],
    stroke: tuple[int, int, int, int] = (255, 255, 255, 80),
    shadow: bool = True,
) -> ImageDraw.ImageDraw:
    x, y = xy
    w, h = size
    mask = rounded_mask(size, radius)

    if shadow:
        shadow_alpha = mask.filter(ImageFilter.GaussianBlur(18)).point(lambda alpha: int(alpha * 0.22))
        shadow_layer = Image.new("RGBA", size, (0, 0, 0, 0))
        shadow_layer.putalpha(shadow_alpha)
        base.alpha_composite(shadow_layer, (x, y + 14))

    panel = Image.new("RGBA", size, tint)
    shine = gradient(size, (255, 255, 255), (255, 255, 255))
    shine_alpha = Image.new("L", size, 0)
    shine_draw = ImageDraw.Draw(shine_alpha)
    shine_draw.polygon([(0, 0), (w, 0), (int(w * 0.68), int(h * 0.45)), (0, int(h * 0.2))], fill=64)
    shine.putalpha(shine_alpha.filter(ImageFilter.GaussianBlur(18)))
    panel.alpha_composite(shine)

    edge = Image.new("RGBA", size, (0, 0, 0, 0))
    edge_draw = ImageDraw.Draw(edge)
    edge_draw.rounded_rectangle((1, 1, w - 2, h - 2), radius=radius - 1, outline=stroke, width=2)
    edge_draw.rounded_rectangle((6, 6, w - 7, int(h * 0.38)), radius=max(radius - 8, 8), outline=(255, 255, 255, 48), width=1)
    panel.alpha_composite(edge)

    clipped = Image.new("RGBA", size, (0, 0, 0, 0))
    clipped.alpha_composite(panel)
    clipped.putalpha(mask)
    base.alpha_composite(clipped, xy)
    return ImageDraw.Draw(base)


def draw_wrapped(draw: ImageDraw.ImageDraw, text: str, xy: tuple[int, int], width: int, fnt: ImageFont.FreeTypeFont, fill, spacing: int = 8) -> int:
    x, y = xy
    line = ""
    for char in text:
        test = line + char
        if draw.textlength(test, font=fnt) <= width or not line:
            line = test
            continue
        draw.text((x, y), line, font=fnt, fill=fill)
        y += fnt.size + spacing
        line = char
    if line:
        draw.text((x, y), line, font=fnt, fill=fill)
        y += fnt.size + spacing
    return y


def draw_chip(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, fill=(230, 252, 255, 152), stroke=(255, 255, 255, 150)):
    fnt = font(30)
    x, y = xy
    tw = int(draw.textlength(text, font=fnt))
    box = (x, y, x + tw + 34, y + 46)
    draw.rounded_rectangle(box, radius=23, fill=fill, outline=stroke, width=1)
    draw.text((x + 17, y + 7), text, font=fnt, fill=(23, 88, 96, 228))
    return box[2] + 14


def chip_width(text: str) -> int:
    return int(ImageDraw.Draw(Image.new("RGBA", (1, 1))).textlength(text, font=font(30))) + 34


def remove_icon_canvas(icon: Image.Image) -> Image.Image:
    icon = icon.copy()
    pixels = icon.load()
    width, height = icon.size
    queue: deque[tuple[int, int]] = deque()
    visited: set[tuple[int, int]] = set()

    def is_blank(pixel: tuple[int, int, int, int]) -> bool:
        red, green, blue, alpha = pixel
        return alpha > 0 and red >= 238 and green >= 238 and blue >= 238 and max(red, green, blue) - min(red, green, blue) <= 18

    for x in range(width):
        for y in (0, height - 1):
            if is_blank(pixels[x, y]):
                queue.append((x, y))
                visited.add((x, y))

    for y in range(height):
        for x in (0, width - 1):
            if (x, y) not in visited and is_blank(pixels[x, y]):
                queue.append((x, y))
                visited.add((x, y))

    while queue:
        x, y = queue.popleft()
        red, green, blue, _ = pixels[x, y]
        pixels[x, y] = (red, green, blue, 0)
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if nx < 0 or ny < 0 or nx >= width or ny >= height or (nx, ny) in visited:
                continue
            if is_blank(pixels[nx, ny]):
                queue.append((nx, ny))
                visited.add((nx, ny))

    return icon


def draw_icon(base: Image.Image, xy: tuple[int, int], size: int):
    icon = Image.open(ICON).convert("RGBA").resize((size, size), Image.Resampling.LANCZOS)
    icon = remove_icon_canvas(icon)
    base.alpha_composite(icon, xy)


def ensure_ui_snapshots():
    required = [
        UI_SNAPSHOTS / "island-collapsed.png",
        UI_SNAPSHOTS / "island-attention.png",
        UI_SNAPSHOTS / "island-expanded.png",
        UI_SNAPSHOTS / "task-panel.png",
        UI_SNAPSHOTS / "task-panel-today.png",
        UI_SNAPSHOTS / "task-panel-review.png",
        UI_SNAPSHOTS / "quick-add.png",
        UI_SNAPSHOTS / "task-detail.png",
        UI_SNAPSHOTS / "settings-display.png",
        UI_SNAPSHOTS / "settings-priority-capsule.png",
        UI_SNAPSHOTS / "settings-shortcuts-data.png",
    ]
    if os.environ.get("TASKISLAND_SKIP_UI_RENDER") == "1" and all(path.exists() for path in required):
        return

    subprocess.run(
        [
            "swift",
            "run",
            "TaskIsland",
            "--render-marketing-assets",
            "--marketing-output",
            str(UI_SNAPSHOTS),
        ],
        cwd=ROOT,
        check=True,
    )
    clip_ui_snapshots()


def clip_ui_snapshots():
    for name, (logical_width, radius) in clip_specs.items():
        path = UI_SNAPSHOTS / name
        image = Image.open(path).convert("RGBA")
        clipped_ui_snapshot(name, image).save(path)


clip_specs = {
    "island-collapsed.png": (172, "capsule"),
    "island-attention.png": (340, "capsule"),
    "island-expanded.png": (440, 28),
    "task-panel.png": (430, 28),
    "task-panel-today.png": (430, 28),
    "task-panel-review.png": (430, 28),
    "quick-add.png": (500, 24),
    "task-detail.png": (430, 12),
    "settings-display.png": (430, 28),
    "settings-priority-capsule.png": (430, 28),
    "settings-shortcuts-data.png": (430, 28),
}


def clipped_ui_snapshot(name: str, image: Image.Image) -> Image.Image:
    spec = clip_specs.get(name)
    if spec is None:
        return image

    logical_width, radius = spec
    scale = image.width / logical_width
    radius_px = image.height // 2 if radius == "capsule" else int(radius * scale)
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, image.width - 1, image.height - 1),
        radius=radius_px,
        fill=255,
    )
    clipped = image.copy()
    clipped.putalpha(ImageChops.multiply(clipped.getchannel("A"), mask))
    return clipped


def paste_ui_snapshot(base: Image.Image, name: str, xy: tuple[int, int], scale: float = 1.0) -> tuple[int, int]:
    image = clipped_ui_snapshot(name, Image.open(UI_SNAPSHOTS / name).convert("RGBA"))
    size = (int(image.width / 3 * scale), int(image.height / 3 * scale))
    image = image.resize(size, Image.Resampling.LANCZOS)
    alpha = image.getchannel("A")
    blur = max(8, int(18 * scale))
    pad = blur * 3
    shadow_alpha = Image.new("L", (size[0] + pad * 2, size[1] + pad * 2), 0)
    shadow_alpha.paste(alpha, (pad, pad))
    shadow_alpha = shadow_alpha.filter(ImageFilter.GaussianBlur(blur)).point(lambda value: int(value * 0.34))
    shadow = Image.new("RGBA", shadow_alpha.size, (0, 0, 0, 0))
    shadow.putalpha(shadow_alpha)
    base.alpha_composite(shadow, (xy[0] - pad, xy[1] - pad + max(4, int(10 * scale))))
    base.alpha_composite(image, xy)
    return size


def draw_plus(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], ink, scale: float):
    x1, y1, x2, y2 = box
    cx = (x1 + x2) // 2
    cy = (y1 + y2) // 2
    arm = int(8 * scale)
    width = max(2, int(2 * scale))
    draw.line((cx - arm, cy, cx + arm, cy), fill=ink, width=width)
    draw.line((cx, cy - arm, cx, cy + arm), fill=ink, width=width)


def draw_check(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], ink, scale: float):
    x1, y1, x2, y2 = box
    draw.line(
        (
            x1 + int(11 * scale),
            y1 + int(22 * scale),
            x1 + int(18 * scale),
            y1 + int(29 * scale),
            x1 + int(31 * scale),
            y1 + int(14 * scale),
        ),
        fill=ink,
        width=max(3, int(3 * scale)),
        joint="curve",
    )


def draw_pin(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], ink, scale: float):
    x1, y1, x2, y2 = box
    cx = (x1 + x2) // 2
    top = y1 + int(10 * scale)
    draw.rounded_rectangle(
        (cx - int(8 * scale), top, cx + int(8 * scale), top + int(11 * scale)),
        radius=int(4 * scale),
        outline=ink,
        width=max(2, int(2 * scale)),
    )
    draw.line((cx, top + int(11 * scale), cx, y2 - int(9 * scale)), fill=ink, width=max(2, int(2 * scale)))
    draw.line(
        (cx - int(9 * scale), top + int(20 * scale), cx + int(9 * scale), top + int(20 * scale)),
        fill=ink,
        width=max(2, int(2 * scale)),
    )


def draw_gear(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], ink, scale: float):
    x1, y1, x2, y2 = box
    cx = (x1 + x2) // 2
    cy = (y1 + y2) // 2
    outer = int(12 * scale)
    inner = int(5 * scale)
    width = max(2, int(2 * scale))
    for dx, dy in [(0, -1), (1, 0), (0, 1), (-1, 0), (1, -1), (1, 1), (-1, 1), (-1, -1)]:
        draw.line(
            (cx + dx * int(outer * 0.65), cy + dy * int(outer * 0.65), cx + dx * outer, cy + dy * outer),
            fill=ink,
            width=width,
        )
    draw.ellipse((cx - outer, cy - outer, cx + outer, cy + outer), outline=ink, width=width)
    draw.ellipse((cx - inner, cy - inner, cx + inner, cy + inner), outline=ink, width=width)


def draw_play(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], ink, scale: float):
    x1, y1, x2, y2 = box
    draw.polygon(
        [
            (x1 + int(15 * scale), y1 + int(12 * scale)),
            (x1 + int(15 * scale), y2 - int(12 * scale)),
            (x2 - int(12 * scale), (y1 + y2) // 2),
        ],
        fill=ink,
    )


def draw_pause(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], ink, scale: float):
    x1, y1, x2, y2 = box
    width = max(3, int(4 * scale))
    top = y1 + int(12 * scale)
    bottom = y2 - int(12 * scale)
    draw.line((x1 + int(16 * scale), top, x1 + int(16 * scale), bottom), fill=ink, width=width)
    draw.line((x2 - int(16 * scale), top, x2 - int(16 * scale), bottom), fill=ink, width=width)


def draw_stop(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], ink, scale: float):
    x1, y1, x2, y2 = box
    inset = int(14 * scale)
    draw.rounded_rectangle(
        (x1 + inset, y1 + inset, x2 - inset, y2 - inset),
        radius=max(2, int(3 * scale)),
        fill=ink,
    )


def draw_trash(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], ink, scale: float):
    x1, y1, x2, y2 = box
    width = max(2, int(2 * scale))
    cx = (x1 + x2) // 2
    top = y1 + int(13 * scale)
    draw.line((cx - int(10 * scale), top, cx + int(10 * scale), top), fill=ink, width=width)
    draw.line((cx - int(5 * scale), top - int(4 * scale), cx + int(5 * scale), top - int(4 * scale)), fill=ink, width=width)
    draw.rounded_rectangle(
        (
            cx - int(8 * scale),
            top + int(4 * scale),
            cx + int(8 * scale),
            y2 - int(10 * scale),
        ),
        radius=max(2, int(3 * scale)),
        outline=ink,
        width=width,
    )
    draw.line((cx - int(3 * scale), top + int(8 * scale), cx - int(3 * scale), y2 - int(14 * scale)), fill=ink, width=max(1, width - 1))
    draw.line((cx + int(3 * scale), top + int(8 * scale), cx + int(3 * scale), y2 - int(14 * scale)), fill=ink, width=max(1, width - 1))


def draw_timer(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], ink, scale: float):
    x1, y1, x2, y2 = box
    cx = (x1 + x2) // 2
    cy = (y1 + y2) // 2 + int(2 * scale)
    r = int(12 * scale)
    width = max(2, int(2 * scale))
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=ink, width=width)
    draw.line((cx, cy, cx, cy - int(7 * scale)), fill=ink, width=width)
    draw.line((cx, cy, cx + int(6 * scale), cy + int(4 * scale)), fill=ink, width=width)
    draw.line((cx - int(5 * scale), y1 + int(8 * scale), cx + int(5 * scale), y1 + int(8 * scale)), fill=ink, width=width)


def draw_icon_button(
    draw: ImageDraw.ImageDraw,
    xy: tuple[int, int],
    size: int,
    icon: str,
    ink=(19, 81, 89, 232),
    scale: float = 1.0,
):
    x, y = xy
    box = (x, y, x + size, y + size)
    draw.rounded_rectangle(box, radius=size // 2, fill=(255, 255, 255, 94), outline=(255, 255, 255, 142))
    icon_scale = size / 42 * scale
    if icon == "plus":
        draw_plus(draw, box, ink, icon_scale)
    elif icon == "check":
        draw_check(draw, box, ink, icon_scale)
    elif icon == "pin":
        draw_pin(draw, box, ink, icon_scale)
    elif icon == "gear":
        draw_gear(draw, box, ink, icon_scale)
    elif icon == "play":
        draw_play(draw, box, ink, icon_scale)
    elif icon == "pause":
        draw_pause(draw, box, ink, icon_scale)
    elif icon == "stop":
        draw_stop(draw, box, ink, icon_scale)
    elif icon == "trash":
        draw_trash(draw, box, ink, icon_scale)
    elif icon == "timer":
        draw_timer(draw, box, ink, icon_scale)


def draw_collapsed_island_mock(base: Image.Image, xy: tuple[int, int], scale: float = 1.0):
    x, y = xy
    w, h = int(344 * scale), int(60 * scale)
    radius = h // 2
    draw = paste_glass(base, xy, (w, h), radius, (232, 252, 255, 178), (255, 255, 255, 162))
    ink = (19, 81, 89, 232)
    colors = [(255, 96, 106), (255, 204, 83), (76, 220, 151)]
    nums = ["2", "5", "3"]
    label = font(int(22 * scale))
    for i, (color, num) in enumerate(zip(colors, nums)):
        cx = x + int((50 + i * 96) * scale)
        cy = y + int(21 * scale)
        r = int(8 * scale)
        draw.ellipse((cx, cy, cx + 2 * r, cy + 2 * r), fill=color)
        draw.text((cx + int(26 * scale), y + int(16 * scale)), num, font=label, fill=ink)


def draw_attention_island_mock(base: Image.Image, xy: tuple[int, int], scale: float = 1.0):
    x, y = xy
    w, h = int(620 * scale), int(96 * scale)
    draw = paste_glass(base, xy, (w, h), h // 2, (232, 252, 255, 174), (255, 255, 255, 154))
    ink = (19, 81, 89, 232)
    muted = (47, 110, 116, 186)
    red = (255, 96, 106)

    icon_size = int(46 * scale)
    icon_x = x + int(30 * scale)
    icon_y = y + (h - icon_size) // 2
    draw.ellipse((icon_x, icon_y, icon_x + icon_size, icon_y + icon_size), fill=(255, 96, 106, 54), outline=(255, 255, 255, 128), width=max(1, int(1 * scale)))
    draw_timer(draw, (icon_x, icon_y, icon_x + icon_size, icon_y + icon_size), ink, scale * 0.88)

    draw.text((x + int(88 * scale), y + int(22 * scale)), "Deepseek 文章", font=font(int(25 * scale)), fill=ink)
    draw.text((x + int(90 * scale), y + int(55 * scale)), "专注中 · 高优先级", font=font(int(17 * scale)), fill=muted)

    countdown_x = x + w - int(214 * scale)
    countdown_y = y + int(30 * scale)
    draw.rounded_rectangle(
        (countdown_x, countdown_y, countdown_x + int(92 * scale), countdown_y + int(36 * scale)),
        radius=int(18 * scale),
        fill=(255, 255, 255, 86),
        outline=red + (82,),
        width=max(1, int(1 * scale)),
    )
    draw.text((countdown_x + int(17 * scale), countdown_y + int(7 * scale)), "24:59", font=font(int(18 * scale)), fill=ink)
    draw_icon_button(draw, (x + w - int(104 * scale), y + int(28 * scale)), int(38 * scale), "pause", ink=ink, scale=scale)
    draw_icon_button(draw, (x + w - int(58 * scale), y + int(28 * scale)), int(38 * scale), "stop", ink=ink, scale=scale)


def draw_island_mock(base: Image.Image, xy: tuple[int, int], scale: float = 1.0):
    x, y = xy
    w, h = int(760 * scale), int(168 * scale)
    draw = paste_glass(base, xy, (w, h), int(34 * scale), (232, 252, 255, 172), (255, 255, 255, 150))
    ink = (19, 81, 89, 232)
    muted = (46, 111, 117, 188)
    task_font = font(int(22 * scale))
    meta_font = font(int(15 * scale))
    tasks = [
        ((255, 96, 106), "Deepseek 文章", "当前", "剩 24:59"),
        ((255, 96, 106), "产品宣传图", "", "今天 18:00"),
        ((255, 204, 83), "同步 Apple 提醒事项", "", "25m"),
    ]
    row_x = x + int(20 * scale)
    row_w = w - int(94 * scale)
    row_h = int(40 * scale)
    row_y = y + int(18 * scale)
    for color, title, badge, meta in tasks:
        draw.rounded_rectangle(
            (row_x, row_y, row_x + row_w, row_y + row_h),
            radius=row_h // 2,
            fill=(255, 255, 255, 72),
            outline=color + (40,),
            width=max(1, int(1 * scale)),
        )
        dot_r = int(5 * scale)
        dot_x = row_x + int(18 * scale)
        dot_y = row_y + row_h // 2 - dot_r
        draw.ellipse((dot_x, dot_y, dot_x + dot_r * 2, dot_y + dot_r * 2), fill=color)
        draw.text((row_x + int(38 * scale), row_y + int(8 * scale)), title, font=task_font, fill=ink)
        text_cursor = row_x + int(38 * scale) + int(draw.textlength(title, font=task_font)) + int(12 * scale)
        if badge:
            badge_w = int(44 * scale)
            draw.rounded_rectangle(
                (text_cursor, row_y + int(10 * scale), text_cursor + badge_w, row_y + int(30 * scale)),
                radius=int(10 * scale),
                fill=(255, 255, 255, 82),
                outline=(255, 255, 255, 96),
            )
            draw.text((text_cursor + int(8 * scale), row_y + int(12 * scale)), badge, font=font(int(12 * scale)), fill=muted)
        draw.text((row_x + row_w - int(182 * scale), row_y + int(11 * scale)), meta, font=meta_font, fill=muted)
        draw_icon_button(draw, (row_x + row_w - int(76 * scale), row_y + int(6 * scale)), int(28 * scale), "check", ink=ink, scale=scale * 0.82)
        draw_icon_button(draw, (row_x + row_w - int(40 * scale), row_y + int(6 * scale)), int(28 * scale), "trash", ink=ink, scale=scale * 0.82)
        row_y += row_h + int(8 * scale)

    divider_x = x + w - int(58 * scale)
    draw.rounded_rectangle((divider_x, y + int(32 * scale), divider_x + max(1, int(1 * scale)), y + h - int(32 * scale)), radius=1, fill=(255, 255, 255, 82))
    draw_icon_button(draw, (x + w - int(50 * scale), y + int(40 * scale)), int(38 * scale), "plus", ink=ink, scale=scale)
    draw_icon_button(draw, (x + w - int(50 * scale), y + int(90 * scale)), int(38 * scale), "pin", ink=ink, scale=scale)


def draw_task_panel_mock(base: Image.Image, xy: tuple[int, int], size: tuple[int, int], scale: float = 1.0):
    x, y = xy
    w, h = size
    draw = paste_glass(base, xy, size, int(34 * scale), (235, 252, 255, 168), (255, 255, 255, 136))
    ink = (20, 82, 90, 232)
    muted = (53, 119, 124, 185)
    margin = int(24 * scale)
    content_right = x + w - margin
    draw_icon(base, (x + margin, y + int(22 * scale)), int(50 * scale))
    draw.text((x + int(82 * scale), y + int(24 * scale)), "任务岛", font=font(int(30 * scale)), fill=ink)
    draw.text((x + int(84 * scale), y + int(62 * scale)), "全部任务 · 当前专注 · 快速新增", font=font(int(17 * scale)), fill=muted)
    draw_icon_button(draw, (content_right - int(86 * scale), y + int(28 * scale)), int(38 * scale), "pin", ink=ink, scale=scale)
    draw_icon_button(draw, (content_right - int(40 * scale), y + int(28 * scale)), int(38 * scale), "gear", ink=ink, scale=scale)

    cursor_y = y + int(94 * scale)
    add_h = int(48 * scale)
    if cursor_y + add_h < y + h - int(28 * scale):
        draw.rounded_rectangle((x + margin, cursor_y, content_right, cursor_y + add_h), radius=int(16 * scale), fill=(255, 255, 255, 92), outline=(255, 255, 255, 126))
        draw.text((x + margin + int(18 * scale), cursor_y + int(13 * scale)), "+  快速新增任务", font=font(int(20 * scale)), fill=muted)
        for i, (label, color) in enumerate([("高", (255, 96, 106)), ("中", (255, 204, 83)), ("低", (76, 220, 151))]):
            px = content_right - int((150 - i * 48) * scale)
            draw.rounded_rectangle((px, cursor_y + int(11 * scale), px + int(38 * scale), cursor_y + int(35 * scale)), radius=int(12 * scale), fill=color + (42,), outline=color + (110,))
            draw.text((px + int(11 * scale), cursor_y + int(5 * scale)), label, font=font(int(17 * scale)), fill=ink)
        cursor_y += add_h + int(10 * scale)

    focus_h = int(56 * scale)
    if cursor_y + focus_h < y + h - int(78 * scale):
        draw.rounded_rectangle((x + margin, cursor_y, content_right, cursor_y + focus_h), radius=int(18 * scale), fill=(255, 255, 255, 86), outline=(255, 255, 255, 118))
        icon_size = int(32 * scale)
        icon_x = x + margin + int(14 * scale)
        icon_y = cursor_y + (focus_h - icon_size) // 2
        draw.ellipse((icon_x, icon_y, icon_x + icon_size, icon_y + icon_size), fill=(76, 220, 151, 62), outline=(255, 255, 255, 120))
        draw_timer(draw, (icon_x, icon_y, icon_x + icon_size, icon_y + icon_size), ink, scale * 0.68)
        draw.text((icon_x + int(45 * scale), cursor_y + int(10 * scale)), "Deepseek 文章", font=font(int(19 * scale)), fill=ink)
        draw.text((icon_x + int(46 * scale), cursor_y + int(34 * scale)), "专注中，剩余 24:59", font=font(int(14 * scale)), fill=muted)
        draw_icon_button(draw, (content_right - int(42 * scale), cursor_y + int(11 * scale)), int(34 * scale), "pause", ink=ink, scale=scale * 0.85)
        cursor_y += focus_h + int(10 * scale)

    chips = [("全部", True), ("今天", False), ("高优", False), ("回顾", False)]
    chip_x = x + margin
    chip_h = int(34 * scale)
    if cursor_y + chip_h < y + h - int(64 * scale):
        for label, selected in chips:
            chip_w = int((54 + len(label) * 14) * scale)
            fill = (255, 255, 255, 120) if selected else (255, 255, 255, 62)
            draw.rounded_rectangle((chip_x, cursor_y, chip_x + chip_w, cursor_y + chip_h), radius=chip_h // 2, fill=fill, outline=(255, 255, 255, 112))
            draw.text((chip_x + int(16 * scale), cursor_y + int(7 * scale)), label, font=font(int(15 * scale)), fill=ink if selected else muted)
            chip_x += chip_w + int(8 * scale)
        cursor_y += chip_h + int(8 * scale)

    search_h = int(36 * scale)
    if cursor_y + search_h < y + h - int(58 * scale):
        draw.rounded_rectangle((x + margin, cursor_y, content_right, cursor_y + search_h), radius=int(14 * scale), fill=(255, 255, 255, 66), outline=(255, 255, 255, 94))
        draw.text((x + margin + int(16 * scale), cursor_y + int(8 * scale)), "搜索标题、备注、标签或项目", font=font(int(14 * scale)), fill=muted)
        cursor_y += search_h + int(8 * scale)

    rows = [
        ((255, 96, 106), "高优先级", "Deepseek 文章", "当前 · 今天 18:00", True),
        ((255, 96, 106), "高优先级", "产品宣传图", "设为当前 · 25m", False),
        ((255, 204, 83), "中优先级", "同步提醒事项", "设为当前 · 明天 10:00", False),
        ((76, 220, 151), "低优先级", "导出 Markdown 备份", "设为当前 · 无日期", False),
    ]
    row_h = int(48 * scale)
    last_group = ""
    for color, group, title, meta, current in rows:
        if cursor_y + row_h > y + h - int(18 * scale):
            break
        if group != last_group and cursor_y + int(20 * scale) + row_h < y + h - int(18 * scale):
            draw.text((x + margin + int(4 * scale), cursor_y), group, font=font(int(14 * scale)), fill=muted)
            cursor_y += int(21 * scale)
            last_group = group
        draw.rounded_rectangle((x + margin, cursor_y, content_right, cursor_y + row_h), radius=int(16 * scale), fill=(255, 255, 255, 84 if current else 62), outline=(255, 255, 255, 112))
        dot_r = int(5 * scale)
        draw.ellipse((x + margin + int(16 * scale), cursor_y + int(19 * scale), x + margin + int(16 * scale) + dot_r * 2, cursor_y + int(19 * scale) + dot_r * 2), fill=color)
        draw.text((x + margin + int(36 * scale), cursor_y + int(7 * scale)), title, font=font(int(18 * scale)), fill=ink)
        draw.text((x + margin + int(36 * scale), cursor_y + int(29 * scale)), meta, font=font(int(12 * scale)), fill=muted)
        draw_icon_button(draw, (content_right - int(150 * scale), cursor_y + int(9 * scale)), int(30 * scale), "timer", ink=ink, scale=scale * 0.72)
        draw_icon_button(draw, (content_right - int(112 * scale), cursor_y + int(9 * scale)), int(30 * scale), "play", ink=ink, scale=scale * 0.72)
        draw_icon_button(draw, (content_right - int(74 * scale), cursor_y + int(9 * scale)), int(30 * scale), "check", ink=ink, scale=scale * 0.72)
        draw_icon_button(draw, (content_right - int(36 * scale), cursor_y + int(9 * scale)), int(30 * scale), "trash", ink=ink, scale=scale * 0.72)
        cursor_y += row_h + int(8 * scale)


def draw_settings_slice(base: Image.Image, xy: tuple[int, int], size: tuple[int, int], scale: float = 1.0):
    x, y = xy
    w, h = size
    draw = paste_glass(base, xy, size, int(30 * scale), (235, 252, 255, 160), (255, 255, 255, 126))
    ink = (20, 82, 90, 232)
    muted = (53, 119, 124, 185)
    draw.text((x + int(30 * scale), y + int(24 * scale)), "专注与提醒", font=font(int(30 * scale)), fill=ink)
    draw.text((x + int(32 * scale), y + int(66 * scale)), "默认专注时长 · 任意日期提醒 · 自定义颜色", font=font(int(20 * scale)), fill=muted)

    track_x = x + int(34 * scale)
    track_y = y + int(122 * scale)
    draw.text((track_x, track_y - int(40 * scale)), "默认专注", font=font(int(22 * scale)), fill=ink)
    draw.rounded_rectangle((track_x, track_y, x + w - int(38 * scale), track_y + int(12 * scale)), radius=int(6 * scale), fill=(255, 255, 255, 112))
    knob_x = track_x + int((w - 110 * scale) * 0.38)
    draw.ellipse((knob_x - int(13 * scale), track_y - int(8 * scale), knob_x + int(13 * scale), track_y + int(18 * scale)), fill=(76, 220, 151), outline=(255, 255, 255, 160), width=2)
    draw.text((x + w - int(112 * scale), track_y - int(38 * scale)), "25 分钟", font=font(int(22 * scale)), fill=ink)

    row_y = y + int(168 * scale)
    for color, title, detail in [
        ((255, 204, 83), "提醒时间", "明天 10:00"),
        ((255, 96, 106), "高优先级", "红色"),
    ]:
        draw.rounded_rectangle((x + int(30 * scale), row_y, x + w - int(30 * scale), row_y + int(54 * scale)), radius=int(18 * scale), fill=(255, 255, 255, 92))
        draw.ellipse((x + int(50 * scale), row_y + int(18 * scale), x + int(68 * scale), row_y + int(36 * scale)), fill=color)
        draw.text((x + int(84 * scale), row_y + int(13 * scale)), title, font=font(int(22 * scale)), fill=ink)
        draw.text((x + w - int(160 * scale), row_y + int(14 * scale)), detail, font=font(int(21 * scale)), fill=muted)
        row_y += int(66 * scale)


def render_landscape():
    size = (1920, 1080)
    img = poster_background(size)
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.ellipse((-260, -300, 760, 700), fill=(255, 255, 255, 70))
    od.ellipse((760, -220, 2100, 760), fill=(87, 219, 220, 48))
    od.ellipse((620, 650, 1560, 1400), fill=(20, 72, 80, 60))
    od.ellipse((1040, 420, 2140, 1280), fill=(122, 255, 199, 42))
    overlay = overlay.filter(ImageFilter.GaussianBlur(82))
    img.alpha_composite(overlay)

    draw = ImageDraw.Draw(img)
    brand_ink = (13, 78, 88, 246)
    muted_ink = (35, 112, 119, 214)
    headline_ink = (9, 69, 80, 248)
    body_ink = (25, 91, 100, 226)
    draw_icon(img, (126, 118), 138)
    draw.text((292, 125), "任务岛", font=font(82), fill=brand_ink)
    draw.text((296, 218), "TaskIsland", font=font(32), fill=muted_ink)
    draw.text((132, 326), "让重要的事，始终在眼前", font=font(62), fill=headline_ink)
    draw_wrapped(
        draw,
        "数字岛看数量，专注岛守时间，行动岛处理任务。",
        (136, 458),
        700,
        font(34),
        body_ink,
        12,
    )
    chip_y = 670
    chip_x = 136
    for text in ["数字岛", "专注岛", "行动岛", "快速新增"]:
        if chip_x + chip_width(text) > 830:
            chip_x = 136
            chip_y += 62
        chip_x = draw_chip(draw, (chip_x, chip_y), text)

    paste_ui_snapshot(img, "task-panel.png", (1425, 250), 0.98)
    paste_ui_snapshot(img, "island-collapsed.png", (1060, 350), 1.75)
    paste_ui_snapshot(img, "island-attention.png", (970, 470), 1.20)
    paste_ui_snapshot(img, "island-expanded.png", (890, 630), 1.12)
    draw.text((135, 960), "轻量聚焦任务面板 · macOS 常驻小工具 · 可打包安装", font=font(28), fill=(214, 244, 243, 204))
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / "taskisland-poster-16x9.png")


def render_portrait():
    size = (1080, 1440)
    img = poster_background(size)
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.ellipse((-220, -190, 760, 840), fill=(255, 255, 255, 72))
    od.ellipse((420, 80, 1340, 960), fill=(88, 222, 221, 46))
    od.ellipse((-60, 940, 980, 1660), fill=(14, 65, 76, 58))
    od.ellipse((420, 820, 1360, 1520), fill=(122, 255, 199, 34))
    overlay = overlay.filter(ImageFilter.GaussianBlur(74))
    img.alpha_composite(overlay)

    draw = ImageDraw.Draw(img)
    brand_ink = (13, 78, 88, 248)
    muted_ink = (35, 112, 119, 216)
    headline_ink = (9, 69, 80, 248)
    body_ink = (25, 91, 100, 226)
    draw_icon(img, (88, 84), 140)
    draw.text((88, 262), "任务岛", font=font(84), fill=brand_ink)
    draw.text((92, 356), "TaskIsland", font=font(34), fill=muted_ink)
    draw.text((88, 456), "让重要的事，始终在眼前", font=font(52), fill=headline_ink)
    draw_wrapped(
        draw,
        "数字岛看数量，专注岛守时间，行动岛处理任务。",
        (92, 552),
        846,
        font(31),
        body_ink,
        12,
    )
    paste_ui_snapshot(img, "task-panel.png", (520, 706), 1.02)
    paste_ui_snapshot(img, "island-collapsed.png", (64, 766), 1.65)
    paste_ui_snapshot(img, "island-attention.png", (54, 884), 1.08)
    paste_ui_snapshot(img, "island-expanded.png", (44, 1032), 0.86)
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / "taskisland-poster-3x4.png")


def screenshot_canvas(title: str, subtitle: str) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    size = (1600, 1000)
    img = gradient(size, (25, 86, 96), (9, 42, 55))
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.ellipse((-220, -260, 760, 660), fill=(107, 223, 229, 56))
    od.ellipse((880, -180, 1840, 720), fill=(122, 255, 199, 42))
    od.ellipse((360, 650, 1380, 1320), fill=(255, 211, 113, 28))
    img.alpha_composite(overlay.filter(ImageFilter.GaussianBlur(80)))

    draw = ImageDraw.Draw(img)
    draw.text((92, 58), title, font=font(54), fill=(250, 255, 255, 250))
    draw.text((96, 128), subtitle, font=font(25), fill=(219, 246, 245, 218))
    return img, draw


def draw_label(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, tone=(230, 252, 255, 156)):
    x, y = xy
    fnt = font(24)
    tw = int(draw.textlength(text, font=fnt))
    draw.rounded_rectangle((x, y, x + tw + 30, y + 42), radius=21, fill=tone, outline=(255, 255, 255, 122))
    draw.text((x + 15, y + 8), text, font=fnt, fill=(19, 81, 89, 230))
    return x + tw + 42


def draw_switch(draw: ImageDraw.ImageDraw, xy: tuple[int, int], on: bool = True):
    x, y = xy
    fill = (75, 211, 153, 235) if on else (216, 228, 230, 180)
    draw.rounded_rectangle((x, y, x + 70, y + 34), radius=17, fill=fill, outline=(255, 255, 255, 100))
    knob_x = x + 40 if on else x + 4
    draw.ellipse((knob_x, y + 4, knob_x + 26, y + 30), fill=(255, 255, 255, 245))


def draw_slider_line(draw: ImageDraw.ImageDraw, xy: tuple[int, int], width: int, progress: float, knob=(76, 220, 151)):
    x, y = xy
    draw.rounded_rectangle((x, y, x + width, y + 12), radius=6, fill=(255, 255, 255, 126))
    draw.rounded_rectangle((x, y, x + int(width * progress), y + 12), radius=6, fill=knob + (230,))
    kx = x + int(width * progress)
    draw.ellipse((kx - 14, y - 8, kx + 14, y + 20), fill=knob, outline=(255, 255, 255, 172), width=2)


def draw_setting_card(
    draw: ImageDraw.ImageDraw,
    xy: tuple[int, int],
    size: tuple[int, int],
    title: str,
    icon: str,
):
    x, y = xy
    w, h = size
    draw.rounded_rectangle((x, y, x + w, y + h), radius=26, fill=(235, 252, 255, 156), outline=(255, 255, 255, 126), width=1)
    draw_icon_button(draw, (x + 24, y + 22), 42, icon, scale=1.0)
    draw.text((x + 82, y + 26), title, font=font(31), fill=(19, 81, 89, 236))


def render_screenshot_floating_island():
    img, draw = screenshot_canvas("数字岛 / 专注岛 / 行动岛", "从数量总览，到专注提醒，再到任务行操作，都留在桌面顶部。")
    ink = (235, 255, 255, 245)
    muted = (219, 246, 245, 218)
    card_ink = (18, 82, 90, 238)
    card_muted = (47, 116, 124, 210)

    states = [
        (
            "数字岛",
            "island-collapsed.png",
            (132, 245),
            2.45,
            "红 / 黄 / 绿数量",
            "分别代表高、中、低优先级；数字是对应优先级的未完成任务数量。",
        ),
        (
            "专注岛",
            "island-attention.png",
            (96, 430),
            1.72,
            "当前任务 + 倒计时",
            "显示当前专注或提醒任务；右侧按钮用于暂停/继续和停止。",
        ),
        (
            "行动岛",
            "island-expanded.png",
            (92, 625),
            1.28,
            "最多 3 条任务",
            "悬停后展示任务行；每行可完成或删除，右侧加号新增，图钉用于固定展开。",
        ),
    ]

    for title, snapshot, xy, scale, summary, detail in states:
        x, y = xy
        draw.text((x + 4, y - 50), title, font=font(30), fill=ink)
        paste_ui_snapshot(img, snapshot, xy, scale)

        card_x = 865
        card_y = y - 36
        paste_glass(img, (card_x, card_y), (590, 150), 28, (235, 252, 255, 168), (255, 255, 255, 132))
        draw.text((card_x + 34, card_y + 26), summary, font=font(31), fill=card_ink)
        draw_wrapped(
            draw,
            detail,
            (card_x + 36, card_y + 76),
            510,
            font(23),
            card_muted,
            8,
        )

    SCREENSHOTS.mkdir(parents=True, exist_ok=True)
    img.save(SCREENSHOTS / "01-floating-island.png")


def render_screenshot_task_panel():
    img, draw = screenshot_canvas("任务面板", "默认显示所有未完成任务，同时提供当前任务、快速新增和多视图切换。")
    paste_ui_snapshot(img, "task-panel.png", (280, 170), 0.98)
    draw_label(draw, (170, 860), "全部任务")
    draw_label(draw, (320, 860), "今天")
    draw_label(draw, (420, 860), "高优")
    draw_label(draw, (535, 860), "回顾")
    draw_label(draw, (660, 860), "固定面板")
    img.save(SCREENSHOTS / "02-task-panel.png")


def render_screenshot_quick_add():
    img, draw = screenshot_canvas("快速新增", "实际快速新增面板：一句话输入任务，并选择默认优先级。")
    paste_ui_snapshot(img, "quick-add.png", (295, 300), 2.02)

    label_x = draw_label(draw, (320, 660), "Control + Option + N")
    label_x = draw_label(draw, (label_x + 8, 660), "自然语言")
    label_x = draw_label(draw, (label_x + 8, 660), "优先级选择")
    draw_label(draw, (label_x + 8, 660), "Esc 取消")
    draw_wrapped(
        draw,
        "输入框里的日期、时间、标签、优先级和 /30m 会由真实快速新增解析器处理；这张图直接使用程序的快速新增窗口截图。",
        (322, 740),
        960,
        font(28),
        (226, 248, 247, 224),
        8,
    )
    img.save(SCREENSHOTS / "03-quick-add.png")


def render_screenshot_task_detail():
    img, draw = screenshot_canvas("任务详情", "实际任务行展开态：编辑时间、项目标签、重复规则和专注分钟。")
    paste_ui_snapshot(img, "task-detail.png", (585, 300), 1.55)

    label_y = 340
    for text in ["标题可编辑", "任意提醒时间", "项目 / 标签", "重复规则", "专注分钟"]:
        draw_label(draw, (185, label_y), text)
        label_y += 66
    img.save(SCREENSHOTS / "04-task-detail.png")


def render_screenshot_views():
    img, draw = screenshot_canvas("任务视图", "同一个真实任务面板可以切换今天、建议、高优、即将、标签、项目和回顾。")
    draw.text((260, 220), "今天", font=font(34), fill=(235, 255, 255, 245))
    draw.text((940, 220), "回顾", font=font(34), fill=(235, 255, 255, 245))
    paste_ui_snapshot(img, "task-panel-today.png", (210, 275), 1.02)
    paste_ui_snapshot(img, "task-panel-review.png", (880, 275), 1.02)

    label_x = draw_label(draw, (260, 900), "横向视图切换")
    label_x = draw_label(draw, (label_x + 8, 900), "今天队列")
    label_x = draw_label(draw, (label_x + 8, 900), "完成记录")
    draw_label(draw, (label_x + 8, 900), "明日建议")
    img.save(SCREENSHOTS / "05-task-views.png")


def render_screenshot_settings_display():
    img, draw = screenshot_canvas("设置：显示与专注", "实际设置面板顶部：显示开关、暗夜模式、默认专注时长和优先级颜色。")
    paste_ui_snapshot(img, "settings-display.png", (570, 215), 1.08)

    label_y = 360
    for text in ["显示悬浮岛", "菜单栏标题", "暗夜模式", "默认专注"]:
        draw_label(draw, (195, label_y), text)
        label_y += 66
    img.save(SCREENSHOTS / "06-settings-display-capsule.png")


def render_screenshot_settings_focus_priority():
    img, draw = screenshot_canvas("设置：优先级与悬浮岛", "实际设置面板中段：优先级颜色、透明度、背景色和文字色。")
    paste_ui_snapshot(img, "settings-priority-capsule.png", (570, 215), 1.08)

    label_y = 360
    for text in ["优先级颜色", "悬浮岛透明度", "背景颜色", "文字颜色"]:
        draw_label(draw, (180, label_y), text)
        label_y += 66
    img.save(SCREENSHOTS / "07-settings-focus-priority.png")


def render_screenshot_settings_shortcuts_data():
    img, draw = screenshot_canvas("设置：快捷键与数据", "实际设置面板底部：快捷键、导入导出、Apple 提醒事项、隐藏和退出。")
    paste_ui_snapshot(img, "settings-shortcuts-data.png", (570, 215), 1.08)

    label_y = 360
    for text in ["快捷键自定义", "JSON / Markdown / CSV", "Apple 提醒事项", "隐藏 / 退出"]:
        draw_label(draw, (145, label_y), text)
        label_y += 66
    img.save(SCREENSHOTS / "08-settings-shortcuts-data.png")


def render_readme_screenshots():
    render_screenshot_floating_island()
    render_screenshot_task_panel()
    render_screenshot_quick_add()
    render_screenshot_task_detail()
    render_screenshot_views()
    render_screenshot_settings_display()
    render_screenshot_settings_focus_priority()
    render_screenshot_settings_shortcuts_data()


if __name__ == "__main__":
    ensure_ui_snapshots()
    render_landscape()
    render_portrait()
    render_readme_screenshots()
    print(f"Generated posters in {OUT}")
    print(f"Generated screenshots in {SCREENSHOTS}")
