{ config, pkgs, ... }:
{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
    dataDir = "/Volumes/Storage/Data/.postgresql/${config.services.postgresql.package.psqlSchema}";
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

      # Wait for the Storage volume to be mounted
      echo "Waiting for /Volumes/Storage to be available..."
      /bin/wait4path "/Volumes/Storage"
      echo "/Volumes/Storage is now available!"
    '';
  };
}
