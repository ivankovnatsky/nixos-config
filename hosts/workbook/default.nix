{ config, lib, pkgs, options, ... }:

{
  imports = [
    ../../system/darwin.nix
    ../../system/homebrew.nix
    ../../system/packages.nix
    ../../system/packages-darwin.nix

    ../../modules/darwin/security/pam.nix
  ];

  homebrew.casks = [
    "aws-vpn-client"
  ];

  security.pam.enableSudoTouchIdAuth = true;
}
