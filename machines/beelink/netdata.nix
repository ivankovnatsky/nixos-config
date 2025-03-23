{ pkgs, config, ... }:
{
  # Enable the Netdata service with enhanced settings
  services.netdata = {
    enable = true;

    # package = pkgs.netdataCloud;

    # Configure claim token file for Netdata Cloud
    # claimTokenFile = "/etc/secrets/netdata_claim_token";

    # TODO: https://learn.netdata.cloud/docs/netdata-agent/database#monitoring-retention-utilization
    # TODO: https://www.netdata.cloud/blog/long-term-data-retention/#retention-configuration
    config = {
      # Global settings
      global = {
        "debug log" = "syslog";
        "error log" = "syslog";
        "access log" = "syslog";
      };

      # Disable FREEIPMI plugin (not needed for desktop/mini PCs)
      # I still see errors in the logs somehow:
      # ```console
      #
      # [ivan@beelink:/etc/netdata]$ journalctl -u netdata --since "1 minute ago" | grep -i sensor
      # Mar 08 11:29:01 beelink netdata[58962]: level=info msg=stopped plugin=go.d collector=sensors job=sensors
      # Mar 08 11:29:13 beelink freeipmi.plugin[69312]: ipmi_monitoring_sensor_readings_by_record_id(): internal system error
      # Mar 08 11:29:13 beelink freeipmi.plugin[69312]: ipmi_monitoring_sensor_readings_by_record_id(): internal system error
      # Mar 08 11:29:13 beelink netdata[69303]: level=info msg="check success" plugin=go.d collector=sensors job=sensors
      # Mar 08 11:29:13 beelink netdata[69303]: level=info msg="started, data collection interval 2s" plugin=go.d collector=sensors job=sensors
      # Mar 08 11:29:14 beelink freeipmi.plugin[69312]: ipmi_monitoring_sensor_readings_by_record_id(): internal system error
      # Mar 08 11:29:14 beelink charts.d.plugin[69420]: sensors: is disabled. Add a line with sensors=force in '/etc/netdata/conf.d/charts.d.plugin.conf' to enable it (or remove the line that disables it).
      # Mar 08 11:29:14 beelink freeipmi.plugin[69312]: ipmi_monitoring_sensor_readings_by_record_id(): internal system error
      # Mar 08 11:29:14 beelink freeipmi.plugin[69312]: ipmi_monitoring_sensor_readings_by_record_id(): internal system error
      # Mar 08 11:29:14 beelink freeipmi.plugin[69312]: main(): sensors failed to initialize. Calling DISABLE.
      # ```
      "plugin:freeipmi" = {
        "enabled" = "no";
      };
    };

    # Create essential config files for plugins
    # https://learn.netdata.cloud/docs/collecting-metrics/hardware-devices-and-sensors/linux-sensors#default-behavior
    configDir = {
      # Configure go.d sensors module
      "go.d/sensors.conf" = pkgs.writeText "go.d-sensors.conf" ''
        # Go.d plugin sensors configuration
        update_every: 2
        jobs:
          - name: sensors
            binary_path: ${pkgs.lm_sensors}/bin/sensors
      '';
    };
  };

  # Open firewall port for Netdata web interface
  networking.firewall = {
    allowedTCPPorts = [ 19999 ];
  };

  # Create the opt-out file in the Netdata configuration directory
  # https://learn.netdata.cloud/docs/netdata-agent/anonymous-telemetry-events
  environment.etc."netdata/.opt-out-from-anonymous-statistics".text = "";

  # Create the claim token file using environment.etc
  # environment.etc."secrets/netdata_claim_token" = {
  #   text = config.secrets.netdataCloudToken;
  #   mode = "0600";
  #   user = "root";
  #   group = "root";
  # };
}
