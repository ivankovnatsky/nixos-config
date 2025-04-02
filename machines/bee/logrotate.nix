{ config, lib, pkgs, ... }:

{
  # Configure log rotation for various log files
  services.logrotate = {
    enable = true;
    settings = {
      dnsmasq = {
        files = "/var/log/dnsmasq/*.log";
        frequency = "daily";
        rotate = 7;
        compress = true;
        delaycompress = true;
        notifempty = true;
        create = "0644 dnsmasq dnsmasq";
      };
    };
  };
} 
