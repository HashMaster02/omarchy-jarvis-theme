#!/bin/bash
# Remove the JARVIS HUD bar: drops the jarvis-* entries from shell.json,
# puts the stock Omarchy menu button back, and deletes the modules.
# Bar transparency is left as it is; toggle it with: omarchy bar transparent toggle
set -euo pipefail

MODULES="$HOME/.config/omarchy/bar/modules"
SHELL_JSON="$HOME/.config/omarchy/shell.json"

command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }

if [[ -f $SHELL_JSON ]]; then
  tmp=$(mktemp)
  jq '
    def entry_id: if type == "object" then (.id // "" | tostring) else tostring end;
    def strip: map(select(entry_id | startswith("jarvis") | not));
    .bar.layout.left = ((.bar.layout.left // []) | strip)
    | .bar.layout.center = ((.bar.layout.center // []) | strip)
    | .bar.layout.right = ((.bar.layout.right // []) | strip)
    | if ([.bar.layout[][] | entry_id] | index("omarchy.menu")) == null
      then .bar.layout.left = ([{id: "omarchy.menu"}] + .bar.layout.left) else . end
  ' "$SHELL_JSON" >"$tmp"
  mv "$tmp" "$SHELL_JSON"
  echo "removed JARVIS entries from $SHELL_JSON"
fi

rm -f "$MODULES"/jarvis-*.qml
echo "removed modules from $MODULES"
echo "done."
