#!/bin/bash
# Install the JARVIS stats screensaver on Omarchy.
#
#   ./install.sh              copy the scripts into ~/.local/bin
#   ./install.sh --link       symlink them instead (edits in this repo apply live)
#   ./install.sh --no-restart skip the shell restart at the end
#
# What it does:
#   1. puts jarvis-screensaver and jarvis-launch-screensaver in ~/.local/bin
#   2. clones Omarchy's built-in idle plugin (omarchy plugin clone omarchy.idle)
#      and points its screensaver hook at the JARVIS launcher
#   3. routes the Screensaver menu entry to JARVIS
#   4. restarts the Omarchy shell so the idle service picks up the change
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BIN="$HOME/.local/bin"
PLUGINS="$HOME/.config/omarchy/plugins"
MENU="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
CLONE_ID="${USER:-$(id -un)}.idle"
link=0; restart=1
for a in "$@"; do
  case $a in
    --link) link=1 ;;
    --no-restart) restart=0 ;;
    -h|--help) sed -n 2,15p "$0"; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 1 ;;
  esac
done

command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }
command -v omarchy >/dev/null || { echo "this installer is for Omarchy" >&2; exit 1; }
command -v sensors >/dev/null || echo "note: lm_sensors not found; temperatures will be blank (sudo pacman -S lm_sensors)"

# 1. scripts
mkdir -p "$BIN"
for f in jarvis-screensaver jarvis-launch-screensaver; do
  if (( link )); then
    ln -sfn "$HERE/$f" "$BIN/$f"
  else
    install -m 755 "$HERE/$f" "$BIN/$f"
  fi
done
echo "installed $BIN/jarvis-screensaver and $BIN/jarvis-launch-screensaver"

# 2. idle plugin clone, patched to launch JARVIS
if [[ ! -d $PLUGINS/$CLONE_ID ]]; then
  omarchy plugin clone omarchy.idle
fi
qml="$PLUGINS/$CLONE_ID/Service.qml"
[[ -f $qml ]] || { echo "expected $qml after cloning omarchy.idle" >&2; exit 1; }
if grep -q 'jarvis-launch-screensaver' "$qml"; then
  echo "idle plugin $CLONE_ID already points at JARVIS"
else
  sed -i 's#|| omarchy-launch-screensaver"#|| \\"$HOME/.local/bin/jarvis-launch-screensaver\\""#' "$qml"
  grep -q 'jarvis-launch-screensaver' "$qml" || { echo "could not patch $qml; edit the screensaver line by hand" >&2; exit 1; }
  echo "patched $qml"
fi

# 3. menu entries
entries='  // JARVIS: route the Screensaver entry to the stats screensaver.
  "system.screensaver": {"icon":"󱄄","label":"Screensaver","action":"$HOME/.local/bin/jarvis-launch-screensaver force"},
  "style.screensaver.jarvis": {"icon":"","label":"Edit JARVIS Screensaver","action":"omarchy-launch-editor $HOME/.local/bin/jarvis-screensaver"},'
mkdir -p "$(dirname "$MENU")"
if [[ ! -f $MENU ]]; then
  printf '{\n%s\n}\n' "$entries" > "$MENU"
  echo "created $MENU"
elif grep -q 'jarvis-launch-screensaver' "$MENU"; then
  echo "menu entries already present"
else
  # insert before the closing brace of the top-level object
  python3 - "$MENU" "$entries" <<'PY'
import sys
path, entries = sys.argv[1], sys.argv[2]
s = open(path).read()
i = s.rstrip().rfind("}")
open(path, "w").write(s[:i].rstrip("\n") + "\n\n" + entries + "\n" + s[i:])
PY
  echo "added menu entries to $MENU"
fi

# 4. reload
if (( restart )); then
  omarchy restart shell
  echo "done. Try it now:  jarvis-launch-screensaver force"
else
  echo "done. Run 'omarchy restart shell' to activate the idle hook."
fi
