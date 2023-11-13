{ pkgs, ... }:

let fishEnable = true;
in
{
  imports = [
    ../modules/default.nix
  ];

  documentation = {
    enable = false;
    man.enable = false;
    info.enable = false;
  };

  nixpkgs.config.allowUnfree = true;

  nix = {
    package = pkgs.nixUnstable;

    extraOptions = ''
      auto-optimise-store = true
      keep-outputs = true
      keep-derivations = true
      experimental-features = nix-command flakes
    '';
  };

  # https://github.com/luishfonseca/dotfiles/blob/main/modules/upgrade-diff.nix
  system.activationScripts.diff = {
    supportsDryActivation = true;
    text = ''
      ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff /run/current-system "$systemConfig"
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
  programs.fish.enable = fishEnable;
}
