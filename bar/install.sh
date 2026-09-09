#!/bin/bash
# Install the JARVIS HUD bar on Omarchy.
#
#   ./install.sh              copy the modules into ~/.config/omarchy/bar/modules
#   ./install.sh --link       symlink them instead (edits in this repo apply live)
#   ./install.sh --no-layout  install the modules only; leave shell.json alone
#
# What it does:
#   1. puts the jarvis-*.qml bar modules in ~/.config/omarchy/bar/modules
#   2. edits ~/.config/omarchy/shell.json (backup kept next to it):
#      - left section:  reactor, HUD frame, bracketed workspaces, then
#        whatever else was there (minus the stock menu button)
#      - right section: bracketed telemetry, then whatever was there
#      - centre section and everything else untouched
#      - bar transparency off so the navy glass shows
#   The shell hot-reloads shell.json; no restart needed.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
MODULES="$HOME/.config/omarchy/bar/modules"
SHELL_JSON="$HOME/.config/omarchy/shell.json"
DEFAULTS="${OMARCHY_PATH:-/usr/share/omarchy}/config/omarchy/shell.json"
link=0; layout=1
for a in "$@"; do
  case $a in
    --link) link=1 ;;
    --no-layout) layout=0 ;;
    -h|--help) sed -n 2,17p "$0"; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 1 ;;
  esac
done

command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }
command -v omarchy >/dev/null || { echo "this installer is for Omarchy" >&2; exit 1; }

# 1. modules
mkdir -p "$MODULES"
for f in "$HERE"/modules/jarvis-*.qml; do
  name=$(basename "$f")
  if (( link )); then
    ln -sfn "$f" "$MODULES/$name"
  else
    install -m 644 "$f" "$MODULES/$name"
  fi
done
echo "installed bar modules in $MODULES"

(( layout )) || { echo "done (modules only)."; exit 0; }

# 2. layout
[[ -f $SHELL_JSON ]] || cp "$DEFAULTS" "$SHELL_JSON"
backup="$SHELL_JSON.bak.$(date +%s)"
cp "$SHELL_JSON" "$backup"
tmp=$(mktemp)
jq --slurpfile jarvis "$HERE/layout.json" '
  def entry_id: if type == "object" then (.id // "" | tostring) else tostring end;
  def is_jarvis: (entry_id | startswith("jarvis"));
  .version = (.version // 1)
  | .bar = (.bar // {})
  | .bar.transparent = false
  | .bar.layout = (.bar.layout // {})
  | .bar.layout.center = (.bar.layout.center // [])
  | .bar.layout.left = ($jarvis[0].left
      + ((.bar.layout.left // []) | map(select(is_jarvis | not))
          | map(select(entry_id != "omarchy.menu" and entry_id != "omarchy.workspaces"))))
  | .bar.layout.right = ($jarvis[0].right
      + ((.bar.layout.right // []) | map(select(is_jarvis | not))))
' "$SHELL_JSON" >"$tmp"
mv "$tmp" "$SHELL_JSON"
echo "updated $SHELL_JSON (backup: $backup)"
echo "done. The bar reloads on its own; if it does not, run: omarchy restart shell"
