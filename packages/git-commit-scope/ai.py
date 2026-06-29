"""AI-backed subject shortening for git-commit-scope."""

import json
import shutil
import subprocess

import click

AI_SHORTEN_PROMPT = """Shorten this git commit subject to STRICTLY {max_chars} characters or fewer. Count carefully.
Output ONLY the shortened subject — no quotes, no backticks, no explanation, no trailing period.
Keep the core meaning. Use common abbreviations (config, auth, env, db, etc.) if needed.

Subject: {subject}
Max chars: {max_chars}"""

AI_BACKENDS = [
    {
        "name": "claude",
        "cmd": [
            "claude",
            "-p",
            "{prompt}",
            "--model",
            "claude-haiku-4-5-20251001",
            "--output-format",
            "json",
        ],
        "parse": "json",
        "json_key": "result",
    },
    {
        "name": "codex",
        "cmd": [
            "codex",
            "exec",
            "--ephemeral",
            "--skip-git-repo-check",
            "-m",
            "gpt-5.3-codex-spark",
            "{prompt}",
        ],
        "parse": "codex",
    },
]


def try_ai_shorten(subject: str, max_chars: int) -> str | None:
    """Try AI backends to shorten a commit subject. Returns shortened subject or None."""
    prompt = AI_SHORTEN_PROMPT.format(max_chars=max_chars, subject=subject)

    for backend in AI_BACKENDS:
        bin_name = backend["cmd"][0]
        if not shutil.which(bin_name):
            click.echo(f"  ai: {backend['name']} not found, skipping", err=True)
            continue

        cmd = [s.replace("{prompt}", prompt) for s in backend["cmd"]]
        click.echo(f"  ai: trying {backend['name']}...", err=True)

        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=60,
                stdin=subprocess.DEVNULL,
            )
            if result.returncode != 0:
                click.echo(
                    f"  ai: {backend['name']} failed (exit {result.returncode})",
                    err=True,
                )
                continue

            shortened = _parse_ai_output(result.stdout, backend)
            if not shortened:
                click.echo(f"  ai: {backend['name']} returned empty output", err=True)
                continue

            if len(shortened) > max_chars:
                click.echo(
                    f"  ai: {backend['name']} suggestion too long: "
                    f"{len(shortened)} chars ({shortened!r})",
                    err=True,
                )
                continue

            return shortened

        except subprocess.TimeoutExpired:
            click.echo(f"  ai: {backend['name']} timed out", err=True)
            continue
        except Exception as e:
            click.echo(f"  ai: {backend['name']} error: {e}", err=True)
            continue

    return None


def _parse_ai_output(stdout: str, backend: dict) -> str | None:
    """Parse AI backend output to extract just the suggested subject."""
    parse_mode = backend.get("parse", "text")

    if parse_mode == "json":
        try:
            data = json.loads(stdout)
            key = backend.get("json_key", "result")
            text = data.get(key, "")
        except (json.JSONDecodeError, KeyError):
            text = stdout
    elif parse_mode == "codex":
        # Codex dumps headers then the response, duplicated at the end.
        # Take the last non-empty line that isn't metadata.
        lines = stdout.strip().split("\n")
        text = ""
        for line in reversed(lines):
            line = line.strip()
            if line and not line.startswith(
                ("---", "user", "codex", "tokens", "Reading")
            ):
                text = line
                break
    else:
        text = stdout.strip()

    if not text:
        return None

    # Strip common AI artifacts
    text = text.strip().strip("`\"'").strip()
    # Remove trailing period if added
    text = text.rstrip(".")
    return text if text else None
