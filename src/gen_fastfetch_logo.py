#!/usr/bin/env python3
"""Render a two-colour arc reactor as braille art for fastfetch.

Usage: gen_fastfetch_logo.py <output.txt> [cols] [rows]
Colour 1 ($1) = rings/coils, colour 2 ($2) = core. Map them in fastfetch's
logo.color. Needs rsvg-convert and ImageMagick.
"""
import math, subprocess, sys, tempfile, os

out = sys.argv[1]
COLS = int(sys.argv[2]) if len(sys.argv) > 2 else 48
ROWS = int(sys.argv[3]) if len(sys.argv) > 3 else 24
PW, PH = COLS * 2, ROWS * 4          # braille: 2x4 pixels per cell
S = 1000; c = S / 2                  # render size

def arc(r, a0, a1, sw):
    x0 = c + r * math.cos(math.radians(a0)); y0 = c + r * math.sin(math.radians(a0))
    x1 = c + r * math.cos(math.radians(a1)); y1 = c + r * math.sin(math.radians(a1))
    large = 1 if (a1 - a0) % 360 > 180 else 0
    return f'<path d="M{x0:.1f} {y0:.1f} A{r} {r} 0 {large} 1 {x1:.1f} {y1:.1f}" fill="none" stroke="#000" stroke-width="{sw}" stroke-linecap="butt"/>'

def ring(r, sw, dash=None):
    d = f' stroke-dasharray="{dash}"' if dash else ""
    return f'<circle cx="{c}" cy="{c}" r="{r}" fill="none" stroke="#000" stroke-width="{sw}"{d}/>'

def svg(body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" viewBox="0 0 {S} {S}"><rect width="{S}" height="{S}" fill="#fff"/>{"".join(body)}</svg>'

# layer 1: rings, ticks, coils, triangle
l1 = [ring(470, 24)]
for i in range(12):
    a = math.radians(360 * i / 24)
    l1.append(f'<line x1="{c + 415 * math.cos(a):.1f}" y1="{c + 415 * math.sin(a):.1f}" x2="{c + 448 * math.cos(a):.1f}" y2="{c + 448 * math.sin(a):.1f}" stroke="#000" stroke-width="20"/>')
for i in range(10):
    l1.append(arc(300, i * 36 + 5, i * 36 + 31, 62))
tri = [(c + 195 * math.cos(math.radians(-90 + 120 * i)), c + 195 * math.sin(math.radians(-90 + 120 * i))) for i in range(3)]
l1.append('<polygon points="' + " ".join(f"{x:.1f},{y:.1f}" for x, y in tri) + '" fill="none" stroke="#000" stroke-width="22" stroke-linejoin="round"/>')
# layer 2: core
l2 = [f'<circle cx="{c}" cy="{c}" r="88" fill="#000"/>']

def mask(body):
    with tempfile.TemporaryDirectory() as d:
        p = os.path.join(d, "l.svg"); open(p, "w").write(svg(body))
        png = os.path.join(d, "l.png")
        subprocess.run(["rsvg-convert", "-w", str(S), "-h", str(S), p, "-o", png], check=True)
        pbm = subprocess.run(["magick", png, "-colorspace", "Gray", "-resize", f"{PW}x{PH}!", "-threshold", "50%", "-compress", "none", "pbm:-"],
                             capture_output=True, text=True, check=True).stdout
    tok = pbm.split()
    assert tok[0] == "P1"
    w, h = int(tok[1]), int(tok[2]); px = tok[3:]
    return [[px[y * w + x] == "1" for x in range(w)] for y in range(h)]  # 1 = black = ink

m1, m2 = mask(l1), mask(l2)
DOT = {(0, 0): 1, (0, 1): 2, (0, 2): 4, (1, 0): 8, (1, 1): 16, (1, 2): 32, (0, 3): 64, (1, 3): 128}
lines = []
for cy in range(ROWS):
    line = ""; cur = None
    for cx in range(COLS):
        code = 0; n1 = n2 = 0
        for dy in range(4):
            for dx in range(2):
                x, y = cx * 2 + dx, cy * 4 + dy
                a = m1[y][x]; b = m2[y][x]
                if a or b:
                    code |= DOT[(dx, dy)]; n1 += a; n2 += b
        if code == 0:
            line += " "; continue
        col = 2 if n2 >= n1 else 1
        if col != cur:
            line += f"${col}"; cur = col
        line += chr(0x2800 + code)
    lines.append(line.rstrip())
while lines and not lines[0].strip(): lines.pop(0)
while lines and not lines[-1].strip(): lines.pop()
open(out, "w").write("\n".join(lines) + "\n")
print(f"wrote {out}: {len(lines)} rows x {max(len(l) for l in lines)} cols (incl. colour markers)")
