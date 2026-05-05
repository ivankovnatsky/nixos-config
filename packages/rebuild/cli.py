"""Click CLI + simple/watch orchestration for rebuild."""

import logging
import os
import platform
import socket
import subprocess
import sys
import threading
import time
from pathlib import Path

import click
import pywatchman

from lock import (
    check_existing_instance,
    cleanup_instance_file,
    cleanup_stale_lock,
    write_instance_file,
)
from runner import (
    detect_rebuild_command,
    refresh_sudo,
    reset_terminal,
    run_rebuild,
)
from util import DEBOUNCE_DELAY, LOOP_INTERVAL, format_duration
from watchman import (
    filter_files_for_machine,
    get_machine_dirs,
    load_watchman_ignores,
    setup_watchman_subscription,
)


def cmd_simple(config_path, command):
    """Run a single rebuild with notifications and suppressed output."""
    config_path_obj = Path(config_path)

    reset_terminal()

    if platform.system() == "Darwin":
        if not config_path_obj.exists():
            logging.info(f"Waiting for {config_path} to be available...")
            subprocess.run(["/bin/wait4path", str(config_path)], check=True)
            logging.info(f"{config_path} is now available!")

    if not config_path_obj.exists():
        logging.error(f"Config path does not exist: {config_path}")
        sys.exit(1)

    os.chdir(config_path)

    # git add -A before rebuild (same as Makefile addall)
    subprocess.run(["git", "add", "-A"], cwd=config_path, check=False)

    if not command:
        command = detect_rebuild_command()
    logging.info(f"Rebuild command: {command}")

    # Refresh sudo before quiet mode so the password prompt is visible
    if "sudo" in command:
        refresh_sudo()

    returncode, _ = run_rebuild(config_path, command, quiet=True)
    sys.exit(returncode)


def cmd_watch(config_path, command, loop, no_watch, interval):
    """Watch for changes and rebuild."""
    config_path_obj = Path(config_path)
    watch = not no_watch

    reset_terminal()

    if check_existing_instance():
        sys.exit(0)

    write_instance_file()
    cleanup_stale_lock()

    if platform.system() == "Darwin":
        if not config_path_obj.exists():
            logging.info(f"Waiting for {config_path} to be available...")
            subprocess.run(["/bin/wait4path", str(config_path)], check=True)
            logging.info(f"{config_path} is now available!")

    if not config_path_obj.exists():
        logging.error(f"Config path does not exist: {config_path}")
        sys.exit(1)

    os.chdir(config_path)

    if command:
        logging.info(f"Rebuild command: {command}")
    else:
        command = detect_rebuild_command()
        logging.info(f"Auto-detected rebuild command: {command}")

    hostname = socket.gethostname().removesuffix(".local")
    logging.info(f"Current machine: {hostname} (filtering changes for other machines)")

    machine_dirs = get_machine_dirs(config_path)
    if machine_dirs and hostname not in machine_dirs:
        logging.warning(
            f"Hostname '{hostname}' not found in machines/ directories: {machine_dirs}. "
            "Machine filtering may not work correctly."
        )
    other_machines = machine_dirs - {hostname}

    ignore_patterns = load_watchman_ignores(config_path)
    logging.info(f"Loaded ignore patterns from .rebuild.json: {ignore_patterns}")

    RECONNECT_DELAY = 5
    MAX_RECONNECT_ATTEMPTS = 10

    debounce_timer = None
    pending_files = []
    timer_lock = threading.Lock()
    rebuild_lock = threading.Lock()
    loop_stop_event = threading.Event()

    def loop_timer_thread():
        logging.info(f"Loop timer started (interval: {format_duration(interval)})")
        while not loop_stop_event.wait(interval):
            logging.info("Loop timer fired, triggering periodic rebuild")
            if not refresh_sudo():
                logging.warning("Failed to refresh sudo, attempting rebuild anyway")
            with timer_lock:
                nonlocal debounce_timer
                if debounce_timer is not None:
                    debounce_timer.cancel()
                    debounce_timer = None
            trigger_rebuild(loop_triggered=True)

    def trigger_rebuild(loop_triggered=False):
        nonlocal pending_files, debounce_timer
        with timer_lock:
            if pending_files:
                files_to_rebuild = list(pending_files)
                if loop_triggered and files_to_rebuild:
                    logging.info("=" * 60)
                    logging.info(
                        f"Loop timer + {len(files_to_rebuild)} file change(s):"
                    )
                    for f in files_to_rebuild[:10]:
                        logging.info(f"  - {f}")
                    if len(files_to_rebuild) > 10:
                        logging.info(f"  ... and {len(files_to_rebuild) - 10} more")
                    logging.info("=" * 60)
                elif not loop_triggered:
                    logging.info("=" * 60)
                    logging.info(
                        f"Rebuilding after {len(files_to_rebuild)} file change(s):"
                    )
                    for f in files_to_rebuild[:10]:
                        logging.info(f"  - {f}")
                    if len(files_to_rebuild) > 10:
                        logging.info(f"  ... and {len(files_to_rebuild) - 10} more")
                    logging.info("=" * 60)
                pending_files = []
            else:
                files_to_rebuild = []

            if loop_triggered and not files_to_rebuild:
                logging.info("=" * 60)
                logging.info("Periodic loop rebuild (no file changes)")
                logging.info("=" * 60)

        if files_to_rebuild:
            files_to_rebuild = filter_files_for_machine(
                files_to_rebuild, other_machines
            )

        if not files_to_rebuild and not loop_triggered:
            logging.info("All changed files belong to other machines, skipping rebuild")
            return

        if files_to_rebuild or loop_triggered:
            # Stage all files so nix flake sees new/changed files
            subprocess.run(["git", "add", "-A"], cwd=config_path, check=False)
            with rebuild_lock:
                _, actually_ran = run_rebuild(config_path, command)
            if not actually_ran:
                with timer_lock:
                    for f in files_to_rebuild:
                        if f not in pending_files:
                            pending_files.append(f)
                    logging.info(
                        f"Re-queued {len(files_to_rebuild)} file(s), will rebuild after current rebuild finishes"
                    )
            else:
                with timer_lock:
                    if pending_files:
                        logging.info(
                            f"{len(pending_files)} file(s) changed during rebuild, scheduling follow-up rebuild in {format_duration(DEBOUNCE_DELAY)}"
                        )
                        debounce_timer = threading.Timer(
                            DEBOUNCE_DELAY, trigger_rebuild
                        )
                        debounce_timer.start()

    client = None
    reconnect_attempts = 0

    # Always run an initial rebuild on startup
    logging.info("Running initial rebuild on startup")
    subprocess.run(["git", "add", "-A"], cwd=config_path, check=False)
    if "sudo" in command:
        refresh_sudo()
    with rebuild_lock:
        run_rebuild(config_path, command)

    if loop:
        if not refresh_sudo():
            logging.warning("Failed initial sudo refresh")
        loop_thread = threading.Thread(target=loop_timer_thread, daemon=True)
        loop_thread.start()

    try:
        if watch:
            while True:
                if client is None:
                    try:
                        client = pywatchman.client()
                        root, sub_name = setup_watchman_subscription(
                            client, config_path, ignore_patterns
                        )
                        reconnect_attempts = 0
                    except (pywatchman.WatchmanError, Exception) as e:
                        reconnect_attempts += 1
                        if reconnect_attempts >= MAX_RECONNECT_ATTEMPTS:
                            logging.error(
                                f"Failed to connect to watchman after {MAX_RECONNECT_ATTEMPTS} attempts, exiting"
                            )
                            sys.exit(1)
                        logging.error(f"Failed to connect to watchman: {e}")
                        logging.info(
                            f"Retrying in {format_duration(RECONNECT_DELAY)} (attempt {reconnect_attempts}/{MAX_RECONNECT_ATTEMPTS})..."
                        )
                        time.sleep(RECONNECT_DELAY)
                        continue

                try:
                    result = client.receive()

                    if "subscription" in result and result["subscription"] == sub_name:
                        if result.get("is_fresh_instance"):
                            logging.info("Fresh watchman instance")
                            continue

                        files = result.get("files", [])
                        if files:
                            with timer_lock:
                                for f in files:
                                    fname = (
                                        f
                                        if isinstance(f, str)
                                        else f.get("name", str(f))
                                    )
                                    if fname not in pending_files:
                                        pending_files.append(fname)

                                if debounce_timer is not None:
                                    debounce_timer.cancel()

                                logging.info(
                                    f"Change detected, waiting {format_duration(DEBOUNCE_DELAY)} for more changes..."
                                )
                                debounce_timer = threading.Timer(
                                    DEBOUNCE_DELAY, trigger_rebuild
                                )
                                debounce_timer.start()

                except pywatchman.SocketTimeout:
                    continue
                except pywatchman.WatchmanError as e:
                    logging.warning(f"Watchman error: {e}")
                    logging.info(
                        f"Reconnecting in {format_duration(RECONNECT_DELAY)}..."
                    )
                    try:
                        client.close()
                    except Exception:
                        pass
                    client = None
                    time.sleep(RECONNECT_DELAY)
        else:
            logging.info("File watching disabled, running in loop-only mode")
            loop_stop_event.wait()

    except KeyboardInterrupt:
        logging.info("Received interrupt, stopping...")
    finally:
        loop_stop_event.set()
        if debounce_timer is not None:
            debounce_timer.cancel()
        if client is not None:
            try:
                client.close()
            except Exception:
                pass
        cleanup_instance_file()


class DefaultToSimple(click.Group):
    """If the first arg isn't a known subcommand, treat it as 'simple <args>'."""

    def parse_args(self, ctx, args):
        if args and args[0] not in self.commands and not args[0].startswith("-"):
            args = ["simple"] + args
        return super().parse_args(ctx, args)


@click.group(cls=DefaultToSimple)
def cli():
    """Nix rebuild tool with simple and watch modes."""


@cli.command()
@click.argument("config_path")
@click.argument("command", required=False, default=None)
def simple(config_path, command):
    """Single rebuild with notifications (quiet output)."""
    cmd_simple(config_path, command)


@cli.command()
@click.argument("config_path")
@click.argument("command", required=False, default=None)
@click.option(
    "--loop",
    is_flag=True,
    help="Also rebuild periodically every INTERVAL seconds (with sudo refresh)",
)
@click.option(
    "--no-watch",
    is_flag=True,
    help="Disable file watching (use with --loop for timer-only mode)",
)
@click.option(
    "--interval",
    type=int,
    default=LOOP_INTERVAL,
    help=f"Interval in seconds between periodic rebuilds when --loop is used (default: {LOOP_INTERVAL})",
)
def watch(config_path, command, loop, no_watch, interval):
    """Watch for file changes and rebuild automatically."""
    if interval != LOOP_INTERVAL and not loop:
        raise click.UsageError("--interval requires --loop")
    if no_watch and not loop:
        raise click.UsageError(
            "--no-watch requires --loop (nothing to do without watching or looping)"
        )
    cmd_watch(config_path, command, loop, no_watch, interval)
