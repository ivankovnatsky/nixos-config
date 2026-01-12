# MacBook Pro Setup

## Xcode License Agreement

During `darwin-rebuild switch` on a fresh MacBook Pro installation, Homebrew may
fail with Xcode license errors:

```console
Error: You have not agreed to the Xcode license. Please resolve this by running:
  sudo xcodebuild -license accept
```

**Resolution:**

```console
sudo xcodebuild -license accept
```

After accepting the license, re-run `darwin-rebuild switch` to complete the
system configuration.

## Xcode Component Selection

When installing Xcode (version 26.0.1 or later), select the following
components:

**Platform Support:**

- ✅ macOS 26.0 (Built-in)
- ✅ iOS 26.0 (10.07 GB)
- ⬜ watchOS 26.0 (not needed, saves 3.83 GB)
- ⬜ tvOS 26.0 (not needed, saves 3.62 GB)
- ⬜ visionOS 26.0 (not needed, saves 6.98 GB)

**Other Components:**

- ✅ Predictive Code Completion Model (2 GB)

This setup includes iOS development support while still saving approximately
14.4 GB by skipping watchOS, tvOS, and visionOS platforms.

## Xcode Notifications

Enable notifications when Xcode requests permission during initial launch.
