#!/usr/bin/env python3

# https://code.claude.com/docs/en/statusline

import json
import os
import re
import shutil
import subprocess
import sys


def strip_ansi(s):
    return re.sub(r"\033\[[0-9;]*m", "", s)


def truncate_line(rendered, cols):
    plain = strip_ansi(rendered)
    if len(plain) <= cols:
        return rendered
    target = cols - 2
    visible = 0
    i = 0
    while visible < target and i < len(rendered):
        if rendered[i] == "\033":
            while i < len(rendered) and rendered[i] != "m":
                i += 1
            i += 1
        else:
            visible += 1
            i += 1
    return rendered[:i] + ".."


def git_info():
    try:
        subprocess.run(
            ["git", "rev-parse", "--git-dir"],
            capture_output=True,
            check=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None

    branch = subprocess.run(
        ["git", "branch", "--show-current"],
        capture_output=True,
        text=True,
    ).stdout.strip()

    staged = subprocess.run(
        ["git", "diff", "--cached", "--numstat"],
        capture_output=True,
        text=True,
    ).stdout.strip()
    staged_count = len(staged.splitlines()) if staged else 0

    modified = subprocess.run(
        ["git", "diff", "--numstat"],
        capture_output=True,
        text=True,
    ).stdout.strip()
    modified_count = len(modified.splitlines()) if modified else 0

    return branch, staged_count, modified_count


def main():
    data = json.load(sys.stdin)

    model_id = data.get("model", {}).get("id", "")
    cwd = data.get("workspace", {}).get("current_dir", "")
    project_dir = data.get("workspace", {}).get("project_dir", "")
    remaining = data.get("context_window", {}).get("remaining_percentage", 100)
    remaining = int(remaining)
    ctx_size = data.get("context_window", {}).get("context_window_size", 200000)
    transcript = data.get("transcript_path", "")

    # stdin is a pipe so shutil.get_terminal_size() defaults to 80;
    # query stderr (still connected to the terminal) instead
    try:
        cols = os.get_terminal_size(sys.stderr.fileno()).columns
    except (OSError, ValueError):
        cols = shutil.get_terminal_size().columns

    # Colors
    CYAN = "\033[36m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    MAGENTA = "\033[35m"
    DIM = "\033[90m"
    RESET = "\033[0m"

    # Format context size
    if ctx_size >= 1_000_000:
        ctx_fmt = f"{ctx_size / 1_000_000:g}M"
    else:
        ctx_fmt = f"{ctx_size // 1000}k"

    # Line 1: model | context remaining | ctx size | git
    line1 = (
        f"{CYAN}{model_id}{RESET} "
        f"{DIM}|{RESET} {remaining}% remaining "
        f"{DIM}|{RESET} {DIM}ctx:{ctx_fmt}{RESET}"
    )

    info = git_info()
    if info:
        branch, staged_count, modified_count = info
        git_status = ""
        if staged_count > 0:
            git_status += f"{GREEN}+{staged_count}{RESET}"
        if modified_count > 0:
            git_status += f"{YELLOW}~{modified_count}{RESET}"
        line1 += f" {DIM}|{RESET} {MAGENTA}{branch}{RESET} {git_status}"

    print(truncate_line(line1, cols))

    # Line 2: pwd (project dir)
    print(truncate_line(f"{DIM}pwd:{RESET} {project_dir}", cols))

    # Line 3: cwd
    print(truncate_line(f"{DIM}cwd:{RESET} {cwd}", cols))

    # Line 4: transcript
    if transcript:
        print(truncate_line(f"{DIM}transcript:{RESET} {transcript}", cols))


if __name__ == "__main__":
    main()
