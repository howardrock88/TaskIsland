#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "posters"
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
        shadow_layer = Image.new("RGBA", size, (0, 0, 0, 120))
        shadow_layer.putalpha(mask.filter(ImageFilter.GaussianBlur(18)))
        base.alpha_composite(shadow_layer, (x, y + 16))

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


def draw_island_mock(base: Image.Image, xy: tuple[int, int], scale: float = 1.0):
    x, y = xy
    w, h = int(720 * scale), int(178 * scale)
    draw = paste_glass(base, xy, (w, h), int(36 * scale), (232, 252, 255, 172), (255, 255, 255, 150))
    label = font(int(26 * scale))
    title = font(int(34 * scale))
    small = font(int(22 * scale))
    ink = (19, 81, 89, 232)
    muted = (46, 111, 117, 188)
    colors = [(255, 96, 106), (255, 204, 83), (76, 220, 151)]
    nums = ["2", "5", "3"]
    for i, (color, num) in enumerate(zip(colors, nums)):
        cx = x + int((44 + i * 92) * scale)
        cy = y + int(42 * scale)
        r = int(10 * scale)
        draw.ellipse((cx, cy, cx + 2 * r, cy + 2 * r), fill=color)
        draw.text((cx + int(28 * scale), cy - int(8 * scale)), num, font=label, fill=ink)
    draw.text((x + int(38 * scale), y + int(86 * scale)), "Deepseek 文章", font=title, fill=ink)
    draw.text((x + int(40 * scale), y + int(130 * scale)), "当前任务 · 25 分钟专注", font=small, fill=muted)
    for i in range(3):
        bx = x + w - int((176 - i * 58) * scale)
        by = y + int(92 * scale)
        draw.rounded_rectangle((bx, by, bx + int(42 * scale), by + int(42 * scale)), radius=int(21 * scale), fill=(255, 255, 255, 82), outline=(255, 255, 255, 132))
        if i == 0:
            cx = bx + int(21 * scale)
            cy = by + int(21 * scale)
            draw.line((cx - int(8 * scale), cy, cx + int(8 * scale), cy), fill=ink, width=max(2, int(2 * scale)))
            draw.line((cx, cy - int(8 * scale), cx, cy + int(8 * scale)), fill=ink, width=max(2, int(2 * scale)))
        elif i == 1:
            draw.line(
                (
                    bx + int(11 * scale),
                    by + int(22 * scale),
                    bx + int(18 * scale),
                    by + int(29 * scale),
                    bx + int(31 * scale),
                    by + int(14 * scale),
                ),
                fill=ink,
                width=max(3, int(3 * scale)),
                joint="curve",
            )
        else:
            draw.text((bx + int(10 * scale), by + int(8 * scale)), "固", font=font(int(22 * scale)), fill=ink)


def draw_task_panel_mock(base: Image.Image, xy: tuple[int, int], size: tuple[int, int], scale: float = 1.0):
    x, y = xy
    w, h = size
    draw = paste_glass(base, xy, size, int(34 * scale), (235, 252, 255, 168), (255, 255, 255, 136))
    ink = (20, 82, 90, 232)
    muted = (53, 119, 124, 185)
    draw_icon(base, (x + int(34 * scale), y + int(30 * scale)), int(64 * scale))
    draw.text((x + int(112 * scale), y + int(35 * scale)), "任务岛", font=font(int(38 * scale)), fill=ink)
    draw.text((x + int(114 * scale), y + int(82 * scale)), "全部任务 · 今天 · 高优 · 回顾", font=font(int(23 * scale)), fill=muted)
    draw.rounded_rectangle((x + w - int(116 * scale), y + int(38 * scale), x + w - int(42 * scale), y + int(78 * scale)), radius=int(20 * scale), fill=(255, 255, 255, 82), outline=(255, 255, 255, 124))
    draw.text((x + w - int(92 * scale), y + int(43 * scale)), "设置", font=font(int(22 * scale)), fill=ink)

    rows = [
        ("#FF606A", "高", "整理发布文档", "今天 10:00"),
        ("#FFCC53", "中", "同步 Apple 提醒事项", "明天"),
        ("#4CDC97", "低", "导出 Markdown 备份", "无日期"),
    ]
    row_y = y + int(130 * scale)
    for color_hex, pri, title, meta in rows:
        row_h = int(70 * scale)
        draw.rounded_rectangle((x + int(32 * scale), row_y, x + w - int(32 * scale), row_y + row_h), radius=int(22 * scale), fill=(255, 255, 255, 98), outline=(255, 255, 255, 136))
        color = tuple(int(color_hex[i : i + 2], 16) for i in (1, 3, 5))
        draw.ellipse((x + int(54 * scale), row_y + int(24 * scale), x + int(76 * scale), row_y + int(46 * scale)), fill=color)
        draw.text((x + int(92 * scale), row_y + int(19 * scale)), title, font=font(int(27 * scale)), fill=ink)
        draw.text((x + w - int(196 * scale), row_y + int(21 * scale)), f"{pri} · {meta}", font=font(int(22 * scale)), fill=muted)
        row_y += row_h + int(18 * scale)


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
    draw_icon(img, (128, 128), 148)
    draw.text((300, 130), "任务岛", font=font(88), fill=(250, 255, 255, 250))
    draw.text((304, 228), "TaskIsland", font=font(34), fill=(204, 244, 242, 214))
    draw.text((132, 338), "把当前任务放到 Mac 桌面最上方。", font=font(62), fill=(250, 255, 255, 248))
    draw_wrapped(
        draw,
        "液态玻璃悬浮岛、红黄绿优先级、快捷新增和专注计时，让待办保持可见，但不打断你正在做的事。",
        (136, 432),
        760,
        font(34),
        (224, 248, 247, 224),
        12,
    )
    chip_y = 614
    chip_x = 136
    for text in ["本地优先", "自定义外观", "Apple 提醒事项", "Markdown / CSV 导出"]:
        if chip_x + chip_width(text) > 890:
            chip_x = 136
            chip_y += 62
        chip_x = draw_chip(draw, (chip_x, chip_y), text)

    draw_island_mock(img, (1010, 154), 1.05)
    draw_task_panel_mock(img, (1028, 410), (724, 470), 1.0)
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
    draw_icon(img, (88, 86), 146)
    draw.text((88, 270), "任务岛", font=font(88), fill=(250, 255, 255, 252))
    draw.text((92, 370), "TaskIsland", font=font(36), fill=(209, 246, 244, 218))
    draw.text((88, 462), "把当前任务放到 Mac", font=font(52), fill=(250, 255, 255, 248))
    draw.text((88, 530), "桌面最上方。", font=font(52), fill=(250, 255, 255, 248))
    draw_wrapped(
        draw,
        "液态玻璃悬浮岛显示优先级数量，展开后查看当前任务、快速新增、开始专注。",
        (92, 626),
        846,
        font(31),
        (224, 248, 247, 224),
        12,
    )
    draw_island_mock(img, (108, 760), 1.12)
    draw_task_panel_mock(img, (112, 990), (856, 338), 0.9)
    chip_x = 92
    chip_y = 1356
    for text in ["本地优先", "优先级", "专注计时"]:
        chip_x = draw_chip(draw, (chip_x, chip_y), text)
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / "taskisland-poster-3x4.png")


if __name__ == "__main__":
    render_landscape()
    render_portrait()
    print(f"Generated posters in {OUT}")
