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
      pinentry.package = pkgs.pinentry-tty;
      defaultCacheTtl = 259200;
      maxCacheTtl = 259200;
    };
  };
}
