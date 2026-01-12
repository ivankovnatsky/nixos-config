#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys
import time
from datetime import datetime


def log(msg: str) -> None:
    print(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} {msg}", flush=True)


def is_root() -> bool:
    return os.geteuid() == 0


def kill_processes(process_name: str) -> int:
    """Kill all processes matching the given name. Returns count of killed processes."""
    try:
        result = subprocess.run(
            ["pgrep", "-i", process_name],
            capture_output=True,
            text=True,
        )
        pids = [p.strip() for p in result.stdout.strip().split("\n") if p.strip()]

        if not pids:
            return 0

        killed = 0
        for pid in pids:
            try:
                if is_root():
                    subprocess.run(["kill", "-9", pid], check=True)
                else:
                    subprocess.run(["sudo", "kill", "-9", pid], check=True)
                log(f"killed PID {pid}")
                killed += 1
            except subprocess.CalledProcessError:
                pass

        return killed
    except subprocess.CalledProcessError:
        return 0


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Continuously prevent a process from running by killing it"
    )
    parser.add_argument("process_name", help="Name of the process to kill")
    parser.add_argument(
        "--interval",
        "-i",
        type=int,
        default=5,
        help="Interval between checks in seconds (default: 5)",
    )
    args = parser.parse_args()

    mode = "root" if is_root() else "user (via sudo)"
    log(
        f"started: blocking '{args.process_name}' (mode: {mode}, interval: {args.interval}s)"
    )

    try:
        while True:
            kill_processes(args.process_name)
            time.sleep(args.interval)
    except KeyboardInterrupt:
        log("stopped")
        sys.exit(0)


if __name__ == "__main__":
    main()
