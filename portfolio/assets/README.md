# NoorAI — Brand Asset System

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
