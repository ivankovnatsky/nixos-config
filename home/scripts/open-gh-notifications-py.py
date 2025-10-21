#!/usr/bin/env python3

import argparse
import subprocess
import sys
import webbrowser
from dataclasses import dataclass
from typing import Iterable, List, Tuple


@dataclass
class Notification:
    thread_id: str
    subject_type: str
    subject_api_url: str


def run_gh(args: List[str]) -> str:
    """Run gh CLI and return stdout, raising on error."""
    proc = subprocess.run(
        ["gh", *args],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )
    if proc.returncode != 0:
        msg = proc.stderr.strip() or proc.stdout.strip() or "unknown error"
        raise RuntimeError(f"gh {' '.join(args)} failed: {msg}")
    return proc.stdout


def fetch_notifications() -> List[Notification]:
    """Fetch unread notifications via gh api, returning basic fields per thread."""
    # Using --jq to avoid streaming-JSON parsing; returns TSV: id, type, subject.url
    jq = ".[] | [.id, .subject.type, .subject.url] | @tsv"
    out = run_gh([
        "api",
        "/notifications",
        "--paginate",
        "-H",
        "Accept: application/vnd.github+json",
        "--jq",
        jq,
    ])

    notifications: List[Notification] = []
    for line in out.splitlines():
        if not line.strip():
            continue
        parts = line.split("\t")
        if len(parts) != 3:
            # Skip malformed lines rather than crashing
            continue
        thread_id, subject_type, subject_api_url = parts
        notifications.append(
            Notification(
                thread_id=thread_id.strip(),
                subject_type=subject_type.strip(),
                subject_api_url=subject_api_url.strip(),
            )
        )
    return notifications


def resolve_html_url(n: Notification) -> str:
    """Resolve a browser URL for a notification subject.

    Tries `gh api <subject.url> --jq .html_url` first (works for PR, Issue,
    WorkflowRun, etc). Falls back to simple API->HTML URL conversion.
    """
    api = n.subject_api_url
    if not api:
        return ""

    # First try to fetch the object's html_url via gh (most objects provide it)
    try:
        html = run_gh(["api", api, "--jq", ".html_url // empty"]).strip()
        if html:
            return html
    except Exception:
        # Ignore and fall back
        pass

    # Fallback: Convert API URL to web URL
    url = api.replace("api.github.com/repos", "github.com")
    # Normalize PR path
    url = url.replace("/pulls/", "/pull/")
    return url


def open_in_browser(url: str) -> bool:
    # Use default browser; open in a new tab if possible
    try:
        return webbrowser.open_new_tab(url)
    except Exception:
        return False


def mark_thread_read(thread_id: str) -> None:
    # Per API: PATCH /notifications/threads/{thread_id} marks as read
    run_gh([
        "api",
        f"/notifications/threads/{thread_id}",
        "-X",
        "PATCH",
        "-H",
        "Accept: application/vnd.github+json",
    ])


def group_urls(ns: Iterable[Notification]) -> Tuple[List[Tuple[str, str]], List[Tuple[str, str]], List[Tuple[str, str]]]:
    """Return (issues, prs, others) each as list of (url, thread_id).

    - PRs will later open with /files
    - Others include Actions workflow runs and any supported subject with html_url
    """
    issue_urls: List[Tuple[str, str]] = []
    pr_urls: List[Tuple[str, str]] = []
    other_urls: List[Tuple[str, str]] = []

    for n in ns:
        url = resolve_html_url(n)
        if not url:
            continue
        if n.subject_type == "PullRequest":
            pr_urls.append((url, n.thread_id))
        elif n.subject_type == "Issue":
            issue_urls.append((url, n.thread_id))
        else:
            other_urls.append((url, n.thread_id))
    return issue_urls, pr_urls, other_urls


def main(argv: List[str]) -> int:
    parser = argparse.ArgumentParser(
        prog="open-gh-notifications",
        description=(
            "Open unread GitHub notifications in your browser using gh CLI. "
            "Pull Requests open on /files. Threads are marked as read after opening."
        ),
    )
    parser.add_argument(
        "-s",
        "--show",
        action="store_true",
        help="Only print the URLs that would be opened (no browser, no marking read)",
    )
    args = parser.parse_args(argv)

    try:
        notifications = fetch_notifications()
    except Exception as e:
        print(f"Failed to fetch notifications via gh: {e}", file=sys.stderr)
        return 1

    issues, prs, others = group_urls(notifications)
    all_urls = [u for u, _ in issues] + [u for u, _ in prs] + [u for u, _ in others]

    if not all_urls:
        print("No notifications found.")
        return 0

    print("URLs to open:")
    for u in all_urls:
        print(u)

    if args.show:
        print("Would open URLs in a new browser window")
        return 0

    # Open issues first, then PRs on /files, then other types (e.g., Actions runs)
    for url, thread_id in issues:
        opened = open_in_browser(url)
        if opened:
            try:
                mark_thread_read(thread_id)
            except Exception as e:
                print(f"Warning: failed to mark thread {thread_id} read: {e}", file=sys.stderr)

    for url, thread_id in prs:
        opened = open_in_browser(f"{url}/files")
        if opened:
            try:
                mark_thread_read(thread_id)
            except Exception as e:
                print(f"Warning: failed to mark thread {thread_id} read: {e}", file=sys.stderr)

    for url, thread_id in others:
        opened = open_in_browser(url)
        if opened:
            try:
                mark_thread_read(thread_id)
            except Exception as e:
                print(f"Warning: failed to mark thread {thread_id} read: {e}", file=sys.stderr)

    print("Opening URLs in a new browser window")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
