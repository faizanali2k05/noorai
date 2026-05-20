"""Generate NoorAI master SVGs: app icon + standalone mark, parametrized."""
import math

# ---- Palette ----
EMERALD = "#1FA971"   # lighter Pakistan green (top-left)
DEEP    = "#01411C"   # official Pakistan flag green (bottom-right)
MID     = "#0B6E3B"

def star_points(cx, cy, r_out, r_in, rot_deg=-90):
    """5-pointed star polygon points string."""
    pts = []
    for i in range(10):
        ang = math.radians(rot_deg + i * 36)
        r = r_out if i % 2 == 0 else r_in
        pts.append(f"{cx + r*math.cos(ang):.2f},{cy + r*math.sin(ang):.2f}")
    return " ".join(pts)

# Composition geometry (1024 canvas)
# Crescent — slimmer, elegant, opening toward upper-right
CB_CX, CB_CY, CB_R = 398, 566, 258      # big white circle
CC_CX, CC_CY, CC_R = 492, 520, 224      # cutting circle (smaller, offset up-right -> bold open crescent)
# Star (sits clearly in the crescent opening, upper-right)
ST_CX, ST_CY = 706, 366
ST_RO, ST_RI = 82, 33

# Neural constellation nodes (x, y, radius, opacity) — kept in open right space
NODES = [
    (852, 286, 14, 1.00),
    (888, 466, 11, 0.85),
    (792, 588, 13, 0.92),
    (628, 240, 10, 0.75),
]
# Edges connecting node indices (or 'S' for star center)
EDGES = [
    ('S', 0), ('S', 1), ('S', 2), ('S', 3),
    (0, 1), (1, 2),
]

def constellation(stroke="#FFFFFF", node_fill="#FFFFFF", line_op=0.55, glow=True):
    parts = []
    # edges first (under nodes)
    def pt(idx):
        if idx == 'S':
            return ST_CX, ST_CY
        return NODES[idx][0], NODES[idx][1]
    for a, b in EDGES:
        x1, y1 = pt(a); x2, y2 = pt(b)
        parts.append(
            f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" '
            f'stroke="{stroke}" stroke-width="4.5" stroke-opacity="{line_op}" stroke-linecap="round"/>'
        )
    # star (brightest node)
    if glow:
        parts.append(f'<circle cx="{ST_CX}" cy="{ST_CY}" r="150" fill="url(#starGlow)"/>')
    parts.append(f'<polygon points="{star_points(ST_CX, ST_CY, ST_RO, ST_RI)}" fill="{node_fill}"/>')
    # satellite nodes
    for (x, y, r, op) in NODES:
        parts.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{node_fill}" fill-opacity="{op}"/>')
        if glow:
            parts.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="none" stroke="{node_fill}" stroke-opacity="0.25" stroke-width="6"/>')
    return "\n    ".join(parts)

def circle_subpath(cx, cy, r):
    return f"M{cx-r},{cy} a{r},{r} 0 1,0 {2*r},0 a{r},{r} 0 1,0 {-2*r},0 z"

def crescent_path(fill):
    d = f"{circle_subpath(CB_CX, CB_CY, CB_R)} {circle_subpath(CC_CX, CC_CY, CC_R)}"
    return f'<path fill="{fill}" fill-rule="evenodd" d="{d}"/>'

# ---------- ICON (full color, squircle bg) ----------
def icon_svg():
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="{EMERALD}"/>
      <stop offset="0.55" stop-color="{MID}"/>
      <stop offset="1" stop-color="{DEEP}"/>
    </linearGradient>
    <radialGradient id="topGlow" cx="0.3" cy="0.25" r="0.85">
      <stop offset="0" stop-color="#FFFFFF" stop-opacity="0.20"/>
      <stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="starGlow" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0" stop-color="#FFFFFF" stop-opacity="0.55"/>
      <stop offset="0.5" stop-color="#FFFFFF" stop-opacity="0.12"/>
      <stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <rect x="0" y="0" width="1024" height="1024" rx="230" ry="230" fill="url(#bg)"/>
  <rect x="0" y="0" width="1024" height="1024" rx="230" ry="230" fill="url(#topGlow)"/>
  <!-- crescent -->
  {crescent_path("#FFFFFF")}
  <!-- neural constellation + star -->
  {constellation()}
</svg>'''

# ---------- MARK (transparent, currentColor) ----------
def mark_svg(color="#FFFFFF", with_glow=False, pad=False):
    glowdef = '''<radialGradient id="starGlow" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0" stop-color="#FFFFFF" stop-opacity="0.5"/>
      <stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/>
    </radialGradient>''' if with_glow else ''
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    {glowdef}
  </defs>
  {crescent_path(color)}
  {constellation(stroke=color, node_fill=color, line_op=0.6, glow=with_glow)}
</svg>'''

if __name__ == "__main__":
    open("icon.svg", "w").write(icon_svg())
    open("mark-white.svg", "w").write(mark_svg("#FFFFFF"))
    open("mark-black.svg", "w").write(mark_svg("#01411C"))
    print("written")
