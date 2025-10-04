#!/usr/bin/env python3

# temperatures.py - Monitor and record maximum temperatures from sensors
#
# This script monitors system temperatures using the 'sensors' command,
# records the maximum temperatures observed, and saves them to a log file.
#
# Usage: temperatures [interval] [logfile]
#   interval: Optional - Time between checks in seconds (default: 2)
#   logfile: Optional - Path to log file (default: /tmp/temperatures-max.json)

import json
import os
import platform
import subprocess
import sys
import time
from datetime import datetime
import signal

# Check if running on Linux
if platform.system() != "Linux":
    print("Error: This script only works on Linux systems")
    sys.exit(1)

# Check if sensors command is available
try:
    subprocess.run(
        ["sensors", "--version"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=True,
    )
except (subprocess.SubprocessError, FileNotFoundError):
    print('Error: "sensors" command not found. Please install lm_sensors package.')
    sys.exit(1)

# Default values
INTERVAL = 2
if len(sys.argv) > 1:
    try:
        INTERVAL = float(sys.argv[1])
    except ValueError:
        print(f'Error: Invalid interval "{sys.argv[1]}". Using default: {INTERVAL}s')

# Set log file location
LOG_FILE = "/tmp/temperatures-max.json"
if len(sys.argv) > 2:
    LOG_FILE = sys.argv[2]

# Initialize max temperatures dictionary
max_temps = {}
# Clean up existing log file on start
if os.path.exists(LOG_FILE):
    os.remove(LOG_FILE)
    print(f"Cleaned up existing log file: {LOG_FILE}")


# Function to get current temperatures as JSON
def get_temperatures():
    result = subprocess.run(
        ["sensors", "-j"], stdout=subprocess.PIPE, text=True, check=True
    )
    return json.loads(result.stdout)


# Function to update max temperatures
def update_max_temps(current_data):
    updated = False

    # Process each chip
    for chip_name, chip_data in current_data.items():
        if "Adapter" in chip_data:  # Skip adapter info
            chip_data.pop("Adapter")

        # Process each sensor in the chip
        for sensor_name, sensor_data in chip_data.items():
            # Look for temperature inputs
            for key, value in sensor_data.items():
                if "temp" in key and "input" in key and isinstance(value, (int, float)):
                    # Create a unique identifier for this temperature sensor
                    sensor_id = f"{chip_name}.{sensor_name}.{key}"

                    # Check if we have a record for this sensor
                    if sensor_id not in max_temps:
                        max_temps[sensor_id] = {
                            "max_temp": value,
                            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                            "chip": chip_name,
                            "sensor": sensor_name,
                            "key": key,
                        }
                        print(f"New sensor: {sensor_id} at {value}°C")
                        updated = True
                    elif value > max_temps[sensor_id]["max_temp"]:
                        old_max = max_temps[sensor_id]["max_temp"]
                        max_temps[sensor_id]["max_temp"] = value
                        max_temps[sensor_id]["timestamp"] = datetime.now().strftime(
                            "%Y-%m-%d %H:%M:%S"
                        )
                        print(f"New max for {sensor_id}: {value}°C (was {old_max}°C)")
                        updated = True

    # Save updated max temperatures
    if updated:
        with open(LOG_FILE, "w") as f:
            json.dump(max_temps, f, indent=2)

    return updated


# Function to display current temperatures in a nice format
def display_temperatures(current_data):
    os.system("clear")
    print(f"Every {INTERVAL}s: sensors")
    print(datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    print()

    # Run sensors command for display
    subprocess.run(["sensors"], check=True)

    print("\nMAXIMUM TEMPERATURES:")
    print("=" * 80)
    print(f"{'SENSOR':<40} {'MAX TEMP':<10} {'RECORDED AT':<20}")
    print("-" * 80)

    # Sort by temperature (highest first)
    sorted_temps = sorted(
        max_temps.items(), key=lambda x: x[1]["max_temp"], reverse=True
    )

    for sensor_id, data in sorted_temps:
        print(f"{sensor_id:<40} {data['max_temp']:>8.1f}°C {data['timestamp']:>20}")


# Handle Ctrl+C gracefully
def signal_handler(sig, frame):
    print("\nMonitoring stopped.")
    print(f"Maximum temperatures saved to {LOG_FILE}")
    sys.exit(0)


signal.signal(signal.SIGINT, signal_handler)

# Main monitoring loop
print("Starting temperature monitoring...")
print("Press Ctrl+C to stop")
print(f"Maximum temperatures will be saved to {LOG_FILE}")
print()

while True:
    # Get current temperatures
    current_data = get_temperatures()

    # Update max temperatures
    updated = update_max_temps(current_data)

    # Display current temperatures
    display_temperatures(current_data)

    # Wait for next check
    time.sleep(INTERVAL)
