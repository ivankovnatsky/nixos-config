{ config, lib, pkgs, ... }:

{
  # Fan control via ACPI thermal cooling devices
  # Reads temperature from: /sys/class/hwmon/hwmon1/temp1_input (coretemp)
  # Controls fans via: /sys/class/thermal/cooling_device{4-8}/cur_state

  # Create a systemd service to control fan based on CPU temperature
  # Fan turns on at 85°C and turns off at 80°C (hysteresis to prevent rapid cycling)

  systemd.services.fan-control = {
    description = "ACPI Fan Temperature Control";
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.bash}/bin/bash ${pkgs.writeScript "fan-control.sh" ''
        #!/usr/bin/env bash
        set -euo pipefail

        # Configuration
        TEMP_HIGH=85000  # Temperature in millidegrees Celsius to turn fan ON (85°C)
        TEMP_LOW=80000   # Temperature in millidegrees Celsius to turn fan OFF (80°C)
        CHECK_INTERVAL=5 # Check every 5 seconds

        # Paths
        TEMP_SENSOR="/sys/class/hwmon/hwmon1/temp1_input"  # Package temperature from coretemp
        FAN_DEVICES=(
          "/sys/class/thermal/cooling_device4/cur_state"
          "/sys/class/thermal/cooling_device5/cur_state"
          "/sys/class/thermal/cooling_device6/cur_state"
          "/sys/class/thermal/cooling_device7/cur_state"
          "/sys/class/thermal/cooling_device8/cur_state"
        )

        # Function to set fan state (0=off, 1=on)
        set_fan_state() {
          local state=$1
          for fan in "''${FAN_DEVICES[@]}"; do
            if [[ -w "$fan" ]]; then
              echo "$state" > "$fan"
            fi
          done
        }

        # Function to get current temperature
        get_temp() {
          if [[ -r "$TEMP_SENSOR" ]]; then
            cat "$TEMP_SENSOR"
          else
            echo "0"
          fi
        }

        echo "Starting fan control service..."
        echo "Fan ON threshold: $((TEMP_HIGH / 1000))°C"
        echo "Fan OFF threshold: $((TEMP_LOW / 1000))°C"

        fan_state=0  # Track current fan state

        while true; do
          temp=$(get_temp)

          if [[ $temp -ge $TEMP_HIGH ]] && [[ $fan_state -eq 0 ]]; then
            echo "Temperature $((temp / 1000))°C >= $((TEMP_HIGH / 1000))°C - Turning fan ON"
            set_fan_state 1
            fan_state=1
          elif [[ $temp -le $TEMP_LOW ]] && [[ $fan_state -eq 1 ]]; then
            echo "Temperature $((temp / 1000))°C <= $((TEMP_LOW / 1000))°C - Turning fan OFF"
            set_fan_state 0
            fan_state=0
          fi

          sleep "$CHECK_INTERVAL"
        done
      ''}";
      Restart = "always";
      RestartSec = "10s";
    };
  };
}
