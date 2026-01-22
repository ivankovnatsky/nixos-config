{ pkgs, ... }:
{
  programs = {
    # Configure GPG for KDE Wallet integration
    gpg = {
      enable = true;
    };
  };

  services = {
    # Configure GPG agent with tty pinentry
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
      defaultCacheTtl = 86400; # 24 hours
      maxCacheTtl = 86400;
      pinentry.package = pkgs.pinentry-tty;
    };
  };
}
