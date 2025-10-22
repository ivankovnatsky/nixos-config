{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.services.nextdns-mgmt;

  profileOptions = types.submodule {
    options = {
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
  };

  enabledProfiles = filterAttrs (_: profile: profile.enable) cfg;
in
{
  options.local.services.nextdns-mgmt = mkOption {
    type = types.attrsOf profileOptions;
    default = {};
    description = "NextDNS profile management instances";
  };

  config = mkMerge [
    # Darwin configuration
    (mkIf (enabledProfiles != {} && pkgs.stdenv.isDarwin) {
      system.activationScripts.postActivation.text = concatStringsSep "\n" (
        mapAttrsToList (name: profile: ''
          echo "Updating NextDNS profile ${name} (${profile.profileId})..."
          ${pkgs.nextdns-mgmt}/bin/nextdns-mgmt update \
            --api-key "${profile.apiKey}" \
            --profile-id "${profile.profileId}" \
            --profile-file "${profile.profileFile}" || echo "Warning: NextDNS update for ${name} failed"
        '') enabledProfiles
      );
    })

    # NixOS configuration
    (mkIf (enabledProfiles != {} && !pkgs.stdenv.isDarwin) {
      system.activationScripts.nextdns-mgmt = {
        text = concatStringsSep "\n" (
          mapAttrsToList (name: profile: ''
            echo "Updating NextDNS profile ${name} (${profile.profileId})..."
            ${pkgs.nextdns-mgmt}/bin/nextdns-mgmt update \
              --api-key "${profile.apiKey}" \
              --profile-id "${profile.profileId}" \
              --profile-file "${profile.profileFile}" || echo "Warning: NextDNS update for ${name} failed"
          '') enabledProfiles
        );
      };
    })
  ];
}
