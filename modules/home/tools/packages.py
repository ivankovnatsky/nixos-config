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


def run_command(
    cmd: List[str], env: Dict = None, cwd: str = None
) -> tuple[int, str, str]:
    result = subprocess.run(
        cmd, capture_output=True, text=True, env=env or os.environ.copy(), cwd=cwd
    )
    return result.returncode, result.stdout, result.stderr


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
        if not line or ":" not in line:
            continue
        has_transport = "(SSE)" in line or "(HTTP)" in line or "(STDIO)" in line
        has_status = "✓" in line or "!" in line or "✗" in line
        if has_transport or has_status:
            server_name = line.split(":")[0].strip()
            if not server_name.startswith("claude.ai "):
                servers.add(server_name)
    log(f"Detected installed MCP servers: {servers}", Color.BLUE)
    return servers


def get_pkg_binary(pkg_info: Dict) -> str:
    """Extract binary name from package info dict."""
    return pkg_info.get("binary", "")


def get_pkg_version(pkg_info: Dict) -> str:
    """Extract version from package info dict."""
    return pkg_info.get("version", "latest")


def get_pkg_subpackages(pkg_info: Dict) -> Dict:
    """Extract subpackages dict from package info dict."""
    return pkg_info.get("subpackages", {})


def get_pkg_post_install(pkg_info: Dict) -> str:
    """Extract postInstall command from package info dict."""
    return pkg_info.get("postInstall", "")


def pkg_install_spec(name: str, version: str) -> str:
    """Build package@version install specifier."""
    if version and version != "latest":
        return f"{name}@{version}"
    return name


def version_changed(pkg: str, pkg_info, state: Dict, manager: str) -> bool:
    """Check if declared version differs from state."""
    declared = get_pkg_version(pkg_info)
    stored = (
        state.get(manager, {}).get("packages", {}).get(pkg, {}).get("version", "latest")
    )
    return declared != stored


def install_bun_packages(packages: Dict, paths: Dict, state: Dict, bun_config: Dict):
    """Fully declarative bun package management.

    Ensures all declared packages exist in ~/.bun/bin at the declared version.
    """
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
    desired = set(packages.keys())
    state_packages = set(state.get("bun", {}).get("packages", {}).keys())

    # Build binary mapping for tracked packages
    all_tracked = {}
    for pkg, pkg_data in state.get("bun", {}).get("packages", {}).items():
        all_tracked[pkg] = pkg_data.get("binary", pkg.split("/")[-1])
    for pkg, pkg_info in packages.items():
        all_tracked[pkg] = get_pkg_binary(pkg_info)

    env = os.environ.copy()
    env["PATH"] = f"{paths['bun']}:{paths['nodejs']}:{env.get('PATH', '')}"

    state_changed = False

    # 1. CLEANUP: Remove packages no longer in config
    to_remove = {
        pkg: binary
        for pkg, binary in all_tracked.items()
        if pkg not in desired and (bun_bin / binary).exists()
    }

    if to_remove:
        log(f"Removing bun packages: {', '.join(to_remove.keys())}", Color.RED)
        cmd = [f"{paths['bun']}/bun", "remove", "-g"] + list(to_remove.keys())
        run_command(cmd, env)
        state_changed = True

    # 2. INSTALL: Ensure all declared packages exist at correct version
    to_install = []
    for pkg, pkg_info in packages.items():
        binary = get_pkg_binary(pkg_info)
        if not (bun_bin / binary).exists() or version_changed(
            pkg, pkg_info, state, "bun"
        ):
            to_install.append(pkg_install_spec(pkg, get_pkg_version(pkg_info)))
    if to_install:
        log(f"Installing bun packages: {', '.join(to_install)}", Color.GREEN)
        cmd = [f"{paths['bun']}/bun", "install", "-g"] + to_install
        returncode, stdout, stderr = run_command(cmd, env)
        if returncode != 0:
            log(f"Failed to install bun packages: {stderr}", Color.RED)
            return False
        state_changed = True

    if not to_remove and not to_install:
        log("All bun packages in sync", Color.BLUE)

    # Update state
    if state_changed or state_packages != desired:
        state.setdefault("bun", {})["packages"] = {
            pkg: {
                "installed": True,
                "binary": get_pkg_binary(pkg_info),
                "version": get_pkg_version(pkg_info),
            }
            for pkg, pkg_info in packages.items()
        }

    return True


def install_npm_packages(packages: Dict, paths: Dict, state: Dict, npm_config: Dict):
    """Declarative npm package management.

    Ensures all declared packages exist in ~/.npm/bin at the declared version.
    """
    # Handle .npmrc creation
    npmrc_content = npm_config.get("configFile")
    if npmrc_content and not state.get("npm", {}).get("npmrc_created"):
        npmrc_path = os.path.expanduser("~/.npmrc")
        if not os.path.exists(npmrc_path):
            log("Creating .npmrc file", Color.GREEN)
            with open(npmrc_path, "w") as f:
                f.write(npmrc_content)
            state.setdefault("npm", {})["npmrc_created"] = True
        else:
            log(".npmrc already exists, skipping creation", Color.BLUE)
            state.setdefault("npm", {})["npmrc_created"] = True

    npm_bin = Path(paths["npmBin"])
    desired = set(packages.keys())
    state_packages = set(state.get("npm", {}).get("packages", {}).keys())

    env = os.environ.copy()
    env["PATH"] = f"{paths['nodejs']}:{env.get('PATH', '')}"

    state_changed = False

    # Build binary mapping for tracked packages
    all_tracked = {}
    for pkg, pkg_data in state.get("npm", {}).get("packages", {}).items():
        all_tracked[pkg] = pkg_data.get("binary", pkg.split("/")[-1])
    for pkg, pkg_info in packages.items():
        all_tracked[pkg] = get_pkg_binary(pkg_info)

    # 1. CLEANUP: Remove packages no longer in config
    to_remove = {
        pkg: binary
        for pkg, binary in all_tracked.items()
        if pkg not in desired and (npm_bin / binary).exists()
    }

    if to_remove:
        log(f"Removing npm packages: {', '.join(to_remove.keys())}", Color.RED)
        cmd = [f"{paths['nodejs']}/npm", "uninstall", "-g"] + list(to_remove.keys())
        run_command(cmd, env)
        state_changed = True

    # 2. INSTALL: Ensure all declared packages exist at correct version
    to_install = []
    for pkg, pkg_info in packages.items():
        binary = get_pkg_binary(pkg_info)
        if not (npm_bin / binary).exists() or version_changed(
            pkg, pkg_info, state, "npm"
        ):
            to_install.append(pkg_install_spec(pkg, get_pkg_version(pkg_info)))
    if to_install:
        log(f"Installing npm packages: {', '.join(to_install)}", Color.GREEN)
        cmd = [f"{paths['nodejs']}/npm", "install", "-g"] + to_install
        returncode, stdout, stderr = run_command(cmd, env)
        if returncode != 0:
            log(f"Failed to install npm packages: {stderr}", Color.RED)
            return False
        state_changed = True

    if not to_remove and not to_install:
        log("All npm packages in sync", Color.BLUE)

    # 3. POST-INSTALL: Run postInstall commands for packages that need them
    # npm global prefix layout: <prefix>/lib/node_modules/<pkg>
    npm_lib = Path(paths["npmBin"]).parent / "lib" / "node_modules"
    for pkg, pkg_info in packages.items():
        post_install = get_pkg_post_install(pkg_info)
        if not post_install:
            continue
        pkg_dir = npm_lib / pkg
        if not pkg_dir.exists():
            continue
        stored_post_install = (
            state.get("npm", {}).get("packages", {}).get(pkg, {}).get("postInstall", "")
        )
        # Run if: package was just installed, or postInstall command changed,
        # or never ran before
        just_installed = pkg_install_spec(pkg, get_pkg_version(pkg_info)) in to_install
        if just_installed or post_install != stored_post_install:
            log(f"Running postInstall for {pkg}: {post_install}", Color.GREEN)
            returncode, stdout, stderr = run_command(
                ["bash", "-c", post_install], env, cwd=str(pkg_dir)
            )
            if returncode != 0:
                log(f"postInstall failed for {pkg}: {stderr}", Color.RED)
            else:
                log(f"postInstall completed for {pkg}", Color.GREEN)
                state_changed = True

    # 4. SUBPACKAGES: Install additional deps inside package's node_modules
    subpkg_failed = False
    for pkg, pkg_info in packages.items():
        subpkgs = get_pkg_subpackages(pkg_info)
        if not subpkgs:
            continue
        pkg_dir = npm_lib / pkg
        if not pkg_dir.exists():
            log(f"Skipping subpackages for {pkg}: package dir not found", Color.YELLOW)
            continue
        # Compare declared subpackages with state to detect version changes
        stored_subpkgs = (
            state.get("npm", {}).get("packages", {}).get(pkg, {}).get("subpackages", {})
        )
        # Migrate from old list format to dict
        if isinstance(stored_subpkgs, list):
            stored_subpkgs = {}
        to_install_sub = []
        for sp_name, sp_info in subpkgs.items():
            sp_version = sp_info.get("version", "latest")
            stored_version = stored_subpkgs.get(sp_name, {}).get("version")
            missing = not (pkg_dir / "node_modules" / sp_name).exists()
            version_diff = sp_version != stored_version
            if missing or version_diff:
                to_install_sub.append(pkg_install_spec(sp_name, sp_version))
        if not to_install_sub:
            continue
        log(
            f"Installing subpackages for {pkg}: {', '.join(to_install_sub)}",
            Color.GREEN,
        )
        cmd = [f"{paths['nodejs']}/npm", "install", "--save=false"] + to_install_sub
        returncode, stdout, stderr = run_command(cmd, env, cwd=str(pkg_dir))
        if returncode != 0:
            log(f"Failed to install subpackages for {pkg}: {stderr}", Color.RED)
            subpkg_failed = True
        else:
            log(f"Installed subpackages for {pkg}", Color.GREEN)
            state_changed = True

    # Update state (always save progress, even on partial failure)
    if state_changed or state_packages != desired:
        state.setdefault("npm", {})["packages"] = {
            pkg: {
                "installed": True,
                "binary": get_pkg_binary(pkg_info),
                "version": get_pkg_version(pkg_info),
                "subpackages": get_pkg_subpackages(pkg_info),
                "postInstall": get_pkg_post_install(pkg_info),
            }
            for pkg, pkg_info in packages.items()
        }

    return not subpkg_failed


def install_uv_packages(packages: Dict, paths: Dict, state: Dict):
    desired = set(packages.keys())
    state_packages = set(state.get("uv", {}).get("packages", {}).keys())

    # Build binary mapping for installed check
    binary_map = {pkg: get_pkg_binary(info) for pkg, info in packages.items()}
    current = get_installed_uv_packages(paths["uvBin"], binary_map)

    all_tracked = {}
    for pkg, pkg_data in state.get("uv", {}).get("packages", {}).items():
        all_tracked[pkg] = pkg_data.get("binary", pkg)
    for pkg, pkg_info in packages.items():
        if pkg not in all_tracked:
            all_tracked[pkg] = get_pkg_binary(pkg_info)

    to_remove = []
    for pkg, binary in all_tracked.items():
        if pkg not in desired and (Path(paths["uvBin"]) / binary).exists():
            to_remove.append(pkg)

    state_changed = False

    env = os.environ.copy()
    env["PATH"] = f"{paths['uv']}:{env.get('PATH', '')}"
    env["UV_TOOL_BIN_DIR"] = paths["uvBin"]
    env["UV_TOOL_DIR"] = paths["uvToolDir"]

    if to_remove:
        log(f"Removing UV packages: {', '.join(to_remove)}", Color.RED)

        for pkg in to_remove:
            cmd = [f"{paths['uv']}/uv", "tool", "uninstall", pkg]
            returncode, stdout, stderr = run_command(cmd, env)

            if returncode != 0:
                log(f"Failed to remove UV package {pkg}: {stderr}", Color.RED)
            else:
                log(f"Removed: {pkg}", Color.GREEN)
                state_changed = True

    # Install missing packages or reinstall on version change
    to_install = []
    for pkg, pkg_info in packages.items():
        if pkg not in current or version_changed(pkg, pkg_info, state, "uv"):
            to_install.append(pkg)

    if to_install:
        log(f"Installing UV packages: {', '.join(to_install)}", Color.GREEN)

        for pkg in to_install:
            pkg_info = packages[pkg]
            spec = pkg_install_spec(pkg, get_pkg_version(pkg_info))
            cmd = [f"{paths['uv']}/uv", "tool", "install", spec]
            # Force reinstall if already present but version changed
            if pkg in current:
                cmd.append("--force")
            returncode, stdout, stderr = run_command(cmd, env)

            if returncode != 0:
                log(f"Failed to install UV package {spec}: {stderr}", Color.RED)
                return False
            else:
                log(f"Installed: {spec}", Color.GREEN)
                state_changed = True
    elif not to_remove:
        log("All UV packages already installed", Color.BLUE)

    if state_changed or state_packages != desired:
        state.setdefault("uv", {})["packages"] = {
            pkg: {
                "installed": True,
                "binary": get_pkg_binary(pkg_info),
                "version": get_pkg_version(pkg_info),
            }
            for pkg, pkg_info in packages.items()
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
                ]
                secret_paths = server_config.get("secretPaths", {})
                for header in server_config.get("headers", []):
                    processed_header = substitute_secrets(header, secret_paths)
                    cmd.extend(["-H", processed_header])
                args = server_config.get("args", [])
                if args:
                    cmd.append("--")
                    cmd.extend(args)
                elif server_config.get("url"):
                    cmd.append(server_config["url"])

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


def install_git_repos(repos: Dict[str, str], paths: Dict, state: Dict):
    """Clone or update git repositories to specified paths."""
    if not repos:
        return True

    installed = set(state.get("gitRepos", {}).get("installed", []))
    desired = set(repos.keys())
    to_install = desired - installed
    to_remove = installed - desired

    env = os.environ.copy()
    env["PATH"] = f"{paths['git']}:{env.get('PATH', '')}"

    state_changed = False

    for dest_path in to_remove:
        expanded_path = os.path.expanduser(dest_path)
        if os.path.exists(expanded_path):
            log(f"Removing git repo: {dest_path}", Color.RED)
            shutil.rmtree(expanded_path)
            state_changed = True
        installed.discard(dest_path)

    for dest_path in to_install:
        repo_url = repos[dest_path]
        expanded_path = os.path.expanduser(dest_path)

        if os.path.exists(expanded_path):
            log(f"Updating git repo: {dest_path}", Color.BLUE)
            cmd = [f"{paths['git']}/git", "-C", expanded_path, "pull", "--ff-only"]
            returncode, stdout, stderr = run_command(cmd, env)
            if returncode != 0:
                log(f"Failed to update {dest_path}: {stderr}", Color.YELLOW)
        else:
            log(f"Cloning git repo: {repo_url} -> {dest_path}", Color.GREEN)
            parent_dir = os.path.dirname(expanded_path)
            os.makedirs(parent_dir, exist_ok=True)
            cmd = [f"{paths['git']}/git", "clone", repo_url, expanded_path]
            returncode, stdout, stderr = run_command(cmd, env)
            if returncode != 0:
                log(f"Failed to clone {repo_url}: {stderr}", Color.RED)
                continue

        installed.add(dest_path)
        state_changed = True

    if not to_install and not to_remove:
        log("All git repos already installed", Color.BLUE)

    if state_changed or installed != desired:
        state.setdefault("gitRepos", {})["installed"] = list(installed)

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

    bun_config = config.get("bun", {})
    npm_config = config.get("npm", {})

    bun_packages = bun_config.get("packages", {})
    bun_only_config = {"configFile": bun_config.get("configFile")}
    success &= install_bun_packages(
        bun_packages, config["paths"], state, bun_only_config
    )

    npm_packages = npm_config.get("packages", {})
    npm_only_config = {"configFile": npm_config.get("configFile")}
    success &= install_npm_packages(
        npm_packages, config["paths"], state, npm_only_config
    )

    if config.get("uv", {}).get("packages"):
        success &= install_uv_packages(config["uv"]["packages"], config["paths"], state)

    # Always call install_mcp_servers to handle both installation and removal
    # Even if servers is empty, we need to remove any existing servers
    success &= install_mcp_servers(
        config.get("mcp", {}).get("servers", {}), config["paths"], state
    )

    if config.get("curlShell"):
        success &= install_curl_shell_scripts(
            config["curlShell"], config["paths"], state
        )

    if config.get("gitRepos"):
        success &= install_git_repos(config["gitRepos"], config["paths"], state)

    save_json(state_file, state)

    if not success:
        sys.exit(1)


if __name__ == "__main__":
    main()
