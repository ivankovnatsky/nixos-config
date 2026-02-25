#!/usr/bin/env python3
"""Simple Obsidian vault manager - create and open vaults from CLI."""

import argparse
import json
import subprocess
import time
from pathlib import Path


def get_obsidian_config_path() -> Path:
    """Get path to Obsidian's config file."""
    return Path.home() / "Library/Application Support/obsidian/obsidian.json"


def read_obsidian_config() -> dict:
    """Read Obsidian's config file, creating it if needed."""
    config_path = get_obsidian_config_path()

    if not config_path.exists():
        return {"vaults": {}}

    with open(config_path) as f:
        return json.load(f)


def write_obsidian_config(config: dict) -> None:
    """Write Obsidian's config file."""
    config_path = get_obsidian_config_path()
    config_path.parent.mkdir(parents=True, exist_ok=True)

    with open(config_path, "w") as f:
        json.dump(config, f, indent=2)


def generate_vault_id() -> str:
    """Generate a unique vault ID (hex string)."""
    import hashlib

    return hashlib.md5(str(time.time_ns()).encode()).hexdigest()


def find_vault_by_path(config: dict, vault_path: Path) -> str | None:
    """Find existing vault ID by path."""
    resolved = str(vault_path.resolve())
    for vault_id, vault_info in config.get("vaults", {}).items():
        if vault_info.get("path") == resolved:
            return vault_id
    return None


def create_vault(vault_path: Path, name: str | None = None) -> tuple[str, bool]:
    """Register a vault with Obsidian. Returns (vault_name, newly_created)."""
    vault_path = vault_path.resolve()

    if not vault_path.exists():
        vault_path.mkdir(parents=True)

    # Create .obsidian folder to mark as vault
    obsidian_dir = vault_path / ".obsidian"
    obsidian_dir.mkdir(exist_ok=True)

    config = read_obsidian_config()

    # Check if already registered
    existing_id = find_vault_by_path(config, vault_path)
    if existing_id:
        vault_name = name or vault_path.name
        print(f"Vault already registered: {vault_name}")
        return vault_name, False

    # Register new vault
    vault_id = generate_vault_id()
    vault_name = name or vault_path.name

    config.setdefault("vaults", {})[vault_id] = {
        "path": str(vault_path),
        "ts": int(time.time() * 1000),
    }

    write_obsidian_config(config)
    print(f"Created vault: {vault_name} at {vault_path}")
    return vault_name, True


def is_obsidian_running() -> bool:
    """Check if Obsidian is running."""
    result = subprocess.run(
        ["pgrep", "-x", "Obsidian"],
        capture_output=True,
    )
    return result.returncode == 0


def quit_obsidian() -> None:
    """Quit Obsidian app gracefully (allows autosave to complete)."""
    subprocess.run(
        ["osascript", "-e", 'quit app "Obsidian"'],
        capture_output=True,
    )
    # Wait for autosave and graceful shutdown
    time.sleep(1.0)


def open_vault(vault_path: Path, just_created: bool = False) -> None:
    """Open a vault in Obsidian."""
    vault_path = vault_path.resolve()

    # Check if vault is already registered
    config = read_obsidian_config()
    was_registered = find_vault_by_path(config, vault_path) is not None

    if not was_registered:
        # New vault - need to quit Obsidian so it reads the new config
        if is_obsidian_running():
            print("Quitting Obsidian to register new vault...")
            quit_obsidian()
        create_vault(vault_path)
    elif just_created and is_obsidian_running():
        # Vault was just registered but Obsidian has stale config
        print("Restarting Obsidian to pick up new vault...")
        quit_obsidian()

    # Open using vault name (more reliable than path)
    vault_name = vault_path.name
    uri = f"obsidian://open?vault={vault_name}"
    subprocess.run(["open", uri], check=True)


def find_vault_by_name(config: dict, name: str) -> tuple[str | None, Path | None]:
    """Find vault ID and path by name."""
    for vault_id, vault_info in config.get("vaults", {}).items():
        path = vault_info.get("path", "")
        if Path(path).name == name:
            return vault_id, Path(path)
    return None, None


def delete_vault(vault_path: Path | None, name: str | None = None) -> None:
    """Unregister a vault from Obsidian's config."""
    config = read_obsidian_config()

    if vault_path:
        vault_path = vault_path.resolve()
        vault_id = find_vault_by_path(config, vault_path)
        display_name = name or vault_path.name
    elif name:
        vault_id, _ = find_vault_by_name(config, name)
        display_name = name
    else:
        print("Error: provide a path or --name")
        raise SystemExit(1)

    if not vault_id:
        print(f"Vault not found: {display_name}")
        raise SystemExit(1)

    del config["vaults"][vault_id]
    write_obsidian_config(config)
    print(f"Unregistered vault: {display_name}")


def list_vaults() -> None:
    """List all registered vaults."""
    config = read_obsidian_config()
    vaults = config.get("vaults", {})

    if not vaults:
        print("No vaults registered")
        return

    for vault_id, info in vaults.items():
        path = info.get("path", "unknown")
        name = Path(path).name if path else "unknown"
        print(f"{name}: {path}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Simple Obsidian vault manager",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    subparsers = parser.add_subparsers(dest="command", help="Commands")

    # create command
    create_parser = subparsers.add_parser("create", help="Create and register a vault")
    create_parser.add_argument(
        "path",
        nargs="?",
        default=".",
        help="Path to vault directory (default: current directory)",
    )
    create_parser.add_argument("--name", help="Custom vault name")

    # open command
    open_parser = subparsers.add_parser("open", help="Open a vault in Obsidian")
    open_parser.add_argument(
        "path",
        nargs="?",
        default=".",
        help="Path to vault directory (default: current directory)",
    )

    # list command
    subparsers.add_parser("list", help="List all registered vaults")

    # delete command
    delete_parser = subparsers.add_parser("delete", help="Unregister a vault")
    delete_parser.add_argument(
        "path",
        nargs="?",
        default=None,
        help="Path to vault directory",
    )
    delete_parser.add_argument("--name", help="Vault name to delete")
    args = parser.parse_args()

    if args.command == "create":
        vault_path = Path(args.path)
        create_vault(vault_path, args.name)
    elif args.command == "open":
        vault_path = Path(args.path)
        open_vault(vault_path)
    elif args.command == "list":
        list_vaults()
    elif args.command == "delete":
        vault_path = Path(args.path) if args.path else None
        delete_vault(vault_path, args.name)
    else:
        # Default: create and open current directory
        vault_path = Path(".")
        _name, newly_created = create_vault(vault_path)
        open_vault(vault_path, just_created=newly_created)


if __name__ == "__main__":
    main()
