# Terminal Emulators

## Terminal.app

- Native macOS terminal
- Excellent session restoration after reboot
- Preserves your working context automatically

## kitty

- Subjectively still faster than Ghostty
- Minimalist UI with tabs rendered as a single unified line
- Feels like a pure terminal without extra window decorations
- Supports desktop notifications

## Ghostty

Pros:

- macOS-leaning UI
- Very fast Quake-style terminal
- Supports desktop notifications

Cons:

- Crashes during lid open events; tabs/windows resume but with completely clean
  state (no session history), unlike Terminal.app which preserves session text
  after crashes or reboots (disabled on macOS)
