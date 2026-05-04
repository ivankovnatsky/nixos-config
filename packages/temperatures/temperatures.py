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

import click

# Initialize max temperatures dictionary
max_temps = {}


# Function to get current temperatures as JSON
def get_temperatures():
    result = subprocess.run(
        ["sensors", "-j"], stdout=subprocess.PIPE, text=True, check=True
    )
    return json.loads(result.stdout)


# Function to update max temperatures
def update_max_temps(current_data, logfile):
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
                        click.echo(f"New sensor: {sensor_id} at {value}°C")
                        updated = True
                    elif value > max_temps[sensor_id]["max_temp"]:
                        old_max = max_temps[sensor_id]["max_temp"]
                        max_temps[sensor_id]["max_temp"] = value
                        max_temps[sensor_id]["timestamp"] = datetime.now().strftime(
                            "%Y-%m-%d %H:%M:%S"
                        )
                        click.echo(
                            f"New max for {sensor_id}: {value}°C (was {old_max}°C)"
                        )
                        updated = True

    # Save updated max temperatures
    if updated:
        with open(logfile, "w") as f:
            json.dump(max_temps, f, indent=2)

    return updated


# Function to display current temperatures in a nice format
def display_temperatures(current_data, interval):
    click.clear()
    click.echo(f"Every {interval}s: sensors")
    click.echo(datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    click.echo()

    # Run sensors command for display
    subprocess.run(["sensors"], check=True)

    click.echo("\nMAXIMUM TEMPERATURES:")
    click.echo("=" * 80)
    click.echo(f"{'SENSOR':<40} {'MAX TEMP':<10} {'RECORDED AT':<20}")
    click.echo("-" * 80)

    # Sort by temperature (highest first)
    sorted_temps = sorted(
        max_temps.items(), key=lambda x: x[1]["max_temp"], reverse=True
    )

    for sensor_id, data in sorted_temps:
        click.echo(
            f"{sensor_id:<40} {data['max_temp']:>8.1f}°C {data['timestamp']:>20}"
        )


# Handle Ctrl+C gracefully
def signal_handler(sig, frame):
    click.echo("\nMonitoring stopped.")
    sys.exit(0)


@click.command()
@click.argument("interval", default=2.0, type=float)
@click.argument("logfile", default="/tmp/temperatures-max.json", type=click.Path())
def main(interval, logfile):
    """Monitor and record maximum temperatures from sensors."""
    # Check if running on Linux
    if platform.system() != "Linux":
        click.echo("Error: This script only works on Linux systems", err=True)
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
        click.echo(
            'Error: "sensors" command not found. Please install lm_sensors package.',
            err=True,
        )
        sys.exit(1)

    # Clean up existing log file on start
    if os.path.exists(logfile):
        os.remove(logfile)
        click.echo(f"Cleaned up existing log file: {logfile}")

    signal.signal(signal.SIGINT, signal_handler)

    # Main monitoring loop
    click.echo("Starting temperature monitoring...")
    click.echo(f"Maximum temperatures will be saved to {logfile}")
    click.echo()

    while True:
        # Get current temperatures
        current_data = get_temperatures()

        # Update max temperatures
        update_max_temps(current_data, logfile)

        # Display current temperatures
        display_temperatures(current_data, interval)

        # Wait for next check
        time.sleep(interval)


if __name__ == "__main__":
    main()
