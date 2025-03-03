# Syncthing configuration for headless NixOS machine
{ config, lib, pkgs, ... }:

{
  # Enable the Syncthing service
  services.syncthing = {
    enable = true;

    # Run as a system service (not as a user)
    systemService = true;

    # Run as your user
    user = "ivan";
    group = "users";

    # Data directory
    dataDir = "/home/ivan/.config/syncthing";

    # Configure to listen on all interfaces (important for headless access)
    guiAddress = "0.0.0.0:8384";

    # Open the required ports in the firewall
    openDefaultPorts = true;

    # Configure settings (previously extraOptions)
    settings = {
      # GUI settings
      gui = {
        # No authentication for simplicity
        # You can access the web UI without credentials
        theme = "default";
        insecureAdminAccess = false;
      };

      # Global options
      options = {
        # Set global announce settings
        globalAnnounceEnabled = true;
        localAnnounceEnabled = true;
        # Relays for connecting when direct connection isn't possible
        relaysEnabled = true;
        # Don't report usage data
        urAccepted = -1;
      };

      # Devices and folders will be configured through the web UI
      # or can be added here if you know the device IDs in advance

      # Folder configuration will be managed through the web UI
      # This is more secure and allows for easier management
      folders = { };
      
      # Recommended folder setup (to be done through web UI):
      # - Folder ID: nixos-config
      # - Label: Sources/github.com/ivankovnatsky/nixos-config
      # - Path: /home/ivan/Sources/github.com/ivankovnatsky/nixos-config

      # Device configuration will be done through the web UI for security
      # This allows you to add devices without storing sensitive IDs in config files
      devices = { };
      
      # Note: After rebuilding, you'll need to add your MacBook device through
      # the Syncthing web UI at http://192.168.50.169:8384/
    };
  };
  
  # Open firewall ports for Syncthing
  # Note: These are redundant if openDefaultPorts = true, but included for clarity
  networking.firewall = {
    allowedTCPPorts = [ 8384 22000 ];  # 8384 for Web UI, 22000 for data transfer
    allowedUDPPorts = [ 22000 21027 ];  # 22000 for data transfer, 21027 for discovery
  };
  
  # Note: For security in a production environment, you might want to add authentication
  # You can do this by adding user/password to the gui settings:
  # settings.gui.user = "username";
  # settings.gui.password = "hashed-password";
}
