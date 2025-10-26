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
    guiAddress = "${config.flags.beeIp}:8384";

    # Open the required ports in the firewall
    openDefaultPorts = true;

    # IMPORTANT: These control whether NixOS will override your manual configurations
    # overrideDevices = true;  # Set to true if you want to manage devices in this file
    # overrideFolders = true;  # Set to true if you want to manage folders in this file

    # Configure settings
    settings = {
      # GUI settings
      # Note: credentials are managed by syncthing-mgmt service (see syncthing-mgmt.nix)
      gui = {
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

      # Devices are managed by syncthing-mgmt service (see syncthing-mgmt.nix)
      # overrideDevices defaults to false, so NixOS won't override API-managed devices
      devices = {};

      # Folders are managed via Syncthing UI
      # overrideFolders defaults to false, so NixOS won't override manually configured folders
      folders = {};
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
    # nixos-config moved to home directory - create structure there with correct ownership
    "d /home/ivan/Sources 0755 ivan users - -"
    "d /home/ivan/Sources/github.com 0755 ivan users - -"
    "d /home/ivan/Sources/github.com/ivankovnatsky 0755 ivan users - -"
  ];

  # ```
  #   Filesystem Watcher Errors
  # For the following folders an error occurred while starting to watch for
  # changes. It will be retried every minute, so the errors might go away soon.
  # If they persist, try to fix the underlying issue and ask for help if you
  # can't.  Support
  #
  # Sources	failed to setup inotify handler. Please increase inotify limits,
  # see https://docs.syncthing.net/users/faq.html#inotify-limits
  # Sources/github.com/NixOS/nixpkgs	failed to setup inotify handler. Please
  # increase inotify limits, see
  # https://docs.syncthing.net/users/faq.html#inotify-limits
  # ```

  # This increases inotify watch limits for Syncthing
  # Reference: https://docs.syncthing.net/users/faq.html#inotify-limits
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 204800; # Default: 8192
    "fs.inotify.max_user_instances" = 512; # Default: 128
    "fs.inotify.max_queued_events" = 32768; # Default: 16384
  };
}
