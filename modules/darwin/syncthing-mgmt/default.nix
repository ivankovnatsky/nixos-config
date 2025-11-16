{ config, lib, pkgs, ... }:

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

    configDir = mkOption {
      type = types.path;
      description = "Path to Syncthing config directory (for reading config.xml)";
      example = "/Users/username/Library/Application Support/Syncthing";
    };

    apiKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Syncthing API key (use apiKeyFile for sops secrets)";
    };

    apiKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/run/secrets/syncthing-api-key";
      description = "Path to file containing Syncthing API key (alternative to using config.xml)";
    };

    gui = mkOption {
      type = types.nullOr (types.submodule {
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
      });
      default = null;
      description = "GUI credentials configuration";
    };

    devices = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "Device-Name" "Another-Device" ];
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
      type = types.attrsOf (types.submodule {
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
            default = [];
            description = "List of device names or IDs to share this folder with";
          };
        };
      });
      default = {};
      example = {
        "shtdy-s2c9s" = {
          path = "/Users/user/Documents";
          label = "Documents";
          devices = [ "Device-Name" ];
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

    interval = mkOption {
      type = types.int;
      default = 86400;
      description = "Sync interval in seconds (default: 86400 = once per day)";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.gui != null -> (
          ((cfg.gui.username != null) != (cfg.gui.usernameFile != null)) &&
          ((cfg.gui.password != null) != (cfg.gui.passwordFile != null))
        );
        message = "Exactly one of username/usernameFile and password/passwordFile must be set for syncthing-mgmt GUI config";
      }
      {
        assertion = (cfg.apiKey == null && cfg.apiKeyFile == null) ||
                    (cfg.apiKey != null && cfg.apiKeyFile == null) ||
                    (cfg.apiKey == null && cfg.apiKeyFile != null);
        message = "Either apiKey or apiKeyFile can be set, but not both";
      }
    ];

    # Darwin launchd service
    local.launchd.services.syncthing-mgmt = {
      enable = true;
      keepAlive = false;
      runAtLoad = true;

      command = let
        syncScript = pkgs.writeShellScript "syncthing-mgmt-sync" ''
          set -e

          echo "Syncing Syncthing configuration..."

          # Wait for Syncthing API to be ready with retry logic
          MAX_RETRIES=30
          RETRY_DELAY=2

          # Get API key from file, option, or config.xml
          ${if cfg.apiKeyFile != null then ''
            API_KEY=$(cat "${cfg.apiKeyFile}")
          '' else if cfg.apiKey != null then ''
            API_KEY="${cfg.apiKey}"
          '' else ''
            API_KEY=$(${pkgs.gnugrep}/bin/grep -m1 "<apikey>" "${cfg.configDir}/config.xml" | ${pkgs.gnused}/bin/sed 's/.*<apikey>\(.*\)<\/apikey>.*/\1/')
          ''}

          echo "Waiting for Syncthing API to be ready..."
          for i in $(${pkgs.coreutils}/bin/seq 1 $MAX_RETRIES); do
            if ${pkgs.curl}/bin/curl -sf -H "X-API-Key: $API_KEY" "${cfg.baseUrl}/rest/system/status" >/dev/null 2>&1; then
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

          # Build config JSON with secrets substituted from files
          CONFIG_FILE=$(mktemp)
          trap "rm -f $CONFIG_FILE" EXIT

          # Start building JSON
          GUI_JSON="null"
          ${optionalString (cfg.gui != null) ''
            USERNAME="${if cfg.gui.usernameFile != null then "__USERNAME__" else cfg.gui.username}"
            PASSWORD="${if cfg.gui.passwordFile != null then "__PASSWORD__" else cfg.gui.password}"

            ${optionalString (cfg.gui.usernameFile != null) ''
              USERNAME=$(cat ${cfg.gui.usernameFile})
            ''}

            ${optionalString (cfg.gui.passwordFile != null) ''
              PASSWORD=$(cat ${cfg.gui.passwordFile})
            ''}

            GUI_JSON=$(${pkgs.jq}/bin/jq -n \
              --arg username "$USERNAME" \
              --arg password "$PASSWORD" \
              '{username: $username, password: $password}')
          ''}

          ${if cfg.deviceDefinitionsFile != null then ''
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
          '' else ''
            # No device registry, devices must be empty
            DEVICES_JSON='{}'
          ''}

          FOLDERS_JSON='${builtins.toJSON cfg.folders}'
          ${optionalString (cfg.foldersFile != null) ''
            # Strip leading whitespace from each line and compact JSON
            FOLDERS_JSON=$(cat ${cfg.foldersFile} | ${pkgs.jq}/bin/jq -c .)
          ''}

          ${pkgs.jq}/bin/jq -n \
            --argjson gui "$GUI_JSON" \
            --argjson devices "$DEVICES_JSON" \
            --argjson folders "$FOLDERS_JSON" \
            '{gui: $gui, devices: $devices, folders: $folders}' > "$CONFIG_FILE"

          # Run declarative sync with API key
          ${if cfg.apiKeyFile != null || cfg.apiKey != null then ''
            ${pkgs.syncthing-mgmt}/bin/syncthing-mgmt declarative \
              --base-url "${cfg.baseUrl}" \
              --api-key "$API_KEY" \
              --config-file "$CONFIG_FILE" \
              ${optionalString cfg.restart "--restart"} 2>&1 || echo "Warning: Syncthing sync failed with exit code $?"
          '' else ''
            ${pkgs.syncthing-mgmt}/bin/syncthing-mgmt declarative \
              --base-url "${cfg.baseUrl}" \
              --config-xml "${cfg.configDir}/config.xml" \
              --config-file "$CONFIG_FILE" \
              ${optionalString cfg.restart "--restart"} 2>&1 || echo "Warning: Syncthing sync failed with exit code $?"
          ''}

          echo "Syncthing sync completed"
        '';
      in "${syncScript}";
    };
  };
}
