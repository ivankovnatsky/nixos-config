{ config, lib, pkgs, ... }:

with lib;

let
  # Check if any home-manager user has local.tools enabled
  anyToolsEnabled =
    config.home-manager ? users
    && any (u: u.local.tools.enable or false) (attrValues config.home-manager.users);
in
{
  config = mkIf anyToolsEnabled {
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      fuse3
      icu
      nss
      openssl
      curl
      expat
      nodejs
    ];
  };
}
