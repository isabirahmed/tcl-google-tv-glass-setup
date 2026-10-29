#!/usr/bin/env python3
"""SVG logos -> Android vector drawables (glyph_<name>.xml) and frosted-glass tile banners (banner_<name>.xml).

Usage: python3 -I build_icons.py <out res/drawable dir>
Reads dl/*.svg (Simple Icons, single path, CC0, drawn white) and custom/*.svg (drawn by hand, with their own solid colours).
The SVGs are treated as untrusted: only the d / fill / stroke attributes of <path> elements are read, and each value is
checked against a whitelist before it is written into XML. No gradients anywhere: solid colours only.
"""
import re, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = Path(sys.argv[1])
D_OK = re.compile(r"^[MmLlHhVvCcSsQqTtAaZz0-9eE.,+\- \n\t]+$")
HEX_OK = re.compile(r"^#[0-9A-Fa-f]{6}$")
NUM_OK = re.compile(r"^[0-9]+(\.[0-9]+)?$")
CAP_OK = {"round", "butt", "square"}
JOIN_OK = {"round", "bevel", "miter"}
# name -> (svg, the app's own colour for the tile's flat tint, glyph size in dp on the 180 x 162 dp tile)
ICONS = {
    "youtube": (HERE / "dl/youtube.svg", "#FF2D3B", 66),
    "stremio": (HERE / "dl/stremio.svg", "#7B5BF5", 58),
    "surfshark": (HERE / "dl/surfshark.svg", "#14B8C6", 56),
    "googleplay": (HERE / "custom/googleplay.svg", "#2EC26A", 54),
    "browsehere": (HERE / "custom/browsehere.svg", "#2F6BFF", 58),
    "weather": (HERE / "custom/weather.svg", "#3C9BF0", 62),
}
# The art is drawn at the card's REAL size, so the card's ImageView shows it 1:1. Drawn at 180 x 162 dp and shrunk to the 86 dp card, the
# logos' cached bitmaps were resampled at 0.48 and their edges came out stair-stepped. 86 dp x 90 % = 77.4 dp = 154.8 px, which
# AppAdapter.tileHeightPx rounds to 155 px (77.5 dp at density 2); keep these in step with config.xml square_tile_dp / square_tile_aspect.
TILE_W, TILE_H = 86, 77.5           # dp
RADIUS = 18.9                        # dp, 22 % of the width (AppAdapter.cornerRadius)
SCALE = TILE_W / 180                 # the glyph sizes below were chosen on a 180 dp wide tile
ICON_CENTER_Y = TILE_H * 0.41        # the logo's centre; the name sits just under it (AppAdapter label padding)

def dp(x):
    return ("%.1f" % x).rstrip("0").rstrip(".")

def attr(tag, name):
    m = re.search(r'\b%s="([^"]*)"' % re.escape(name), tag)
    return m.group(1) if m else None

def argb(hexcol):
    return "#FF" + hexcol[1:].upper()

def vector(svg):
    paths = re.findall(r"<path\b[^>]*>", svg)
    if not paths:
        raise SystemExit("no <path> in svg")
    body = []
    for tag in paths:
        d = attr(tag, "d")
        if not d or not D_OK.match(d):
            raise SystemExit("refusing path data: %r" % (d or "")[:60])
        fill, stroke = attr(tag, "fill"), attr(tag, "stroke")
        line = ['    <path android:pathData="%s"' % " ".join(d.split())]
        if stroke and stroke != "none":
            if not HEX_OK.match(stroke):
                raise SystemExit("refusing stroke %r" % stroke)
            sw = attr(tag, "stroke-width") or "1"
            if not NUM_OK.match(sw):
                raise SystemExit("refusing stroke-width %r" % sw)
            line.append('android:strokeColor="%s" android:strokeWidth="%s"' % (argb(stroke), sw))
            cap, join = attr(tag, "stroke-linecap"), attr(tag, "stroke-linejoin")
            if cap in CAP_OK: line.append('android:strokeLineCap="%s"' % cap)
            if join in JOIN_OK: line.append('android:strokeLineJoin="%s"' % join)
        if fill != "none":
            line.append('android:fillColor="%s"' % (argb(fill) if fill and HEX_OK.match(fill) else "#FFFFFFFF"))   # no fill: white
        body.append(" ".join(line) + "/>")
    return ('<?xml version="1.0" encoding="utf-8"?>\n'
            '<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="24dp" android:height="24dp"\n'
            '    android:viewportWidth="24" android:viewportHeight="24">\n' + "\n".join(body) + "\n</vector>\n")

BANNER = '''<?xml version="1.0" encoding="utf-8"?>
<!-- Glass layers of the frosted card for %(name)s (config.xml, app_banners), modelled on the owner's reference card. The blurred
     wallpaper is painted underneath by the launcher (GlassBackdrop, the card's background). On top of it: a smoky dark veil
     (the glass is darker than what is behind it), a soft light that fades out towards the middle and a diagonal light from the
     top-left corner (the uneven "gradient frosting"), a flat whisper of the app's colour (no edge line: the card is just glass), and the logo a little
     above centre so the name (drawn by the launcher) sits tight under it. Radius %(r)sdp of %(w)sdp = the 22%% corner
     AppAdapter.cornerRadius clips to. Drawn at the card's real size (no ImageView rescaling), which keeps the logo's edges smooth. Made by work/icons/build_icons.py. -->
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:width="%(w)sdp" android:height="%(h)sdp">
        <shape android:shape="rectangle">
            <solid android:color="#66000000" />
            <corners android:radius="%(r)sdp" />
        </shape>
    </item>
    <item android:width="%(w)sdp" android:height="%(h)sdp">
        <shape android:shape="rectangle">
            <solid android:color="#10FFFFFF" />
            <corners android:radius="%(r)sdp" />
        </shape>
    </item>
    <item android:width="%(w)sdp" android:height="%(h)sdp">
        <shape android:shape="rectangle">
            <gradient android:angle="270" android:startColor="#22FFFFFF" android:centerColor="#00FFFFFF" android:endColor="#00FFFFFF" android:centerY="0.55" />
            <corners android:radius="%(r)sdp" />
        </shape>
    </item>
    <item android:width="%(w)sdp" android:height="%(h)sdp">
        <shape android:shape="rectangle">
            <gradient android:angle="315" android:startColor="#24FFFFFF" android:endColor="#00FFFFFF" />
            <corners android:radius="%(r)sdp" />
        </shape>
    </item>
    <item android:width="%(w)sdp" android:height="%(h)sdp">
        <shape android:shape="rectangle">
            <solid android:color="%(tint)s" />
            <corners android:radius="%(r)sdp" />
        </shape>
    </item>
    <item android:width="%(size)sdp" android:height="%(size)sdp" android:top="%(top)sdp" android:gravity="top|center_horizontal"
        android:drawable="@drawable/glyph_%(name)s" />
</layer-list>
'''

for name, (path, brand, size) in ICONS.items():
    OUT.joinpath("glyph_%s.xml" % name).write_text(vector(path.read_text()))
    tint = "#12" + brand[1:]   # 7 % of the app's colour, flat
    OUT.joinpath("banner_%s.xml" % name).write_text(BANNER % {
        "name": name, "w": dp(TILE_W), "h": dp(TILE_H), "r": dp(RADIUS), "size": dp(size * SCALE),
        "top": dp(ICON_CENTER_Y - size * SCALE / 2), "tint": tint})
    print("wrote glyph_%s.xml + banner_%s.xml" % (name, name))
