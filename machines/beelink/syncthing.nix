{
  # Enable the Syncthing service
  services.syncthing = {
    enable = true;

    # Run as a system service (not as a user)
    systemService = true;

    # Run as your user
    user = "ivan";
    group = "users";

    # Data directory - this is where synchronized files will be stored
    dataDir = "/home/ivan";

    # Config directory - this is where configuration is persisted
    configDir = "/home/ivan/.config/syncthing";

    # Configure to listen on local network (needed for headless access)
    guiAddress = "192.168.50.169:8384";

    # Open the required ports in the firewall
    openDefaultPorts = true;

    # IMPORTANT: These control whether NixOS will override your manual configurations
    # overrideDevices = true;  # Set to true if you want to manage devices in this file
    # overrideFolders = true;  # Set to true if you want to manage folders in this file

    # Configure settings
    settings = {
      # GUI settings
      gui = {
        # No authentication for simplicity
        # You can access the web UI without credentials
        theme = "default";
        insecureAdminAccess = false;
        insecureSkipHostcheck = false;
        insecureAllowFrameLoading = false;
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

      # Define your devices here
      devices = {
        "Ivans-MacBook-Air" = {
          id = "5MIKWQG-5SHSMR4-ZHROMA3-TGV222E-JAJ35VZ-2INPU7I-W34IVQ3-WIYLUQM";
        };
        "Ivans-MacBook-Pro" = {
          id = "UEZFRWE-UX5HT7X-OEL7HRC-ZQT6MJL-UHXIQVX-Z5B4IZO-EHQCZ22-FA2RNAI";
        };
        "Lusha-Macbook-Ivan-Kovnatskyi" = {
          id = "3CKXPYL-MWZLPKJ-NMKQOLS-HX4EOYE-765MZ2W-3U3WGTU-FKGHNAD-OGAN4QL";
        };
      };

      # Define your folders here
      folders = {
        "Sources/github.com/ivankovnatsky/nixos-config" = {
          id = "shtdy-s2c9s";
          label = "Sources/github.com/ivankovnatsky/nixos-config";
          path = "/home/ivan/Sources/github.com/ivankovnatsky/nixos-config";
          devices = [
            "Ivans-MacBook-Air"
            "Ivans-MacBook-Pro"
            "Lusha-Macbook-Ivan-Kovnatskyi"
          ];
        };
      };
    };
  };

  # Open firewall ports for Syncthing
  # Note: These are redundant if openDefaultPorts = true, but included for clarity
  networking.firewall = {
    allowedTCPPorts = [
      8384
      22000
    ]; # 8384 for Web UI, 22000 for data transfer
    allowedUDPPorts = [
      22000
      21027
    ]; # 22000 for data transfer, 21027 for discovery
  };

  # Note: For security in a production environment, you might want to add authentication
  # You can do this by adding user/password to the gui settings:
  # settings.gui.user = "username";
  # settings.gui.password = "hashed-password";
}
