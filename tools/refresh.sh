#!/bin/bash
# Re-import assets and refresh the global script class cache (needed after adding class_name scripts or assets).
cd "$(dirname "$0")/.."
godot --headless --path . --import > /tmp/godot_import.log 2>&1
grep -E "^(ERROR|SCRIPT ERROR)" /tmp/godot_import.log | head -20
