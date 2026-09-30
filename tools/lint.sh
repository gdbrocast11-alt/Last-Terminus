#!/bin/bash
# Parse-check all game scripts inside the full project so autoloads resolve.
cd "$(dirname "$0")/.."
godot --headless --path . --import > /tmp/godot_import.log 2>&1
timeout 300 godot --headless --path . res://tools/godot/builder.tscn -- lint 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "SCRIPT ERROR|Parse Error|Compile Error|   at: GDScript|LINT" | grep -v "Failed to compile depended"
