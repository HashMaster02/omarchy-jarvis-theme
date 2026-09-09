import math, sys
W,H=3840,2160; CY="#00d8ff"; GD="#ffc857"
o=[]; a=o.append
a(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">')
a('''<defs>
 <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0b1521"/><stop offset="1" stop-color="#040a12"/></linearGradient>
 <radialGradient id="hz" cx="50%" cy="100%" r="70%"><stop offset="0" stop-color="#00d8ff" stop-opacity="0.22"/><stop offset="1" stop-color="#00d8ff" stop-opacity="0"/></radialGradient>
 <filter id="glow" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="5"/></filter>
</defs>''')
a(f'<rect width="{W}" height="{H}" fill="url(#bg)"/>')
a(f'<rect width="{W}" height="{H}" fill="url(#hz)"/>')
# perspective floor grid
hy=H*0.62; vx=W/2
a(f'<g stroke="{CY}" stroke-opacity="0.16" stroke-width="1.5">')
for i in range(-40,41):
    x=vx+i*W/12
    a(f'<line x1="{vx}" y1="{hy}" x2="{x:.0f}" y2="{H}"/>')
y=hy
for k in range(1,40):
    y=hy+(H-hy)*(1-1/(1+k*0.18))
    a(f'<line x1="0" y1="{y:.0f}" x2="{W}" y2="{y:.0f}"/>')
a('</g>')
a(f'<line x1="0" y1="{hy}" x2="{W}" y2="{hy}" stroke="{CY}" stroke-opacity="0.7" stroke-width="3" filter="url(#glow)"/>')
a(f'<line x1="0" y1="{hy}" x2="{W}" y2="{hy}" stroke="#e6f7ff" stroke-opacity="0.9" stroke-width="1.5"/>')
# small sun / reactor on horizon
a(f'<circle cx="{vx}" cy="{hy}" r="120" fill="{CY}" fill-opacity="0.18" filter="url(#glow)"/>')
a(f'<circle cx="{vx}" cy="{hy}" r="40" fill="#e6f7ff" fill-opacity="0.9"/>')
# sky arcs
for r,op,c in ((520,0.25,CY),(700,0.15,CY),(900,0.10,CY),(610,0.35,GD)):
    x0=vx-r; x1=vx+r
    a(f'<path d="M{x0} {hy} A{r} {r} 0 0 1 {x1} {hy}" fill="none" stroke="{c}" stroke-opacity="{op}" stroke-width="2" stroke-dasharray="{"30 22" if c==GD else "none"}"/>')
# ticks along horizon
a(f'<g stroke="{CY}" stroke-opacity="0.45" stroke-width="2">')
for i in range(0,W,60):
    l=26 if (i//60)%5==0 else 10
    a(f'<line x1="{i}" y1="{hy-l}" x2="{i}" y2="{hy}"/>')
a('</g>')
# corner brackets
def br(x,y,sx,sy):
    a(f'<path d="M{x} {y+sy*140} V{y} H{x+sx*140}" fill="none" stroke="{CY}" stroke-opacity="0.5" stroke-width="3"/>')
m=140; br(m,m,1,1); br(W-m,m,-1,1); br(m,H-m,1,-1); br(W-m,H-m,-1,-1)
a('</svg>')
open(sys.argv[1],"w").write("\n".join(o))
