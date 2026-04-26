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

      vars = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = {
          externalDomain = "example.com";
          miniIp = "192.168.50.4";
        };
        description = "Variables to substitute in profile JSON (@KEY@ → value)";
      };

      varsFiles = mkOption {
        type = types.attrsOf types.path;
        default = { };
        example = {
          externalDomain = "/run/secrets/external-domain";
        };
        description = "Variables to substitute from file contents (@KEY@ → file content)";
      };
    };
  };

  enabledProfiles = filterAttrs (_: profile: profile.enable) cfg;

  mkSyncScript =
    name: profile:
    pkgs.writeShellScript "nextdns-mgmt-${name}-sync" ''
      set -e

      echo "Updating NextDNS profile ${name}..."

      ${
        if profile.apiKeyFile != null then
          ''API_KEY="$(cat ${profile.apiKeyFile})"''
        else
          ''API_KEY="${profile.apiKey}"''
      }

      PROFILE_JSON=$(mktemp)
      trap 'rm -f "$PROFILE_JSON"' EXIT
      cp "${profile.profileFile}" "$PROFILE_JSON"
      ${concatStringsSep "\n      " (
        mapAttrsToList (
          key: value: ''${pkgs.gnused}/bin/sed -i "s|@${key}@|${value}|g" "$PROFILE_JSON"''
        ) profile.vars
      )}
      ${concatStringsSep "\n      " (
        mapAttrsToList (
          key: path:
          ''${pkgs.gnused}/bin/sed -i "s|@${key}@|$(cat ${path})|g" "$PROFILE_JSON"''
        ) profile.varsFiles
      )}

      PROFILE_ID_ARGS=()
      ${
        if profile.profileIdFile != null then
          ''PROFILE_ID_ARGS=(--profile-id "$(cat ${profile.profileIdFile})")''
        else if profile.profileId != null then
          ''PROFILE_ID_ARGS=(--profile-id "${profile.profileId}")''
        else
          ""
      }

      ${pkgs.nextdns-mgmt}/bin/nextdns-mgmt update \
        --api-key "$API_KEY" \
        --name "${name}" \
        --profile-file "$PROFILE_JSON" \
        "''${PROFILE_ID_ARGS[@]}" 2>&1 || echo "Warning: NextDNS update for ${name} failed with exit code $?"

      echo "NextDNS profile ${name} update completed"
    '';
in
{
  options.local.services.nextdns-mgmt = mkOption {
    type = types.attrsOf profileOptions;
    default = { };
    description = "NextDNS profile management instances";
  };

  config = mkIf (enabledProfiles != { }) (mkMerge [
    {
      assertions = flatten (
        mapAttrsToList (name: profile: [
          {
            assertion = (profile.apiKey != null) != (profile.apiKeyFile != null);
            message = "Exactly one of apiKey or apiKeyFile must be set for nextdns-mgmt profile '${name}'";
          }
          {
            assertion = !(profile.profileId != null && profile.profileIdFile != null);
            message = "At most one of profileId or profileIdFile may be set for nextdns-mgmt profile '${name}' (otherwise the profile is looked up or created by name)";
          }
        ]) enabledProfiles
      );
    }

    # Darwin: one launchd user agent per profile, runs at login.
    (mkIf pkgs.stdenv.hostPlatform.isDarwin {
      local.launchd.services = listToAttrs (
        mapAttrsToList (
          name: profile:
          nameValuePair "nextdns-mgmt-${name}" {
            enable = true;
            keepAlive = false;
            runAtLoad = true;
            command = "${mkSyncScript name profile}";
          }
        ) enabledProfiles
      );
    })

    # Linux: one systemd user service per profile, started at login.
    (mkIf pkgs.stdenv.hostPlatform.isLinux {
      systemd.user.services = mapAttrs' (
        name: profile:
        nameValuePair "nextdns-mgmt-${name}" {
          Unit.Description = "Sync NextDNS profile ${name}";
          Service = {
            Type = "oneshot";
            ExecStart = "${mkSyncScript name profile}";
          };
          Install.WantedBy = [ "default.target" ];
        }
      ) enabledProfiles;
    })
  ]);
}
