{ config, lib, ... }:
{
  sops.secrets.postgres-monitoring-password = {
    key = "postgres/monitoring/password";
    owner = "postgres";
    group = "postgres";
  };

  services.matrix-synapse = {
    enable = true;
    settings = {
      server_name = "matrix.${config.secrets.externalDomain}";

      listeners = [
        {
          port = 8008;
          bind_addresses = [ config.flags.beeIp ];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = [
            {
              names = [
                "client"
                "federation"
              ];
              compress = false;
            }
          ];
        }
      ];

      database = {
        name = "psycopg2";
        args = {
          database = "matrix-synapse";
          user = "matrix-synapse";
        };
        # Allow en_US.UTF-8 collation instead of C (common on NixOS)
        allow_unsafe_locale = true;
      };

      enable_registration = true;
      enable_registration_without_verification = true;
      # NOTE: registration_shared_secret should be set via extraConfigFiles
      # to avoid storing it in Nix store. For now, you can temporarily set
      # a secret here for initial user registration, then remove it and use
      # the matrix-synapse-register_new_matrix_user command instead.
      # Generate with: pwgen -s 64 1
      registration_shared_secret = "";

      url_preview_enabled = false;
    };

    # Optional: For production, use extraConfigFiles for secrets
    # extraConfigFiles = [
    #   "/var/lib/matrix-synapse/secrets.yaml"
    # ];
  };

  # PostgreSQL database for Synapse (not auto-configured by module)
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "matrix-synapse" ];
    ensureUsers = [
      {
        name = "matrix-synapse";
        ensureDBOwnership = true;
      }
      {
        name = "postgres_monitor";
      }
    ];
    # Enable network access for monitoring (listens on localhost + bee IP only)
    enableTCPIP = true;
    settings = {
      listen_addresses = lib.mkForce "127.0.0.1,${config.flags.beeIp}";
    };
    # Allow connections from Tailscale network for monitoring
    authentication = ''
      host all postgres_monitor ${config.flags.miniIp}/32 scram-sha-256
      host all postgres_monitor 127.0.0.1/32 trust
    '';
  };

  # Create dedicated monitoring user with limited privileges
  # This service runs only once, creating a stamp file to prevent re-execution
  systemd.services.postgresql-setup-monitoring = {
    description = "Setup PostgreSQL monitoring user with limited privileges";
    after = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig = {
      ConditionPathExists = "!/var/lib/postgresql/.monitoring-setup-done";
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "postgres";
      Group = "postgres";
    };
    script = ''
      PASSWORD=$(cat ${config.sops.secrets.postgres-monitoring-password.path})
      ${config.services.postgresql.package}/bin/psql -c "ALTER USER postgres_monitor WITH PASSWORD '$PASSWORD';" || true
      ${config.services.postgresql.package}/bin/psql -c "GRANT pg_monitor TO postgres_monitor;" || true
      touch /var/lib/postgresql/.monitoring-setup-done
    '';
  };

  # Not auto-configured by module
  networking.firewall.allowedTCPPorts = [
    8008 # Matrix Synapse
    5432 # PostgreSQL (for monitoring from mini)
  ];

  # Wait for network to be online before starting (DHCP must assign IP first)
  systemd.services.postgresql = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };

  systemd.services.matrix-synapse = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };
}
