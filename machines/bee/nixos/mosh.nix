{ ... }:
{
  # Enable mosh (mobile shell)
  programs.mosh.enable = true;

  # Open firewall ports for mosh (UDP 60000-61000)
  networking.firewall.allowedUDPPortRanges = [
    {
      from = 60000;
      to = 61000;
    }
  ];
}
