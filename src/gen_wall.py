import math, sys
W,H = 3840,2160
cx,cy = W/2, H/2
CY="#00d8ff"; GD="#ffc857"
out=[]
a=out.append
a(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">')
a('''<defs>
 <radialGradient id="bg" cx="50%" cy="50%" r="75%">
  <stop offset="0" stop-color="#0f2236"/><stop offset="0.55" stop-color="#0b1521"/><stop offset="1" stop-color="#040a12"/>
 </radialGradient>
 <radialGradient id="core" cx="50%" cy="50%" r="50%">
  <stop offset="0" stop-color="#ffffff" stop-opacity="0.95"/><stop offset="0.35" stop-color="#7aeaff" stop-opacity="0.85"/>
  <stop offset="0.7" stop-color="#00d8ff" stop-opacity="0.35"/><stop offset="1" stop-color="#00d8ff" stop-opacity="0"/>
 </radialGradient>
 <filter id="glow" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="6"/></filter>
 <filter id="glow2" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="18"/></filter>
 <pattern id="grid" width="120" height="120" patternUnits="userSpaceOnUse">
  <path d="M120 0H0V120" fill="none" stroke="#00d8ff" stroke-opacity="0.06" stroke-width="1"/>
 </pattern>
</defs>''')
a(f'<rect width="{W}" height="{H}" fill="url(#bg)"/>')
a(f'<rect width="{W}" height="{H}" fill="url(#grid)"/>')
# faint scanlines
a(f'<g stroke="#000" stroke-opacity="0.12" stroke-width="1">')
for y in range(0,H,4): a(f'<line x1="0" y1="{y}" x2="{W}" y2="{y}"/>')
a('</g>')

def ring(r, sw, op, color=CY, dash=None, extra=""):
    d = f' stroke-dasharray="{dash}"' if dash else ""
    a(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{color}" stroke-opacity="{op}" stroke-width="{sw}"{d}{extra}/>')

def arc(r, a0, a1, sw, op, color=CY, extra=""):
    x0=cx+r*math.cos(math.radians(a0)); y0=cy+r*math.sin(math.radians(a0))
    x1=cx+r*math.cos(math.radians(a1)); y1=cy+r*math.sin(math.radians(a1))
    large = 1 if (a1-a0)%360>180 else 0
    a(f'<path d="M{x0:.1f} {y0:.1f} A{r} {r} 0 {large} 1 {x1:.1f} {y1:.1f}" fill="none" stroke="{color}" stroke-opacity="{op}" stroke-width="{sw}" stroke-linecap="round"{extra}/>')

def ticks(r, n, length, sw, op, color=CY, skip=1):
    a(f'<g stroke="{color}" stroke-opacity="{op}" stroke-width="{sw}">')
    for i in range(n):
        if i%skip: continue
        t=math.radians(360*i/n)
        a(f'<line x1="{cx+r*math.cos(t):.1f}" y1="{cy+r*math.sin(t):.1f}" x2="{cx+(r+length)*math.cos(t):.1f}" y2="{cy+(r+length)*math.sin(t):.1f}"/>')
    a('</g>')

# outer glow halo
a(f'<circle cx="{cx}" cy="{cy}" r="700" fill="{CY}" fill-opacity="0.05" filter="url(#glow2)"/>')
# big outer rings
ring(880, 2, 0.18); ring(860, 1, 0.12, dash="6 18")
ticks(880, 180, 18, 2, 0.25, skip=1); ticks(880, 36, 40, 3, 0.35)
arc(820, -30, 60, 6, 0.55); arc(820, 150, 240, 6, 0.55)
arc(790, 100, 130, 10, 0.5, GD); arc(790, 280, 310, 10, 0.5, GD)
ring(740, 1.5, 0.22, dash="40 20")
# mid rings
ring(620, 3, 0.35); ticks(620, 120, 14, 2, 0.35)
arc(590, 200, 340, 4, 0.6, extra=' filter="url(#glow)"'); arc(590, 200, 340, 3, 0.9)
arc(590, 20, 160, 4, 0.6, extra=' filter="url(#glow)"'); arc(590, 20, 160, 3, 0.9)
ring(540, 1, 0.25, dash="3 9")
arc(510, -60, 20, 12, 0.7, GD); arc(510, 120, 200, 12, 0.7, GD)
# inner reactor
ring(430, 6, 0.85, extra=' filter="url(#glow)"'); ring(430, 3, 1)
ticks(400, 60, 22, 4, 0.8)
ring(370, 2, 0.6)
# reactor triangle
tr=[(cx+330*math.cos(math.radians(-90+120*i)), cy+330*math.sin(math.radians(-90+120*i))) for i in range(3)]
pts=" ".join(f"{x:.1f},{y:.1f}" for x,y in tr)
a(f'<polygon points="{pts}" fill="none" stroke="{CY}" stroke-opacity="0.9" stroke-width="10" stroke-linejoin="round" filter="url(#glow)"/>')
a(f'<polygon points="{pts}" fill="#00d8ff" fill-opacity="0.08" stroke="#e6f7ff" stroke-width="4" stroke-linejoin="round"/>')
# ten coil segments
a(f'<g stroke="{CY}" stroke-width="26" stroke-opacity="0.75" fill="none">')
for i in range(10):
    a0=i*36+4; a1=i*36+32
    x0=cx+290*math.cos(math.radians(a0)); y0=cy+290*math.sin(math.radians(a0))
    x1=cx+290*math.cos(math.radians(a1)); y1=cy+290*math.sin(math.radians(a1))
    a(f'<path d="M{x0:.1f} {y0:.1f} A290 290 0 0 1 {x1:.1f} {y1:.1f}"/>')
a('</g>')
# core
a(f'<circle cx="{cx}" cy="{cy}" r="260" fill="url(#core)"/>')
a(f'<circle cx="{cx}" cy="{cy}" r="150" fill="url(#core)"/>')
a(f'<circle cx="{cx}" cy="{cy}" r="120" fill="none" stroke="#e6f7ff" stroke-opacity="0.9" stroke-width="3"/>')

# corner HUD brackets
def bracket(x,y,sx,sy):
    a(f'<path d="M{x} {y+sy*140} V{y} H{x+sx*140}" fill="none" stroke="{CY}" stroke-opacity="0.5" stroke-width="3"/>')
    a(f'<path d="M{x+sx*20} {y+sy*90} V{y+sy*20} H{x+sx*90}" fill="none" stroke="{GD}" stroke-opacity="0.45" stroke-width="2"/>')
m=140
bracket(m,m,1,1); bracket(W-m,m,-1,1); bracket(m,H-m,1,-1); bracket(W-m,H-m,-1,-1)
# side data bars
a(f'<g fill="{CY}" fill-opacity="0.28">')
for i in range(22):
    h=(math.sin(i*1.3)*0.5+0.5)*60+10
    a(f'<rect x="{m+40+i*22}" y="{H-m-40-h:.0f}" width="12" height="{h:.0f}"/>')
a('</g>')
a(f'<g stroke="{CY}" stroke-opacity="0.3" stroke-width="2">')
for i in range(12):
    w=(math.cos(i*0.9)*0.5+0.5)*260+80
    a(f'<line x1="{W-m-40}" y1="{m+60+i*16}" x2="{W-m-40-w:.0f}" y2="{m+60+i*16}"/>')
a('</g>')
a('</svg>')
open(sys.argv[1],"w").write("\n".join(out))
