"""Utility functions: password hashing, config parsing, client construction."""

import sys
import subprocess
import logging
import xml.etree.ElementTree as ET
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Optional, List, Dict, Any, Tuple

import bcrypt

from client import SyncthingClient


def hash_password(password: str) -> str:
    """Hash password using bcrypt (cost factor 10)."""
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt(rounds=10)).decode(
        "utf-8"
    )


def format_bytes(bytes_val: int) -> str:
    """Format bytes into human-readable format (KB, MB, GB, TB)."""
    if bytes_val == 0:
        return "0 B"

    units = ["B", "KB", "MB", "GB", "TB"]
    unit_index = 0
    size = float(bytes_val)

    while size >= 1024 and unit_index < len(units) - 1:
        size /= 1024
        unit_index += 1

    # Show 2 decimal places for values < 10, 1 decimal for >= 10
    if size < 10:
        return f"{size:.2f} {units[unit_index]}"
    else:
        return f"{size:.1f} {units[unit_index]}"


def get_api_key_from_config(config_path: str) -> str:
    """Extract API key from Syncthing config.xml."""
    try:
        tree = ET.parse(config_path)
        root = tree.getroot()
        api_key = root.find(".//gui/apikey")
        if api_key is not None and api_key.text:
            return api_key.text
        raise Exception("API key not found in config.xml")
    except Exception as e:
        raise Exception(f"Failed to read API key from {config_path}: {e}")


def find_listening_address(port: int = 8384) -> Optional[str]:
    """
    Find what address is listening on the given port using system tools.
    Returns the listening address (e.g., '127.0.0.1', '0.0.0.0', '192.168.1.10') or None.
    """
    if sys.platform == "darwin":
        # macOS: use lsof
        try:
            result = subprocess.run(
                ["lsof", "-i", f":{port}", "-sTCP:LISTEN", "-n", "-P"],
                capture_output=True,
                text=True,
                timeout=5,
            )
            if result.returncode == 0 and result.stdout:
                # Parse lsof output - format: COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME (STATE)
                # Example: syncthing 13446 ivan 17u IPv4 ... TCP 127.0.0.1:8384 (LISTEN)
                for line in result.stdout.strip().split("\n")[1:]:  # Skip header
                    parts = line.split()
                    if len(parts) >= 9:
                        # Find the address:port part (contains : and is before (LISTEN))
                        for part in reversed(parts):
                            if ":" in part and not part.startswith("("):
                                addr = part.rsplit(":", 1)[0]
                                if addr == "*":
                                    return "0.0.0.0"
                                return addr
        except (subprocess.TimeoutExpired, FileNotFoundError):
            pass
    else:
        # Linux: use ss
        try:
            result = subprocess.run(
                ["ss", "-tlnH", "sport", "=", f":{port}"],
                capture_output=True,
                text=True,
                timeout=5,
            )
            if result.returncode == 0 and result.stdout:
                # Parse ss output - format: State Recv-Q Send-Q Local Address:Port Peer Address:Port
                for line in result.stdout.strip().split("\n"):
                    parts = line.split()
                    if len(parts) >= 4:
                        local_addr = parts[3]  # Local Address:Port
                        if ":" in local_addr:
                            addr = local_addr.rsplit(":", 1)[0]
                            # Handle IPv6 bracket notation
                            if addr.startswith("[") and addr.endswith("]"):
                                addr = addr[1:-1]
                            if addr == "*" or addr == "0.0.0.0" or addr == "::":
                                return "0.0.0.0"
                            return addr
        except (subprocess.TimeoutExpired, FileNotFoundError):
            pass

    return None


def get_client(args, use_fallback: bool = True):
    """
    Get a configured SyncthingClient from args.

    If use_fallback is True (default for CLI mode), will try to find a reachable
    Syncthing instance by checking what's listening on port 8384.
    """
    # Get API key
    if hasattr(args, "api_key") and args.api_key:
        api_key = args.api_key
    elif hasattr(args, "config_xml") and args.config_xml:
        api_key = get_api_key_from_config(args.config_xml)
    else:
        raise Exception("Either --api-key or --config-xml must be provided")

    base_url = args.base_url

    # For CLI mode, auto-detect Syncthing address from port listener
    if use_fallback and hasattr(args, "mode") and args.mode == "cli":
        listening_addr = find_listening_address(8384)

        if listening_addr:
            # If bound to 0.0.0.0, use localhost
            if listening_addr == "0.0.0.0":
                detected_url = "http://127.0.0.1:8384"
            else:
                detected_url = f"http://{listening_addr}:8384"

            if detected_url != base_url:
                logging.info(f"Detected Syncthing at {detected_url}")
            base_url = detected_url
        else:
            error_msg = """
No process listening on port 8384.

Please check that:
  1. Syncthing is running
  2. The correct URL is specified with --base-url
"""
            logging.error(error_msg)
            raise Exception("Syncthing is not running (nothing listening on port 8384)")

    return SyncthingClient(base_url, api_key)


def fetch_completions_parallel(
    client, tasks: List[Tuple[str, Optional[str]]], max_workers: int = 5
) -> Dict[Tuple[str, Optional[str]], Any]:
    """
    Fetch completion status for multiple device/folder combinations in parallel.

    Args:
        client: SyncthingClient instance
        tasks: List of (device_id, folder_id) tuples. folder_id can be None for device-level completion.
        max_workers: Maximum parallel requests

    Returns:
        Dict mapping (device_id, folder_id) to completion data
    """
    results = {}

    def fetch_one(task):
        device_id, folder_id = task
        try:
            return task, client.get_completion(device_id, folder_id)
        except Exception:
            return task, None

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = {executor.submit(fetch_one, task): task for task in tasks}
        for future in as_completed(futures):
            task, result = future.result()
            if result:
                results[task] = result

    return results


def fetch_folder_statuses_parallel(
    client, folder_ids: List[str], max_workers: int = 5
) -> Dict[str, Any]:
    """
    Fetch folder statuses in parallel.

    Args:
        client: SyncthingClient instance
        folder_ids: List of folder IDs
        max_workers: Maximum parallel requests

    Returns:
        Dict mapping folder_id to status data
    """
    results = {}

    def fetch_one(folder_id):
        try:
            return folder_id, client.get_folder_status(folder_id)
        except Exception:
            return folder_id, None

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = {executor.submit(fetch_one, fid): fid for fid in folder_ids}
        for future in as_completed(futures):
            folder_id, result = future.result()
            if result:
                results[folder_id] = result

    return results
