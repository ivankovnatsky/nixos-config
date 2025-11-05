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
        type = types.nullOr types.str;
        default = null;
        example = "abc123";
        description = "NextDNS profile ID to sync";
      };

      profileIdFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/run/secrets/nextdns-profile-id";
        description = "Path to file containing NextDNS profile ID";
      };

      profileFile = mkOption {
        type = types.path;
        example = ./nextdns/profile.json;
        description = "Path to NextDNS profile JSON file";
      };

      apiKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "NextDNS API key";
      };

      apiKeyFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/run/secrets/nextdns-api-key";
        description = "Path to file containing NextDNS API key";
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

  config = mkIf (enabledProfiles != {}) {
    assertions = flatten (mapAttrsToList (name: profile: [
      {
        assertion = (profile.apiKey != null) != (profile.apiKeyFile != null);
        message = "Exactly one of apiKey or apiKeyFile must be set for nextdns-mgmt profile '${name}'";
      }
      {
        assertion = (profile.profileId != null) != (profile.profileIdFile != null);
        message = "Exactly one of profileId or profileIdFile must be set for nextdns-mgmt profile '${name}'";
      }
    ]) enabledProfiles);

    # Darwin launchd services (one per profile)
    local.launchd.services = listToAttrs (mapAttrsToList (name: profile:
      nameValuePair "nextdns-mgmt-${name}" {
        enable = true;
        keepAlive = false;
        runAtLoad = true;

          command = let
            syncScript = pkgs.writeShellScript "nextdns-mgmt-${name}-sync" ''
              set -e

              ${if profile.profileIdFile != null
                then ''echo "Updating NextDNS profile ${name}..."''
                else ''echo "Updating NextDNS profile ${name} (${profile.profileId})..."''}

              ${if profile.apiKeyFile != null
                then ''API_KEY="$(cat ${profile.apiKeyFile})"''
                else ''API_KEY="${profile.apiKey}"''}
              ${if profile.profileIdFile != null
                then ''PROFILE_ID="$(cat ${profile.profileIdFile})"''
                else ''PROFILE_ID="${profile.profileId}"''}

              ${pkgs.nextdns-mgmt}/bin/nextdns-mgmt update \
                --api-key "$API_KEY" \
                --profile-id "$PROFILE_ID" \
                --profile-file "${profile.profileFile}" 2>&1 || echo "Warning: NextDNS update for ${name} failed with exit code $?"

              echo "NextDNS profile ${name} update completed"
            '';
          in "${syncScript}";
        }
      ) enabledProfiles);
  };
}
