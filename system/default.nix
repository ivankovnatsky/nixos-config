{ config, pkgs, ... }:

{
  imports = [
    ../modules/flags
  ];

  documentation = {
    enable = false;
    man.enable = false;
    info.enable = false;
  };

  nixpkgs.config.allowUnfree = true;

  nix = {
    extraOptions = ''
      auto-optimise-store = true
      keep-outputs = true
      keep-derivations = true
      experimental-features = nix-command flakes
      warn-dirty = false
      accept-flake-config = true
    '';
  };

  # error:
  #      Failed assertions:
  #      - users.users.ivan.shell is set to zsh, but
  #      programs.zsh.enable is not true. This will cause the zsh
  #      shell to lack the basic nix directories in its PATH and might make
  #      logging in as that user impossible. You can fix it with:
  #      programs.zsh.enable = true;
  programs.zsh.enable = true;
  programs.fish.enable = config.flags.enableFishShell;
}
