#!/usr/bin/env python3

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Set


class Color:
    GREEN = "\033[32m"
    RED = "\033[31m"
    YELLOW = "\033[33m"
    BLUE = "\033[34m"
    RESET = "\033[0m"


def log(message: str, color: str = ""):
    print(f"{color}{message}{Color.RESET}")


def load_json(path: str) -> Dict:
    if not os.path.exists(path):
        return {}
    with open(path, "r") as f:
        return json.load(f)


def save_json(path: str, data: Dict):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(data, f, indent=2)


LEGACY_STATE_DIRS = [
    "manual-packages",  # Original name, renamed to "tools" in 2026-01
]


def migrate_state_file(new_state_file: str):
    """Migrate state file from legacy locations to current location."""
    if os.path.exists(new_state_file):
        return

    # Get the base directory pattern: ~/.config/home-manager/<name>/state.json
    # We replace the current dir name with each legacy name to check
    state_dir = os.path.dirname(new_state_file)
    parent_dir = os.path.dirname(state_dir)
    state_filename = os.path.basename(new_state_file)

    for legacy_dir in LEGACY_STATE_DIRS:
        old_state_file = os.path.join(parent_dir, legacy_dir, state_filename)
        if os.path.exists(old_state_file):
            log(
                f"Migrating state file from {old_state_file} to {new_state_file}",
                Color.YELLOW,
            )
            os.makedirs(os.path.dirname(new_state_file), exist_ok=True)
            shutil.copy2(old_state_file, new_state_file)
            log("State file migrated successfully", Color.GREEN)
            return


def run_command(cmd: List[str], env: Dict = None) -> tuple[int, str, str]:
    result = subprocess.run(
        cmd, capture_output=True, text=True, env=env or os.environ.copy()
    )
    return result.returncode, result.stdout, result.stderr


def get_installed_npm_packages(npm_bin: str, packages: Dict[str, str]) -> Set[str]:
    bun_bin = Path.home() / ".bun" / "bin"

    installed = set()
    for package, binary in packages.items():
        if (bun_bin / binary).exists() or (Path(npm_bin) / binary).exists():
            installed.add(package)
    return installed


def get_installed_uv_packages(uv_bin: str, packages: Dict[str, str]) -> Set[str]:
    installed = set()
    for package, binary in packages.items():
        if (Path(uv_bin) / binary).exists():
            installed.add(package)
    return installed


def get_installed_mcp_servers(claude_cli: str, env: Dict = None) -> Set[str]:
    if not os.path.exists(claude_cli):
        return set()

    returncode, stdout, stderr = run_command([claude_cli, "mcp", "list"], env)
    if returncode != 0:
        log(f"Failed to list MCP servers (exit {returncode}): {stderr}", Color.YELLOW)
        return set()

    servers = set()
    for line in stdout.split("\n"):
        line = line.strip()
        if ":" in line and ("(SSE)" in line or "(HTTP)" in line or "(STDIO)" in line):
            server_name = line.split(":")[0].strip()
            servers.add(server_name)
    log(f"Detected installed MCP servers: {servers}", Color.BLUE)
    return servers


def install_npm_packages(
    packages: Dict[str, str], paths: Dict, state: Dict, npm_config: Dict
):
    # Handle .npmrc creation
    npmrc_path = os.path.expanduser("~/.npmrc")
    npmrc_content = npm_config.get("configFile")

    if npmrc_content and not state.get("npm", {}).get("npmrc_created"):
        if not os.path.exists(npmrc_path):
            log("Creating .npmrc file", Color.GREEN)
            with open(npmrc_path, "w") as f:
                f.write(npmrc_content)
            state.setdefault("npm", {})["npmrc_created"] = True
        else:
            log(".npmrc already exists, skipping creation", Color.BLUE)
            state.setdefault("npm", {})["npmrc_created"] = True

    desired = set(packages.keys())
    state_packages = set(state.get("npm", {}).get("packages", {}).keys())

    # Check what's currently installed from what we're tracking
    current = get_installed_npm_packages(paths["npmBin"], packages)

    # Build a complete mapping of all tracked packages (state + current config)
    # to their binaries for removal detection
    all_tracked = {}
    for pkg, pkg_data in state.get("npm", {}).get("packages", {}).items():
        all_tracked[pkg] = pkg_data.get("binary", pkg.split("/")[-1])
    for pkg, binary in packages.items():
        if pkg not in all_tracked:
            all_tracked[pkg] = binary

    # Check if binaries exist for packages that should be removed (not in desired config)
    to_remove = []
    for pkg, binary in all_tracked.items():
        if pkg not in desired and (Path(paths["npmBin"]) / binary).exists():
            to_remove.append(pkg)

    state_changed = False

    if to_remove:
        log(f"Removing NPM packages: {', '.join(to_remove)}", Color.RED)
        env = os.environ.copy()
        env["PATH"] = f"{paths['bun']}:{env.get('PATH', '')}"

        cmd = [f"{paths['bun']}/bun", "remove", "-g"] + list(to_remove)
        returncode, stdout, stderr = run_command(cmd, env)

        if returncode != 0:
            log(f"Failed to remove NPM packages: {stderr}", Color.RED)
        else:
            log(f"Removed: {', '.join(to_remove)}", Color.GREEN)
            state_changed = True

    to_install = desired - current

    if to_install:
        log(f"Installing NPM packages: {', '.join(to_install)}", Color.GREEN)
        env = os.environ.copy()
        env["PATH"] = f"{paths['bun']}:{env.get('PATH', '')}"

        cmd = [f"{paths['bun']}/bun", "install", "-g"] + list(to_install)
        returncode, stdout, stderr = run_command(cmd, env)

        if returncode != 0:
            log(f"Failed to install NPM packages: {stderr}", Color.RED)
            return False

        state_changed = True
    elif not to_remove:
        log("All NPM packages already installed", Color.BLUE)

    # Update state with current desired packages (including binary names)
    if state_changed or state_packages != desired:
        state.setdefault("npm", {})["packages"] = {
            pkg: {"installed": True, "binary": binary}
            for pkg, binary in packages.items()
        }

    return True


def install_uv_packages(packages: Dict[str, str], paths: Dict, state: Dict):
    desired = set(packages.keys())
    state_packages = set(state.get("uv", {}).get("packages", {}).keys())

    current = get_installed_uv_packages(paths["uvBin"], packages)

    all_tracked = {}
    for pkg, pkg_data in state.get("uv", {}).get("packages", {}).items():
        all_tracked[pkg] = pkg_data.get("binary", pkg)
    for pkg, binary in packages.items():
        if pkg not in all_tracked:
            all_tracked[pkg] = binary

    to_remove = []
    for pkg, binary in all_tracked.items():
        if pkg not in desired and (Path(paths["uvBin"]) / binary).exists():
            to_remove.append(pkg)

    state_changed = False

    if to_remove:
        log(f"Removing UV packages: {', '.join(to_remove)}", Color.RED)
        env = os.environ.copy()
        env["PATH"] = f"{paths['uv']}:{env.get('PATH', '')}"

        for pkg in to_remove:
            cmd = [f"{paths['uv']}/uv", "tool", "uninstall", pkg]
            returncode, stdout, stderr = run_command(cmd, env)

            if returncode != 0:
                log(f"Failed to remove UV package {pkg}: {stderr}", Color.RED)
            else:
                log(f"Removed: {pkg}", Color.GREEN)
                state_changed = True

    to_install = desired - current

    if to_install:
        log(f"Installing UV packages: {', '.join(to_install)}", Color.GREEN)
        env = os.environ.copy()
        env["PATH"] = f"{paths['uv']}:{env.get('PATH', '')}"

        for pkg in to_install:
            cmd = [f"{paths['uv']}/uv", "tool", "install", pkg]
            returncode, stdout, stderr = run_command(cmd, env)

            if returncode != 0:
                log(f"Failed to install UV package {pkg}: {stderr}", Color.RED)
                return False
            else:
                log(f"Installed: {pkg}", Color.GREEN)
                state_changed = True
    elif not to_remove:
        log("All UV packages already installed", Color.BLUE)

    if state_changed or state_packages != desired:
        state.setdefault("uv", {})["packages"] = {
            pkg: {"installed": True, "binary": binary}
            for pkg, binary in packages.items()
        }

    return True


def substitute_secrets(text: str, secret_paths: Dict[str, str]) -> str:
    """Replace @VARIABLE@ placeholders with content from secret files."""
    result = text
    for var_name, file_path in secret_paths.items():
        placeholder = f"@{var_name}@"
        if placeholder in result:
            try:
                with open(file_path, "r") as f:
                    secret_value = f.read().strip()
                result = result.replace(placeholder, secret_value)
            except Exception as e:
                log(f"Failed to read secret file {file_path}: {e}", Color.RED)
    return result


def install_mcp_servers(servers: Dict, paths: Dict, state: Dict):
    claude_cli = paths["claudeCli"]

    if not os.path.exists(claude_cli):
        log("Claude CLI not found, skipping MCP server configuration", Color.YELLOW)
        return True

    env = os.environ.copy()
    env["PATH"] = (
        f"{paths['nodejs']}:{paths['npmBin']}:{paths['python']}:{env.get('PATH', '')}"
    )

    desired = set(servers.keys())
    current = get_installed_mcp_servers(claude_cli, env)
    to_install = desired - current
    to_remove = current - desired

    state_changed = False

    if to_remove:
        log(f"Removing MCP servers: {', '.join(to_remove)}", Color.RED)
        for server_name in to_remove:
            returncode, _, stderr = run_command(
                [claude_cli, "mcp", "remove", server_name, "-s", "user"], env
            )
            if returncode != 0:
                log(f"Failed to remove {server_name}: {stderr}", Color.RED)
            else:
                log(f"Removed {server_name}", Color.GREEN)
                state_changed = True

    if to_install:
        log(f"Installing MCP servers: {', '.join(to_install)}", Color.GREEN)
        for server_name in to_install:
            server_config = servers[server_name]

            if server_config.get("command"):
                cmd = server_config["command"].split()
            else:
                cmd = [
                    claude_cli,
                    "mcp",
                    "add",
                    "--scope",
                    server_config["scope"],
                    "--transport",
                    server_config["transport"],
                    server_name,
                    server_config["url"],
                ]
                secret_paths = server_config.get("secretPaths", {})
                for header in server_config.get("headers", []):
                    processed_header = substitute_secrets(header, secret_paths)
                    cmd.extend(["-H", processed_header])

            returncode, _, stderr = run_command(cmd, env)
            if returncode != 0:
                if "already exists" in stderr:
                    log(
                        f"{server_name} already exists, marking as installed",
                        Color.BLUE,
                    )
                else:
                    log(f"Failed to install {server_name}: {stderr}", Color.RED)
                    continue
            else:
                log(f"Installed {server_name}", Color.GREEN)
                state_changed = True

    if not to_install and not to_remove:
        log("All MCP servers already installed", Color.BLUE)

    if state_changed or set(state.get("mcp", {}).get("servers", {}).keys()) != desired:
        state.setdefault("mcp", {})["servers"] = {
            name: {
                "installed": True,
                "scope": config["scope"],
                "transport": config["transport"],
                "url": config["url"],
            }
            for name, config in servers.items()
        }

    return True


def main():
    if len(sys.argv) < 3 or sys.argv[1] != "--config":
        log("Usage: packages.py --config <config.json>", Color.RED)
        sys.exit(1)

    config_path = sys.argv[2]
    config = load_json(config_path)

    state_file = config["stateFile"]
    migrate_state_file(state_file)
    state = load_json(state_file)

    success = True

    if config.get("npm", {}).get("packages"):
        success &= install_npm_packages(
            config["npm"]["packages"], config["paths"], state, config["npm"]
        )

    if config.get("uv", {}).get("packages"):
        success &= install_uv_packages(config["uv"]["packages"], config["paths"], state)

    if config.get("mcp", {}).get("servers"):
        success &= install_mcp_servers(config["mcp"]["servers"], config["paths"], state)

    save_json(state_file, state)

    if not success:
        sys.exit(1)


if __name__ == "__main__":
    main()
