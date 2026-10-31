#!/bin/bash
# Rebuilds the script class cache through the editor and prints each script error once, with its line.
cd "$(dirname "$0")/.."
timeout 150 godot --headless --path . --editor --quit > /tmp/claude-0/imp.log 2>&1
grep -A1 "SCRIPT ERROR" /tmp/claude-0/imp.log | grep -v "^--" | paste - - | grep -v "Compile Error: \s*at" | sort -u | sed 's/SCRIPT ERROR: //; s/\s*at: GDScript::reload (res:\/\// @ /' | head -40
