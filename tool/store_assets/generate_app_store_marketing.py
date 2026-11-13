#!/usr/bin/env python3
"""Builds App Store marketing images from the captured screenshots.

Outputs, under assets/store/app-store/marketing/:
  header-5244x2950.png         promotional header artwork, both sizes
  header-3840x1646.png         App Store Connect accepts
  search-result-5244x2950.png  landscape search-result artwork, in each
  search-result-3840x2560.png  size App Store Connect accepts
  search-result-1920x1280.png
  captioned-screenshots/iphone-6.9/  first three screenshot slots with
  captioned-screenshots/ipad-13/     captions

Each image is laid out as HTML and rendered with headless Chrome, so the
captions use the system San Francisco font. Run after
capture_app_store_screenshots.sh:

  python3 tool/store_assets/generate_app_store_marketing.py
"""

from __future__ import annotations

import html
import pathlib
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
STORE = ROOT / "assets" / "store"
SHOTS = STORE / "app-store" / "screenshots"
OUT = STORE / "app-store" / "marketing"
ICON = STORE / "docscanly-app-icon-1024.png"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# Search results show the first three screenshots, so lead with the scan.
SEARCH_SLOTS = ["05-crop", "06-enhance", "01-library"]

BASE_CSS = """
* { margin: 0; padding: 0; box-sizing: border-box; }
html, body { width: 100%; height: 100%; overflow: hidden; }
body {
  font-family: -apple-system, "SF Pro Display", "Helvetica Neue", sans-serif;
  color: #fff;
  background:
    radial-gradient(ellipse at 50% 0%, rgba(99,102,241,.55), transparent 60%),
    radial-gradient(ellipse at 100% 100%, rgba(124,58,237,.55), transparent 55%),
    linear-gradient(160deg, #1e2a8a 0%, #2730a8 45%, #3b1fa8 100%);
  position: relative;
}
.glow {
  position: absolute; left: 0; right: 0; height: 6px;
  background: linear-gradient(90deg, transparent, #67e8f9 20%, #22d3ee 50%, #67e8f9 80%, transparent);
  box-shadow: 0 0 40px 12px rgba(34,211,238,.45);
}
.device {
  position: absolute; background: #0b0b10;
  box-shadow: 0 60px 140px rgba(5,8,40,.6), 0 0 0 3px rgba(255,255,255,.12) inset;
}
.device img { display: block; width: 100%; height: auto; }
"""


def uri(path: pathlib.Path) -> str:
    return path.resolve().as_uri()


def render(markup: str, width: int, height: int, out: pathlib.Path) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        page = pathlib.Path(tmp) / "page.html"
        page.write_text(markup, encoding="utf-8")
        subprocess.run(
            [
                CHROME,
                "--headless=new",
                "--disable-gpu",
                "--hide-scrollbars",
                "--force-device-scale-factor=1",
                "--allow-file-access-from-files",
                f"--window-size={width},{height}",
                f"--screenshot={out}",
                page.as_uri(),
            ],
            check=True,
            capture_output=True,
        )
    print(f"wrote {out.relative_to(ROOT)}")


def caption(name: str) -> tuple[str, str]:
    title, subtitle = "", ""
    for line in (SHOTS / "iphone-6.9" / f"{name}.txt").read_text().splitlines():
        if line.startswith("Title:"):
            title = line.split(":", 1)[1].strip()
        elif line.startswith("Subtitle:"):
            subtitle = line.split(":", 1)[1].strip()
    if not title:
        sys.exit(f"{name}.txt has no title")
    return title, subtitle


def captioned(
    shot: pathlib.Path,
    title: str,
    subtitle: str,
    *,
    width: int,
    height: int,
    device_width: int,
    bezel: int,
    radius: int,
    top: int,
    title_size: int,
) -> str:
    screen_width = device_width - 2 * bezel
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>{BASE_CSS}
.caption {{ position: absolute; top: {int(top * 0.2)}px; left: 0; right: 0;
  text-align: center; padding: 0 {int(width * 0.07)}px; }}
.title {{ font-size: {title_size}px; font-weight: 800; letter-spacing: -0.02em;
  line-height: 1.08; }}
.subtitle {{ margin-top: {int(title_size * 0.35)}px; font-size: {int(title_size * 0.46)}px;
  font-weight: 500; opacity: .82; line-height: 1.25; }}
.device {{ left: {(width - device_width) // 2}px; top: {top}px; width: {device_width}px;
  padding: {bezel}px; border-radius: {radius}px; }}
.device img {{ border-radius: {radius - bezel}px; width: {screen_width}px; }}
.glow {{ top: {top - 70}px; opacity: .9; }}
</style></head><body>
<div class="caption">
  <div class="title">{html.escape(title)}</div>
  {f'<div class="subtitle">{html.escape(subtitle)}</div>' if subtitle else ''}
</div>
<div class="glow"></div>
<div class="device"><img src="{uri(shot)}"></div>
</body></html>"""


def header(width: int, height: int) -> str:
    """Text on the left, three iPhones on the right.

    Laid out on a stage 1080 design units tall and scaled to the exact output
    size, so each supported aspect ratio gets its own arrangement.
    """
    scale = height / 1080
    stage = width / scale
    roomy = stage > 2200
    phone_scale = 1.0 if roomy else 0.84
    font_scale = 1.0 if roomy else 0.74
    margin = 130 if roomy else 110

    # Screenshot aspect ratio (width / height) of the 6.9" captures.
    aspect = 1320 / 2868
    centre_screen = 908 * phone_scale
    side_screen = 752 * phone_scale
    centre_pad, side_pad = 16 * phone_scale, 14 * phone_scale
    centre_w = centre_screen * aspect + 2 * centre_pad
    side_w = side_screen * aspect + 2 * side_pad
    # Negative: a small gap, so no screen is covered by its neighbour.
    overlap = -28 * phone_scale
    right_left = stage - margin - side_w
    centre_left = right_left - centre_w + overlap
    left_left = centre_left - side_w + overlap
    centre_top = (1080 - (centre_screen + 2 * centre_pad)) / 2
    side_top = (1080 - (side_screen + 2 * side_pad)) / 2 + 30
    text_width = left_left - margin - 80

    left_phone = SHOTS / "iphone-6.9" / "01-library.png"
    centre_phone = SHOTS / "iphone-6.9" / "05-crop.png"
    right_phone = SHOTS / "iphone-6.9" / "03-compress.png"
    f = font_scale
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>{BASE_CSS}
.stage {{ position: absolute; left: 0; top: 0; width: {stage}px; height: 1080px;
  transform: scale({scale}); transform-origin: 0 0; }}
.brand {{ position: absolute; left: {margin}px; top: 0; bottom: 0; width: {text_width}px;
  display: flex; flex-direction: column; justify-content: center; }}
.row {{ display: flex; align-items: center; gap: {40 * f}px; }}
.row img {{ width: {180 * f}px; height: {180 * f}px; border-radius: {42 * f}px;
  box-shadow: 0 30px 80px rgba(5,8,40,.5); }}
.name {{ font-size: {128 * f}px; font-weight: 800; letter-spacing: -0.03em; }}
.tag {{ margin-top: {48 * f}px; font-size: {88 * f}px; font-weight: 700; line-height: 1.1;
  letter-spacing: -0.02em; }}
.sub {{ margin-top: {30 * f}px; font-size: {48 * f}px; font-weight: 500; opacity: .8;
  line-height: 1.3; }}
.glow {{ top: 537px; left: {left_left - 140}px; }}
.device img {{ width: auto; }}
.phone {{ top: {side_top}px; padding: {side_pad}px; border-radius: {74 * phone_scale}px; z-index: 1; }}
.phone img {{ height: {side_screen}px; border-radius: {60 * phone_scale}px; }}
.left {{ left: {left_left}px; }}
.right {{ left: {right_left}px; }}
.centre {{ left: {centre_left}px; top: {centre_top}px; padding: {centre_pad}px;
  border-radius: {86 * phone_scale}px; z-index: 2; }}
.centre img {{ height: {centre_screen}px; border-radius: {70 * phone_scale}px; }}
</style></head><body><div class="stage">
<div class="glow"></div>
<div class="brand">
  <div class="row"><img src="{uri(ICON)}"><div class="name">DocScanly</div></div>
  <div class="tag">Scan, edit and share&nbsp;PDFs</div>
  <div class="sub">Crop, enhance, compress, watermark &mdash; all on your device.</div>
</div>
<div class="device phone left"><img src="{uri(left_phone)}"></div>
<div class="device phone right"><img src="{uri(right_phone)}"></div>
<div class="device centre"><img src="{uri(centre_phone)}"></div>
</div></body></html>"""


def search_result(width: int, height: int) -> str:
    """Headline across the top, four iPhones in a row beneath it.

    Laid out on a stage 1080 design units tall and scaled to the exact
    output size.
    """
    scale = height / 1080
    stage = width / scale
    aspect = 1320 / 2868
    shots = ["05-crop", "06-enhance", "01-library", "03-compress"]
    # Inner phones are taller, so the row reads as a gentle arc.
    screens = [600, 680, 680, 600]
    pad = 13
    gap = 34
    widths = [h * aspect + 2 * pad for h in screens]
    row = sum(widths) + gap * (len(widths) - 1)
    # Shrink the row if a narrow stage cannot hold it.
    fit = min(1.0, (stage - 160) / row)
    x = (stage - row * fit) / 2
    phones = []
    for name, screen, w in zip(shots, screens, widths):
        h = (screen + 2 * pad) * fit
        top = 1080 - 40 - h - (0 if screen == max(screens) else 0)
        phones.append(
            f'<div class="device" style="left:{x}px;top:{top}px;'
            f'padding:{pad * fit}px;border-radius:{62 * fit}px">'
            f'<img style="height:{screen * fit}px;width:auto;'
            f'border-radius:{50 * fit}px" src="{uri(SHOTS / "iphone-6.9" / f"{name}.png")}"></div>'
        )
        x += (w + gap) * fit
    return f"""<!doctype html><html><head><meta charset="utf-8"><style>{BASE_CSS}
.stage {{ position: absolute; left: 0; top: 0; width: {stage}px; height: 1080px;
  transform: scale({scale}); transform-origin: 0 0; }}
.head {{ position: absolute; top: 56px; left: 0; right: 0; text-align: center; }}
.row {{ display: inline-flex; align-items: center; gap: 26px; }}
.row img {{ width: 96px; height: 96px; border-radius: 22px;
  box-shadow: 0 20px 50px rgba(5,8,40,.5); }}
.name {{ font-size: 76px; font-weight: 800; letter-spacing: -0.03em; }}
.tag {{ margin-top: 18px; font-size: 54px; font-weight: 700; letter-spacing: -0.02em; }}
.sub {{ margin-top: 10px; font-size: 32px; font-weight: 500; opacity: .8; }}
.glow {{ top: 700px; }}
</style></head><body><div class="stage">
<div class="glow"></div>
<div class="head">
  <div class="row"><img src="{uri(ICON)}"><div class="name">DocScanly</div></div>
  <div class="tag">Scan, edit and share&nbsp;PDFs</div>
  <div class="sub">Crop, enhance, compress, watermark &mdash; all on your device.</div>
</div>
{"".join(phones)}
</div></body></html>"""


def main() -> None:
    if not pathlib.Path(CHROME).exists():
        sys.exit("Google Chrome is required to render the marketing images.")

    for width, height in [(5244, 2950), (3840, 1646)]:
        render(
            header(width, height),
            width,
            height,
            OUT / f"header-{width}x{height}.png",
        )

    for width, height in [(5244, 2950), (3840, 2560), (1920, 1280)]:
        render(
            search_result(width, height),
            width,
            height,
            OUT / f"search-result-{width}x{height}.png",
        )

    for slot, name in enumerate(SEARCH_SLOTS, start=1):
        title, subtitle = caption(name)
        render(
            captioned(
                SHOTS / "iphone-6.9" / f"{name}.png",
                title,
                subtitle,
                width=1320,
                height=2868,
                device_width=1040,
                bezel=28,
                radius=150,
                top=640,
                title_size=104,
            ),
            1320,
            2868,
            OUT / "captioned-screenshots" / "iphone-6.9" / f"0{slot}-{name}.png",
        )
        render(
            captioned(
                SHOTS / "ipad-13" / f"{name}.png",
                title,
                subtitle,
                width=2064,
                height=2752,
                device_width=1600,
                bezel=22,
                radius=70,
                top=560,
                title_size=112,
            ),
            2064,
            2752,
            OUT / "captioned-screenshots" / "ipad-13" / f"0{slot}-{name}.png",
        )


if __name__ == "__main__":
    main()
