{ config, lib, pkgs, options, ... }:

{
  imports = [
    ../../system/darwin.nix
    ../../system/environment.nix
    ../../system/homebrew.nix
    ../../system/nix.nix
    ../../system/packages.nix
    ../../system/packages-darwin.nix

    ../../modules/darwin/security/pam.nix
  ];

  security.pam.enableSudoTouchIdAuth = true;
}