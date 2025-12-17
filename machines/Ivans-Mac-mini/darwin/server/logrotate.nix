{ ... }:
{
  # Enable the logrotate service
  local.services.logrotate = {
    enable = true;
    frequency = "daily";

    # Global settings can be configured here if needed
    settings = {
      header = {
        # Override or add to the default global settings
        dateext = true;
        compress = true;
        nodelaycompress = true; # Force immediate compression for all log files
        notifempty = true;
        missingok = true;
        rotate = 7; # Default number of rotations to keep
      };
    };
  };
}
