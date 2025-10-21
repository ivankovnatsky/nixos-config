{ config, pkgs, ... }:
{
  # SMB client configuration for a3 machine
  # This enables mounting SMB shares from mini (Ivans-Mac-mini) machine
  #
  # Uses macOS built-in File Sharing:
  # - Standard SMB port 445
  # - Share: //ivans-mac-mini.local/Storage
  # - Authenticated with 'samba' sharing-only user

  # Enable CIFS support for mounting Windows/SMB shares
  boot.supportedFilesystems = [ "cifs" ];

  # Install necessary packages for SMB client functionality
  environment.systemPackages = with pkgs; [
    cifs-utils # Tools for mounting CIFS/SMB shares
    samba # SMB client tools (smbclient, etc.)
  ];

  # Create mount points for SMB shares
  systemd.tmpfiles.rules = [
    "d /mnt/smb 0755 root root -" # Main SMB mount directory
    "d /mnt/smb/mini-storage 0755 root root -" # Mini storage share
  ];

  # Configure systemd mount units for automatic mounting
  systemd.mounts = [
    {
      description = "Mount mini storage SMB share (macOS File Sharing)";
      what = "//ivans-mac-mini.local/Storage";
      where = "/mnt/smb/mini-storage";
      type = "cifs";
      options = let
        credFile = pkgs.writeText "smb-credentials-mini" ''
          username=${config.secrets.smb.mini.username}
          password=${config.secrets.smb.mini.password}
        '';
      in "credentials=${credFile},uid=1000,gid=100,iocharset=utf8,file_mode=0644,dir_mode=0755,vers=3.0,ip=${config.flags.miniIp}";
      wantedBy = [ "multi-user.target" ];
    }
  ];

  # Configure systemd automount units for on-demand mounting
  systemd.automounts = [
    {
      description = "Automount mini storage SMB share";
      where = "/mnt/smb/mini-storage";
      wantedBy = [ "multi-user.target" ];
    }
  ];

  # Note: mDNS/.local hostname resolution is configured in networking.nix

  # Network configuration for SMB
  networking.firewall = {
    # Allow outbound SMB/CIFS connections
    allowedTCPPorts = [
      445 # Standard SMB port (macOS File Sharing)
    ];
  };
}
