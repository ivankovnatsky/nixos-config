{ config, pkgs, lib, ... }:

let
  dataDir = "/Volumes/Storage/Data/.matrix/bridges/discord";
  port = 29323;
  registrationFile = "${dataDir}/discord-registration.yaml";
  settingsFormat = pkgs.formats.json { };

  # NOTE: If you change the port, you must manually delete the registration file:
  #   rm /Volumes/Storage/Data/.matrix/bridges/discord/discord-registration.yaml
  # Then restart both the bridge and Synapse services to regenerate with the new port.

  # Base config without server_name and permissions (will be added at runtime)
  bridgeConfig = {
    homeserver = {
      address = "http://${config.flags.miniIp}:8009";
      # domain will be set at runtime
      software = "standard";
    };

    appservice = {
      address = "http://127.0.0.1:${toString port}";
      hostname = "127.0.0.1";
      port = port;

      id = "discord";
      bot = {
        username = "discordbot";
        displayname = "Discord Bridge Bot";
      };

      database = {
        type = "sqlite3";
        uri = "file:${dataDir}/mautrix-discord.db?_txlock=immediate";
      };
    };

    bridge = {
      command_prefix = "!discord";
      permissions = {
        # Permissions will be set at runtime
        "*" = "relay";
      };
    };

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

  settingsFileUnsubstituted = settingsFormat.generate "mautrix-discord-config.json" bridgeConfig;
  settingsFile = "${dataDir}/config.json";

in
{
  launchd.user.agents.mautrix-discord = {
    serviceConfig = {
      Label = "org.nixos.mautrix-discord";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/agents/log/launchd/mautrix-discord.out.log";
      StandardErrorPath = "/tmp/agents/log/launchd/mautrix-discord.error.log";
      ThrottleInterval = 10;
    };

    command =
      let
        initScript = pkgs.writeShellScript "mautrix-discord-init" ''
          set -e

          # Add lottieconverter and ffmpeg to PATH for sticker/media conversion
          export PATH="${pkgs.lottieconverter}/bin:${pkgs.ffmpeg-headless}/bin:$PATH"

          # Create log directory
          mkdir -p /tmp/agents/log/launchd

          # Wait for the Storage volume to be mounted
          echo "Waiting for /Volumes/Storage to be available..."
          /bin/wait4path "/Volumes/Storage"
          echo "/Volumes/Storage is now available!"

          # Read secrets from sops
          EXTERNAL_DOMAIN=$(cat ${config.sops.secrets.external-domain.path})
          MATRIX_USERNAME=$(cat ${config.sops.secrets.matrix-username.path})
          SERVER_NAME="matrix.$EXTERNAL_DOMAIN"
          ADMIN_USER="@$MATRIX_USERNAME:$SERVER_NAME"

          # Create data directory
          mkdir -p ${dataDir}

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
            ${pkgs.mautrix-discord}/bin/mautrix-discord \
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
          exec ${pkgs.mautrix-discord}/bin/mautrix-discord \
            --config='${settingsFile}'
        '';
      in
      "${initScript}";
  };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "mautrix-discord-show-registration" ''
      if [ ! -f ${registrationFile} ]; then
        echo "Registration file not found. Start mautrix-discord service first."
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
