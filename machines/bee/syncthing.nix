{ config, ... }:
{
  # Enable the Syncthing service
  #
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
    guiAddress = "0.0.0.0:8384";

    # Open the required ports in the firewall
    openDefaultPorts = true;

    # IMPORTANT: These control whether NixOS will override your manual configurations
    # overrideDevices = true;  # Set to true if you want to manage devices in this file
    # overrideFolders = true;  # Set to true if you want to manage folders in this file

    # Configure settings
    settings = {
      # GUI settings
      gui = {
        theme = "default";
        insecureAdminAccess = false;
        insecureSkipHostcheck = false;
        insecureAllowFrameLoading = false;

        user = config.secrets.syncthingCredentials.username;
        password = config.secrets.syncthingCredentials.hashedPassword;
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
        "Lusha-Macbook-Ivan-Kovnatskyi" = { 
          id = config.secrets.syncthing.devices.LushaMacbookIvanKovnatskyi;
        };
        "Ivans-Mac-mini" = {
          id = config.secrets.syncthing.devices.IvansMacMini;
        };
        "Ivans-MacBook-Air" = {
          id = config.secrets.syncthing.devices.IvansMacBookAir;
        };
        "Ivans-MacBook-Pro" = {
          id = config.secrets.syncthing.devices.IvansMacBookPro;
        };
        "Ally" = {
          id = "ZIM6RNR-RYUHZQE-L5KJUAT-BF7MAJ4-NSIZIIY-USMGRTU-YHT4T5M-KZX6DQE";
        };
      };

      # Define your folders here
      folders = {
        "Sources/github.com/ivankovnatsky/nixos-config" = {
          id = "shtdy-s2c9s";
          label = "Sources/github.com/ivankovnatsky/nixos-config";
          path = "/storage/Sources/github.com/ivankovnatsky/nixos-config";
          devices = [
            "Ivans-Mac-mini"
            "Ivans-MacBook-Air"
            "Ivans-MacBook-Pro"
            "Lusha-Macbook-Ivan-Kovnatskyi"
          ];
        };
        "Sources/github.com/ivankovnatsky/deck" = {
          id = "tgrp6-ccmmf";
          label = "Sources/github.com/ivankovnatsky/deck";
          path = "/storage/Sources/github.com/ivankovnatsky/deck";
          devices = [
            "Ivans-Mac-mini"
            "Ivans-MacBook-Air"
            "Ivans-MacBook-Pro"
          ];
        };
        "Sources/github.com/ivankovnatsky/windows-config" = {
          id = "jumpj-dcicb";
          label = "Sources/github.com/ivankovnatsky/windows-config";
          path = "/storage/Sources/github.com/ivankovnatsky/windows-config";
          devices = [
            "Ivans-Mac-mini"
            "Ivans-MacBook-Air"
            "Ivans-MacBook-Pro"
          ];
        };
        "Sources/github.com/NixOS/nixpkgs" = {
          id = "kwhyl-jbqmu";
          label = "Sources/github.com/NixOS/nixpkgs";
          path = "/storage/Sources/github.com/NixOS/nixpkgs";
          devices = [
            "Ivans-Mac-mini"
            "Ivans-MacBook-Air"
            "Ivans-MacBook-Pro"
            "Lusha-Macbook-Ivan-Kovnatskyi"
          ];
        };
        "Sources" = {
          id = "fpbxa-6zw5z";
          label = "Sources";
          path = "/storage/Sources";
          devices = [
            "Ivans-Mac-mini"
            "Ivans-MacBook-Air"
            "Ivans-MacBook-Pro"
          ];
        };
        "Data" = {
          id = "data";
          label = "Data";
          path = "/storage/Data";
          devices = [
            "Ivans-Mac-mini"
          ];
        };
        "Sources/github.com/ivankovnatsky/backup-home-go" = {
          id = "ek7as-rhzzz";
          label = "Sources/github.com/ivankovnatsky/backup-home-go";
          path = "/storage/Sources/github.com/ivankovnatsky/backup-home-go";
          devices = [
            "Ivans-Mac-mini"
            "Ivans-MacBook-Air"
            "Ivans-MacBook-Pro"
            "Lusha-Macbook-Ivan-Kovnatskyi"
          ];
        };
        "Sources/github.com/narugit/smctemp" = {
          id = "smctemp";
          label = "Sources/github.com/narugit/smctemp";
          path = "/storage/Sources/github.com/narugit/smctemp";
          devices = [
            "Ivans-Mac-mini"
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

  # Add explicit systemd dependencies to ensure Syncthing starts after network is up
  systemd.services.syncthing = {
    after = [
      "network-online.target"
      "systemd-tmpfiles-setup.service"
    ];
    wants = [ "network-online.target" ];
    requires = [ "systemd-tmpfiles-setup.service" ];
  };

  # Use systemd-tmpfiles to ensure directories exist with proper permissions
  systemd.tmpfiles.rules = [
    # Create subdirectories mentioned in Syncthing config
    "d /storage/Sources/github.com 0755 ivan users - -"
    "d /storage/Sources/github.com/ivankovnatsky 0755 ivan users - -"
    "d /storage/Sources/github.com/ivankovnatsky/nixos-config 0755 ivan users - -"
    "d /storage/Sources/github.com/ivankovnatsky/deck 0755 ivan users - -"
    "d /storage/Sources/github.com/ivankovnatsky/windows-config 0755 ivan users - -"
    "d /storage/Sources/github.com/ivankovnatsky/backup-home-go 0755 ivan users - -"

    "d /storage/Sources/github.com/NixOS/nixpkgs 0755 ivan users - -"

    # Create /storage/Sources if it doesn't exist and ensure correct permissions
    "d /storage/Sources 0700 ivan users - -"

    # Create /storage/Data if it doesn't exist and ensure correct permissions
    "d /storage/Data 0700 ivan users - -"
  ];
}
