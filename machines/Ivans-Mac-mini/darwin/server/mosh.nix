{ pkgs, ... }:
{
  # Enable mosh (mobile shell)
  environment.systemPackages = with pkgs; [
    mosh
  ];

  # Note: macOS firewall configuration for mosh UDP ports (60000-61000)
  # is typically handled through:
  # 1. System Preferences > Security & Privacy > Firewall > Firewall Options
  # 2. Or using pfctl for advanced configuration
  #
  # If you have the firewall enabled and mosh doesn't work, you may need to:
  # - Allow incoming connections for mosh-server
  # - Or configure pfctl rules to allow UDP ports 60000-61000
}
