#!/usr/bin/env python3

import os
import sys
import time
import glob
import signal
from datetime import datetime

INTERVAL = 2
if len(sys.argv) > 1:
    try:
        INTERVAL = float(sys.argv[1])
    except ValueError:
        print(f'Error: Invalid interval "{sys.argv[1]}". Using default: {INTERVAL}s')


def read_file(path):
    try:
        with open(path) as f:
            return f.read().strip()
    except (OSError, IOError):
        return None


def get_rapl_power(interval):
    """Measure CPU power via RAPL energy counters over an interval."""
    rapl_base = "/sys/class/powercap"
    domains = {}

    # Find all RAPL domains via the actual device hierarchy (not flat symlinks)
    device_base = "/sys/devices/virtual/powercap/intel-rapl"
    for pkg in sorted(glob.glob(f"{device_base}/intel-rapl:[0-9]*")):
        name = read_file(f"{pkg}/name")
        energy = read_file(f"{pkg}/energy_uj")
        if name and energy:
            domains[pkg] = {"name": name, "energy_start": int(energy)}

        # Sub-domains (e.g., core, uncore, dram)
        for sub in sorted(glob.glob(f"{pkg}/intel-rapl:*")):
            if not os.path.isdir(sub):
                continue
            sub_name = read_file(f"{sub}/name")
            sub_energy = read_file(f"{sub}/energy_uj")
            if sub_name and sub_energy:
                domains[sub] = {"name": sub_name, "energy_start": int(sub_energy)}

    if not domains:
        return []

    time.sleep(interval)

    results = []
    for path, info in domains.items():
        energy_end = read_file(f"{path}/energy_uj")
        if energy_end:
            diff = int(energy_end) - info["energy_start"]
            # Handle counter wrap
            if diff < 0:
                max_range = read_file(f"{path}/max_energy_range_uj")
                if max_range:
                    diff += int(max_range)
            watts = diff / (interval * 1_000_000)
            results.append((info["name"], watts))

    return results


def get_gpu_power():
    """Read GPU power from hwmon and nvidia-smi."""
    results = []

    # Check hwmon for amdgpu
    for hwmon in glob.glob("/sys/class/hwmon/hwmon*"):
        name = read_file(f"{hwmon}/name")
        if name == "amdgpu":
            for power_file in ["power1_average", "power1_input"]:
                val = read_file(f"{hwmon}/{power_file}")
                if val:
                    watts = int(val) / 1_000_000
                    label = "AMD iGPU" if watts < 5 else "AMD GPU"
                    results.append((label, watts))
                    break

    # Check nvidia-smi
    try:
        import subprocess
        result = subprocess.run(
            ["nvidia-smi", "--query-gpu=name,power.draw", "--format=csv,noheader,nounits"],
            capture_output=True, text=True, timeout=5,
        )
        if result.returncode == 0:
            for line in result.stdout.strip().split("\n"):
                if line.strip():
                    parts = line.split(", ")
                    if len(parts) == 2:
                        gpu_name = parts[0].strip()
                        watts = float(parts[1].strip())
                        results.append((gpu_name, watts))
    except (FileNotFoundError, subprocess.TimeoutExpired, ValueError):
        pass

    return results


def display(rapl_results, gpu_results):
    os.system("clear")
    print(f"Power Consumption Monitor (every {INTERVAL}s)")
    print(datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    print()
    print(f"{'Component':<30} {'Power':>10}")
    print("-" * 42)

    total = 0.0

    for name, watts in rapl_results:
        print(f"  CPU {name:<26} {watts:>8.1f} W")
        total += watts

    for name, watts in gpu_results:
        print(f"  {name:<28} {watts:>8.1f} W")
        total += watts

    print("-" * 42)
    print(f"  {'Total (measured)':<28} {total:>8.1f} W")
    print()
    print("Note: Wall power will be higher (PSU losses, RAM, fans, storage)")


def signal_handler(sig, frame):
    print("\nStopped.")
    sys.exit(0)


signal.signal(signal.SIGINT, signal_handler)

# First iteration: measure RAPL inline
while True:
    rapl = get_rapl_power(min(INTERVAL, 1))
    gpu = get_gpu_power()
    display(rapl, gpu)
    remaining = INTERVAL - min(INTERVAL, 1)
    if remaining > 0:
        time.sleep(remaining)
