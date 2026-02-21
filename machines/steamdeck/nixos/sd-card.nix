# SD card automounting is handled by Jovian's steamos-automount via udisks2
# (enabled by jovian.steamos.useSteamOSConfig = true in jovian.nix).
# Do not add fstab entries — they conflict with the automounter and mount
# as root, which prevents Steam from detecting the SD card.
{ }
