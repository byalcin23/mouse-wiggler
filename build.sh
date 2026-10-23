#!/bin/zsh
set -euo pipefail
cd "${0:A:h}"
app="$PWD/Mouse Wiggler.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources" .build
for architecture in arm64 x86_64; do
    xcrun swiftc -O -target "$architecture-apple-macos14.0" MouseMover.swift \
        -o ".build/MouseWiggler-$architecture" \
        -framework AppKit -framework ApplicationServices -framework IOKit
done
lipo -create .build/MouseWiggler-arm64 .build/MouseWiggler-x86_64 \
    -output "$app/Contents/MacOS/MouseWiggler"
xcrun swift generate-icon.swift .build/MouseMover.iconset
iconutil -c icns .build/MouseMover.iconset -o "$app/Contents/Resources/MouseMover.icns"
cp Info.plist "$app/Contents/Info.plist"
chmod -R a+rX "$app"
codesign --force --sign - "$app"
codesign --verify --deep --strict "$app"
echo "Built $app (Apple Silicon + Intel)"
