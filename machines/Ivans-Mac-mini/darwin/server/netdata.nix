{ config, ... }:
{
  services.netdata = {
    enable = true;
    # Store service stdout/stderr in /tmp
    logDir = "/tmp/log/netdata";

    # Explicitly configure Netdata to use /tmp for its logs
    config = ''
      [global]
      log directory = /tmp/log/netdata
      debug log = /tmp/log/netdata/debug.log
      error log = /tmp/log/netdata/error.log
      access log = /tmp/log/netdata/access.log
      bind to = ${config.flags.miniIp}

      # Reduce log verbosity
      [logs]
      debug log = info
      error log level = error

      [web]
      bind to = ${config.flags.miniIp}
    '';
  };

  # Create the opt-out file in the Netdata configuration directory
  environment.etc."netdata/.opt-out-from-anonymous-statistics".text = "";

  # Configure logrotate for netdata logs
  local.services.logrotate.settings = {
    # Standard log files
    netdata-logs = {
      files = "/tmp/log/netdata/*.log";
      rotate = 14; # Keep logs for 14 days
      size = "50M"; # Production size limit
      copytruncate = true; # Needed for netdata which keeps the file open
      create = "0640 root wheel";
      compress = true;
      # Immediate compression (no delaycompress)
      missingok = true;
      notifempty = true;
    };

    # Backup files - compressed immediately and removed after rotation
    netdata-backups = {
      files = "/tmp/log/netdata/*.backup";
      rotate = 1; # Keep only one backup at most
      size = "1K"; # Rotate even small backup files
      copytruncate = true;
      create = "0640 root wheel";
      compress = true;
      missingok = true;
      notifempty = false; # Rotate even empty backups
    };
  };
}
