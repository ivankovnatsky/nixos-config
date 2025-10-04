{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.local.services.nextdns-mgmt;

  applyBlocklist = pkgs.writeShellScript "apply-nextdns-blocklist" ''
    set -euo pipefail

    ${pkgs.nextdns-mgmt}/bin/nextdns-mgmt sync-all \
      --api-key "${config.secrets.nextDnsApiKey}" \
      --profiles-dir ${config.users.users.${config.user}.home}/nixos-config/machines
  '';

in
{
  options.local.services.nextdns-mgmt = {
    enable = mkEnableOption "declarative NextDNS profile synchronization";

    profiles = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "abc123" "def456" ];
      description = "NextDNS profile IDs to configure (deprecated - use profile.json files instead)";
    };
  };

  config = mkIf cfg.enable {
    # Darwin: Apply during system activation
    system.activationScripts.nextdns-mgmt = mkIf pkgs.stdenv.isDarwin {
      text = ''
        echo "Syncing NextDNS denylist..."
        ${applyBlocklist} || echo "Warning: NextDNS sync failed"
      '';
    };

    # NixOS: Apply during system activation
    system.activationScripts.nextdns-mgmt = mkIf (!pkgs.stdenv.isDarwin) {
      text = ''
        echo "Syncing NextDNS denylist..."
        ${applyBlocklist} || echo "Warning: NextDNS sync failed"
      '';
    };
  };
}
