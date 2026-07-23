{ pkgs, lib, ... }:
let
  inherit (pkgs.stdenv.targetPlatform) isDarwin isLinux;
  ttl = 60 * 60 * 20;
in
{
  programs.gpg.enable = true;

  services = lib.mkIf isLinux {
    gpg-agent = {
      enable = true;
      pinentry.package = pkgs.pinentry-tty;
      defaultCacheTtl = ttl;
      maxCacheTtl = ttl;
    };
  };

  home.file.".gnupg/gpg-agent.conf" = lib.mkIf isDarwin {
    text = ''
      default-cache-ttl ${builtins.toString ttl}
      max-cache-ttl ${builtins.toString ttl}
      pinentry-program ${pkgs.pinentry-tty}/bin/pinentry-tty
    '';
  };

  targets.darwin.defaults."org.gpgtools.pinentry-mac" = {
    UseKeychain = false;
  };
}
