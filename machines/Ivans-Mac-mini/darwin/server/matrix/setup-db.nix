{ config, pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "matrix-setup-db" ''
      set -e

      echo "Setting up Matrix Synapse database..."

      # Create database and user (using Unix socket peer auth)
      ${pkgs.postgresql}/bin/psql -h /tmp -p 5433 postgres <<EOF
      SELECT 'CREATE DATABASE matrix_synapse' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'matrix_synapse')\gexec
      DO \$\$
      BEGIN
        IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'matrix_synapse') THEN
          CREATE USER matrix_synapse;
        END IF;
      END
      \$\$;
      GRANT ALL PRIVILEGES ON DATABASE matrix_synapse TO matrix_synapse;
      ALTER DATABASE matrix_synapse OWNER TO matrix_synapse;
      EOF

      echo "Database setup complete!"
      echo ""
      echo "Next steps:"
      echo "1. Start matrix-synapse service"
      echo "2. Register a user with: matrix-synapse-register"
    '')
  ];
}
