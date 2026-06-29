{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "zap";
    };
    global.brewfile = true;
    brews = [
      "bitwarden-cli"
      # fish-from-nix on aarch64-darwin ships with invalid linker-signed
      # adhoc cdhash from cache.nixos.org → SIGKILL at exec. See
      # Notes/Configs/NixConfig/Issues/NixStoreExternalDiskDarwinFragility.md
      # Session 5. Use brew fish until upstream fix lands.
      "fish"
      # Since nix places it's new installs under newly generated nix store
      # path, we can't relay on nixpkgs pam-reattach, because after nixpkgs
      # upgrades PAM auth is broken for a common user. To fix it we need to
      # enable root user and edit /private/etc/pam.d/sudo to unblock auth.
      "pam-reattach"
      "mpv"
      "zapp"
      # Moved off the Nix store to relieve the internal /nix volume (M4 base):
      "macmon"
      "treefmt"
      "grip"
      "typos-cli"
    ];
    casks = [
      "whatsapp"
      "hammerspoon"
      "kitty"
      "mac-mouse-fix"
      "obsidian"
      "silicon-labs-vcp-driver"
      # Was nixpkgs-nixos-master-edge.antigravity-cli; cask auto-updates. Binary: agy
      "antigravity-cli"
    ];
    masApps = {
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "Bitwarden" = 1352778147;
    };
  };
}
