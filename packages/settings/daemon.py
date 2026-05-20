"""Daemon: long-running settings agent with pluggable features.

Currently ships a single feature (autovolume); the structure is in place so
additional desktop-configuration features can be slotted into the same loop
without spawning more processes.
"""

from __future__ import annotations

import signal
import sys
import time

import click

from autovolume import (
    DEFAULT_CHECK_INTERVAL,
    DEFAULT_IDLE_SECONDS,
    DEFAULT_THRESHOLD_PERCENT,
    AutoVolume,
)


def register(cli):
    @cli.group()
    def daemon():
        """Long-running settings daemon (macOS + Linux)."""

    @daemon.command("run")
    @click.option(
        "--autovolume/--no-autovolume",
        default=True,
        help="Lower system volume after sustained silence.",
    )
    @click.option(
        "--autovolume-idle",
        type=click.IntRange(min=1),
        default=DEFAULT_IDLE_SECONDS,
        show_default=True,
        help="Seconds of silence before lowering volume.",
    )
    @click.option(
        "--autovolume-threshold",
        type=float,
        default=DEFAULT_THRESHOLD_PERCENT,
        show_default=True,
        help="Volume percentage to lower to.",
    )
    @click.option(
        "--check-interval",
        type=click.IntRange(min=1),
        default=DEFAULT_CHECK_INTERVAL,
        show_default=True,
        help="Seconds between daemon ticks.",
    )
    @click.option(
        "--verbose/--quiet",
        default=True,
        help="Log feature activity.",
    )
    def run(
        autovolume: bool,
        autovolume_idle: int,
        autovolume_threshold: float,
        check_interval: int,
        verbose: bool,
    ):
        """Run the settings daemon loop until interrupted."""
        stop = {"flag": False}

        def _handle_term(signum, _frame):
            if verbose:
                print(
                    f"[daemon] received signal {signum}; stopping",
                    file=sys.stdout,
                    flush=True,
                )
            stop["flag"] = True

        signal.signal(signal.SIGTERM, _handle_term)
        signal.signal(signal.SIGINT, _handle_term)

        features = []
        if autovolume:
            features.append(
                AutoVolume(autovolume_idle, autovolume_threshold, verbose)
            )

        if not features:
            # Idle instead of exiting: a non-zero exit would make launchd
            # KeepAlive / systemd Restart respawn us in a tight loop.
            print(
                "[daemon] no features enabled; idling (signal to stop)",
                file=sys.stdout,
                flush=True,
            )
            while not stop["flag"]:
                time.sleep(1)
            return

        if verbose:
            names = ", ".join(f.name for f in features)
            print(
                f"[daemon] starting features=[{names}] "
                f"interval={check_interval}s",
                file=sys.stdout,
                flush=True,
            )

        while not stop["flag"]:
            for feature in features:
                try:
                    feature.tick()
                except Exception as e:
                    print(
                        f"[daemon] feature {feature.name} error: {e}",
                        file=sys.stderr,
                        flush=True,
                    )
            # Sleep in 1s slices so SIGTERM/SIGINT is honored promptly.
            slept = 0
            while slept < check_interval and not stop["flag"]:
                time.sleep(1)
                slept += 1
