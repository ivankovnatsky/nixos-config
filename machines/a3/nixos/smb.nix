{ config, pkgs, ... }:
{
  # SMB client configuration for a3 machine
  # This enables mounting SMB shares from mini (Ivans-Mac-mini) machine
  #
  # Uses macOS built-in File Sharing:
  # - Standard SMB port 445
  # - Share: //ivans-mac-mini.local/Storage
  # - Authenticated with 'samba' sharing-only user

  # Sops secrets for SMB credentials
  sops.secrets.smb-mini-username = {
    key = "smb/mini/username";
  };

  sops.secrets.smb-mini-password = {
    key = "smb/mini/password";
  };

  # Enable CIFS support for mounting Windows/SMB shares
  boot.supportedFilesystems = [ "cifs" ];

  # Install necessary packages for SMB client functionality
  environment.systemPackages = with pkgs; [
    cifs-utils # Tools for mounting CIFS/SMB shares
    samba # SMB client tools (smbclient, etc.)
  ];

  # Create SMB credentials file at runtime using sops secrets
  systemd.tmpfiles.rules = [
    "d /mnt/smb 0755 root root -" # Main SMB mount directory
    "d /mnt/smb/mini-storage 0755 root root -" # Mini storage share
  ];

  # Generate credentials file at boot using sops secrets (stored in tmpfs)
  systemd.services.smb-credentials-mini = {
    description = "Generate SMB credentials file for mini share";
    wantedBy = [ "multi-user.target" ];
    before = [ "mnt-smb-mini\\x2dstorage.mount" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      cat > /run/smb-mini-credentials <<EOF
      username=$(cat ${config.sops.secrets.smb-mini-username.path})
      password=$(cat ${config.sops.secrets.smb-mini-password.path})
      EOF
      chmod 600 /run/smb-mini-credentials
    '';
  };

  # Configure systemd mount units for automatic mounting
  systemd.mounts = [
    {
      description = "Mount mini storage SMB share (macOS File Sharing)";
      what = "//ivans-mac-mini.local/Storage";
      where = "/mnt/smb/mini-storage";
      type = "cifs";
      options = "credentials=/run/smb-mini-credentials,uid=1000,gid=100,iocharset=utf8,file_mode=0644,dir_mode=0755,vers=3.0,ip=${config.flags.miniIp}";
      wantedBy = [ "multi-user.target" ];
      after = [ "smb-credentials-mini.service" ];
      requires = [ "smb-credentials-mini.service" ];
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
