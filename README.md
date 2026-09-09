# JARVIS — an Omarchy theme

Stark Industries HUD for [Omarchy](https://omarchy.org): deep navy glass,
arc-reactor cyan, hot-rod gold. Active window borders sweep from cyan to gold.

![JARVIS preview](preview.png)

## Install

```bash
omarchy-theme-install https://github.com/HashMaster02/omarchy-jarvis-theme.git
```

The installer clones this repo into `~/.config/omarchy/themes/jarvis` and
applies it. Switch back any time with `omarchy theme set <name>` or the
theme picker.

## What's included

- `colors.toml` — the palette Omarchy uses to build every terminal, editor,
  bar and notification theme
- `backgrounds/` — two 4K wallpapers: the arc reactor and a horizon glow
- `unlock.png` — lock-screen wordmark
- `icons.theme` — icon theme name (`Yaru-blue`)
- `keyboard.rgb` — keyboard backlight colour, for keyboards Omarchy can drive
- `shell.bar.toml`, `shell.controls.toml` — bar and control chrome colours
  for the Omarchy shell (navy glass bar, cyan hover glow, gold alerts)
- `bar/` — the JARVIS HUD bar modules and their installer (see below)
- `screensaver/` — the stats screensaver and its installer (see below)
- `src/` — generator scripts for every asset above, so the wallpapers and the
  fastfetch logo can be regenerated or tweaked (see `src/README.md`)

## HUD bar

Arc reactor, bracketed workspaces, a glowing edge line, Wi-Fi signal and
ping, and live CPU / MEM / GPU telemetry, on top of Omarchy's own bar so every stock widget keeps
working. Not applied by the theme installer; run:

```bash
~/.config/omarchy/themes/jarvis/bar/install.sh
```

See [`bar/README.md`](bar/README.md) for options and uninstall.

![bar](preview-bar.png)

## Screensaver

The theme also ships the JARVIS stats screensaver, an animated arc reactor
with live system telemetry. It is not applied by the theme installer; run:

```bash
~/.config/omarchy/themes/jarvis/screensaver/install.sh
```

See [`screensaver/README.md`](screensaver/README.md) for details and uninstall.

![screensaver](preview-screensaver.png)

## Updating

```bash
cd ~/.config/omarchy/themes/jarvis && git pull && omarchy theme set jarvis
```
