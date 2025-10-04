{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.local.services.nextdns-mgmt;
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

    apiKey = mkOption {
      type = types.str;
      description = "NextDNS API key";
    };
  };

  config = mkMerge [
    # Darwin configuration
    (mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
      system.activationScripts.postActivation.text = ''
        echo "Updating NextDNS profile ${cfg.profileId}..."
        ${pkgs.nextdns-mgmt}/bin/nextdns-mgmt update \
          --api-key "${cfg.apiKey}" \
          --profile-id "${cfg.profileId}" \
          --profile-file "${cfg.profileFile}" || echo "Warning: NextDNS update failed"
      '';
    })

    # NixOS configuration
    (mkIf (cfg.enable && !pkgs.stdenv.isDarwin) {
      system.activationScripts.nextdns-mgmt = {
        text = ''
          echo "Updating NextDNS profile ${cfg.profileId}..."
          ${pkgs.nextdns-mgmt}/bin/nextdns-mgmt update \
            --api-key "${cfg.apiKey}" \
            --profile-id "${cfg.profileId}" \
            --profile-file "${cfg.profileFile}" || echo "Warning: NextDNS update failed"
        '';
      };
    })
  ];
}
