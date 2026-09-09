#!/bin/bash
# Remove the JARVIS screensaver and restore Omarchy's stock one.
set -euo pipefail
BIN="$HOME/.local/bin"
MENU="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
CLONE_ID="${USER:-$(id -un)}.idle"

if omarchy plugin list 2>/dev/null | grep -q "^$CLONE_ID "; then
  omarchy plugin remove "$CLONE_ID" --yes
  omarchy plugin enable omarchy.idle
fi
rm -f "$BIN/jarvis-screensaver" "$BIN/jarvis-launch-screensaver"
if [[ -f $MENU ]]; then
  sed -i '/JARVIS: route the Screensaver entry/d; /jarvis-launch-screensaver/d; /jarvis-screensaver"/d' "$MENU"
fi
omarchy restart shell
echo "JARVIS screensaver removed; stock screensaver restored."
