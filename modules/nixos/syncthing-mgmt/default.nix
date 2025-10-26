{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.local.services.syncthing-mgmt;

  configJson = pkgs.writeText "syncthing-config.json" (builtins.toJSON {
    gui = optionalAttrs (cfg.gui != null) {
      username = cfg.gui.username;
      password = cfg.gui.password;
    };
    devices = cfg.devices;
  });
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
      default = "/var/lib/syncthing/.config/syncthing";
      description = "Path to Syncthing config directory (for reading config.xml)";
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
      type = types.attrsOf types.str;
      default = {};
      example = {
        "Device-Name" = "AAAA111-BBBB222-CCCC333-DDDD444-EEEE555-FFFF666-GGGG777-HHHH888";
      };
      description = "Devices to add to Syncthing (name = device ID)";
    };

    devicesFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/run/secrets/syncthing-devices.json";
      description = "Path to JSON file containing devices (alternative to devices option)";
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
            description = "List of device IDs to share this folder with";
          };
        };
      });
      default = {};
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
        assertion = cfg.gui != null -> (
          (cfg.gui.username != null) != (cfg.gui.usernameFile != null) &&
          (cfg.gui.password != null) != (cfg.gui.passwordFile != null)
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

          DEVICES_JSON='${builtins.toJSON cfg.devices}'
          ${optionalString (cfg.devicesFile != null) ''
            # Strip leading whitespace from each line and compact JSON
            DEVICES_JSON=$(cat ${cfg.devicesFile} | ${pkgs.jq}/bin/jq -c .)
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

          ${pkgs.syncthing-mgmt}/bin/syncthing-mgmt sync \
            --base-url "${cfg.baseUrl}" \
            --config-xml "${cfg.configDir}/config.xml" \
            --config-file "$CONFIG_FILE" \
            ${optionalString cfg.restart "--restart"} || echo "Warning: Syncthing sync failed"
        '';
      };
    };
  };
}
