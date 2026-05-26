{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.services.syncthing-mgmt;
in
{
  options.local.services.syncthing-mgmt = {
    enable = mkEnableOption "declarative Syncthing GUI and device synchronization";

    baseUrl = mkOption {
      type = types.str;
      default = "http://localhost:8384";
      description = "Syncthing instance base URL";
    };

    localDeviceName = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "bee";
      description = "Name to set for this device (the local Syncthing instance)";
    };

    configDir = mkOption {
      type = types.path;
      default = "/var/lib/syncthing/.config/syncthing";
      description = "Path to Syncthing config directory (for reading config.xml)";
    };

    gui = mkOption {
      type = types.nullOr (
        types.submodule {
          options = {
            username = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "GUI username";
            };

            usernameFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              example = "/run/secrets/syncthing-gui-username";
              description = "Path to file containing GUI username";
            };

            password = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "GUI password (will be bcrypt hashed if not already)";
            };

            passwordFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              example = "/run/secrets/syncthing-gui-password";
              description = "Path to file containing GUI password (bcrypt hash or plain text)";
            };
          };
        }
      );
      default = null;
      description = "GUI credentials configuration";
    };

    devices = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "Device-Name"
        "Another-Device"
      ];
      description = ''
        List of device names to connect to on this machine.
        Device IDs are looked up from deviceDefinitionsFile.
        Devices referenced in folders are automatically included.
      '';
    };

    deviceDefinitionsFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/run/secrets/syncthing-devices.json";
      description = ''
        Path to JSON file containing device name to ID mappings (device registry).
        This acts as a lookup table for all known devices.
        Devices are merged with the 'devices' option (this file takes precedence).
        Only devices referenced in folders will actually be configured.
      '';
    };

    folders = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            path = mkOption {
              type = types.str;
              description = "Path to the folder on disk";
            };
            label = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Label for the folder (defaults to folder ID)";
            };
            devices = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "List of device IDs to share this folder with";
            };
          };
        }
      );
      default = { };
      example = {
        "shtdy-s2c9s" = {
          path = "/home/user/Documents";
          label = "Documents";
          devices = [ "AAAA111-BBBB222-..." ];
        };
      };
      description = "Folders to sync (folder ID = config)";
    };

    foldersFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/run/secrets/syncthing-folders.json";
      description = "Path to JSON file containing folders (alternative to folders option)";
    };

    restart = mkOption {
      type = types.bool;
      default = false;
      description = "Restart Syncthing after applying configuration changes";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion =
          cfg.gui != null
          -> (
            (cfg.gui.username != null) != (cfg.gui.usernameFile != null)
            && (cfg.gui.password != null) != (cfg.gui.passwordFile != null)
          );
        message = "Exactly one of username/usernameFile and password/passwordFile must be set for syncthing-mgmt GUI config";
      }
    ];

    systemd.services.syncthing-mgmt-sync = {
      description = "Syncthing GUI and device configuration synchronization";
      wantedBy = [ "multi-user.target" ];
      after = [ "syncthing.service" ];
      wants = [ "syncthing.service" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
        ExecStart = pkgs.writeShellScript "syncthing-mgmt-sync" ''
          echo "Syncing Syncthing configuration..."

          # Single 0700 tempdir for all transient secret files. Trap covers it
          # before any secret touches disk so an abort never leaks.
          STATE_DIR=$(${pkgs.coreutils}/bin/mktemp -d -t syncthing-mgmt.XXXXXX)
          ${pkgs.coreutils}/bin/chmod 700 "$STATE_DIR"
          trap '${pkgs.coreutils}/bin/rm -rf "$STATE_DIR"' EXIT

          KEY_FILE="$STATE_DIR/api-key"
          CURL_HEADERS="$STATE_DIR/curl-headers"

          # Resolve API key from Syncthing's own config.xml. Check xmllint
          # exit code (not file size) so an empty file isn't misread as ok.
          if ! ${pkgs.libxml2}/bin/xmllint --xpath 'string(configuration/gui/apikey)' "${cfg.configDir}/config.xml" > "$KEY_FILE" 2>/dev/null || ! [ -s "$KEY_FILE" ]; then
            echo "ERROR: Could not read API key from ${cfg.configDir}/config.xml"
            exit 1
          fi

          # Assemble the curl headers file (only contains the API key now).
          {
            ${pkgs.coreutils}/bin/printf 'X-API-Key: '
            ${pkgs.coreutils}/bin/cat "$KEY_FILE"
            ${pkgs.coreutils}/bin/printf '\n'
          } > "$CURL_HEADERS"

          # Wait for Syncthing API to be ready with retry logic
          MAX_RETRIES=30
          RETRY_DELAY=2

          echo "Waiting for Syncthing API to be ready..."
          for i in $(${pkgs.coreutils}/bin/seq 1 $MAX_RETRIES); do
            if ${pkgs.curl}/bin/curl -sf -H "@$CURL_HEADERS" "${cfg.baseUrl}/rest/system/status" >/dev/null 2>&1; then
              echo "Syncthing API is ready (attempt $i/$MAX_RETRIES)"
              break
            fi

            if [ $i -eq $MAX_RETRIES ]; then
              echo "ERROR: Syncthing API not ready after $MAX_RETRIES attempts (${cfg.baseUrl})"
              exit 1
            fi

            echo "Waiting for Syncthing API... (attempt $i/$MAX_RETRIES, retrying in ''${RETRY_DELAY}s)"
            ${pkgs.coreutils}/bin/sleep $RETRY_DELAY
          done

          # Build config JSON with secrets substituted from files. All temp
          # files live in STATE_DIR (set + trapped at the top of this script).
          CONFIG_FILE="$STATE_DIR/config.json"

          # Start building JSON. jq --rawfile reads credentials from a
          # private file so values never appear on jq's argv. For literal
          # `username` / `password` options we read via writeText so the
          # value never crosses any process's argv.
          GUI_JSON="null"
          ${optionalString (cfg.gui != null) ''
            ${
              if cfg.gui.usernameFile != null then
                ''USERNAME_FILE="${cfg.gui.usernameFile}"''
              else
                ''USERNAME_FILE="${pkgs.writeText "syncthing-gui-username" cfg.gui.username}"''
            }
            ${
              if cfg.gui.passwordFile != null then
                ''PASSWORD_FILE="${cfg.gui.passwordFile}"''
              else
                ''PASSWORD_FILE="${pkgs.writeText "syncthing-gui-password" cfg.gui.password}"''
            }
            GUI_JSON=$(${pkgs.jq}/bin/jq -n \
              --rawfile username "$USERNAME_FILE" \
              --rawfile password "$PASSWORD_FILE" \
              '{username: ($username | rtrimstr("\n")), password: ($password | rtrimstr("\n"))}')
          ''}

          ${
            if cfg.deviceDefinitionsFile != null then
              ''
                # Load full device registry from file
                ALL_DEVICES=$(cat ${cfg.deviceDefinitionsFile} | ${pkgs.jq}/bin/jq -c .)

                # Extract device names from folders configuration
                FOLDERS_JSON_TMP='${builtins.toJSON cfg.folders}'
                FOLDER_DEVICES=$(echo "$FOLDERS_JSON_TMP" | ${pkgs.jq}/bin/jq -r '[.[] | .devices[]] | unique | .[]')

                # Combine explicit devices list with folder devices
                EXPLICIT_DEVICES='${builtins.toJSON cfg.devices}'
                NEEDED_DEVICES=$(echo "$EXPLICIT_DEVICES" | ${pkgs.jq}/bin/jq -r '.[]'; echo "$FOLDER_DEVICES" | sort -u)

                # Filter device registry to only needed devices
                DEVICES_JSON=$(echo "$ALL_DEVICES" | ${pkgs.jq}/bin/jq -c \
                  --argjson needed "$(echo "$NEEDED_DEVICES" | ${pkgs.jq}/bin/jq -R -s 'split("\n") | map(select(length > 0)) | unique')" \
                  'with_entries(select(.key as $k | $needed | index($k)))')

                echo "Configured devices (from registry):" >&2
                echo "$DEVICES_JSON" | ${pkgs.jq}/bin/jq -r 'keys[]' >&2
              ''
            else
              ''
                # No device registry, devices must be empty
                DEVICES_JSON='{}'
              ''
          }

          FOLDERS_JSON='${builtins.toJSON cfg.folders}'
          ${optionalString (cfg.foldersFile != null) ''
            # Strip leading whitespace from each line and compact JSON
            FOLDERS_JSON=$(cat ${cfg.foldersFile} | ${pkgs.jq}/bin/jq -c .)
          ''}

          ${pkgs.jq}/bin/jq -n \
            --argjson gui "$GUI_JSON" \
            --argjson devices "$DEVICES_JSON" \
            --argjson folders "$FOLDERS_JSON" ${
              optionalString (cfg.localDeviceName != null) ''
                \
                            --arg localDeviceName "${cfg.localDeviceName}"''
            } \
            '{gui: $gui, devices: $devices, folders: $folders${
              optionalString (cfg.localDeviceName != null) ", localDeviceName: $localDeviceName"
            }}' > "$CONFIG_FILE"

          ${pkgs.syncthing-mgmt}/bin/syncthing-mgmt declarative \
            --base-url "${cfg.baseUrl}" \
            --config-xml "${cfg.configDir}/config.xml" \
            --config-file "$CONFIG_FILE" \
            ${optionalString cfg.restart "--restart"}
        '';
      };
    };
  };
}
