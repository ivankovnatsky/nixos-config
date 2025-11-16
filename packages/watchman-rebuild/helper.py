#!/usr/bin/env python3
"""
Watchman-based rebuild tool that auto-detects platform and watches for changes.
"""

import sys
import subprocess
import platform
import os
import logging
from pathlib import Path

import pywatchman
from watchman_rebuild import load_watchman_ignores, build_watchman_expression

# Configure logging to write to stdout instead of stderr
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S',
    handlers=[logging.StreamHandler(sys.stdout)]
)


def detect_rebuild_command():
    """Detect the appropriate rebuild command based on platform."""
    system = platform.system()
    args = "switch --impure -L --flake ."

    # Check if we're running as root
    is_root = os.geteuid() == 0
    sudo_prefix = "" if is_root else "sudo -E "

    if system == 'Darwin':
        return f"{sudo_prefix}darwin-rebuild {args}"
    elif system == 'Linux':
        return f"{sudo_prefix}nixos-rebuild {args}"
    else:
        raise RuntimeError(f"Unsupported platform: {system}")


def send_notification(success):
    """Send platform-specific notification."""
    system = platform.system()

    if system == 'Darwin':
        try:
            if success:
                subprocess.run([
                    'osascript', '-e',
                    'display notification "🟢 Darwin rebuild successful!" with title "Nix configuration"'
                ], check=False, capture_output=True)
            else:
                subprocess.run([
                    'osascript', '-e',
                    'display notification "🔴 Darwin rebuild failed!" with title "Nix configuration"'
                ], check=False, capture_output=True)
        except:
            pass
    elif system == 'Linux':
        try:
            if os.environ.get('DISPLAY'):
                if success:
                    subprocess.run([
                        'notify-send',
                        '🟢 NixOS rebuild successful!',
                        'Nix configuration'
                    ], check=False, capture_output=True)
                else:
                    subprocess.run([
                        'notify-send',
                        '🔴 NixOS rebuild failed!',
                        'Nix configuration'
                    ], check=False, capture_output=True)
        except:
            pass


def run_rebuild(config_path, command):
    """Run the rebuild command."""
    logging.info(f"Running: {command}")
    env = os.environ.copy()
    env['NIXPKGS_ALLOW_UNFREE'] = '1'
    # Redirect stderr to stdout so all output goes to the same log file
    result = subprocess.run(command, shell=True, cwd=config_path, env=env, stderr=subprocess.STDOUT)
    if result.returncode == 0:
        logging.info("✅ Rebuild successful")
        send_notification(True)
    else:
        logging.error(f"❌ Rebuild failed with exit code {result.returncode}")
        send_notification(False)
    return result.returncode


def watch_and_rebuild(config_path, command=None):
    """Watch for changes and rebuild."""
    config_path_obj = Path(config_path)

    # Wait for path on Darwin (for volume mounts)
    if platform.system() == 'Darwin':
        if not config_path_obj.exists():
            logging.info(f"Waiting for {config_path} to be available...")
            subprocess.run(['/bin/wait4path', str(config_path)], check=True)
            logging.info(f"{config_path} is now available!")

    # Verify path exists
    if not config_path_obj.exists():
        logging.error(f"Config path does not exist: {config_path}")
        sys.exit(1)

    # Change to config directory
    os.chdir(config_path)

    # Auto-detect command if not provided
    if command is None:
        command = detect_rebuild_command()
        logging.info(f"Auto-detected rebuild command: {command}")

    ignore_dirs = load_watchman_ignores(config_path)
    logging.info(f"Loaded ignore patterns from .watchman-rebuild.json: {ignore_dirs}")

    client = pywatchman.client()

    try:
        # Watch the config path
        watch_result = client.query('watch-project', config_path)
        if 'warning' in watch_result:
            logging.warning(f"Watchman warning: {watch_result['warning']}")

        root = watch_result['watch']
        relative_path = watch_result.get('relative_path', '')

        logging.info(f"Watchman watching: {root}")

        # Subscribe to file changes
        query = {
            'expression': build_watchman_expression(ignore_dirs),
            'fields': ['name'],
        }

        if relative_path:
            query['relative_root'] = relative_path

        sub_name = 'watchman-rebuild'
        client.query('subscribe', root, sub_name, query)

        logging.info("Watching for changes...")

        # Wait for changes
        while True:
            try:
                result = client.receive()

                if 'subscription' in result and result['subscription'] == sub_name:
                    if result.get('is_fresh_instance'):
                        logging.info("Fresh watchman instance")
                        continue

                    files = result.get('files', [])
                    if files:
                        logging.info("=" * 60)
                        logging.info(f"Detected {len(files)} file change(s):")
                        for f in files[:10]:  # Show first 10 files
                            fname = f if isinstance(f, str) else f.get('name', str(f))
                            logging.info(f"  - {fname}")
                        if len(files) > 10:
                            logging.info(f"  ... and {len(files) - 10} more")
                        logging.info("=" * 60)
                        run_rebuild(config_path, command)
                        logging.info("=" * 60)

            except pywatchman.SocketTimeout:
                continue

    except KeyboardInterrupt:
        logging.info("Received interrupt, stopping...")
    finally:
        try:
            client.close()
        except:
            pass


if __name__ == '__main__':
    if len(sys.argv) < 2:
        logging.error(f"Usage: {sys.argv[0]} <config_path> [command]")
        logging.error(f"  If command is not provided, it will be auto-detected")
        logging.error(f"  (sudo is automatically used when not running as root)")
        sys.exit(1)

    config_path = sys.argv[1]
    command = sys.argv[2] if len(sys.argv) > 2 else None

    watch_and_rebuild(config_path, command)
