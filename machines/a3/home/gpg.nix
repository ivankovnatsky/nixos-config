{ pkgs, ... }:
{
  programs = {
    # Configure GPG for KDE Wallet integration
    gpg = {
      enable = true;
    };
  };

  services = {
    # Configure GPG agent with Qt pinentry for KDE Wallet
    gpg-agent = {
      enable = true;
      pinentry.package = pkgs.pinentry-qt;
      enableSshSupport = true;
      defaultCacheTtl = 86400; # 24 hours
      maxCacheTtl = 86400;
    };
  };
}
