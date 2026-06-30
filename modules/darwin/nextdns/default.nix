{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.nextdns;

  setDnsScript = pkgs.writeShellScript "set-nextdns" ''
    set -e

    DNS1=$(/bin/cat "${config.sops.secrets."nextdns-1".path}")
    DNS2=$(/bin/cat "${config.sops.secrets."nextdns-2".path}")

    ${concatMapStringsSep "\n" (
      svc:
      ''/usr/sbin/networksetup -setdnsservers "${svc}" "$DNS1" "$DNS2" ${concatStringsSep " " cfg.fallbackDns}''
    ) config.networking.knownNetworkServices}

    echo "NextDNS DNS configured: $DNS1 $DNS2"
  '';
in
{
  options.local.nextdns = {
    enable = mkEnableOption "NextDNS DNS configuration from sops secrets";

    machine = mkOption {
      type = types.str;
      description = "Machine name in nextDNS/<machine>/IPs sops path";
      example = "Air";
    };

    fallbackDns = mkOption {
      type = types.listOf types.str;
      default = [
        "1.1.1.1"
        "1.0.0.1"
      ];
      description = "Fallback DNS servers appended after NextDNS IPs";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets."nextdns-1".key = "nextDNS/${cfg.machine}/IPs/0";
    sops.secrets."nextdns-2".key = "nextDNS/${cfg.machine}/IPs/1";

    local.launchd.services.nextdns = {
      enable = true;
      waitForSecrets = true;
      keepAlive = false;
      command = "${setDnsScript}";
      extraServiceConfig = {
        # macOS/DHCP can reset per-service DNS back to the router after the
        # one-shot launchd job has run. Re-apply periodically so the machine
        # keeps using its own NextDNS profile instead of the router/Asus one.
        StartInterval = 60;
      };
    };
  };
}
