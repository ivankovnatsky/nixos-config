{ config, lib, ... }:

with lib;
{
  options.inventory = {
    machineIp = mkOption {
      type = types.str;
      description = "This machine's IP address";
      # Returns "" for hosts not in the lookup. Switching to a loud failure is
      # a separate decision.
      default =
        let
          hostName = config.networking.hostName or "";
        in
        {
          "Ivans-MacBook-Air" = config.inventory.airIp;
          "Ivans-MacBook-Pro" = config.inventory.proIp;
          "Ivans-Mac-mini" = config.inventory.miniIp;
          "a3" = config.inventory.a3Ip;
        }
        .${hostName} or "";
    };

    airIp = mkOption {
      type = types.str;
      description = "Air IP address";
      default = "192.168.50.8";
    };

    proIp = mkOption {
      type = types.str;
      description = "Pro IP address";
      default = "192.168.50.7";
    };

    miniIp = mkOption {
      type = types.str;
      description = "Mac mini ethernet IP address";
      default = "192.168.50.4";
    };

    miniWifiIp = mkOption {
      type = types.str;
      description = "Mac mini WiFi IP address";
      default = "192.168.50.12";
    };

    machineBindAddress = mkOption {
      type = types.str;
      description = "Address for services to bind to (0.0.0.0 for all interfaces)";
      default = config.inventory.machineIp;
    };

    machineLocalAddress = mkOption {
      type = types.str;
      description = "Address for connecting to local services (127.0.0.1 when binding all interfaces)";
      default = config.inventory.machineIp;
    };

    a3Ip = mkOption {
      type = types.str;
      description = "a3 ethernet IP address";
      default = "192.168.50.6";
    };

    a3WifiIp = mkOption {
      type = types.str;
      description = "a3 WiFi IP address";
      default = "192.168.50.11";
    };

    miniVmIp = mkOption {
      type = types.str;
      description = "mini-vm OrbStack VM IP address";
      default = "192.168.138.4";
    };

    sshKeys = {
      air = mkOption {
        type = types.str;
        description = "MacBook Air SSH public key";
        default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILC9hnu0qrOSGfAm8fcjZdNtn0UJlHjfzSJKglz0UDZv ivan@Ivans-MacBook-Air";
      };
      pro = mkOption {
        type = types.str;
        description = "MacBook Pro SSH public key";
        default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOjvopV6VNPr5MbP6Fx98PKhgCYqfSVoRdR5PzV+n871 ivan@Ivans-MacBook-Pro";
      };
      a3 = mkOption {
        type = types.str;
        description = "a3 SSH public key";
        default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGaj1+gRvTcHyQY8PRINdUCLOuL0MboCUea+Ki7yhNin ivan@a3";
      };
      mini = mkOption {
        type = types.str;
        description = "Mac mini SSH public key";
        default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKQLGp4dAt11hMxOTkKCrPoTnQmXO3MNk9fgveK6NJll ivan@Ivans-Mac-mini";
      };
    };
  };
}
