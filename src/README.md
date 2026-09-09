# JARVIS theme sources

Regenerate assets from here (needs python3, rsvg-convert, imagemagick):

    python3 gen_wall.py  /tmp/1.svg && rsvg-convert -w 3840 -h 2160 /tmp/1.svg -o ../backgrounds/1-arc-reactor.png
    python3 gen_wall2.py /tmp/2.svg && rsvg-convert -w 3840 -h 2160 /tmp/2.svg -o ../backgrounds/2-horizon.png
    rsvg-convert -w 800 -h 188 unlock.svg -o ../unlock.png
    magick ../backgrounds/1-arc-reactor.png -resize 1800x1012^ -gravity center -extent 1800x1012 ../preview.png

Then re-apply:  omarchy theme set jarvis

Fastfetch / About logo (two-colour braille, $1 rings, $2 core):

    python3 gen_fastfetch_logo.py ~/.config/omarchy/branding/about.txt 48 24

Colours are mapped in ~/.config/fastfetch/config.jsonc under logo.color.
