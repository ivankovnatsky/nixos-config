{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.nextdns-dns;

  setDnsScript = pkgs.writeShellScript "set-nextdns-dns" ''
    set -e

    DNS1=$(/bin/cat "${config.sops.secrets."nextdns-dns-1".path}")
    DNS2=$(/bin/cat "${config.sops.secrets."nextdns-dns-2".path}")

    ${concatMapStringsSep "\n" (
      svc: ''/usr/sbin/networksetup -setdnsservers "${svc}" "$DNS1" "$DNS2" ${concatStringsSep " " cfg.fallbackDns}''
    ) config.networking.knownNetworkServices}

    echo "NextDNS DNS configured: $DNS1 $DNS2"
  '';
in
{
  options.local.nextdns-dns = {
    enable = mkEnableOption "NextDNS DNS configuration from sops secrets";

    machine = mkOption {
      type = types.str;
      description = "Machine name in nextDNS/IPs/<machine> sops path";
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
    sops.secrets."nextdns-dns-1".key = "nextDNS/IPs/${cfg.machine}/0";
    sops.secrets."nextdns-dns-2".key = "nextDNS/IPs/${cfg.machine}/1";

    local.launchd.services.nextdns-dns = {
      enable = true;
      waitForSecrets = true;
      keepAlive = false;
      command = "${setDnsScript}";
    };
  };
}
