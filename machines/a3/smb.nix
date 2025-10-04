{ config, pkgs, ... }:
{
  imports = [
    ../../modules/secrets
  ];

  # SMB client configuration for a3 machine
  # This enables mounting SMB shares from bee machine

  # Enable CIFS support for mounting Windows/SMB shares
  boot.supportedFilesystems = [ "cifs" ];

  # Create SMB credential files from secrets
  environment.etc = {
    "nixos/smb-credentials-bee" = {
      text = ''
        username=${config.secrets.smb.bee.username}
        password=${config.secrets.smb.bee.password}
        domain=${config.secrets.smb.bee.domain}
      '';
      mode = "0600";
    };
  };

  # Install necessary packages for SMB client functionality
  environment.systemPackages = with pkgs; [
    cifs-utils # Tools for mounting CIFS/SMB shares
    samba # SMB client tools (smbclient, etc.)
  ];

  # Create mount points for SMB shares
  systemd.tmpfiles.rules = [
    "d /mnt/smb 0755 root root -" # Main SMB mount directory
    "d /mnt/smb/bee-storage 0755 root root -" # Bee storage share
  ];

  # Configure systemd mount units for automatic mounting
  systemd.mounts = [
    {
      description = "Mount bee storage SMB share";
      what = "//bee/storage";
      where = "/mnt/smb/bee-storage";
      type = "cifs";
      options = "credentials=/etc/nixos/smb-credentials-bee,uid=1000,gid=100,iocharset=utf8,file_mode=0644,dir_mode=0755,vers=3.0,ip=${config.flags.beeIp}";
      wantedBy = [ "multi-user.target" ];
    }
  ];

  # Configure systemd automount units for on-demand mounting
  systemd.automounts = [
    {
      description = "Automount bee storage SMB share";
      where = "/mnt/smb/bee-storage";
      wantedBy = [ "multi-user.target" ];
    }
  ];

  # Note: mDNS/.local hostname resolution is configured in networking.nix

  # Network configuration for SMB
  networking.firewall = {
    # Allow outbound SMB/CIFS connections
    allowedTCPPorts = [
      139 # NetBIOS Session Service
      445 # SMB over TCP
    ];
    allowedUDPPorts = [
      137 # NetBIOS Name Service
      138 # NetBIOS Datagram Service
    ];
  };

  # SMB credentials are automatically configured from secrets module
}
