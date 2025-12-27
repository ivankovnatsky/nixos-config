{ config, pkgs, lib, username, ... }:

let
  dataDir = "${config.flags.miniStoragePath}/.matrix/core/synapse";
  format = pkgs.formats.yaml { };

  # Base config without server_name (will be added at runtime)
  synapseConfig = {
    report_stats = false;

    listeners = [
      {
        port = 8009;
        bind_addresses = [ config.flags.miniIp ];
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
      "${config.flags.miniStoragePath}/.matrix/bridges/whatsapp/whatsapp-registration.yaml"
      "${config.flags.miniStoragePath}/.matrix/bridges/discord/discord-registration.yaml"
      "${config.flags.miniStoragePath}/.matrix/bridges/messenger/messenger-registration.yaml"
      "${config.flags.miniStoragePath}/.matrix/bridges/instagram/instagram-registration.yaml"
      "${config.flags.miniStoragePath}/.matrix/bridges/linkedin/linkedin-registration.yaml"
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
  # Sops secrets for Matrix services (used by all Matrix services)
  sops.secrets.matrix-username = {
    key = "matrix/username";
    owner = username;
    mode = "0444"; # Readable by user services
  };

  local.launchd.services.matrix-synapse = {
    enable = true;
    waitForPath = config.flags.miniStoragePath;
    dataDir = dataDir;
    extraDirs = [ "${dataDir}/media_store" ];

    preStart =
      let
        synapsePackage = pkgs.matrix-synapse.override {
          extras = [ "postgres" "url-preview" ];
        };
      in
      ''
        # Read secrets from sops
        EXTERNAL_DOMAIN=$(cat ${config.sops.secrets.external-domain.path})
        SERVER_NAME="matrix.$EXTERNAL_DOMAIN"

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
        ${builtins.readFile ./setup-db.sql}
        EOSQL
        echo "Database setup complete!"

        # Generate config with server_name from sops at runtime
        # Add server_name to the base config
        cat ${configFile} > /tmp/synapse-config-temp.yaml
        echo "server_name: $SERVER_NAME" >> /tmp/synapse-config-temp.yaml

        # Initialize database if needed
        if [ ! -f ${dataDir}/homeserver.yaml ]; then
          echo "Generating Synapse config..."
          ${synapsePackage}/bin/synapse_homeserver \
            --config-path /tmp/synapse-config-temp.yaml \
            --generate-config \
            --server-name "$SERVER_NAME" \
            --data-directory ${dataDir} \
            --report-stats no
        fi

        # Copy our configuration (make writable) with server_name
        cp /tmp/synapse-config-temp.yaml ${dataDir}/homeserver.yaml
        chmod 644 ${dataDir}/homeserver.yaml
        cp ${logConfig} ${dataDir}/log.config
      '';

    command =
      let
        synapsePackage = pkgs.matrix-synapse.override {
          extras = [ "postgres" "url-preview" ];
        };
      in
      "${synapsePackage}/bin/synapse_homeserver --config-path ${dataDir}/homeserver.yaml";
  };
}
