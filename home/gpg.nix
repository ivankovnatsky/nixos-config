{ pkgs, lib, ... }:
let
  inherit (pkgs.stdenv.targetPlatform) isDarwin isLinux;
in
{
  programs = {
    gpg = {
      enable = true;
    };
  };

  services = lib.mkIf isLinux {
    gpg-agent = {
      enable = true;
      pinentry.package = pkgs.pinentry-tty;
      defaultCacheTtl = 43200;
      maxCacheTtl = 43200;
    };
  };

  home.file.".gnupg/gpg-agent.conf" = lib.mkIf isDarwin {
    text = ''
      default-cache-ttl 43200
      max-cache-ttl 43200
      pinentry-program ${pkgs.pinentry_mac}/bin/pinentry-mac
    '';
  };
}
