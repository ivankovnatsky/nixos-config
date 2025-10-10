{ config, pkgs, lib, ... }:

# NOTE: WhatsApp frequently requires bridge updates to maintain compatibility.
# If login fails with "Client outdated (405)" error, check for newer versions:
#   nix search nixpkgs mautrix-whatsapp
# Current version: 0.12.5-unstable-2025-10-04

let
  dataDir = "/Volumes/Storage/Data/.matrix/bridges/whatsapp";
  serverName = "matrix.${config.secrets.externalDomain}";
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

  bridgeConfig = {
    homeserver = {
      address = "http://127.0.0.1:8009";
      domain = serverName;
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
        "@${config.secrets.matrix.username}:${serverName}" = "admin";
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

  launchd.user.agents.mautrix-whatsapp = {
    serviceConfig = {
      Label = "org.nixos.mautrix-whatsapp";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/agents/log/launchd/mautrix-whatsapp.out.log";
      StandardErrorPath = "/tmp/agents/log/launchd/mautrix-whatsapp.error.log";
      ThrottleInterval = 10;
    };

    command =
      let
        initScript = pkgs.writeShellScript "mautrix-whatsapp-init" ''
          set -e

          # Add ffmpeg to PATH for voice message conversion
          export PATH="${pkgs.ffmpeg-headless}/bin:$PATH"

          # Create log directory
          mkdir -p /tmp/agents/log/launchd

          # Wait for the Storage volume to be mounted
          echo "Waiting for /Volumes/Storage to be available..."
          /bin/wait4path "/Volumes/Storage"
          echo "/Volumes/Storage is now available!"

          # Create data directory
          mkdir -p ${dataDir}

          # Substitute the settings file (for future env var support)
          test -f '${settingsFile}' && rm -f '${settingsFile}'
          old_umask=$(umask)
          umask 0177
          cp '${settingsFileUnsubstituted}' '${settingsFile}'
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

          # Start bridge
          export HOME=${dataDir}
          exec ${whatsappPackage}/bin/mautrix-whatsapp \
            --config='${settingsFile}'
        '';
      in
      "${initScript}";
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
