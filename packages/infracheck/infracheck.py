"""Run infrastructure health checks and alert on failures."""

import json
import platform
import subprocess
import sys
import urllib.error
import urllib.request

import click


def send_discord(webhook_url, message):
    payload = json.dumps({"content": message}).encode()
    req = urllib.request.Request(
        webhook_url,
        data=payload,
        headers={
            "Content-Type": "application/json",
            "User-Agent": "infracheck/1.0",
        },
    )
    try:
        urllib.request.urlopen(req, timeout=10)
        return True
    except Exception as e:
        print(f"Discord notification failed: {e}", file=sys.stderr)
        return False


def load_config(path):
    with open(path) as f:
        return json.load(f)


def get_webhook_url(config):
    webhook_file = config.get("discordWebhookFile")
    if webhook_file:
        with open(webhook_file) as f:
            return f.read().strip()
    return None


def check_command(opts):
    cmd = opts.get("command")
    if not cmd:
        return False, "no command specified"

    expect_exit = opts.get("expectExit", 0)
    timeout_secs = opts.get("timeout", 30)
    try:
        result = subprocess.run(
            cmd if isinstance(cmd, list) else ["sh", "-c", cmd],
            capture_output=True,
            text=True,
            timeout=timeout_secs,
        )
        if result.returncode != expect_exit:
            stderr = result.stderr.strip()[:200] if result.stderr else ""
            return False, f"exit {result.returncode}: {stderr}"
        return True, "ok"
    except subprocess.TimeoutExpired:
        return False, f"timed out after {timeout_secs}s"
    except Exception as e:
        return False, str(e)


def check_url(opts):
    url = opts.get("url")
    if not url:
        return False, "no url specified"

    timeout_secs = opts.get("timeout", 10)
    expect_status = opts.get("expectStatus", 200)
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "infracheck/1.0"})
        resp = urllib.request.urlopen(req, timeout=timeout_secs)
        status = resp.status
    except urllib.error.HTTPError as e:
        status = e.code
    except Exception as e:
        return False, str(e)

    if status != expect_status:
        return False, f"HTTP {status} (expected {expect_status})"
    return True, f"HTTP {status}"


CHECKS = {
    "command": check_command,
    "url": check_url,
}


def run_checks(checks_config):
    results = []
    for check in checks_config:
        name = check.get("name", "unnamed")
        check_type = check.get("type")
        opts = check.get("options", {})

        if check_type not in CHECKS:
            results.append((name, False, f"unknown check type: {check_type}"))
            continue

        passed, message = CHECKS[check_type](opts)
        results.append((name, passed, message))

    return results


def format_results(hostname, results):
    failures = [(n, m) for n, passed, m in results if not passed]
    if not failures:
        return None

    lines = [f"**[infracheck@{hostname}]** {len(failures)} check(s) failed:\n"]
    for name, message in failures:
        lines.append(f"- **{name}**: {message}")

    return "\n".join(lines)


@click.command()
@click.option("--config", required=True, help="Path to config JSON file.")
@click.option("--dry-run", is_flag=True, help="Print instead of sending.")
@click.option("--verbose", is_flag=True, help="Show all check results.")
def main(config, dry_run, verbose):
    """Run infrastructure health checks and alert on failures."""
    cfg = load_config(config)
    hostname = platform.node()

    checks_config = cfg.get("checks", [])
    if not checks_config:
        print("No checks configured.")
        return

    results = run_checks(checks_config)

    if verbose:
        for name, passed, message in results:
            status = "PASS" if passed else "FAIL"
            print(f"[{status}] {name}: {message}")

    message = format_results(hostname, results)

    if not message:
        if verbose:
            print("\nAll checks passed.")
        return

    if dry_run:
        print(message)
        return

    webhook_url = get_webhook_url(cfg)
    if not webhook_url:
        print(message)
        return

    if send_discord(webhook_url, message):
        print(
            f"Alert sent to Discord ({len([r for r in results if not r[1]])} failure(s))."
        )
    else:
        print(message)
        sys.exit(1)


if __name__ == "__main__":
    main()
