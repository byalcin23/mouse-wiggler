# Mouse Wiggler

A tiny, native macOS utility with a single ON/OFF button, a circular countdown, and a custom mint-colored cursor icon. No Python, Homebrew, or runtime dependencies required for the packaged app.

## Install

1. Download the latest **universal DMG** from [Releases](https://github.com/byalcin23/mouse-wiggler/releases/latest).
2. Open the DMG and drag **Mouse Wiggler** onto **Applications**.
3. Open Mouse Wiggler from Applications.
4. Allow **Mouse Wiggler** in **System Settings → Privacy & Security → Accessibility**. If it isn't listed, add the app with the **+** button. Press **ON** again after granting permission.

**Requirements:** macOS 14 Sonoma or later, Apple Silicon or Intel.

The release is ad-hoc signed, **not Apple Developer ID signed or notarized**. macOS may block an app downloaded from GitHub. Only if you trust this source, use the per-app **Open Anyway** option in **System Settings → Privacy & Security**, then confirm opening the app. Do not disable Gatekeeper globally. On managed Macs, your administrator may need to approve it.

A ZIP and SHA-256 checksums are also provided with each release. To check a downloaded package, run `shasum -a 256` on it and compare its hash with `SHA256SUMS.txt` from the same release.

## Use

- **ON:** keeps the display and Mac from automatically sleeping due to inactivity. Every 15 seconds, the cursor traces a quick, approximately 2-pixel-diameter circle and returns to its starting point.
- **OFF:** stops the countdown and movement, and releases the keep-awake assertion immediately.
- Closing the window quits the app and releases the assertion. The app always starts OFF.
- Movement is skipped while a mouse button is held. If the cursor moves more than 4 pixels from the expected position during a circle, the animation stops rather than pulling it back.

Keep-awake uses macOS IOKit power assertions, not only synthetic mouse input. It does not change persistent power settings, bypass a locked screen, override administrator security policies, or prevent sleep caused by closing the lid, choosing Sleep, or a low battery. Keeping the display awake increases battery usage.

The app makes no network requests, collects no analytics, and has no login item or background service. Accessibility permission is used only to move the cursor while enabled. Removing the app from Applications uninstalls it; you can also remove its Accessibility permission.

## Build from source

Install Apple's Xcode Command Line Tools (`xcode-select --install`), then:

```sh
./build.sh
open 'Mouse Wiggler.app'
```

Or double-click `start.command`; it builds the app when needed and opens it. The build produces a universal Apple Silicon + Intel app and ad-hoc signs it locally. Rebuilding may require regranting Accessibility permission.

To create the drag-to-Applications DMG, ZIP, and checksums:

```sh
./package.sh
```

Output is written to `dist/`. Build output and packages are excluded from Git; downloadable binaries are attached to GitHub Releases.

## References

- [Apple: Prevent user-idle display sleep](https://developer.apple.com/documentation/iokit/kiopmassertiontypepreventuseridledisplaysleep)
- [Apple: IOPMAssertionCreateWithName](https://developer.apple.com/documentation/iokit/1557134-iopmassertioncreatewithname)
- [Apple: App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [Apple: Progress indicators](https://developer.apple.com/design/human-interface-guidelines/progress-indicators)
