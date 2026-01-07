#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys
import time


def is_root() -> bool:
    return os.geteuid() == 0


def kill_processes(process_name: str, verbose: bool = False) -> int:
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
                killed += 1
                if verbose:
                    print(f"Killed process {pid}")
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
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Print when processes are killed",
    )
    args = parser.parse_args()

    mode = "root" if is_root() else "user (via sudo)"
    print(f"Preventing '{args.process_name}' from running (mode: {mode})")
    print(f"Checking every {args.interval} seconds...")

    try:
        while True:
            killed = kill_processes(args.process_name, args.verbose)
            if killed > 0 and args.verbose:
                print(f"Killed {killed} process(es)")
            time.sleep(args.interval)
    except KeyboardInterrupt:
        print("\nStopped")
        sys.exit(0)


if __name__ == "__main__":
    main()
