#!/bin/zsh
set -euo pipefail
cd "${0:A:h}"
./build.sh
version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Info.plist)
staging=$(mktemp -d "${TMPDIR:-/tmp/}mouse-wiggler.XXXXXX")
trap 'rm -rf "$staging"' EXIT
mkdir -p dist
ditto 'Mouse Wiggler.app' "$staging/Mouse Wiggler.app"
ln -s /Applications "$staging/Applications"
hdiutil create -volname 'Mouse Wiggler' -srcfolder "$staging" -ov -format UDZO \
    "dist/Mouse-Wiggler-$version-universal.dmg"
ditto -c -k --sequesterRsrc --keepParent 'Mouse Wiggler.app' \
    "dist/Mouse-Wiggler-$version-universal.zip"
(cd dist && shasum -a 256 "Mouse-Wiggler-$version-universal.dmg" \
    "Mouse-Wiggler-$version-universal.zip" > SHA256SUMS.txt)
echo "Packages are ready in $PWD/dist"
