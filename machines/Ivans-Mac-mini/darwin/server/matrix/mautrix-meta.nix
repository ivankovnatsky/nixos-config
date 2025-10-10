{ config, pkgs, lib, ... }:

let
  serverName = "matrix.${config.secrets.externalDomain}";
  settingsFormat = pkgs.formats.json { };

  # Messenger configuration
  messengerDataDir = "/Volumes/Storage/Data/.matrix/bridges/messenger";
  messengerPort = 29324;
  messengerRegistrationFile = "${messengerDataDir}/messenger-registration.yaml";

  messengerConfig = {
    homeserver = {
      address = "http://127.0.0.1:8009";
      domain = serverName;
      software = "standard";
    };

    appservice = {
      address = "http://127.0.0.1:${toString messengerPort}";
      hostname = "127.0.0.1";
      port = messengerPort;

      id = "messenger";
      bot = {
        username = "facebookbot";
        displayname = "Messenger bridge bot";
        avatar = "mxc://maunium.net/ygtkteZsXnGJLJHRchUwYWak";
      };
      username_template = "facebook_{{.}}";
    };

    bridge = {
      command_prefix = "!fb";
      permissions = {
        "@${config.secrets.matrix.username}:${serverName}" = "admin";
        "*" = "relay";
      };
    };

    network = {
      mode = "messenger";
    };

    database = {
      type = "sqlite3-fk-wal";
      uri = "file:${messengerDataDir}/mautrix-meta.db?_txlock=immediate";
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

  messengerSettingsFileUnsubstituted = settingsFormat.generate "mautrix-meta-messenger-config.json" messengerConfig;
  messengerSettingsFile = "${messengerDataDir}/config.json";

  # Instagram configuration
  instagramDataDir = "/Volumes/Storage/Data/.matrix/bridges/instagram";
  instagramPort = 29325;
  instagramRegistrationFile = "${instagramDataDir}/instagram-registration.yaml";

  instagramConfig = {
    homeserver = {
      address = "http://127.0.0.1:8009";
      domain = serverName;
      software = "standard";
    };

    appservice = {
      address = "http://127.0.0.1:${toString instagramPort}";
      hostname = "127.0.0.1";
      port = instagramPort;

      id = "instagram";
      bot = {
        username = "instagrambot";
        displayname = "Instagram bridge bot";
        avatar = "mxc://maunium.net/JxjlbZUlCPULEeHZSwleUXQv";
      };
      username_template = "instagram_{{.}}";
    };

    bridge = {
      command_prefix = "!ig";
      permissions = {
        "@${config.secrets.matrix.username}:${serverName}" = "admin";
        "*" = "relay";
      };
    };

    network = {
      mode = "instagram";
    };

    database = {
      type = "sqlite3-fk-wal";
      uri = "file:${instagramDataDir}/mautrix-meta.db?_txlock=immediate";
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

  instagramSettingsFileUnsubstituted = settingsFormat.generate "mautrix-meta-instagram-config.json" instagramConfig;
  instagramSettingsFile = "${instagramDataDir}/config.json";

in
{
  # Messenger bridge
  launchd.user.agents.mautrix-meta-messenger = {
    serviceConfig = {
      Label = "org.nixos.mautrix-meta-messenger";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/agents/log/launchd/mautrix-meta-messenger.out.log";
      StandardErrorPath = "/tmp/agents/log/launchd/mautrix-meta-messenger.error.log";
      ThrottleInterval = 10;
    };

    command =
      let
        initScript = pkgs.writeShellScript "mautrix-meta-messenger-init" ''
          set -e

          # Create log directory
          mkdir -p /tmp/agents/log/launchd

          # Wait for the Storage volume to be mounted
          echo "Waiting for /Volumes/Storage to be available..."
          /bin/wait4path "/Volumes/Storage"
          echo "/Volumes/Storage is now available!"

          # Create data directory
          mkdir -p ${messengerDataDir}

          # Substitute the settings file
          test -f '${messengerSettingsFile}' && rm -f '${messengerSettingsFile}'
          old_umask=$(umask)
          umask 0177
          cp '${messengerSettingsFileUnsubstituted}' '${messengerSettingsFile}'
          umask $old_umask

          # Generate the appservice's registration file if absent
          if [ ! -f '${messengerRegistrationFile}' ]; then
            echo "Generating registration file..."
            ${pkgs.mautrix-meta}/bin/mautrix-meta \
              --generate-registration \
              --config='${messengerSettingsFile}' \
              --registration='${messengerRegistrationFile}'
          fi

          # Sync registration tokens back to config
          old_umask=$(umask)
          umask 0177
          ${pkgs.yq}/bin/yq -s '.[0].appservice.as_token = .[1].as_token
            | .[0].appservice.hs_token = .[1].hs_token
            | .[0]' \
            '${messengerSettingsFile}' '${messengerRegistrationFile}' > '${messengerSettingsFile}.tmp'
          mv '${messengerSettingsFile}.tmp' '${messengerSettingsFile}'
          umask $old_umask

          # Start bridge
          export HOME=${messengerDataDir}
          exec ${pkgs.mautrix-meta}/bin/mautrix-meta \
            --config='${messengerSettingsFile}'
        '';
      in
      "${initScript}";
  };

  # Instagram bridge
  launchd.user.agents.mautrix-meta-instagram = {
    serviceConfig = {
      Label = "org.nixos.mautrix-meta-instagram";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/agents/log/launchd/mautrix-meta-instagram.out.log";
      StandardErrorPath = "/tmp/agents/log/launchd/mautrix-meta-instagram.error.log";
      ThrottleInterval = 10;
    };

    command =
      let
        initScript = pkgs.writeShellScript "mautrix-meta-instagram-init" ''
          set -e

          # Create log directory
          mkdir -p /tmp/agents/log/launchd

          # Wait for the Storage volume to be mounted
          echo "Waiting for /Volumes/Storage to be available..."
          /bin/wait4path "/Volumes/Storage"
          echo "/Volumes/Storage is now available!"

          # Create data directory
          mkdir -p ${instagramDataDir}

          # Substitute the settings file
          test -f '${instagramSettingsFile}' && rm -f '${instagramSettingsFile}'
          old_umask=$(umask)
          umask 0177
          cp '${instagramSettingsFileUnsubstituted}' '${instagramSettingsFile}'
          umask $old_umask

          # Generate the appservice's registration file if absent
          if [ ! -f '${instagramRegistrationFile}' ]; then
            echo "Generating registration file..."
            ${pkgs.mautrix-meta}/bin/mautrix-meta \
              --generate-registration \
              --config='${instagramSettingsFile}' \
              --registration='${instagramRegistrationFile}'
          fi

          # Sync registration tokens back to config
          old_umask=$(umask)
          umask 0177
          ${pkgs.yq}/bin/yq -s '.[0].appservice.as_token = .[1].as_token
            | .[0].appservice.hs_token = .[1].hs_token
            | .[0]' \
            '${instagramSettingsFile}' '${instagramRegistrationFile}' > '${instagramSettingsFile}.tmp'
          mv '${instagramSettingsFile}.tmp' '${instagramSettingsFile}'
          umask $old_umask

          # Start bridge
          export HOME=${instagramDataDir}
          exec ${pkgs.mautrix-meta}/bin/mautrix-meta \
            --config='${instagramSettingsFile}'
        '';
      in
      "${initScript}";
  };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "mautrix-meta-show-registrations" ''
      echo "=== Messenger Bridge ==="
      if [ ! -f ${messengerRegistrationFile} ]; then
        echo "Registration file not found. Start mautrix-meta-messenger service first."
      else
        echo "Registration file: ${messengerRegistrationFile}"
      fi

      echo ""
      echo "=== Instagram Bridge ==="
      if [ ! -f ${instagramRegistrationFile} ]; then
        echo "Registration file not found. Start mautrix-meta-instagram service first."
      else
        echo "Registration file: ${instagramRegistrationFile}"
      fi

      echo ""
      echo "Add these to Synapse's homeserver.yaml:"
      echo ""
      echo "app_service_config_files:"
      echo "  - ${messengerRegistrationFile}"
      echo "  - ${instagramRegistrationFile}"
      echo ""
      echo "Then restart matrix-synapse service."
    '')
  ];
}
