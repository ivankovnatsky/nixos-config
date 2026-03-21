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


def git_branch():
    try:
        subprocess.run(
            ["git", "rev-parse", "--git-dir"],
            capture_output=True,
            check=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None

    return subprocess.run(
        ["git", "branch", "--show-current"],
        capture_output=True,
        text=True,
    ).stdout.strip()


def shorten_path(path):
    home = os.path.expanduser("~")
    if path.startswith(home):
        path = "~" + path[len(home) :]
    return path


def shorten_path_to_fit(path, prefix, cols):
    """Progressively strip leading directories until path fits."""
    short = shorten_path(path)
    prefix_len = len(strip_ansi(prefix))
    if prefix_len + len(short) <= cols:
        return short

    parts = short.split("/")
    while len(parts) > 1:
        parts.pop(0)
        candidate = "/".join(parts)
        if prefix_len + len(candidate) <= cols:
            return candidate
    return parts[0]


def output(line, cols):
    if cols > 0:
        print(truncate_line(line, cols))
    else:
        print(line)


def main():
    raw = sys.stdin.read()
    try:
        data = json.loads(raw)
    except (json.JSONDecodeError, ValueError):
        data = {}

    model_id = data.get("model", {}).get("id", "")
    cwd = data.get("workspace", {}).get("current_dir", "")
    project_dir = data.get("workspace", {}).get("project_dir", "")
    remaining = data.get("context_window", {}).get("remaining_percentage", 100)
    remaining = int(remaining)
    ctx_size = data.get("context_window", {}).get("context_window_size", 200000)
    transcript = data.get("transcript_path", "")

    try:
        cols = os.get_terminal_size(sys.stderr.fileno()).columns
    except (OSError, ValueError):
        cols = shutil.get_terminal_size().columns

    # Colors
    CYAN = "\033[36m"
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

    branch = git_branch()
    if branch:
        line1 += f" {DIM}|{RESET} {MAGENTA}{branch}{RESET}"

    output(line1, cols)

    # Show both pwd and cwd only when different, otherwise just cwd
    pwd_prefix = f"{DIM}pwd:{RESET} "
    cwd_prefix = f"{DIM}cwd:{RESET} "
    tx_prefix = f"{DIM}transcript:{RESET} "

    if project_dir != cwd:
        output(
            f"{pwd_prefix}{shorten_path_to_fit(project_dir, pwd_prefix, cols)}", cols
        )
    output(f"{cwd_prefix}{shorten_path_to_fit(cwd, cwd_prefix, cols)}", cols)

    if transcript:
        output(f"{tx_prefix}{shorten_path_to_fit(transcript, tx_prefix, cols)}", cols)


if __name__ == "__main__":
    main()
