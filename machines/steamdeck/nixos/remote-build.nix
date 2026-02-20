{ config, lib, pkgs, ... }:
{
  # Generate SSH key for root to connect to remote builder
  systemd.services.generate-nixbuilder-ssh-key = {
    description = "Generate SSH key for root remote builds";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if [ ! -f /root/.ssh/nixbuilder ]; then
        mkdir -p /root/.ssh
        ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f /root/.ssh/nixbuilder -N "" -C "root@steamdeck"
        chmod 600 /root/.ssh/nixbuilder
        chmod 644 /root/.ssh/nixbuilder.pub
      fi
    '';
  };

  # Configure root's SSH to connect to a3's nixbuilder user
  programs.ssh.extraConfig = ''
    Host a3
      HostName 192.168.50.6
      IdentitiesOnly yes
      IdentityFile /root/.ssh/nixbuilder
      User nixbuilder
      StrictHostKeyChecking accept-new
  '';
}
