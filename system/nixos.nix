{ pkgs, ... }:

{
  imports = [
    ./packages.nix
  ];

  security = {
    rtkit.enable = true;
    sudo.configFile = ''
      Defaults timestamp_timeout=240
    '';
  };

  users.users.ivan = {
    description = "Ivan Kovnatsky";
    isNormalUser = true;
    home = "/home/ivan";
    shell = pkgs.fish;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
  };

  virtualisation = {
    docker = {
      enable = true;
      enableOnBoot = false;
    };
  };

  # https://github.com/luishfonseca/dotfiles/blob/main/modules/upgrade-diff.nix
  # This only works on NixOS, did not investigate darwin, but let it lie here
  # for now.
  system.activationScripts.diff = {
    supportsDryActivation = true;
    text = ''
      ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff /run/current-system "$systemConfig"
    '';
  };
}
