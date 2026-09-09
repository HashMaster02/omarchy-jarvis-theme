# JARVIS HUD bar

Custom modules for Omarchy's built-in status bar that turn it into a Stark
Industries HUD. They are plain QML bar modules, so every stock widget
(audio, network, bluetooth, power, clock, tray…) keeps working exactly as
before; the modules only add chrome around them.

![bar](../preview-bar.png)

| Module | What it does |
|---|---|
| `jarvis-reactor` | Animated arc reactor + `J.A.R.V.I.S` wordmark. Left click opens the Omarchy menu, right click a terminal. Replaces the stock menu button. |
| `jarvis-hud` | Zero-width module that draws the frame: cyan-to-gold edge line with glow, ruler ticks and a slow light sweep. |
| `jarvis-bracket` | Chamfered `⟨ ⟩` brackets; used in pairs (`side: open` / `close`) around the workspaces and the telemetry. |
| `jarvis-net` | Wi-Fi name, signal meter and ping (to 1.1.1.1 by default), or `WIRED` / `OFFLINE`. Ping turns gold from 80 ms and red from 200 ms. Left click opens Omarchy's network panel, right click refreshes. |
| `jarvis-stats` | CPU, memory and GPU load with segmented meters (cyan → gold at 70% → red at 90%); CPU temperature is available as a fourth readout (`temp`). Left click opens btop, right click refreshes. Reads `/proc` and sysfs only, so a sleeping discrete GPU stays asleep. |

The bar colours (navy glass background, gold "attention" colour, cyan hover
chrome, 30 px height) come from the theme itself via `shell.bar.toml` and
`shell.controls.toml`, which Omarchy merges into the shell's `shell.toml`
whenever the theme is applied. Those need no installer.

## Install

```bash
~/.config/omarchy/themes/jarvis/bar/install.sh          # copy modules
~/.config/omarchy/themes/jarvis/bar/install.sh --link   # symlink (edits apply live)
```

The installer copies the modules to `~/.config/omarchy/bar/modules/`, then
edits `~/.config/omarchy/shell.json` (a timestamped backup is left next to
it): the left section becomes reactor · frame · `⟨ workspaces ⟩` followed by
whatever else was there, the right section gets `⟨ uplink ⟩ ⟨ telemetry ⟩` in
front of your existing widgets, the centre section is untouched, and bar transparency
is switched off so the navy glass shows. The shell hot-reloads the file.

`--no-layout` installs the modules only, if you would rather place them
yourself:

```bash
omarchy bar put jarvis-reactor --section left --index 0   # ids are the file names
```

Custom modules are addressed by id, so the layout entries look like
`{ "id": "jarvis-stats", "type": "qml" }`. To use a module twice (the
brackets), give each entry its own id and point `source` at the file; see
`layout.json`.

## Settings

Every module reads its options from its `shell.json` entry, e.g.
`omarchy bar set jarvis-stats items '["cpu","mem"]' --json`. The options are
listed at the top of each `.qml` file. Highlights:

- `jarvis-stats`: `items` (any of `cpu`, `mem`, `gpu`, `temp`), `interval`
  seconds, `meters` on/off, `onClick`.
- `jarvis-net`: `host` to ping, `interval` seconds, `maxChars` before the
  network name is shortened, `showName`, `meters`, `onClick`.
- `jarvis-reactor`: `label` (set to `""` for the glyph alone), `onClick`,
  `onRightClick`, `tooltip`.
- `jarvis-hud`: `ticks`, `sweep`.
- All modules: `accent`, `gold` (and `warn` for the meters) to recolour.

## Uninstall

```bash
~/.config/omarchy/themes/jarvis/bar/uninstall.sh
```

Removes the JARVIS entries from `shell.json`, puts the stock menu button back
and deletes the modules. Transparency is left as it is; `omarchy bar
transparent toggle` flips it back.

## Notes

- Editing a module file is not picked up live (the bar caches custom
  modules); run `omarchy restart shell` after changes.
- Vertical bars: the reactor drops its wordmark, the telemetry shows values
  only, and the frame hides itself.
