#!/bin/zsh
set -euo pipefail
cd "${0:A:h}"
app="$PWD/Mouse Wiggler.app"
binary="$app/Contents/MacOS/MouseWiggler"
if [[ ! -x "$binary" || MouseMover.swift -nt "$binary" || Info.plist -nt "$app/Contents/Info.plist" || ! -f "$app/Contents/Resources/MouseMover.icns" || generate-icon.swift -nt "$app/Contents/Resources/MouseMover.icns" ]]; then
    ./build.sh
fi
open "$app"
