{ config, pkgs, lib, ... }:

let
  dataDir = "/Volumes/Storage/Data/.matrix/core/synapse";
  serverName = "matrix.${config.secrets.externalDomain}";
  format = pkgs.formats.yaml { };

  synapseConfig = {
    server_name = serverName;
    report_stats = false;

    listeners = [
      {
        port = 8009;
        bind_addresses = [ "127.0.0.1" ];
        type = "http";
        tls = false;
        x_forwarded = true;
        resources = [
          {
            names = [ "client" "federation" ];
            compress = false;
          }
        ];
      }
    ];

    database = {
      name = "psycopg2";
      args = {
        database = "matrix_synapse";
        user = "matrix_synapse";
        host = "/tmp";
        port = 5433;
      };
      allow_unsafe_locale = true;
    };

    enable_registration = true;
    enable_registration_without_verification = true;

    url_preview_enabled = false;

    log_config = "${dataDir}/log.config";
    signing_key_path = "${dataDir}/signing.key";
    media_store_path = "${dataDir}/media_store";

    app_service_config_files = [
      "/Volumes/Storage/Data/.matrix/bridges/whatsapp/whatsapp-registration.yaml"
    ];
  };

  configFile = format.generate "homeserver.yaml" synapseConfig;

  logConfig = pkgs.writeText "log.config" ''
    version: 1
    formatters:
      precise:
        format: '%(asctime)s - %(name)s - %(lineno)d - %(levelname)s - %(request)s - %(message)s'
    handlers:
      file:
        class: logging.handlers.RotatingFileHandler
        formatter: precise
        filename: ${dataDir}/homeserver.log
        maxBytes: 104857600
        backupCount: 10
        encoding: utf8
      console:
        class: logging.StreamHandler
        formatter: precise
    loggers:
      synapse:
        level: INFO
      synapse.storage.SQL:
        level: INFO
    root:
      level: INFO
      handlers: [file, console]
    disable_existing_loggers: false
  '';

in
{
  launchd.user.agents.matrix-synapse = {
    serviceConfig = {
      Label = "org.nixos.matrix-synapse";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/agents/log/launchd/matrix-synapse.out.log";
      StandardErrorPath = "/tmp/agents/log/launchd/matrix-synapse.error.log";
      ThrottleInterval = 10;
    };

    command =
      let
        synapsePackage = pkgs.matrix-synapse.override {
          extras = [ "postgres" "url-preview" ];
        };

        initScript = pkgs.writeShellScript "matrix-synapse-init" ''
          set -e

          # Create log directory
          mkdir -p /tmp/agents/log/launchd

          # Wait for the Storage volume to be mounted
          echo "Waiting for /Volumes/Storage to be available..."
          /bin/wait4path "/Volumes/Storage"
          echo "/Volumes/Storage is now available!"

          # Wait for PostgreSQL to be available
          echo "Waiting for PostgreSQL..."
          until [ -S /tmp/.s.PGSQL.5433 ]; do
            echo "PostgreSQL is unavailable - sleeping"
            sleep 1
          done
          echo "PostgreSQL socket found!"
          sleep 2
          echo "PostgreSQL is up!"

          # Setup database and user (idempotent)
          echo "Setting up Matrix database..."
          ${pkgs.postgresql}/bin/psql -h /tmp -p 5433 -U postgres postgres <<'EOSQL' || true
          ${builtins.readFile ./setup-matrix-db.sql}
          EOSQL
          echo "Database setup complete!"

          # Create data directory
          mkdir -p ${dataDir}
          mkdir -p ${dataDir}/media_store

          # Initialize database if needed
          if [ ! -f ${dataDir}/homeserver.yaml ]; then
            echo "Generating Synapse config..."
            ${synapsePackage}/bin/synapse_homeserver \
              --config-path ${configFile} \
              --generate-config \
              --server-name ${serverName} \
              --data-directory ${dataDir} \
              --report-stats no
          fi

          # Copy our configuration (make writable)
          cp ${configFile} ${dataDir}/homeserver.yaml
          chmod 644 ${dataDir}/homeserver.yaml
          cp ${logConfig} ${dataDir}/log.config

          # Start Synapse
          exec ${synapsePackage}/bin/synapse_homeserver \
            --config-path ${dataDir}/homeserver.yaml
        '';
      in
      "${initScript}";
  };
}
