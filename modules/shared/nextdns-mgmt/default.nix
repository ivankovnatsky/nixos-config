{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.local.services.nextdns-mgmt;

  updateProfile = pkgs.writeShellScript "update-nextdns-profile" ''
    set -euo pipefail

    ${pkgs.nextdns-mgmt}/bin/nextdns-mgmt update \
      --api-key "${config.secrets.nextDnsApiKey}" \
      --profile-id "${cfg.profileId}" \
      --profile-file "${cfg.profileFile}"
  '';

in
{
  options.local.services.nextdns-mgmt = {
    enable = mkEnableOption "declarative NextDNS profile synchronization";

    profileId = mkOption {
      type = types.str;
      example = "abc123";
      description = "NextDNS profile ID to sync";
    };

    profileFile = mkOption {
      type = types.path;
      example = ./nextdns/profile.json;
      description = "Path to NextDNS profile JSON file";
    };
  };

  config = mkIf cfg.enable {
    # Darwin: Apply during system activation
    system.activationScripts.nextdns-mgmt = mkIf pkgs.stdenv.isDarwin {
      text = ''
        echo "Updating NextDNS profile ${cfg.profileId}..."
        ${updateProfile} || echo "Warning: NextDNS update failed"
      '';
    };

    # NixOS: Apply during system activation
    system.activationScripts.nextdns-mgmt = mkIf (!pkgs.stdenv.isDarwin) {
      text = ''
        echo "Updating NextDNS profile ${cfg.profileId}..."
        ${updateProfile} || echo "Warning: NextDNS update failed"
      '';
    };
  };
}
