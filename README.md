# Squeeky Clean Mac

A tiny native macOS utility that locks your keyboard, mouse, trackpad, clicks, gestures, and scrolling while you clean your Mac.

When cleaning mode is active, hold both Command keys together for 3 seconds to unlock.

## Download

Download the latest `Squeeky-Clean-Mac.zip` from the GitHub Releases page, unzip it, then move `Squeeky Clean Mac.app` to `/Applications`.

Because the app is not notarized yet, macOS may block the first launch. Open it with:

1. Right-click `Squeeky Clean Mac.app`.
2. Choose `Open`.
3. Confirm `Open` in the macOS dialog.

The app will ask for Privacy & Security permissions the first time you start cleaning mode.

## Permissions

Squeeky Clean Mac uses macOS-native input APIs:

- Input Monitoring lets the app observe keyboard, mouse, trackpad, and scroll events.
- Accessibility lets the app filter those events while cleaning mode is active.

Accessibility is required before cleaning mode can start. Input Monitoring is still requested and shown in the app, but macOS can report it late for debug builds, so the app treats it as advisory after Accessibility is granted.

If you enabled permissions while running from Xcode and the app still looks stale, quit the running app and launch it again. macOS applies Privacy & Security changes to the signed app instance, and a restart is often needed.

The app is intentionally not sandboxed. A real global input lock is not compatible with the standard app sandbox.

## Build From Source

Requirements:

- macOS 26.3 or newer
- Xcode 26.5 or newer

Build:

```sh
xcodebuild -project SqueekyCleanMac.xcodeproj -scheme SqueekyCleanMac -configuration Debug build
```

Create a downloadable release zip:

```sh
Scripts/package_release.sh
```

The script prints the generated zip path.

## GitHub Release Flow

Every push to `main` runs the GitHub Actions workflow, builds a release zip, and publishes it to the GitHub Releases page automatically.

Release tags use this format:

```text
main-<github-run-number>-<short-commit-sha>
```

Users can download `Squeeky-Clean-Mac.zip` from the latest release, unzip it, move the app to `/Applications`, then right-click and open it once.

## License

MIT
