{ config, pkgs, lib, ... }:

# NOTE: WhatsApp frequently requires bridge updates to maintain compatibility.
# If login fails with "Client outdated (405)" error, check for newer versions:
#   nix search nixpkgs mautrix-whatsapp
# Current version: 0.12.5-unstable-2025-10-04

let
  dataDir = "${config.flags.miniStoragePath}/.matrix/bridges/whatsapp";
  port = 29321;
  registrationFile = "${dataDir}/whatsapp-registration.yaml";
  settingsFormat = pkgs.formats.json { };

  # NOTE: If you change the port, you must manually delete the registration file:
  #   rm /Volumes/Storage/Data/.matrix/bridges/whatsapp/whatsapp-registration.yaml
  # Then restart both the bridge and Synapse services to regenerate with the new port.

  whatsappPackage = pkgs.mautrix-whatsapp.overrideAttrs (old: {
    version = "0.12.5-unstable-2025-10-04";
    src = pkgs.fetchFromGitHub {
      owner = "mautrix";
      repo = "whatsapp";
      rev = "425556d0fa511bd2c898469f55de10c98cd912f5";
      hash = "sha256-fzOPUdTM7mRhKBuGrGMuX2bokBpn4KdVclXjrAT4koM=";
    };
    vendorHash = "sha256-t3rvnKuuZe8j3blyQTANMoIdTc2n4XXri6qfjIgFR0A=";
  });

  # Base config without server_name and permissions (will be added at runtime)
  bridgeConfig = {
    homeserver = {
      address = "http://${config.flags.miniIp}:8009";
      # domain will be set at runtime
    };

    appservice = {
      address = "http://127.0.0.1:${toString port}";
      hostname = "127.0.0.1";
      port = port;

      id = "whatsapp";
      bot = {
        username = "whatsappbot";
        displayname = "WhatsApp Bridge Bot";
      };
      username_template = "whatsapp_{{.}}";
    };

    bridge = {
      command_prefix = "!wa";
      permissions = {
        # Permissions will be set at runtime
        "*" = "relay";
      };
      relay.enabled = true;
    };

    network = {
      displayname_template = "{{or .BusinessName .PushName .Phone}} (WA)";
      identity_change_notices = true;
      history_sync = {
        request_full_sync = true;
      };
    };

    database = {
      type = "sqlite3-fk-wal";
      uri = "file:${dataDir}/mautrix-whatsapp.db?_txlock=immediate";
    };

    double_puppet = {
      servers = { };
      secrets = { };
    };

    encryption.pickle_key = "";
    provisioning.shared_secret = "";
    public_media.signing_key = "";
    direct_media.server_key = "";

    logging = {
      min_level = "info";
      writers = [
        {
          type = "stdout";
          format = "pretty-colored";
          time_format = " ";
        }
      ];
    };
  };

  settingsFileUnsubstituted = settingsFormat.generate "mautrix-whatsapp-config.json" bridgeConfig;
  settingsFile = "${dataDir}/config.json";

in
{
  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];

  local.launchd.services.mautrix-whatsapp = {
    enable = true;
    waitForPath = config.flags.miniStoragePath;
    dataDir = dataDir;

    environment = {
      PATH = "${pkgs.ffmpeg-headless}/bin";
      HOME = dataDir;
    };

    preStart = ''
      # Read secrets from sops
      EXTERNAL_DOMAIN=$(cat ${config.sops.secrets.external-domain.path})
      MATRIX_USERNAME=$(cat ${config.sops.secrets.matrix-username.path})
      SERVER_NAME="matrix.$EXTERNAL_DOMAIN"
      ADMIN_USER="@$MATRIX_USERNAME:$SERVER_NAME"

      # Copy base config and update with runtime values
      test -f '${settingsFile}' && rm -f '${settingsFile}'
      old_umask=$(umask)
      umask 0177
      cp '${settingsFileUnsubstituted}' '${settingsFile}'

      # Update config with server_name and permissions using jq
      ${pkgs.jq}/bin/jq \
        --arg domain "$SERVER_NAME" \
        --arg admin "$ADMIN_USER" \
        '.homeserver.domain = $domain | .bridge.permissions[$admin] = "admin"' \
        '${settingsFile}' > '${settingsFile}.tmp'
      mv '${settingsFile}.tmp' '${settingsFile}'
      umask $old_umask

      # Generate the appservice's registration file if absent
      if [ ! -f '${registrationFile}' ]; then
        echo "Generating registration file..."
        ${whatsappPackage}/bin/mautrix-whatsapp \
          --generate-registration \
          --config='${settingsFile}' \
          --registration='${registrationFile}'
      fi

      # Sync registration tokens back to config
      old_umask=$(umask)
      umask 0177
      ${pkgs.yq}/bin/yq -s '.[0].appservice.as_token = .[1].as_token
        | .[0].appservice.hs_token = .[1].hs_token
        | .[0]' \
        '${settingsFile}' '${registrationFile}' > '${settingsFile}.tmp'
      mv '${settingsFile}.tmp' '${settingsFile}'
      umask $old_umask
    '';

    command = "${whatsappPackage}/bin/mautrix-whatsapp --config='${settingsFile}'";
  };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "mautrix-whatsapp-show-registration" ''
      if [ ! -f ${registrationFile} ]; then
        echo "Registration file not found. Start mautrix-whatsapp service first."
        exit 1
      fi

      echo "Registration file location: ${registrationFile}"
      echo ""
      echo "Add this to Synapse's homeserver.yaml:"
      echo ""
      echo "app_service_config_files:"
      echo "  - ${registrationFile}"
      echo ""
      echo "Then restart matrix-synapse service."
    '')
  ];
}
