#!/bin/bash
# Parses every script and prints the errors with their file and line. Run from infall-godot/.
cd "$(dirname "$0")/.."
for f in $(find scripts tools -name "*.gd" | sort); do
  out=$(timeout 30 godot --headless --path . --check-only --script "res://$f" 2>&1 | grep -E "SCRIPT ERROR|ERROR:|at: " | grep -v "Failed to load script" | grep -v "Identifier not found: Library" | grep -v "Identifier not found: Settings" | grep -v "Identifier not found: Sfx")
  if [ -n "$out" ]; then echo "== $f"; echo "$out" | head -12; fi
done
