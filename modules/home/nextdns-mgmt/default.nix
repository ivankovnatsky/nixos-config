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

      profileFile = mkOption {
        type = types.path;
        example = ./nextdns/profile.json;
        description = "Path to NextDNS profile JSON file";
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

      # API key and profile id are read by the CLI from
      # ~/.config/sops-nix/secrets/{nextdns-api-key,nextdns-profile-${name}}.

      STATE_DIR=$(${pkgs.coreutils}/bin/mktemp -d -t nextdns-mgmt.XXXXXX)
      ${pkgs.coreutils}/bin/chmod 700 "$STATE_DIR"
      trap '${pkgs.coreutils}/bin/rm -rf "$STATE_DIR"' EXIT
      PROFILE_JSON="$STATE_DIR/profile.json"
      SED_SCRIPT="$STATE_DIR/sed-script"
      ${pkgs.coreutils}/bin/cp "${profile.profileFile}" "$PROFILE_JSON"
      # Build a sed script file so sops varsFiles values never appear on argv.
      ${concatStringsSep "\n      " (
        mapAttrsToList (
          key: value:
          ''${pkgs.coreutils}/bin/printf 's|@${key}@|%s|g\n' ${lib.escapeShellArg value} >> "$SED_SCRIPT"''
        ) profile.vars
      )}
      ${concatStringsSep "\n      " (
        mapAttrsToList (key: path: ''
          ${pkgs.coreutils}/bin/printf 's|@${key}@|' >> "$SED_SCRIPT"
          ${pkgs.coreutils}/bin/tr -d '\n' < ${path} >> "$SED_SCRIPT"
          ${pkgs.coreutils}/bin/printf '|g\n' >> "$SED_SCRIPT"
        '') profile.varsFiles
      )}
      ${pkgs.gnused}/bin/sed -i -f "$SED_SCRIPT" "$PROFILE_JSON"

      ${pkgs.nextdns-mgmt}/bin/nextdns-mgmt update \
        --name "${name}" \
        --profile-file "$PROFILE_JSON" 2>&1 || echo "Warning: NextDNS update for ${name} failed with exit code $?"

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
          Unit = {
            Description = "Sync NextDNS profile ${name}";
            # Wait for sops-nix to decrypt secrets before reading them.
            After = [ "sops-nix.service" ];
            Wants = [ "sops-nix.service" ];
          };
          Service = {
            Type = "exec";
            ExecStart = "${mkSyncScript name profile}";
          };
          Install.WantedBy = [ "default.target" ];
        }
      ) enabledProfiles;
    })
  ]);
}
