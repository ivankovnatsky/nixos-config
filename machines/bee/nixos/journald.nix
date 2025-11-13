{ config
, lib
, pkgs
, ...
}:

{
  # Configure systemd-journald to limit log size
  services.journald = {
    # Enable persistent storage of logs
    extraConfig = ''
      # Store journal on disk
      Storage=persistent

      # Compress journal files
      Compress=yes

      # Split journals by user
      SplitMode=uid

      # Limit journal size to 100M (adjust as needed)
      SystemMaxUse=100M

      # Limit individual journal files to 10M
      SystemMaxFileSize=10M

      # Keep journals for 7 days max
      MaxRetentionSec=7day

      # Forward to syslog (if you're using it)
      # ForwardToSyslog=yes

      # Rate limiting: 1000 messages per 30 seconds per service
      RateLimitInterval=30s
      RateLimitBurst=1000
    '';
  };
}
