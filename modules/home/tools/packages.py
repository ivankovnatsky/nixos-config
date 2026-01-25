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


def get_installed_bun_packages(bun_bin: str, packages: Dict[str, str]) -> Set[str]:
    installed = set()
    for package, binary in packages.items():
        if (Path(bun_bin) / binary).exists():
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


def install_bun_packages(
    packages: Dict[str, str], paths: Dict, state: Dict, bun_config: Dict
):
    """Fully declarative bun package management.

    Ensures:
    - All declared packages exist in ~/.bun/bin
    - No declared packages exist in ~/.npm/bin (cleanup legacy)
    - Packages removed from config are removed from both locations
    """
    # Migrate state from "npm" to "bun" for backward compatibility
    if "npm" in state and "bun" not in state:
        log("Migrating state from npm to bun", Color.YELLOW)
        state["bun"] = state.pop("npm")

    # Handle .bunfig.toml creation (only if bun.configFile is set)
    bunfig_content = bun_config.get("configFile")
    if bunfig_content and not state.get("bun", {}).get("bunfig_created"):
        bunfig_path = os.path.expanduser("~/.bunfig.toml")
        if not os.path.exists(bunfig_path):
            log("Creating .bunfig.toml file", Color.GREEN)
            with open(bunfig_path, "w") as f:
                f.write(bunfig_content)
            state.setdefault("bun", {})["bunfig_created"] = True
        else:
            log(".bunfig.toml already exists, skipping creation", Color.BLUE)
            state.setdefault("bun", {})["bunfig_created"] = True

    bun_bin = Path(paths["bunBin"])
    npm_bin = Path(paths["npmBin"])
    desired = set(packages.keys())

    # Merge state packages from both npm and bun for tracking (backward compat)
    bun_state_packages = state.get("bun", {}).get("packages", {})
    npm_state_packages = state.get("npm", {}).get("packages", {})
    merged_state_packages = {**npm_state_packages, **bun_state_packages}
    state_packages = set(merged_state_packages.keys())

    # Build binary mapping for all tracked packages
    all_tracked = {}
    for pkg, pkg_data in merged_state_packages.items():
        all_tracked[pkg] = pkg_data.get("binary", pkg.split("/")[-1])
    for pkg, binary in packages.items():
        all_tracked[pkg] = binary

    env = os.environ.copy()
    env["PATH"] = f"{paths['bun']}:{paths['nodejs']}:{env.get('PATH', '')}"

    state_changed = False

    # 1. CLEANUP: Remove packages no longer in config from both locations
    to_remove = {
        pkg: binary
        for pkg, binary in all_tracked.items()
        if pkg not in desired
        and ((bun_bin / binary).exists() or (npm_bin / binary).exists())
    }

    if to_remove:
        log(f"Removing unmanaged packages: {', '.join(to_remove.keys())}", Color.RED)
        # Try bun first
        cmd = [f"{paths['bun']}/bun", "remove", "-g"] + list(to_remove.keys())
        run_command(cmd, env)
        # Fallback to npm for any remaining
        still_present = [
            pkg
            for pkg, binary in to_remove.items()
            if (bun_bin / binary).exists() or (npm_bin / binary).exists()
        ]
        if still_present:
            cmd = [f"{paths['nodejs']}/npm", "uninstall", "-g"] + still_present
            run_command(cmd, env)
        state_changed = True

    # 2. CLEANUP LEGACY: Remove npm versions of declared packages
    npm_cleanup = [
        pkg for pkg, binary in packages.items() if (npm_bin / binary).exists()
    ]
    if npm_cleanup:
        log(f"Removing legacy npm versions: {', '.join(npm_cleanup)}", Color.YELLOW)
        cmd = [f"{paths['nodejs']}/npm", "uninstall", "-g"] + npm_cleanup
        run_command(cmd, env)
        state_changed = True

    # 3. INSTALL: Ensure all declared packages exist in bun bin
    to_install = [
        pkg for pkg, binary in packages.items() if not (bun_bin / binary).exists()
    ]
    if to_install:
        log(f"Installing bun packages: {', '.join(to_install)}", Color.GREEN)
        cmd = [f"{paths['bun']}/bun", "install", "-g"] + to_install
        returncode, stdout, stderr = run_command(cmd, env)
        if returncode != 0:
            log(f"Failed to install bun packages: {stderr}", Color.RED)
            return False
        state_changed = True

    if not to_remove and not npm_cleanup and not to_install:
        log("All bun packages in sync", Color.BLUE)

    # Update state
    if state_changed or state_packages != desired:
        state.setdefault("bun", {})["packages"] = {
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


def install_curl_shell_scripts(scripts: Dict[str, str], paths: Dict, state: Dict):
    """Install scripts via curl piped to shell interpreter."""
    if not scripts:
        return True

    installed = set(state.get("curlShell", {}).get("installed", []))
    desired = set(scripts.keys())
    to_install = desired - installed

    if not to_install:
        log("All curl shell scripts already installed", Color.BLUE)
        return True

    env = os.environ.copy()
    env["PATH"] = (
        f"{paths.get('bash', '/bin')}:{paths['curl']}:"
        f"{paths.get('perl', '')}:{paths.get('coreutils', '')}:{env.get('PATH', '')}"
    )

    state_changed = False

    for url in to_install:
        shell = scripts[url]
        log(f"Running: curl -fsSL {url} | {shell}", Color.GREEN)

        shell_path = (
            f"{paths.get('bash', '/bin')}/{shell}" if shell == "bash" else shell
        )

        curl_cmd = [f"{paths['curl']}/curl", "-fsSL", url]
        curl_proc = subprocess.Popen(
            curl_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env
        )

        shell_proc = subprocess.Popen(
            [shell_path],
            stdin=curl_proc.stdout,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=env,
        )

        curl_proc.stdout.close()
        stdout, stderr = shell_proc.communicate()

        if shell_proc.returncode != 0:
            log(f"Failed to run script from {url}: {stderr.decode()}", Color.RED)
            continue

        log(f"Successfully installed from {url}", Color.GREEN)
        installed.add(url)
        state_changed = True

    if state_changed:
        state.setdefault("curlShell", {})["installed"] = list(installed)

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

    # Support both bun and npm config keys for backward compatibility
    bun_config = config.get("bun", {})
    npm_config = config.get("npm", {})
    packages = {**npm_config.get("packages", {}), **bun_config.get("packages", {})}
    # Only use bun.configFile for bunfig.toml (not npm.configFile - different format)
    bun_only_config = {"configFile": bun_config.get("configFile")}

    if packages:
        success &= install_bun_packages(
            packages, config["paths"], state, bun_only_config
        )

    if config.get("uv", {}).get("packages"):
        success &= install_uv_packages(config["uv"]["packages"], config["paths"], state)

    if config.get("mcp", {}).get("servers"):
        success &= install_mcp_servers(config["mcp"]["servers"], config["paths"], state)

    if config.get("curlShell"):
        success &= install_curl_shell_scripts(
            config["curlShell"], config["paths"], state
        )

    save_json(state_file, state)

    if not success:
        sys.exit(1)


if __name__ == "__main__":
    main()
