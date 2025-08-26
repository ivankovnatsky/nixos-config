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
      defaultCacheTtl = 86400; # 24 hours
      maxCacheTtl = 86400;
      extraConfig = ''
        allow-preset-passphrase
        pinentry-program ${pkgs.kwalletcli}/bin/pinentry-kwallet
      '';
    };
  };
}
