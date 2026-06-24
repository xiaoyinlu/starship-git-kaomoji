# Assets

Preview images for the README.

| File | Description |
|------|-------------|
| `demo-clean.png` | Clean repo — hero screenshot (README) |
| `demo-dirty.png` | Dirty working tree |
| `demo-states.png` | Gallery of all git-state faces |
| `demo-layout.png` | Two-line architecture diagram |
| `demo-*.svg` | Source files used to generate PNGs |

## Why PNG, not SVG?

GitHub sanitizes SVG in READMEs (strips styles, blocks scripts, fonts often missing). PNG displays consistently everywhere.

## Regenerate PNG from SVG

```bash
brew install librsvg
cd docs/assets
for f in demo-*.svg; do rsvg-convert -w 1840 "$f" -o "${f%.svg}.png"; done
```

## Real terminal screenshots (optional)

```bash
screencapture -i ~/Desktop/prompt-clean.png
```

Replace `demo-clean.png` / `demo-dirty.png` for photo-real previews.
