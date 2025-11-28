{ pkgs, ... }:
{
  programs = {
    gpg = {
      enable = true;
    };
  };

  services = {
    gpg-agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-tty;
      defaultCacheTtl = 86400;
      maxCacheTtl = 86400;
    };
  };
}
