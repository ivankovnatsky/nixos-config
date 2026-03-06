#!/usr/bin/env python3
"""Taskmanager: Add tasks to both macOS Reminders and Taskwarrior."""

import argparse
import platform
import shutil
import subprocess
import sys


def has_command(cmd):
    return shutil.which(cmd) is not None


def is_darwin():
    return platform.system() == "Darwin"


def run(cmd):
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(
            f"Error running {' '.join(cmd)}: {result.stderr.strip()}", file=sys.stderr
        )
    return result


def main():
    parser = argparse.ArgumentParser(
        description="Add tasks to both macOS Reminders and Taskwarrior"
    )
    parser.add_argument("description", help="Task description")
    parser.add_argument(
        "--project", default="Inbox", help="Project/list name (default: Inbox)"
    )

    args = parser.parse_args()
    project = args.project
    prefixed = f"{project}: {args.description}"

    if is_darwin() and has_command("reminders"):
        existing = subprocess.run(
            ["reminders", "show-lists"], capture_output=True, text=True
        )
        if project not in existing.stdout.splitlines():
            run(["reminders", "new-list", project])

        result = run(["reminders", "add", project, prefixed])
        if result.returncode == 0:
            print(f"Reminders ({project}): added")

    if has_command("task"):
        result = run(["task", "add", prefixed, f"project:{project}"])
        if result.returncode == 0:
            print(f"Taskwarrior ({project}): added")


if __name__ == "__main__":
    main()
