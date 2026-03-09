#!/usr/bin/env python3

import argparse
import json
import re
import subprocess
import sys


def run(cmd, capture=True, suppress_stderr=False):
    if suppress_stderr:
        result = subprocess.run(cmd, capture_output=True, text=True)
    else:
        result = subprocess.run(cmd, capture_output=capture, text=True)
    if result.returncode != 0 and capture and not suppress_stderr:
        print(result.stderr, file=sys.stderr, end="")
    return result


def tw_find(args):
    pattern = " ".join(args.pattern)
    result = run(
        [
            "task",
            "rc.verbose=nothing",
            "rc.detection=off",
            "rc.defaultwidth=0",
            "all",
        ]
    )
    if result.returncode != 0:
        sys.exit(1)

    regex = re.compile(pattern, re.IGNORECASE)
    matches = []
    for line in result.stdout.splitlines():
        if regex.search(line):
            matches.append(line)
            # Extract UUID (first column, typically 8+ hex chars or short ID)
            parts = line.split()
            if parts:
                matches[-1] = (line, parts[0])

    if not matches:
        print(f"No tasks matching '{pattern}'")
        return

    for _line, task_id in matches:
        info = run(["task", task_id], suppress_stderr=True)
        if info.returncode == 0:
            print(info.stdout)


def tw_view(args):
    result = run(
        ["task", "export", "rc.verbose=nothing"],
    )
    if result.returncode != 0:
        sys.exit(1)

    nu_script = """
    $in | from json
    | where status == "pending"
    | select id project? description due? urgency tags?
    | sort-by -r urgency
    | table -i false
    """
    nu = run(["nu", "--stdin", "-c", nu_script], capture=False)
    if nu.returncode != 0:
        # Fallback: use python directly
        try:
            tasks = json.loads(result.stdout)
        except json.JSONDecodeError:
            print("Failed to parse task export", file=sys.stderr)
            sys.exit(1)

        pending = [t for t in tasks if t.get("status") == "pending"]
        pending.sort(key=lambda t: t.get("urgency", 0), reverse=True)

        if not pending:
            print("No pending tasks")
            return

        fmt = "{:<4} {:<15} {:<50} {:<12} {:<8}"
        print(fmt.format("ID", "Project", "Description", "Due", "Urgency"))
        print("-" * 89)
        for t in pending:
            print(
                fmt.format(
                    t.get("id", ""),
                    (t.get("project") or "")[:15],
                    (t.get("description") or "")[:50],
                    (t.get("due") or "")[:12],
                    f"{t.get('urgency', 0):.1f}",
                )
            )


def rem_find(args):
    pattern = " ".join(args.pattern)
    result = run(
        ["reminders", "show-all", "--include-completed", "--format", "json"]
    )
    if result.returncode != 0:
        print("Failed to fetch reminders", file=sys.stderr)
        sys.exit(1)

    try:
        reminders = json.loads(result.stdout)
    except json.JSONDecodeError:
        print("Failed to parse reminders JSON", file=sys.stderr)
        sys.exit(1)

    regex = re.compile(pattern, re.IGNORECASE)
    matches = [r for r in reminders if regex.search(r.get("title", ""))]

    if not matches:
        print(f"No reminders matching '{pattern}'")
        return

    for r in matches:
        print(json.dumps(r, indent=2, ensure_ascii=False))
        print()


def rem_view(args):
    result = run(
        ["reminders", "show-all", "--format", "json"]
    )
    if result.returncode != 0:
        print("Failed to fetch reminders", file=sys.stderr)
        sys.exit(1)

    try:
        reminders = json.loads(result.stdout)
    except json.JSONDecodeError:
        print("Failed to parse reminders JSON", file=sys.stderr)
        sys.exit(1)

    if not reminders:
        print("No reminders")
        return

    for r in reminders:
        status = "done" if r.get("isCompleted") else "pending"
        due = r.get("dueDate", "")
        title = r.get("title", "")
        list_name = r.get("list", "")
        print(f"[{status}] [{list_name}] {title}  due: {due}")


def main():
    parser = argparse.ArgumentParser(
        prog="task-mgmt",
        description="Manage tasks across Taskwarrior and macOS Reminders",
    )
    sub = parser.add_subparsers(dest="backend", help="Backend to use")

    # Taskwarrior
    tw_parser = sub.add_parser("t", aliases=["tw", "taskwarrior"], help="Taskwarrior")
    tw_sub = tw_parser.add_subparsers(dest="command")

    tw_find_p = tw_sub.add_parser("find", help="Search tasks by pattern")
    tw_find_p.add_argument("pattern", nargs="+", help="Search pattern")
    tw_find_p.set_defaults(func=tw_find)

    tw_view_p = tw_sub.add_parser("view", help="View pending tasks")
    tw_view_p.set_defaults(func=tw_view)

    # Reminders
    rem_parser = sub.add_parser(
        "r", aliases=["rem", "rems", "reminders"], help="macOS Reminders"
    )
    rem_sub = rem_parser.add_subparsers(dest="command")

    rem_find_p = rem_sub.add_parser("find", help="Search reminders by pattern")
    rem_find_p.add_argument("pattern", nargs="+", help="Search pattern")
    rem_find_p.set_defaults(func=rem_find)

    rem_view_p = rem_sub.add_parser("view", help="View reminders")
    rem_view_p.set_defaults(func=rem_view)

    args = parser.parse_args()

    if not args.backend:
        parser.print_help()
        sys.exit(1)

    if not hasattr(args, "func") or args.func is None:
        # No subcommand given, print help for the backend
        if args.backend in ("t", "tw", "taskwarrior"):
            tw_parser.print_help()
        elif args.backend in ("r", "rem", "rems", "reminders"):
            rem_parser.print_help()
        sys.exit(1)

    args.func(args)


if __name__ == "__main__":
    main()
