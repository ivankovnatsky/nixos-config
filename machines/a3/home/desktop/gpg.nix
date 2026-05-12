{ pkgs, ... }:
{
  programs = {
    # Configure GPG for KDE Wallet integration
    gpg = {
      enable = true;
    };
  };

  services = {
    # Configure GPG agent with kwallet pinentry for KDE Wallet integration
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
      defaultCacheTtl = 60 * 60 * 12; # 12 hours
      maxCacheTtl = 60 * 60 * 12;
      extraConfig = ''
        allow-preset-passphrase
        no-allow-external-cache
        pinentry-program ${pkgs.kwalletcli}/bin/pinentry-kwallet
      '';
    };
  };
}
