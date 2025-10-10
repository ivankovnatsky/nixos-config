{ config, pkgs, lib, ... }:

let
  dataDir = "/Volumes/Storage/Data/.matrix/bridges/discord";
  serverName = "matrix.${config.secrets.externalDomain}";
  port = 29323;
  registrationFile = "${dataDir}/discord-registration.yaml";
  settingsFormat = pkgs.formats.json { };

  # NOTE: If you change the port, you must manually delete the registration file:
  #   rm /Volumes/Storage/Data/.matrix/bridges/discord/discord-registration.yaml
  # Then restart both the bridge and Synapse services to regenerate with the new port.

  bridgeConfig = {
    homeserver = {
      address = "http://127.0.0.1:8009";
      domain = serverName;
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
        "@${config.secrets.matrix.username}:${serverName}" = "admin";
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

          # Create log directory
          mkdir -p /tmp/agents/log/launchd

          # Wait for the Storage volume to be mounted
          echo "Waiting for /Volumes/Storage to be available..."
          /bin/wait4path "/Volumes/Storage"
          echo "/Volumes/Storage is now available!"

          # Create data directory
          mkdir -p ${dataDir}

          # Substitute the settings file
          test -f '${settingsFile}' && rm -f '${settingsFile}'
          old_umask=$(umask)
          umask 0177
          cp '${settingsFileUnsubstituted}' '${settingsFile}'
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
