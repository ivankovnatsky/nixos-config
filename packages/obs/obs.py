#!/usr/bin/env python3
"""Simple Obsidian vault manager - create and open vaults from CLI."""

import hashlib
import json
import subprocess
import time
from pathlib import Path
from urllib.parse import quote

import click


def get_obsidian_config_path() -> Path:
    return Path.home() / "Library/Application Support/obsidian/obsidian.json"


def read_obsidian_config() -> dict:
    config_path = get_obsidian_config_path()
    if not config_path.exists():
        return {"vaults": {}}
    with open(config_path) as f:
        return json.load(f)


def write_obsidian_config(config: dict) -> None:
    config_path = get_obsidian_config_path()
    config_path.parent.mkdir(parents=True, exist_ok=True)
    with open(config_path, "w") as f:
        json.dump(config, f, indent=2)


def generate_vault_id() -> str:
    return hashlib.md5(str(time.time_ns()).encode()).hexdigest()


def find_vault_by_path(config: dict, vault_path: Path) -> str | None:
    resolved = str(vault_path.resolve())
    for vault_id, vault_info in config.get("vaults", {}).items():
        if vault_info.get("path") == resolved:
            return vault_id
    return None


def find_vault_by_name(config: dict, name: str) -> tuple[str | None, Path | None]:
    for vault_id, vault_info in config.get("vaults", {}).items():
        path = vault_info.get("path", "")
        if Path(path).name == name:
            return vault_id, Path(path)
    return None, None


def find_parent_vault(start: Path) -> Path | None:
    current = start.resolve().parent
    while current != current.parent:
        if (current / ".obsidian").is_dir():
            return current
        current = current.parent
    return None


def is_obsidian_running() -> bool:
    result = subprocess.run(["pgrep", "-x", "Obsidian"], capture_output=True)
    return result.returncode == 0


def quit_obsidian() -> None:
    subprocess.run(
        ["osascript", "-e", 'quit app "Obsidian"'],
        capture_output=True,
    )
    time.sleep(1.0)


def _create_vault(vault_path: Path, name: str | None = None) -> tuple[str, bool]:
    vault_path = vault_path.resolve()
    if not vault_path.exists():
        vault_path.mkdir(parents=True)

    (vault_path / ".obsidian").mkdir(exist_ok=True)

    config = read_obsidian_config()
    existing_id = find_vault_by_path(config, vault_path)
    if existing_id:
        vault_name = name or vault_path.name
        click.echo(f"Vault already registered: {vault_name}")
        return vault_name, False

    vault_id = generate_vault_id()
    vault_name = name or vault_path.name
    config.setdefault("vaults", {})[vault_id] = {
        "path": str(vault_path),
        "ts": int(time.time() * 1000),
    }
    write_obsidian_config(config)
    click.echo(f"Created vault: {vault_name} at {vault_path}")
    return vault_name, True


def _open_vault(vault_path: Path, just_created: bool = False, file_path: str | None = None) -> None:
    vault_path = vault_path.resolve()
    config = read_obsidian_config()
    was_registered = find_vault_by_path(config, vault_path) is not None

    if not was_registered:
        if is_obsidian_running():
            click.echo("Quitting Obsidian to register new vault...")
            quit_obsidian()
        _create_vault(vault_path)
    elif just_created and is_obsidian_running():
        click.echo("Restarting Obsidian to pick up new vault...")
        quit_obsidian()

    vault_name = vault_path.name
    uri = f"obsidian://open?vault={vault_name}"
    if file_path:
        uri += f"&file={quote(file_path)}"
    subprocess.run(["open", uri], check=True)


def resolve_open_target(path_str: str) -> tuple[Path, str | None]:
    target = Path(path_str).resolve()
    if target.is_file() and target.suffix == ".md":
        vault = find_parent_vault(target)
        if not vault:
            raise click.ClickException(f"No Obsidian vault found for {target}")
        return vault, str(target.relative_to(vault))
    return target, None


class ObsGroup(click.Group):
    """Custom group that falls through to default open behavior for unknown args."""

    def parse_args(self, ctx: click.Context, args: list[str]) -> list[str]:
        # If first arg looks like a path (not a command or option), prepend "open"
        if args and args[0] not in self.commands and not args[0].startswith("-"):
            args = ["open"] + args
        return super().parse_args(ctx, args)


@click.group(cls=ObsGroup, invoke_without_command=True)
@click.pass_context
def cli(ctx: click.Context) -> None:
    """Simple Obsidian vault manager."""
    if ctx.invoked_subcommand is not None:
        return
    vault_path = Path(".")
    parent_vault = find_parent_vault(vault_path.resolve())
    if parent_vault:
        click.echo(f"Inside existing vault: {parent_vault.name}")
        _open_vault(parent_vault)
    else:
        _name, newly_created = _create_vault(vault_path)
        _open_vault(vault_path, just_created=newly_created)


@cli.command()
@click.argument("path", default=".", type=click.Path())
@click.option("--name", help="Custom vault name.")
def create(path: str, name: str | None) -> None:
    """Create and register a vault."""
    _create_vault(Path(path), name)


@cli.command("open")
@click.argument("path", default=".", type=click.Path())
def open_cmd(path: str) -> None:
    """Open a vault or .md file in Obsidian."""
    vault, file_rel = resolve_open_target(path)
    _open_vault(vault, file_path=file_rel)


@cli.command("list")
def list_cmd() -> None:
    """List all registered vaults."""
    config = read_obsidian_config()
    vaults = config.get("vaults", {})
    if not vaults:
        click.echo("No vaults registered")
        return
    for _vault_id, info in vaults.items():
        path = info.get("path", "unknown")
        name = Path(path).name if path else "unknown"
        click.echo(f"{name}: {path}")


@cli.command()
@click.argument("path", required=False, default=None, type=click.Path())
@click.option("--name", help="Vault name to delete.")
def delete(path: str | None, name: str | None) -> None:
    """Unregister a vault."""
    config = read_obsidian_config()

    if path:
        vault_path = Path(path).resolve()
        vault_id = find_vault_by_path(config, vault_path)
        display_name = name or vault_path.name
    elif name:
        vault_id, _ = find_vault_by_name(config, name)
        display_name = name
    else:
        raise click.ClickException("Provide a path or --name")

    if not vault_id:
        raise click.ClickException(f"Vault not found: {display_name}")

    del config["vaults"][vault_id]
    write_obsidian_config(config)
    click.echo(f"Unregistered vault: {display_name}")


if __name__ == "__main__":
    cli()
