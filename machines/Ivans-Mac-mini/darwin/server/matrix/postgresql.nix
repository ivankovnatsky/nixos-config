{ config, pkgs, ... }:
{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
    dataDir = "${config.flags.miniStoragePath}/.postgresql/${config.services.postgresql.package.psqlSchema}";
    enableTCPIP = false;
    port = 5433;

    authentication = ''
      local all all trust
      host  all all 127.0.0.1/32 md5
      host  all all ::1/128      md5
    '';

    settings = {
      log_connections = true;
      log_disconnections = true;
      log_line_prefix = "[%p] ";
    };
  };

  launchd.user.agents.postgresql = {
    serviceConfig = {
      StandardOutPath = "/tmp/agents/log/launchd/postgresql.out.log";
      StandardErrorPath = "/tmp/agents/log/launchd/postgresql.error.log";
    };

    # Prepend wait4path for external volume to the script
    script = pkgs.lib.mkBefore ''
      # Create log directory
      mkdir -p /tmp/agents/log/launchd

      # Wait for the storage path to be available
      echo "Waiting for ${config.flags.miniStoragePath} to be available..."
      /bin/wait4path "${config.flags.miniStoragePath}"
      echo "${config.flags.miniStoragePath} is now available!"
    '';
  };
}
