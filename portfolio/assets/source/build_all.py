"""Build the complete NoorAI brand asset system from master geometry."""
import os, math, shutil
import cairosvg
from PIL import Image
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
import svgbuild as S

ROOT = "/home/claude/noorai-brand-assets"
EMERALD, DEEP, MID = S.EMERALD, S.DEEP, S.MID
ACCENT_LIGHT = "#5EEAD4"   # bright mint for "AI" on dark bg

def fresh(p):
    if os.path.exists(p): shutil.rmtree(p)
    os.makedirs(p)

def mkdir(p):
    os.makedirs(p, exist_ok=True)

# ---------------- Wordmark outlining ----------------
FONT_BOLD = "/usr/share/fonts/truetype/google-fonts/Poppins-Bold.ttf"
FONT_MED  = "/usr/share/fonts/truetype/google-fonts/Poppins-Medium.ttf"

class Outliner:
    def __init__(self, path):
        self.font = TTFont(path)
        self.gs = self.font.getGlyphSet()
        self.cmap = self.font.getBestCmap()
        self.upm = self.font["head"].unitsPerEm
        self.hmtx = self.font["hmtx"]
    def run(self, text, size, x0, baseline, tracking=0.0):
        """Return (svg_group_string, advance_width). y grows downward (SVG)."""
        scale = size / self.upm
        x = x0
        parts = []
        for ch in text:
            gname = self.cmap[ord(ch)]
            pen = SVGPathPen(self.gs)
            self.gs[gname].draw(pen)
            d = pen.getCommands()
            if d:
                parts.append(
                    f'<path d="{d}" transform="translate({x:.2f},{baseline:.2f}) '
                    f'scale({scale:.5f},{-scale:.5f})"/>'
                )
            x += self.hmtx[gname][0] * scale + tracking
        return "\n  ".join(parts), x - x0

BOLD = Outliner(FONT_BOLD)

def wordmark_group(size, x0, baseline, color_noor, color_ai, tracking=-0.5):
    g1, w1 = BOLD.run("Noor", size, x0, baseline, tracking)
    g2, w2 = BOLD.run("AI",   size, x0 + w1 + size*0.06, baseline, tracking)
    svg = (f'<g fill="{color_noor}">\n  {g1}\n</g>\n'
           f'<g fill="{color_ai}">\n  {g2}\n</g>')
    total_w = w1 + size*0.06 + w2
    return svg, total_w

# ---------------- Tight mark (auto-cropped bbox) ----------------
def compute_art_bbox():
    cairosvg.svg2png(url="/home/claude/mark-white.svg", write_to="/home/claude/_bbox.png",
                     output_width=1024, output_height=1024)
    im = Image.open("/home/claude/_bbox.png")
    return im.getbbox()  # (l,t,r,b) of non-transparent

# ---------------- Master SVGs ----------------
def write_masters(md):
    open(f"{md}/noorai-icon.svg","w").write(S.icon_svg())
    open(f"{md}/noorai-mark-white.svg","w").write(S.mark_svg("#FFFFFF"))
    open(f"{md}/noorai-mark-green.svg","w").write(S.mark_svg(DEEP))
    open(f"{md}/noorai-mark-black.svg","w").write(S.mark_svg("#0A0A0A"))
    # color mark on transparent (gradient crescent + white-ish network) -> use green mark as the "color" mark
    open(f"{md}/noorai-mark-color.svg","w").write(_color_mark())
    # lockups
    open(f"{md}/noorai-lockup-horizontal.svg","w").write(lockup_horizontal(dark_bg=False))
    open(f"{md}/noorai-lockup-horizontal-dark.svg","w").write(lockup_horizontal(dark_bg=True))
    open(f"{md}/noorai-lockup-stacked.svg","w").write(lockup_stacked(dark_bg=False))
    open(f"{md}/noorai-wordmark.svg","w").write(wordmark_only(dark_bg=False))
    open(f"{md}/noorai-wordmark-dark.svg","w").write(wordmark_only(dark_bg=True))

def _color_mark():
    # crescent in brand gradient, network in deep green — for light backgrounds
    grad = f'''<linearGradient id="cm" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="{EMERALD}"/><stop offset="1" stop-color="{DEEP}"/>
    </linearGradient>'''
    body = S.crescent_path("url(#cm)") + "\n    " + S.constellation(stroke=DEEP, node_fill=DEEP, line_op=0.55, glow=False)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">\n'
            f'  <defs>{grad}</defs>\n  {body}\n</svg>')

# Mark with tight viewBox for lockups
L, T, Rr, B = (140, 272, 902, 824)  # refined below at runtime
def mark_inner(color, glow=False):
    return S.crescent_path(color) + "\n  " + S.constellation(stroke=color, node_fill=color, line_op=0.6, glow=glow)

def lockup_horizontal(dark_bg):
    bbox = (L, T, Rr, B)
    mw = bbox[2]-bbox[0]; mh = bbox[3]-bbox[1]
    H = 280.0
    mark_scale = H / mh
    mark_w = mw * mark_scale
    gap = H*0.34
    txt_size = H*0.62
    noor = "#FFFFFF" if dark_bg else DEEP
    ai = ACCENT_LIGHT if dark_bg else EMERALD
    mark_color = "#FFFFFF" if dark_bg else None
    baseline = H*0.5 + txt_size*0.36
    wm, ww = wordmark_group(txt_size, bbox[0]*0 + mark_w + gap, baseline, noor, ai)
    total_w = mark_w + gap + ww
    pad = 40
    mark_inner_svg = (mark_inner("#FFFFFF") if dark_bg else mark_inner_color())
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {total_w+pad*2:.0f} {H+pad*2:.0f}" '
            f'width="{total_w+pad*2:.0f}" height="{H+pad*2:.0f}">\n'
            f'  {_defs_color()}'
            f'  <g transform="translate({pad},{pad})">\n'
            f'    <g transform="translate(0,0) scale({mark_scale:.5f}) translate({-bbox[0]},{-bbox[1]})">\n'
            f'      {mark_inner_svg}\n    </g>\n'
            f'    {wm}\n'
            f'  </g>\n</svg>')

def mark_inner_color():
    return S.crescent_path("url(#cmL)") + "\n  " + S.constellation(stroke=DEEP, node_fill=DEEP, line_op=0.5, glow=False)

def _defs_color():
    return (f'<defs><linearGradient id="cmL" x1="0" y1="0" x2="1" y2="1">'
            f'<stop offset="0" stop-color="{EMERALD}"/><stop offset="1" stop-color="{DEEP}"/>'
            f'</linearGradient></defs>\n')

def lockup_stacked(dark_bg):
    bbox=(L,T,Rr,B); mw=bbox[2]-bbox[0]; mh=bbox[3]-bbox[1]
    MK=300.0; ms=MK/mh; mark_w=mw*ms
    txt=120.0
    noor="#FFFFFF" if dark_bg else DEEP
    ai=ACCENT_LIGHT if dark_bg else EMERALD
    wm,ww=wordmark_group(txt,0,0,noor,ai)
    pad=40
    W=max(mark_w,ww); 
    mark_x=(W-mark_w)/2; txt_x=(W-ww)/2
    baseline=MK+ txt*1.05
    wm,ww=wordmark_group(txt,txt_x,baseline,noor,ai)
    H=baseline+txt*0.1
    mark_inner_svg=(mark_inner("#FFFFFF") if dark_bg else mark_inner_color())
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W+pad*2:.0f} {H+pad*2:.0f}" '
            f'width="{W+pad*2:.0f}" height="{H+pad*2:.0f}">\n  {_defs_color()}'
            f'  <g transform="translate({pad},{pad})">\n'
            f'    <g transform="translate({mark_x:.1f},0) scale({ms:.5f}) translate({-bbox[0]},{-bbox[1]})">{mark_inner_svg}</g>\n'
            f'    {wm}\n  </g>\n</svg>')

def wordmark_only(dark_bg):
    txt=200.0
    noor="#FFFFFF" if dark_bg else DEEP
    ai=ACCENT_LIGHT if dark_bg else EMERALD
    pad=30
    wm,ww=wordmark_group(txt,pad, pad+txt*0.78, noor, ai)
    H=txt*1.0+pad*2
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {ww+pad*2:.0f} {H:.0f}" '
            f'width="{ww+pad*2:.0f}" height="{H:.0f}">\n  {wm}\n</svg>')

# ---------------- Rasterization helpers ----------------
def rasterize(svg_path, png_path, size, bg=None):
    cairosvg.svg2png(url=svg_path, write_to=png_path, output_width=size, output_height=size,
                     background_color=bg)

def square_png_from_icon(png_path, size):
    rasterize(f"{ROOT}/master/noorai-icon.svg", png_path, size)

def circle_mask(img):
    from PIL import ImageDraw
    m = Image.new("L", img.size, 0)
    d = ImageDraw.Draw(m); d.ellipse([0,0,img.size[0]-1,img.size[1]-1], fill=255)
    out = img.copy(); out.putalpha(m); return out

def squircle_mask(img, radius_frac=0.225):
    from PIL import ImageDraw
    w,h=img.size; r=int(w*radius_frac)
    m=Image.new("L",img.size,0); d=ImageDraw.Draw(m)
    d.rounded_rectangle([0,0,w-1,h-1], radius=r, fill=255)
    out=img.copy(); out.putalpha(m); return out

def main():
    fresh(ROOT)
    for sub in ["master","web","web/favicon","android/play",
                "android/mipmap-mdpi","android/mipmap-hdpi","android/mipmap-xhdpi",
                "android/mipmap-xxhdpi","android/mipmap-xxxhdpi",
                "android/adaptive","android/res-values","source","preview"]:
        mkdir(f"{ROOT}/{sub}")

    # refine bbox from actual render
    global L,T,Rr,B
    bb = compute_art_bbox()
    if bb:
        # add small breathing room
        pad=18
        L=max(0,bb[0]-pad); T=max(0,bb[1]-pad); Rr=min(1024,bb[2]+pad); B=min(1024,bb[3]+pad)

    write_masters(f"{ROOT}/master")

    # ---------- Tight transparent marks (PNG) for compositing ----------
    cairosvg.svg2png(url=f"{ROOT}/master/noorai-mark-white.svg", write_to="/home/claude/_mw.png",
                     output_width=2048, output_height=2048)
    mw_full = Image.open("/home/claude/_mw.png").convert("RGBA")
    mark_white = mw_full.crop(mw_full.getbbox())

    # ===================== WEB =====================
    web=f"{ROOT}/web"
    # PWA / generic
    for s in [192,512]:
        square_png_from_icon(f"{web}/icon-{s}.png", s)
    # favicons
    for s in [16,32,48,64]:
        square_png_from_icon(f"{web}/favicon/favicon-{s}.png", s)
    # favicon.ico (multi-res)
    ico_src = Image.open(f"{web}/favicon/favicon-64.png").convert("RGBA")
    ico_src.save(f"{web}/favicon.ico", sizes=[(16,16),(32,32),(48,48)])
    # apple-touch (no transparency, padded bg already squircle but apple adds its own mask -> full bleed bg)
    appletouch = Image.new("RGBA",(180,180), DEEP)
    icon180 = Image.open_icon = None
    cairosvg.svg2png(url=f"{ROOT}/master/noorai-icon.svg", write_to="/home/claude/_i180.png",
                     output_width=180, output_height=180)
    i180 = Image.open("/home/claude/_i180.png").convert("RGBA")
    appletouch.alpha_composite(i180)
    appletouch.convert("RGB").save(f"{web}/apple-touch-icon.png")
    # maskable (full-bleed gradient bg + mark in safe zone ~80%)
    for s in [192,512]:
        mk = Image.new("RGBA",(s,s),(0,0,0,0))
        # gradient bg
        bg = gradient_square(s)
        mk.alpha_composite(bg)
        scale = (s*0.62)/max(mark_white.size)
        mwi = mark_white.resize((int(mark_white.size[0]*scale), int(mark_white.size[1]*scale)), Image.LANCZOS)
        mk.alpha_composite(mwi, ((s-mwi.size[0])//2,(s-mwi.size[1])//2))
        mk.convert("RGB").save(f"{web}/maskable-{s}.png")
    # logo png exports (transparent) from lockups & mark
    cairosvg.svg2png(url=f"{ROOT}/master/noorai-lockup-horizontal.svg",
                     write_to=f"{web}/logo-horizontal.png", output_width=1200)
    cairosvg.svg2png(url=f"{ROOT}/master/noorai-lockup-horizontal-dark.svg",
                     write_to=f"{web}/logo-horizontal-dark.png", output_width=1200)
    cairosvg.svg2png(url=f"{ROOT}/master/noorai-mark-color.svg",
                     write_to=f"{web}/logo-mark.png", output_width=512, output_height=512)
    # copy key svgs into web
    for f in ["noorai-mark-color.svg","noorai-lockup-horizontal.svg","noorai-icon.svg"]:
        shutil.copy(f"{ROOT}/master/{f}", f"{web}/{f}")
    # OG / social image 1200x630
    make_og(f"{web}/og-image.png", mark_white)
    # webmanifest
    open(f"{web}/site.webmanifest","w").write(WEBMANIFEST)

    # ===================== ANDROID =====================
    a=f"{ROOT}/android"
    # Play Store hi-res 512
    square_png_from_icon(f"{a}/play/play-store-icon-512.png", 512)
    # legacy mipmaps (square + round) per density
    dens = {"mdpi":48,"hdpi":72,"xhdpi":96,"xxhdpi":144,"xxxhdpi":192}
    for name,px in dens.items():
        cairosvg.svg2png(url=f"{ROOT}/master/noorai-icon.svg", write_to="/home/claude/_t.png",
                         output_width=px, output_height=px)
        base=Image.open("/home/claude/_t.png").convert("RGBA")
        squircle_mask(base).save(f"{a}/mipmap-{name}/ic_launcher.png")
        circle_mask(base).save(f"{a}/mipmap-{name}/ic_launcher_round.png")
        # adaptive foreground per density (108dp canvas, art in 66dp safe zone)
        fg_px = int(px*108/48)  # scale 48->108 ratio
        fg = adaptive_foreground(fg_px, mark_white)
        fg.save(f"{a}/mipmap-{name}/ic_launcher_foreground.png")
        bgp = gradient_square(fg_px)
        bgp.save(f"{a}/mipmap-{name}/ic_launcher_background.png")
        mono = adaptive_foreground(fg_px, mark_white, mono=True)
        mono.save(f"{a}/mipmap-{name}/ic_launcher_monochrome.png")
    # reference 432 adaptive sources
    fg432 = adaptive_foreground(432, mark_white); fg432.save(f"{a}/adaptive/ic_launcher_foreground.png")
    gradient_square(432).save(f"{a}/adaptive/ic_launcher_background.png")
    adaptive_foreground(432, mark_white, mono=True).save(f"{a}/adaptive/ic_launcher_monochrome.png")
    open(f"{a}/adaptive/ic_launcher.xml","w").write(ADAPTIVE_XML)
    open(f"{a}/res-values/ic_launcher_background.xml","w").write(COLOR_XML)
    open(f"{a}/adaptive/README.txt","w").write(ANDROID_README)

    # ===================== SOURCE + PREVIEW =====================
    shutil.copy("/home/claude/svgbuild.py", f"{ROOT}/source/svgbuild.py")
    shutil.copy("/home/claude/build_all.py", f"{ROOT}/source/build_all.py")
    make_preview(f"{ROOT}/preview/brand-sheet.png", mark_white)
    open(f"{ROOT}/README.md","w").write(README)
    print("BUILD COMPLETE")

# ---- gradient helper (diagonal emerald->deep) ----
def gradient_square(size):
    from PIL import Image as I
    img = I.new("RGBA",(size,size))
    px = img.load()
    e=tuple(int(EMERALD[i:i+2],16) for i in (1,3,5))
    m=tuple(int(MID[i:i+2],16) for i in (1,3,5))
    dd=tuple(int(DEEP[i:i+2],16) for i in (1,3,5))
    for y in range(size):
        for x in range(size):
            t=(x+y)/(2*size)
            if t<0.55:
                u=t/0.55; c=tuple(int(e[i]+(m[i]-e[i])*u) for i in range(3))
            else:
                u=(t-0.55)/0.45; c=tuple(int(m[i]+(dd[i]-m[i])*u) for i in range(3))
            px[x,y]=(c[0],c[1],c[2],255)
    return img

def adaptive_foreground(size, mark_white, mono=False):
    canvas=Image.new("RGBA",(size,size),(0,0,0,0))
    # safe zone ~ 66/108 of full; keep mark within ~0.58 of canvas for comfortable margin
    target=size*0.58
    scale=target/max(mark_white.size)
    m=mark_white.resize((max(1,int(mark_white.size[0]*scale)),max(1,int(mark_white.size[1]*scale))),Image.LANCZOS)
    canvas.alpha_composite(m,((size-m.size[0])//2,(size-m.size[1])//2))
    return canvas

def make_og(path, mark_white):
    W,Hh=1200,630
    img=Image.new("RGBA",(W,Hh))
    # gradient bg
    g=gradient_square(max(W,Hh)).resize((W,Hh))
    img.alpha_composite(g)
    # mark left
    scale=(Hh*0.62)/max(mark_white.size)
    m=mark_white.resize((int(mark_white.size[0]*scale),int(mark_white.size[1]*scale)),Image.LANCZOS)
    img.alpha_composite(m,(120,(Hh-m.size[1])//2))
    # wordmark text via svg render
    cairosvg.svg2png(url=f"{ROOT}/master/noorai-wordmark-dark.svg", write_to="/home/claude/_wm.png",
                     output_width=620)
    wm=Image.open("/home/claude/_wm.png").convert("RGBA")
    img.alpha_composite(wm,(120+m.size[0]+70,(Hh-wm.size[1])//2))
    img.convert("RGB").save(path)

def make_preview(path, mark_white):
    W,Hh=1400,900
    img=Image.new("RGBA",(W,Hh),(245,247,246,255))
    # top: icon big
    cairosvg.svg2png(url=f"{ROOT}/master/noorai-icon.svg", write_to="/home/claude/_pi.png",
                     output_width=300,output_height=300)
    icon=Image.open("/home/claude/_pi.png").convert("RGBA")
    img.alpha_composite(icon,(80,80))
    # round + squircle small
    img.alpha_composite(circle_mask(icon).resize((150,150)),(420,80))
    img.alpha_composite(squircle_mask(icon).resize((150,150)),(420,250))
    # lockup
    cairosvg.svg2png(url=f"{ROOT}/master/noorai-lockup-horizontal.svg", write_to="/home/claude/_pl.png", output_width=620)
    lk=Image.open("/home/claude/_pl.png").convert("RGBA")
    img.alpha_composite(lk,(640,120))
    # dark strip with white lockup
    from PIL import ImageDraw
    d=ImageDraw.Draw(img); d.rectangle([80,470,1320,760],fill=DEEP)
    cairosvg.svg2png(url=f"{ROOT}/master/noorai-lockup-horizontal-dark.svg", write_to="/home/claude/_pld.png", output_width=620)
    lkd=Image.open("/home/claude/_pld.png").convert("RGBA")
    img.alpha_composite(lkd,(120,520))
    img.convert("RGB").save(path)

# ---------------- static text assets ----------------
WEBMANIFEST = '''{
  "name": "NoorAI",
  "short_name": "NoorAI",
  "description": "NoorAI",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#01411C",
  "theme_color": "#01411C",
  "icons": [
    { "src": "/icon-192.png", "sizes": "192x192", "type": "image/png", "purpose": "any" },
    { "src": "/icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "any" },
    { "src": "/maskable-192.png", "sizes": "192x192", "type": "image/png", "purpose": "maskable" },
    { "src": "/maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
'''

ADAPTIVE_XML = '''<?xml version="1.0" encoding="utf-8"?>
<!-- res/mipmap-anydpi-v26/ic_launcher.xml -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
'''

COLOR_XML = '''<?xml version="1.0" encoding="utf-8"?>
<!-- res/drawable/ic_launcher_background.xml  (or use the supplied gradient PNG) -->
<resources>
    <color name="ic_launcher_background">#01411C</color>
</resources>
'''

ANDROID_README = '''ANDROID ADAPTIVE ICON — how to install
=======================================
Place files in your Android project's res/ folder:

  res/mipmap-mdpi/ic_launcher.png            (and the other densities)
  res/mipmap-*/ic_launcher_round.png
  res/mipmap-*/ic_launcher_foreground.png
  res/mipmap-*/ic_launcher_monochrome.png
  res/drawable/ic_launcher_background.png    (or use the color in res-values)
  res/mipmap-anydpi-v26/ic_launcher.xml      (provided as ic_launcher.xml)
  res/mipmap-anydpi-v26/ic_launcher_round.xml (copy of ic_launcher.xml)

The foreground art is sized inside the 66dp safe zone, so the launcher mask
(circle, squircle, rounded-square, teardrop) will never clip the crescent or star.
<monochrome> drives Android 13+ themed icons.
'''

README = '''# NoorAI — Brand Asset System

A complete logo + icon set fusing the **Pakistani flag** (crescent + star, official
green `#01411C`) with **AI** — the star is the brightest node in a small neural
constellation, which also evokes *Noor* (نور, "light").

## Concept
- **Crescent + star** → instantly Pakistani / recognisable.
- **Neural constellation** → the star anchors a small network of light-nodes (AI).
- **Glow** → *Noor* = light.
- **Graceful degradation** → at favicon sizes the thin network drops away and the
  mark reads cleanly as crescent + star.

## Colors
| Token | Hex | Use |
|-------|-----|-----|
| Pakistan Green (deep) | `#01411C` | primary, dark text, backgrounds |
| Emerald | `#1FA971` | gradient top, "AI" accent on light |
| Mid Green | `#0B6E3B` | gradient mid |
| Mint Accent | `#5EEAD4` | "AI" accent on dark |
| White | `#FFFFFF` | crescent, mark on dark |

Typeface: **Poppins** (wordmark is outlined to vector paths — no font dependency).

## Folder map
```
master/    Editable vector sources (SVG): icon, marks (white/green/black/color),
           wordmark, and horizontal/stacked lockups (light + dark).
web/        favicon.ico (16/32/48), favicon-*.png, icon-192/512 (PWA),
            maskable-192/512, apple-touch-icon, og-image (1200x630),
            logo SVGs/PNGs, site.webmanifest.
android/    play-store-icon-512, mipmap-*/ (ic_launcher, _round, _foreground,
            _monochrome, _background per density), adaptive/ (432 sources +
            ic_launcher.xml), res-values/ (background color).
preview/    brand-sheet.png — quick visual overview.
source/     The Python that generated everything (re-run to regenerate).
```

## Regenerate
```
pip install cairosvg pillow fonttools --break-system-packages
python source/build_all.py
```

## Honest notes
- The mark is intentionally asymmetric (network sits in the crescent's opening).
  Keep clear space ≈ the star's height around the mark in layouts.
- Don't recolor the crescent to anything but white / deep-green / black — the
  green↔white contrast is the recognisability anchor.
- For tiny UI (≤24px) prefer `noorai-mark-*` over the full icon.
'''

if __name__ == "__main__":
    main()
