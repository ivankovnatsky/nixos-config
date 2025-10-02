#!/usr/bin/env python3

import json
import os
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


def run_command(cmd: List[str], env: Dict = None) -> tuple[int, str, str]:
    result = subprocess.run(
        cmd, capture_output=True, text=True, env=env or os.environ.copy()
    )
    return result.returncode, result.stdout, result.stderr


def get_installed_npm_packages(npm_bin: str) -> Set[str]:
    npm_path = Path(npm_bin).parent.parent
    if not npm_path.exists():
        return set()

    installed = set()
    for binary in ["npm-groovy-lint", "claude", "codex", "gemini", "happy"]:
        if (Path(npm_bin) / binary).exists():
            package_map = {
                "npm-groovy-lint": "npm-groovy-lint",
                "claude": "@anthropic-ai/claude-code",
                "codex": "@openai/codex",
                "gemini": "@google/gemini-cli",
                "happy": "happy-coder",
            }
            installed.add(package_map.get(binary, binary))
    return installed


def get_installed_mcp_servers(claude_cli: str) -> Set[str]:
    if not os.path.exists(claude_cli):
        return set()

    returncode, stdout, _ = run_command([claude_cli, "mcp", "list"])
    if returncode != 0:
        return set()

    servers = set()
    for line in stdout.split("\n"):
        line = line.strip()
        if ":" in line and ("(SSE)" in line or "(HTTP)" in line or "(STDIO)" in line):
            server_name = line.split(":")[0].strip()
            servers.add(server_name)
    return servers


def install_npm_packages(packages: List[str], paths: Dict, state: Dict, npm_config: Dict):
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

    current = get_installed_npm_packages(paths["npmBin"])
    desired = set(packages)

    to_install = desired - current
    to_remove = current - desired

    if to_remove:
        log(f"Would remove NPM packages: {', '.join(to_remove)}", Color.RED)
        log("(Skipping removal - manual cleanup recommended)", Color.YELLOW)

    if to_install:
        log(f"Installing NPM packages: {', '.join(to_install)}", Color.GREEN)
        env = os.environ.copy()
        env["PATH"] = f"{paths['nodejs']}:{paths['tar']}:{paths['gzip']}:{paths['curl']}:{env.get('PATH', '')}"

        npm_cmd = [f"{paths['nodejs']}/npm", "install", "--global", "--force"] + list(
            packages
        )
        returncode, stdout, stderr = run_command(npm_cmd, env)

        if returncode != 0:
            log(f"Failed to install NPM packages: {stderr}", Color.RED)
            return False

        state.setdefault("npm", {})["packages"] = {pkg: {"installed": True} for pkg in packages}
    else:
        log("All NPM packages already installed", Color.BLUE)

    return True


def install_mcp_servers(servers: Dict, paths: Dict, state: Dict):
    claude_cli = paths["claudeCli"]

    if not os.path.exists(claude_cli):
        log("Claude CLI not found, skipping MCP server configuration", Color.YELLOW)
        return True

    env = os.environ.copy()
    env["PATH"] = f"{paths['nodejs']}:{paths['npmBin']}:{paths['python']}:{env.get('PATH', '')}"

    # Check state first - if all servers are in state as installed, skip
    state_servers = set(state.get("mcp", {}).get("servers", {}).keys())
    desired = set(servers.keys())

    if state_servers == desired:
        log("All MCP servers already installed", Color.BLUE)
        return True

    current = get_installed_mcp_servers(claude_cli)
    to_install = desired - current
    to_remove = current - desired

    if to_remove:
        log(f"Removing MCP servers: {', '.join(to_remove)}", Color.RED)
        for server_name in to_remove:
            returncode, _, stderr = run_command(
                [claude_cli, "mcp", "remove", server_name, "-s", "user"], env
            )
            if returncode != 0:
                log(f"Failed to remove {server_name}: {stderr}", Color.RED)

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
                for header in server_config.get("headers", []):
                    cmd.extend(["-H", header])

            returncode, _, stderr = run_command(cmd, env)
            if returncode != 0:
                if "already exists" in stderr:
                    log(f"{server_name} already exists, marking as installed", Color.BLUE)
                else:
                    log(f"Failed to install {server_name}: {stderr}", Color.RED)
                    continue
            else:
                log(f"Installed {server_name}", Color.GREEN)

        state.setdefault("mcp", {})["servers"] = {
            name: {
                "installed": True,
                "scope": config["scope"],
                "transport": config["transport"],
                "url": config["url"],
            }
            for name, config in servers.items()
        }
    else:
        log("All MCP servers already installed", Color.BLUE)

    return True


def main():
    if len(sys.argv) < 3 or sys.argv[1] != "--config":
        log("Usage: manage-activation.py --config <config.json>", Color.RED)
        sys.exit(1)

    config_path = sys.argv[2]
    config = load_json(config_path)

    state_file = config["stateFile"]
    state = load_json(state_file)


    success = True

    if config.get("npm", {}).get("packages"):
        success &= install_npm_packages(
            config["npm"]["packages"], config["paths"], state, config["npm"]
        )

    if config.get("mcp", {}).get("servers"):
        success &= install_mcp_servers(
            config["mcp"]["servers"], config["paths"], state
        )

    save_json(state_file, state)

    if not success:
        sys.exit(1)


if __name__ == "__main__":
    main()
