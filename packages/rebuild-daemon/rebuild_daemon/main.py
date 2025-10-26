#!/usr/bin/env python3
"""
Rebuild daemon for automated NixOS/Darwin configuration rebuilds.

This daemon watches for file changes using watchman-make and triggers rebuilds.
No tmux, just direct logging to files that can be tailed.
"""

import argparse
import logging
import os
import platform
import subprocess
import sys
import time
from pathlib import Path
from typing import Optional


class RebuildDaemon:
    """Daemon for automated configuration rebuilds."""

    def __init__(
        self,
        config_path: str,
        log_dir: Optional[str] = None,
    ):
        self.config_path = Path(config_path)
        self.platform = platform.system()

        # FIXME: Remove log handling if we're using launchd and systemd log
        # management.
        if log_dir:
            self.log_dir = Path(log_dir)
        else:
            if self.platform == "Darwin":
                self.log_dir = Path("/tmp/log/launchd")
            else:
                self.log_dir = Path("/tmp/log")

        self.log_dir.mkdir(parents=True, exist_ok=True)

        self._setup_logging()

    def _setup_logging(self):
        """Configure logging to both console and file."""
        log_format = "%(asctime)s [%(levelname)s] %(message)s"
        date_format = "%Y-%m-%d %H:%M:%S"

        logging.basicConfig(
            level=logging.INFO,
            format=log_format,
            datefmt=date_format,
            handlers=[
                logging.StreamHandler(sys.stdout),
            ],
        )

        self.logger = logging.getLogger(__name__)

    def _get_rebuild_command(self) -> list[str]:
        """Get the platform-specific rebuild command."""
        if self.platform == "Darwin":
            return ["darwin-rebuild", "switch", "--impure", "--verbose", "-L", "--flake", "."]
        else:
            return ["nixos-rebuild", "switch", "--impure", "--verbose", "-L", "--flake", "."]

    def _get_rebuild_env(self) -> dict:
        """Get environment variables for rebuild."""
        env = os.environ.copy()
        env["NIXPKGS_ALLOW_UNFREE"] = "1"
        return env

    def _notify_success(self):
        """Send platform-specific success notification."""
        if self.platform == "Darwin":
            try:
                subprocess.run(
                    [
                        "osascript",
                        "-e",
                        'display notification "🟢 Darwin rebuild successful!" with title "Nix configuration"',
                    ],
                    check=False,
                    capture_output=True,
                )
            except Exception:
                pass
        else:
            try:
                if os.environ.get("DISPLAY"):
                    subprocess.run(
                        [
                            "notify-send",
                            "🟢 NixOS rebuild successful!",
                            "Nix configuration",
                        ],
                        check=False,
                        capture_output=True,
                    )
            except Exception:
                pass

    def _notify_failure(self):
        """Send platform-specific failure notification."""
        if self.platform == "Darwin":
            try:
                subprocess.run(
                    [
                        "osascript",
                        "-e",
                        'display notification "🔴 Darwin rebuild failed!" with title "Nix configuration"',
                    ],
                    check=False,
                    capture_output=True,
                )
            except Exception:
                pass
        else:
            try:
                if os.environ.get("DISPLAY"):
                    subprocess.run(
                        [
                            "notify-send",
                            "🔴 NixOS rebuild failed!",
                            "Nix configuration",
                        ],
                        check=False,
                        capture_output=True,
                    )
            except Exception:
                pass

    def _run_rebuild(self) -> bool:
        """Execute rebuild command and return success status."""
        cmd = self._get_rebuild_command()
        env = self._get_rebuild_env()

        self.logger.info(f"Running rebuild: {' '.join(cmd)}")

        try:
            result = subprocess.run(
                cmd,
                cwd=self.config_path,
                env=env,
                check=False,
            )

            if result.returncode == 0:
                self.logger.info("✅ Rebuild successful")
                self._notify_success()
                return True
            else:
                self.logger.error(f"❌ Rebuild failed with exit code {result.returncode}")
                self._notify_failure()
                return False

        except Exception as e:
            self.logger.error(f"❌ Rebuild exception: {e}")
            self._notify_failure()
            return False

    def _wait_for_path_darwin(self):
        """Wait for config path to be available on Darwin (for volume mounts)."""
        if not self.config_path.exists():
            self.logger.info(f"Waiting for {self.config_path} to be available...")
            subprocess.run(["/bin/wait4path", str(self.config_path)], check=True)
            self.logger.info(f"{self.config_path} is now available!")

    def _run_watchman_loop(self):
        """Run watchman-make in a loop with restart logic."""
        rebuild_cmd = self._get_rebuild_command()
        rebuild_cmd_str = " ".join(rebuild_cmd)

        watchman_env = self._get_rebuild_env()

        while True:
            self.logger.info("Watching for changes...")

            try:
                subprocess.run(
                    [
                        "watchman-make",
                        "--pattern", "**/*",
                        "--run", rebuild_cmd_str,
                    ],
                    cwd=self.config_path,
                    env=watchman_env,
                    check=False,
                )
            except Exception as e:
                self.logger.error(f"Watchman error: {e}")

            self.logger.info("watchman-make exited, restarting in 3 seconds...")
            time.sleep(3)

    def run(self):
        """Main daemon loop."""
        self.logger.info(f"Starting rebuild daemon for {self.platform}")
        self.logger.info(f"Config path: {self.config_path}")
        self.logger.info(f"Log directory: {self.log_dir}")

        if self.platform == "Darwin":
            self._wait_for_path_darwin()

        if not self.config_path.exists():
            self.logger.error(f"Config path does not exist: {self.config_path}")
            sys.exit(1)

        os.chdir(self.config_path)

        self.logger.info("Performing initial build...")
        self._run_rebuild()

        self.logger.info("Starting watchman loop...")
        self._run_watchman_loop()


def main():
    """CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Rebuild daemon for automated NixOS/Darwin configuration rebuilds"
    )
    parser.add_argument(
        "--config",
        required=True,
        help="Path to nixos-config repository",
    )
    parser.add_argument(
        "--log-dir",
        help="Directory for log files (default: /tmp/log/launchd on Darwin, /tmp/log on Linux)",
    )

    args = parser.parse_args()

    daemon = RebuildDaemon(
        config_path=args.config,
        log_dir=args.log_dir,
    )

    try:
        daemon.run()
    except KeyboardInterrupt:
        logging.info("Received interrupt, shutting down...")
        sys.exit(0)


if __name__ == "__main__":
    main()
