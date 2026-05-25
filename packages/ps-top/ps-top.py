#!/usr/bin/env python3
"""Show top 10 processes by current CPU%, with %MEM as tiebreaker.

Uses psutil to sample CPU over a 1s window — equivalent to `top -bn2`
without the output-parsing fragility.
"""

import psutil

INTERVAL = 1.0
LIMIT = 10


def main() -> None:
    procs = list(psutil.process_iter(["name"]))
    for p in procs:
        try:
            p.cpu_percent(interval=None)
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass

    psutil.cpu_percent(interval=INTERVAL)

    rows = []
    for p in procs:
        try:
            cpu = p.cpu_percent(interval=None)
            mem = p.memory_percent()
            try:
                cmd_parts = p.cmdline()
                cmd = " ".join(cmd_parts) if cmd_parts else (p.info["name"] or "")
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                cmd = p.info["name"] or ""
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
        rows.append((p.pid, cpu, mem, cmd))

    rows.sort(key=lambda r: (-r[1], -r[2]))

    print(f"{'PID':>7} {'%CPU':>5} {'%MEM':>5} COMMAND")
    for pid, cpu, mem, cmd in rows[:LIMIT]:
        print(f"{pid:>7} {cpu:>5.1f} {mem:>5.1f} {cmd}")


if __name__ == "__main__":
    main()
