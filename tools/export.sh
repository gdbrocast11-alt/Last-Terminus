#!/bin/bash
# Export release builds: tools/export.sh [linux|windows|all]
cd "$(dirname "$0")/.."
what="${1:-all}"
godot --headless --path . --import > /tmp/export_import.log 2>&1
if [ "$what" = "linux" ] || [ "$what" = "all" ]; then
  mkdir -p builds/linux
  godot --headless --path . --export-release "Linux x86_64" builds/linux/LastTerminus.x86_64 2>&1 | tail -2
fi
if [ "$what" = "windows" ] || [ "$what" = "all" ]; then
  mkdir -p builds/windows
  godot --headless --path . --export-release "Windows x86_64" builds/windows/LastTerminus.exe 2>&1 | tail -2
fi
ls -la builds/*/
