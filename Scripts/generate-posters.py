#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "posters"
SCREENSHOTS = ROOT / "assets" / "screenshots"
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


def draw_icon(base: Image.Image, xy: tuple[int, int], size: int):
    icon = Image.open(ICON).convert("RGBA").resize((size, size), Image.Resampling.LANCZOS)
    base.alpha_composite(icon, xy)


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
    img = gradient(size, (23, 78, 92), (11, 42, 54))
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.ellipse((-240, -280, 760, 660), fill=(107, 223, 229, 68))
    od.ellipse((1260, -160, 2200, 700), fill=(122, 255, 199, 54))
    od.ellipse((620, 680, 1560, 1400), fill=(255, 211, 113, 34))
    overlay = overlay.filter(ImageFilter.GaussianBlur(82))
    img.alpha_composite(overlay)

    draw = ImageDraw.Draw(img)
    draw_icon(img, (126, 118), 138)
    draw.text((292, 125), "任务岛", font=font(82), fill=(250, 255, 255, 250))
    draw.text((296, 218), "TaskIsland", font=font(32), fill=(204, 244, 242, 214))
    draw.text((132, 326), "让下一件事，", font=font(68), fill=(250, 255, 255, 250))
    draw.text((132, 414), "始终在眼前。", font=font(68), fill=(250, 255, 255, 250))
    draw_wrapped(
        draw,
        "任务岛把待办、优先级和专注计时悬浮在桌面上方。少打开一个窗口，多推进一件事。",
        (136, 534),
        700,
        font(34),
        (224, 248, 247, 224),
        12,
    )
    chip_y = 720
    chip_x = 136
    for text in ["液态玻璃悬浮岛", "快速新增", "专注计时", "Apple 提醒事项"]:
        if chip_x + chip_width(text) > 830:
            chip_x = 136
            chip_y += 62
        chip_x = draw_chip(draw, (chip_x, chip_y), text)

    draw_collapsed_island_mock(img, (1118, 100), 1.0)
    draw_attention_island_mock(img, (1010, 204), 1.0)
    draw_island_mock(img, (902, 336), 1.02)
    draw_task_panel_mock(img, (930, 572), (800, 360), 0.86)
    draw.text((135, 960), "轻量聚焦任务面板 · macOS 常驻小工具 · 可打包安装", font=font(28), fill=(214, 244, 243, 204))
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / "taskisland-poster-16x9.png")


def render_portrait():
    size = (1080, 1440)
    img = gradient(size, (26, 91, 100), (11, 47, 60))
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.ellipse((-220, -160, 760, 820), fill=(100, 222, 230, 70))
    od.ellipse((520, 130, 1340, 960), fill=(128, 255, 204, 52))
    od.ellipse((-60, 960, 980, 1660), fill=(255, 211, 113, 34))
    overlay = overlay.filter(ImageFilter.GaussianBlur(74))
    img.alpha_composite(overlay)

    draw = ImageDraw.Draw(img)
    draw_icon(img, (88, 84), 140)
    draw.text((88, 262), "任务岛", font=font(84), fill=(250, 255, 255, 252))
    draw.text((92, 356), "TaskIsland", font=font(34), fill=(209, 246, 244, 218))
    draw.text((88, 456), "让下一件事，", font=font(56), fill=(250, 255, 255, 248))
    draw.text((88, 528), "始终在眼前。", font=font(56), fill=(250, 255, 255, 248))
    draw_wrapped(
        draw,
        "从小胶囊到完整面板，任务、提醒和专注都留在桌面最顺手的位置。",
        (92, 624),
        846,
        font(31),
        (224, 248, 247, 224),
        12,
    )
    draw_collapsed_island_mock(img, (112, 756), 1.06)
    draw_attention_island_mock(img, (112, 850), 0.95)
    draw_island_mock(img, (112, 970), 0.88)
    draw_task_panel_mock(img, (112, 1134), (856, 284), 0.70)
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
    img, draw = screenshot_canvas("悬浮岛", "收起时只留优先级数量，悬停后展开当前任务和快速操作。")
    draw_collapsed_island_mock(img, (150, 255), 1.18)
    draw_attention_island_mock(img, (150, 380), 1.0)
    draw_island_mock(img, (150, 535), 1.05)
    draw_task_panel_mock(img, (900, 240), (570, 470), 0.74)
    x = draw_label(draw, (150, 770), "小胶囊：高 / 中 / 低数量")
    x = draw_label(draw, (x, 770), "中胶囊：专注 / 提醒")
    draw_label(draw, (x, 770), "展开态：任务行操作")
    draw.text((920, 760), "点击空白区域打开完整任务面板；固定后可以常驻查看。", font=font(28), fill=(226, 248, 247, 224))
    SCREENSHOTS.mkdir(parents=True, exist_ok=True)
    img.save(SCREENSHOTS / "01-floating-island.png")


def render_screenshot_task_panel():
    img, draw = screenshot_canvas("任务面板", "默认显示所有未完成任务，同时提供当前任务、快速新增和多视图切换。")
    draw_task_panel_mock(img, (150, 210), (1280, 610), 1.08)
    draw_settings_slice(img, (920, 650), (420, 210), 0.78)
    draw_label(draw, (170, 860), "全部任务")
    draw_label(draw, (320, 860), "今天")
    draw_label(draw, (420, 860), "高优")
    draw_label(draw, (535, 860), "回顾")
    draw_label(draw, (660, 860), "固定面板")
    img.save(SCREENSHOTS / "02-task-panel.png")


def render_screenshot_quick_add():
    img, draw = screenshot_canvas("快速新增", "用一句话创建任务，自动识别日期、时间、标签、优先级和专注分钟。")
    x, y, w, h = 250, 300, 1100, 330
    paste_glass(img, (x, y), (w, h), 34, (235, 252, 255, 176), (255, 255, 255, 146))
    draw_icon(img, (x + 46, y + 42), 74)
    draw.text((x + 140, y + 45), "快速新增任务", font=font(42), fill=(18, 82, 90, 238))
    draw_icon_button(draw, (x + w - 88, y + 42), 44, "plus")
    draw.rounded_rectangle((x + 56, y + 142, x + w - 56, y + 214), radius=24, fill=(255, 255, 255, 118), outline=(255, 255, 255, 158))
    draw.text((x + 86, y + 160), "明天 10点 发周报 #工作 !高 /30m", font=font(34), fill=(18, 82, 90, 236))
    chip_x = x + 56
    for text in ["明天 10:00", "高优先级", "#工作", "30 分钟"]:
        chip_x = draw_label(draw, (chip_x, y + 244), text)
    draw.text((x + 58, y + 650 - 42), "支持快捷键唤起，也可以从悬浮岛加号进入。", font=font(28), fill=(226, 248, 247, 224))
    img.save(SCREENSHOTS / "03-quick-add.png")


def render_screenshot_task_detail():
    img, draw = screenshot_canvas("任务详情", "单条任务里可以设置备注、日期提醒、重复、项目标签、子任务和专注时长。")
    x, y, w, h = 165, 230, 1270, 650
    paste_glass(img, (x, y), (w, h), 36, (235, 252, 255, 168), (255, 255, 255, 136))
    ink = (20, 82, 90, 236)
    muted = (53, 119, 124, 190)
    draw.ellipse((x + 44, y + 42, x + 70, y + 68), fill=(255, 96, 106))
    draw.text((x + 90, y + 33), "Deepseek 文章", font=font(42), fill=ink)
    draw_icon_button(draw, (x + w - 150, y + 34), 46, "check")
    draw_icon_button(draw, (x + w - 92, y + 34), 46, "play")
    left_x = x + 56
    top = y + 126
    rows = [
        ("备注", "补充文章结构、引用链接和发布前检查"),
        ("截止时间", "今天 18:00"),
        ("提醒时间", "今天 17:30"),
        ("重复规则", "不重复 / 每天 / 每周 / 每月 / 每年"),
        ("项目与标签", "写作 · #AI #研究"),
    ]
    for i, (label, value) in enumerate(rows):
        yy = top + i * 74
        draw.rounded_rectangle((left_x, yy, x + w - 56, yy + 54), radius=18, fill=(255, 255, 255, 94))
        draw.text((left_x + 22, yy + 14), label, font=font(22), fill=muted)
        draw.text((left_x + 190, yy + 13), value, font=font(24), fill=ink)
    draw.text((left_x, y + h - 126), "子任务", font=font(26), fill=ink)
    draw.text((left_x + 125, y + h - 126), "□ 搜集资料    □ 写初稿    □ 发布前校对", font=font(24), fill=muted)
    draw.text((left_x, y + h - 76), "专注分钟", font=font(26), fill=ink)
    draw_slider_line(draw, (left_x + 130, y + h - 64), 430, 0.42)
    draw.text((left_x + 590, y + h - 76), "25 分钟", font=font(26), fill=ink)
    img.save(SCREENSHOTS / "04-task-detail.png")


def render_screenshot_views():
    img, draw = screenshot_canvas("任务视图", "同一批任务可以按全部、今天、建议、高优、即将、无日期、标签、项目、已完成和回顾查看。")
    cards = [
        ("全部", "所有未完成任务", ["Deepseek 文章", "设置明天提醒", "导出 Markdown 备份"]),
        ("今天", "今天要处理的任务", ["写发布说明", "同步提醒事项"]),
        ("建议", "按日期与优先级推荐", ["高优任务优先", "被推迟任务提示"]),
        ("回顾", "完成、推迟、专注统计", ["今日完成 5", "专注 1h 20m", "明天建议关注 2"]),
    ]
    positions = [(120, 230), (835, 230), (120, 585), (835, 585)]
    for (title, subtitle, rows), pos in zip(cards, positions):
        x, y = pos
        paste_glass(img, pos, (645, 290), 30, (235, 252, 255, 162), (255, 255, 255, 130))
        draw.text((x + 36, y + 28), title, font=font(38), fill=(20, 82, 90, 236))
        draw.text((x + 38, y + 76), subtitle, font=font(22), fill=(53, 119, 124, 190))
        for i, row in enumerate(rows):
            yy = y + 124 + i * 50
            draw.rounded_rectangle((x + 34, yy, x + 610, yy + 36), radius=18, fill=(255, 255, 255, 94))
            draw.ellipse((x + 54, yy + 12, x + 66, yy + 24), fill=[(255, 96, 106), (255, 204, 83), (76, 220, 151)][i % 3])
            draw.text((x + 84, yy + 5), row, font=font(22), fill=(20, 82, 90, 228))
    img.save(SCREENSHOTS / "05-task-views.png")


def render_screenshot_settings_display():
    img, draw = screenshot_canvas("设置：显示与悬浮岛", "展示悬浮岛开关、菜单栏标题、暗夜模式、位置、透明度、背景色和文字色。")
    draw_setting_card(draw, (120, 230), (650, 600), "显示", "gear")
    rows = [("显示悬浮岛", True), ("菜单栏标题", True), ("暗夜模式", False)]
    for i, (label, on) in enumerate(rows):
        yy = 320 + i * 92
        draw.text((170, yy), label, font=font(28), fill=(20, 82, 90, 236))
        draw_switch(draw, (620, yy), on)
    draw_setting_card(draw, (830, 230), (650, 600), "悬浮岛", "pin")
    labels = [("顶部间距", "0"), ("透明度", "42%")]
    for i, (label, value) in enumerate(labels):
        yy = 320 + i * 100
        draw.text((880, yy), label, font=font(27), fill=(20, 82, 90, 236))
        draw_slider_line(draw, (1040, yy + 12), 300, 0.22 if i == 0 else 0.42)
        draw.text((1370, yy), value, font=font(24), fill=(53, 119, 124, 190))
    for i, (label, color, action) in enumerate([("背景颜色", (221, 247, 255), "恢复默认"), ("文字颜色", (18, 82, 90), "自动")]):
        yy = 522 + i * 100
        draw.text((880, yy), label, font=font(27), fill=(20, 82, 90, 236))
        draw.rounded_rectangle((1190, yy - 4, 1240, yy + 44), radius=14, fill=color, outline=(255, 255, 255, 150), width=2)
        draw_label(draw, (1270, yy - 4), action)
    img.save(SCREENSHOTS / "06-settings-display-capsule.png")


def render_screenshot_settings_focus_priority():
    img, draw = screenshot_canvas("设置：专注与优先级", "展示默认专注时长、快捷时长按钮，以及高 / 中 / 低优先级颜色。")
    draw_setting_card(draw, (120, 230), (650, 600), "专注", "play")
    draw.text((170, 330), "默认时长", font=font(28), fill=(20, 82, 90, 236))
    draw_slider_line(draw, (320, 342), 310, 0.42)
    draw.text((650, 330), "25 分钟", font=font(24), fill=(53, 119, 124, 190))
    x = 170
    for text in ["15 分钟", "25 分钟", "45 分钟", "60 分钟"]:
        x = draw_label(draw, (x, 420), text)
    draw.text((170, 516), "单个任务可在任务详情里单独设置专注分钟。", font=font(24), fill=(53, 119, 124, 196))

    draw_setting_card(draw, (830, 230), (650, 600), "优先级颜色", "gear")
    priorities = [("高优先级", (255, 96, 106), "#FF606A"), ("中优先级", (255, 204, 83), "#FFCC53"), ("低优先级", (76, 220, 151), "#4CDC97")]
    for i, (label, color, hex_value) in enumerate(priorities):
        yy = 330 + i * 110
        draw.rounded_rectangle((880, yy - 18, 1428, yy + 58), radius=22, fill=(255, 255, 255, 96))
        draw.ellipse((910, yy + 4, 940, yy + 34), fill=color)
        draw.text((965, yy), label, font=font(27), fill=(20, 82, 90, 236))
        draw.text((1265, yy + 3), hex_value, font=font(23), fill=(53, 119, 124, 190))
    draw_label(draw, (1040, 694), "恢复默认")
    img.save(SCREENSHOTS / "07-settings-focus-priority.png")


def render_screenshot_settings_shortcuts_data():
    img, draw = screenshot_canvas("设置：快捷键与数据", "展示快速新增快捷键、导出格式、导入导出、Apple 提醒事项、隐藏和退出。")
    draw_setting_card(draw, (120, 230), (650, 600), "快捷键", "gear")
    draw.text((170, 330), "快速新增", font=font(28), fill=(20, 82, 90, 236))
    draw_label(draw, (500, 322), "Option + Q")
    draw.text((170, 425), "修饰键", font=font(25), fill=(53, 119, 124, 190))
    x = 290
    for text in ["Option", "Control", "Command"]:
        x = draw_label(draw, (x, 416), text)
    draw.text((170, 520), "按键", font=font(25), fill=(53, 119, 124, 190))
    x = 290
    for text in ["Q", "A", "Space"]:
        x = draw_label(draw, (x, 512), text)
    draw_label(draw, (170, 630), "恢复默认")

    draw_setting_card(draw, (830, 230), (650, 600), "操作", "gear")
    draw.text((880, 330), "导出格式", font=font(27), fill=(20, 82, 90, 236))
    x = 1020
    for text in ["JSON", "Markdown", "CSV"]:
        x = draw_label(draw, (x, 322), text)
    action_rows = [
        ("刷新", "导出", "导入"),
        ("导入提醒", "导出提醒"),
        ("隐藏", "退出"),
    ]
    yy = 430
    for row in action_rows:
        x = 880
        for text in row:
            x = draw_label(draw, (x, yy), text)
        yy += 96
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
    render_landscape()
    render_portrait()
    render_readme_screenshots()
    print(f"Generated posters in {OUT}")
    print(f"Generated screenshots in {SCREENSHOTS}")
