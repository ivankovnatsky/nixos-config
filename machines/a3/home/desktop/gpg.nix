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
      enableSshSupport = true;
      defaultCacheTtl = 60 * 60 * 12; # 12 hours
      maxCacheTtl = 60 * 60 * 12;
      extraConfig = ''
        allow-preset-passphrase
        no-allow-external-cache
        pinentry-program ${pkgs.pinentry-qt}/bin/pinentry-qt
      '';
    };
  };
}
