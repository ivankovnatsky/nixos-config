#!/usr/bin/env python3
"""
Spawn tmux sessions with multiple windows, each running a command in a specified folder.

Usage examples:
    # From fd/find output via pipe
    fd . --type directory | rg 'pattern' | tmux-spawn --command 'terragrunt init && tofu plan'

    # From explicit folders
    tmux-spawn --folders ./dir1 ./dir2 ./dir3 --command 'make build'

    # With custom session name
    tmux-spawn --folders ./dir1 --command 'npm test' --session my-session
"""

import subprocess
import sys
import time

import click


def get_folders_from_stdin():
    """Read folder paths from stdin (pipe)."""
    if sys.stdin.isatty():
        return []
    return [line.strip() for line in sys.stdin if line.strip()]


def run_tmux_command(
    args: list[str], check: bool = True
) -> subprocess.CompletedProcess:
    """Run a tmux command."""
    return subprocess.run(["tmux"] + args, check=check, capture_output=True, text=True)


def session_exists(session_name: str) -> bool:
    """Check if a tmux session already exists."""
    result = run_tmux_command(["has-session", "-t", session_name], check=False)
    return result.returncode == 0


def create_session(session_name: str, first_dir: str, command: str):
    """Create a new tmux session with the first window."""
    run_tmux_command(
        [
            "new-session",
            "-d",
            "-s",
            session_name,
            "-c",
            first_dir,
        ]
    )
    run_tmux_command(
        [
            "send-keys",
            "-t",
            session_name,
            command,
            "Enter",
        ]
    )


def add_window(session_name: str, directory: str, command: str):
    """Add a new window to an existing session."""
    run_tmux_command(
        [
            "new-window",
            "-t",
            session_name,
            "-c",
            directory,
        ]
    )
    run_tmux_command(
        [
            "send-keys",
            "-t",
            session_name,
            command,
            "Enter",
        ]
    )


def attach_session(session_name: str):
    """Attach to a tmux session."""
    subprocess.run(["tmux", "attach", "-t", session_name])


@click.command(
    epilog="""
Examples:\n
  # Pipe folders from fd/find\n
  fd . --type directory | rg 'pattern' | tmux-spawn --command 'make build'\n\n
  # Explicit folders\n
  tmux-spawn --folders ./dir1 --folders ./dir2 --command 'npm test'\n\n
  # Custom session name\n
  tmux-spawn --folders ./dir1 --command 'cargo build' --session my-build
""",
)
@click.option(
    "--folders",
    multiple=True,
    help="List of folders to open in tmux windows. Can also be piped via stdin.",
)
@click.option(
    "--command",
    "-c",
    required=True,
    help="Command to run in each tmux window.",
)
@click.option(
    "--session",
    "-s",
    default=None,
    help="Custom tmux session name. Defaults to 'tmux-spawn-<timestamp>'.",
)
@click.option(
    "--no-attach",
    is_flag=True,
    help="Don't attach to the session after creating it.",
)
def main(folders, command, session, no_attach):
    """Spawn tmux sessions with windows for each folder, running a command."""
    # Collect folders from both stdin and --folders argument
    all_folders = []
    stdin_folders = get_folders_from_stdin()
    if stdin_folders:
        all_folders.extend(stdin_folders)
    if folders:
        all_folders.extend(folders)

    if not all_folders:
        click.echo(
            "Error: No folders provided. Use --folders or pipe folder paths.",
            err=True,
        )
        sys.exit(1)

    # Generate session name
    session_name = session or f"tmux-spawn-{int(time.time())}"

    # Check if session already exists
    if session_exists(session_name):
        click.echo(f"Error: Session '{session_name}' already exists.", err=True)
        sys.exit(1)

    # Create session with first folder
    click.echo(
        f"Creating session '{session_name}' with {len(all_folders)} window(s)...",
        err=True,
    )
    create_session(session_name, all_folders[0], command)

    # Add remaining folders as windows
    for folder in all_folders[1:]:
        add_window(session_name, folder, command)

    click.echo(
        f"Session '{session_name}' created with {len(all_folders)} window(s).",
        err=True,
    )

    # Attach to session
    if not no_attach:
        attach_session(session_name)


if __name__ == "__main__":
    main()
