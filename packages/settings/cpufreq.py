"""Cpufreq: Cap CPU max frequency via sysfs (Linux only)."""

from __future__ import annotations

import os
import shutil
import sys
from pathlib import Path

import click

from common import is_linux

CPU_BASE = Path("/sys/devices/system/cpu")
KHZ_PER_GHZ = 1_000_000


def _cpufreq_dirs() -> list[Path]:
    if not CPU_BASE.is_dir():
        return []
    return sorted(p for p in CPU_BASE.glob("cpu[0-9]*") if (p / "cpufreq").is_dir())


def _read_int(path: Path) -> int | None:
    try:
        return int(path.read_text().strip())
    except (OSError, ValueError):
        return None


def cpufreq_get() -> list[dict]:
    out: list[dict] = []
    for cpu in _cpufreq_dirs():
        cf = cpu / "cpufreq"
        scaling_max = _read_int(cf / "scaling_max_freq")
        cpuinfo_max = _read_int(cf / "cpuinfo_max_freq")
        if scaling_max is None or cpuinfo_max is None:
            continue
        out.append(
            {"cpu": cpu.name, "scaling_max": scaling_max, "cpuinfo_max": cpuinfo_max}
        )
    return out


def _reexec_with_sudo() -> None:
    """Re-exec the current process under sudo. Does not return on success."""
    sudo = shutil.which("sudo")
    if sudo is None:
        print("Error: sudo not found; re-run as root", file=sys.stderr)
        sys.exit(1)
    os.execvp(sudo, [sudo, sys.executable, *sys.argv])


def cpufreq_set_max(khz: int) -> int:
    cpus = _cpufreq_dirs()
    if not cpus:
        print("No cpufreq-capable CPUs found", file=sys.stderr)
        return 1

    if os.geteuid() != 0:
        _reexec_with_sudo()

    # Validate per-CPU; on hybrid CPUs (P/E cores) hw limits differ across cores.
    for cpu in cpus:
        cf = cpu / "cpufreq"
        hw_max = _read_int(cf / "cpuinfo_max_freq")
        hw_min = _read_int(cf / "cpuinfo_min_freq")
        if hw_max is not None and khz > hw_max:
            print(
                f"Error: {khz} kHz exceeds {cpu.name} hardware max {hw_max} kHz",
                file=sys.stderr,
            )
            return 1
        if hw_min is not None and khz < hw_min:
            print(
                f"Error: {khz} kHz is below {cpu.name} hardware min {hw_min} kHz",
                file=sys.stderr,
            )
            return 1

    failed = 0
    for cpu in cpus:
        target = cpu / "cpufreq" / "scaling_max_freq"
        try:
            target.write_text(str(khz))
        except OSError as e:
            print(f"Error writing {target}: {e}", file=sys.stderr)
            failed += 1

    written = len(cpus) - failed
    print(
        f"Set scaling_max_freq={khz / KHZ_PER_GHZ:.2f} GHz "
        f"on {written}/{len(cpus)} CPUs"
    )
    return 1 if failed else 0


def register(cli):
    @cli.command()
    @click.option(
        "--max",
        "max_khz",
        type=int,
        default=None,
        metavar="KHZ",
        help="Cap CPU max frequency in kHz (e.g. 4000000 for 4.0 GHz). "
        "Auto-elevates via sudo.",
    )
    def cpufreq(max_khz):
        """Get or cap CPU max frequency (Linux only)."""
        if not is_linux():
            print("cpufreq is Linux-only", file=sys.stderr)
            sys.exit(1)

        if max_khz is None:
            info = cpufreq_get()
            if not info:
                print("No cpufreq-capable CPUs found", file=sys.stderr)
                sys.exit(1)
            for entry in info:
                scaling = entry["scaling_max"] / KHZ_PER_GHZ
                hw = entry["cpuinfo_max"] / KHZ_PER_GHZ
                print(
                    f"{entry['cpu']}: scaling_max={scaling:.2f} GHz hw_max={hw:.2f} GHz"
                )
            return

        sys.exit(cpufreq_set_max(max_khz))
