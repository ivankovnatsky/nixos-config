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
      "macmon"
      "grip"
      "typos-cli"
      "age"
      "aria2"
      "pre-commit"
      "rumdl"
      "git-delta"
      "dust"
      "ggh"
      "gitleaks"
      "gofumpt"
      "golangci-lint"
      "jq"
      "prettier"
      "node"
      "pigz"
      "poppler"
      "ruff"
      "rclone"
      "shellcheck"
      "shfmt"
      "sops"
      "stylua"
      "tree"
      "wget"
      "zoxide"
      "uv"
      "summarize"
      "bat"
      "btop"
      "duf"
      "erdtree"
      "exiftool"
      "fzf"
      "imagemagick"
      "magic-wormhole"
      "pandoc"
      "parallel"
      "pv"
      "ripgrep"
      "rust-analyzer"
      "swiftformat"
      "typst"
      "typstyle"
      "watchman"
      "forgit"
    ];
    casks = [
      "firefox@developer-edition"
      "mullvad-vpn"
      "bitwarden"
      "whatsapp"
      "hammerspoon"
      "kitty"
      "mac-mouse-fix"
      "obsidian"
      "silicon-labs-vcp-driver"
    ];
    masApps = {
      "Numbers" = 361304891;
    };
  };
}
