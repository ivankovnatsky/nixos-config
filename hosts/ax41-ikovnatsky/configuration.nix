{ config, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use GRUB2 as the boot loader.
  # We don't use systemd-boot because Hetzner uses BIOS legacy boot.
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub = {
    enable = true;
    efiSupport = false;
    devices = [ "/dev/nvme0n1" "/dev/nvme1n1" ];
  };

  # The madm RAID was created with a certain hostname, which madm will consider
  # the "home hostname". Changing the system hostname will result in the array
  # being considered "foregin" as opposed to "local", and showing it as
  # '/dev/md/<hostname>:root0' instead of '/dev/md/root0'.

  # This is mdadm's protection against accidentally putting a RAID disk
  # into the wrong machine and corrupting data by accidental sync, see
  # https://bugzilla.redhat.com/show_bug.cgi?id=606481#c14 and onward.
  # We set the HOMEHOST manually go get the short '/dev/md' names,
  # and so that things look and are configured the same on all such
  # machines irrespective of host names.
  # We do not worry about plugging disks into the wrong machine because
  # we will never exchange disks between machines.
  environment.etc."mdadm.conf".text = ''
    HOMEHOST <ignore>
  '';
  # The RAIDs are assembled in stage1, so we need to make the config
  # available there.
  boot.initrd.services.swraid.mdadmConf = config.environment.etc."mdadm.conf".text;

  # Network (Hetzner uses static IP assignments, and we don't use DHCP here)
  networking.useDHCP = false;

  networking.interfaces."enp35s0" = {
    ipv4 = {
      addresses = [{
        address = "${config.secrets.workHetznerServerIPv4}";
        prefixLength = 24;
      }];

      routes = [
        # Default IPv4 gateway route
        {
          address = "0.0.0.0";
          prefixLength = 0;
          via = "${config.secrets.workHetznerServerIPv4Gateway}";
        }
      ];
    };

    ipv6 = {
      addresses = [{
        address = "${config.secrets.workHetznerServerIPv6}";
        prefixLength = 64;
      }];

      # Default IPv6 route
      routes = [{
        address = "::";
        prefixLength = 0;
        via = "${config.secrets.workHetznerServerIPv6Gateway}";
      }];
    };
  };

  networking = {
    hostName = "ax41-ikovnatsky";

    # https://docs.hetzner.com/dns-console/dns/general/recursive-name-servers/
    # Resolution does not work unless hetzner servers used. Firewall could be
    # configured to fix this, but I don't have access to it on work server, so
    # leave it be.
    nameservers = [ "185.12.64.1" "185.12.64.2" ];

    # https://www.reddit.com/r/hetzner/comments/11qaxur/hetzner_rclone_google_drive_if_youre_getting_an/
    # https://forum.rclone.org/t/429-google-drive-errors-back-for-anyone-using-hetzner-even-with-cloudflare-or-google-dns-used/36671/174
    extraHosts = ''
      142.250.113.95 www.googleapis.com
      142.251.16.95 www.googleapis.com
      172.253.63.95 www.googleapis.com
      142.251.111.95 www.googleapis.com
      142.251.163.95 www.googleapis.com
      142.251.167.95 www.googleapis.com
      142.250.74.78 www.googleapis.com
    '';
  };

  # Initial empty root password for easy login:
  users.users.root.initialHashedPassword = "";
  services.openssh.permitRootLogin = "prohibit-password";
  services.openssh.enable = true;

  # Only comment out when ivan password set and ssh connectivity
  # verified.
  # users.users.root.openssh.authorizedKeys.keys = [
  #   "${config.secrets.sshPublicKey}"
  # ];

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "22.11"; # Did you read the comment?
}
