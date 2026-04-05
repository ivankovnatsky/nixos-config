"""Repository init, sync, and status operations."""

import os
import sys

from alerting import alert
from git_ops import has_git_lock, run_git


def init_repo(repo, webhook_url=None):
    path = repo["path"]
    remote = repo["remote"]
    remote_url = repo["remoteUrl"]
    branch = repo["branch"]
    display = repo.get("name") or os.path.basename(path)
    name = f"{display} ({remote}/{branch})"

    if not os.path.isdir(path):
        print(f"{name}: creating directory {path}", file=sys.stderr)
        try:
            os.makedirs(path, exist_ok=True)
        except OSError as e:
            alert(webhook_url, f"`{name}`: failed to create directory — {e}")
            return False

    git_dir = os.path.join(path, ".git")
    if not os.path.isdir(git_dir):
        print(f"{name}: initializing git repo at {path}", file=sys.stderr)
        result = run_git("init", cwd=path)
        if result.returncode != 0:
            alert(webhook_url, f"`{name}`: git init failed")
            return False

    # Ensure remote exists with correct URL
    result = run_git("remote", "get-url", remote, cwd=path, check=False)
    if result.returncode != 0:
        print(f"{name}: adding remote {remote} -> {remote_url}", file=sys.stderr)
        run_git("remote", "add", remote, remote_url, cwd=path)
    elif result.stdout.strip() != remote_url:
        print(f"{name}: updating remote {remote} -> {remote_url}", file=sys.stderr)
        run_git("remote", "set-url", remote, remote_url, cwd=path)
    else:
        print(f"{name}: remote {remote} OK", file=sys.stderr)

    # Fetch from remote
    result = run_git("fetch", remote, cwd=path, check=False)
    if result.returncode != 0:
        alert(webhook_url, f"`{name}`: fetch failed — {result.stderr.strip()}")
        return False

    # Ensure branch exists and tracks remote
    result = run_git("rev-parse", "--verify", branch, cwd=path, check=False)
    if result.returncode != 0:
        # Local branch doesn't exist — check if remote branch does
        result = run_git(
            "rev-parse", "--verify", f"{remote}/{branch}", cwd=path, check=False
        )
        if result.returncode == 0:
            print(
                f"{name}: creating branch {branch} tracking {remote}/{branch}",
                file=sys.stderr,
            )
            result = run_git(
                "checkout",
                "-b",
                branch,
                "--track",
                f"{remote}/{branch}",
                cwd=path,
                check=False,
            )
            if result.returncode != 0:
                alert(
                    webhook_url,
                    f"`{name}`: failed to create branch {branch} — {result.stderr.strip()}",
                )
                return False
        else:
            print(
                f"{name}: branch {branch} not on remote yet (will be created on first push)",
                file=sys.stderr,
            )
    else:
        # Set upstream tracking
        run_git("branch", "-u", f"{remote}/{branch}", branch, cwd=path, check=False)

    print(f"{name}: init complete", file=sys.stderr)
    return True


def needs_init(repo):
    """Check if a repo needs initialization."""
    path = repo["path"]
    remote = repo["remote"]
    remote_url = repo["remoteUrl"]

    if not os.path.isdir(path):
        return True
    if not os.path.isdir(os.path.join(path, ".git")):
        return True

    result = run_git("remote", "get-url", remote, cwd=path, check=False)
    if result.returncode != 0:
        return True
    if result.stdout.strip() != remote_url:
        return True

    return False


def sync_repo(repo, webhook_url=None):
    path = repo["path"]
    remote = repo["remote"]
    branch = repo["branch"]
    sync_mode = repo.get("syncMode", "pull-push")
    display = repo.get("name") or os.path.basename(path)
    name = f"{display} ({remote}/{branch})"

    if not os.path.isdir(path):
        print(f"{name}: skip ({path} does not exist)", file=sys.stderr)
        return True

    if not os.path.isdir(os.path.join(path, ".git")):
        print(f"{name}: skip (not a git repo)", file=sys.stderr)
        return True

    if has_git_lock(path):
        print(f"{name}: skip (git lock file exists)", file=sys.stderr)
        return True

    ok = True
    actions = []

    # Fetch
    result = run_git("fetch", remote, cwd=path, check=False)
    if result.returncode != 0:
        alert(webhook_url, f"`{name}`: fetch failed — {result.stderr.strip()}")
        return False

    # Check if remote branch exists
    result = run_git(
        "rev-parse", "--verify", f"{remote}/{branch}", cwd=path, check=False
    )
    remote_exists = result.returncode == 0

    # Check if local branch exists
    result = run_git("rev-parse", "--verify", branch, cwd=path, check=False)
    local_exists = result.returncode == 0

    # Pull (ff-only) — only if HEAD is on the target branch and this repo allows pulls.
    if sync_mode == "push-only":
        print(f"{name}: skip pull (push-only mode)", file=sys.stderr)
    elif remote_exists and local_exists:
        head_ref = run_git("symbolic-ref", "--short", "HEAD", cwd=path, check=False)
        current_branch = head_ref.stdout.strip() if head_ref.returncode == 0 else None

        if current_branch != branch:
            print(
                f"{name}: skip pull (HEAD is on {current_branch!r}, not {branch!r})",
                file=sys.stderr,
            )
        else:
            local_before = run_git(
                "rev-parse", branch, cwd=path, check=False
            ).stdout.strip()
            result = run_git(
                "merge", "--ff-only", f"{remote}/{branch}", cwd=path, check=False
            )
            if result.returncode != 0:
                alert(
                    webhook_url,
                    f"`{name}`: pull failed (not fast-forward) — resolve manually",
                )
                ok = False
            else:
                local_after = run_git(
                    "rev-parse", branch, cwd=path, check=False
                ).stdout.strip()
                if local_before != local_after:
                    count = run_git(
                        "rev-list",
                        "--count",
                        f"{local_before}..{local_after}",
                        cwd=path,
                        check=False,
                    )
                    n = count.stdout.strip() if count.returncode == 0 else "?"
                    actions.append(f"pulled {n} commit(s)")

    # Push — skip for pull-only repos.
    if sync_mode == "pull-only":
        print(f"{name}: skip push (pull-only mode)", file=sys.stderr)
    elif local_exists:
        local_sha = run_git("rev-parse", branch, cwd=path, check=False).stdout.strip()
        remote_sha = (
            run_git(
                "rev-parse", f"{remote}/{branch}", cwd=path, check=False
            ).stdout.strip()
            if remote_exists
            else None
        )
        result = run_git("push", remote, branch, cwd=path, check=False)
        if result.returncode != 0:
            stderr = result.stderr.strip()
            if "non-fast-forward" in stderr or "rejected" in stderr:
                alert(
                    webhook_url,
                    f"`{name}`: push rejected (non-fast-forward) — resolve manually",
                )
            else:
                alert(webhook_url, f"`{name}`: push failed — {stderr}")
            ok = False
        elif remote_sha and local_sha != remote_sha:
            count = run_git(
                "rev-list",
                "--count",
                f"{remote_sha}..{local_sha}",
                cwd=path,
                check=False,
            )
            n = count.stdout.strip() if count.returncode == 0 else "?"
            actions.append(f"pushed {n} commit(s)")
    elif not remote_exists:
        print(f"{name}: skip (no local or remote branch yet)", file=sys.stderr)

    if ok:
        summary = ", ".join(actions) if actions else "up to date"
        print(f"{name}: OK ({summary})", file=sys.stderr)

    return ok


def status_repo(repo):
    path = repo["path"]
    remote = repo["remote"]
    branch = repo["branch"]
    display = repo.get("name") or os.path.basename(path)
    name = f"{display} ({remote}/{branch})"

    if not os.path.isdir(path) or not os.path.isdir(os.path.join(path, ".git")):
        print(f"{name}: not a repo")
        return

    # Fetch silently
    run_git("fetch", remote, cwd=path, check=False)

    local = run_git("rev-parse", branch, cwd=path, check=False)
    remote_ref = run_git("rev-parse", f"{remote}/{branch}", cwd=path, check=False)

    if local.returncode != 0:
        print(f"{name}: no local branch")
        return
    if remote_ref.returncode != 0:
        print(f"{name}: no remote branch (local only)")
        return

    local_sha = local.stdout.strip()
    remote_sha = remote_ref.stdout.strip()

    if local_sha == remote_sha:
        print(f"{name}: up to date")
        return

    ahead = run_git(
        "rev-list", "--count", f"{remote}/{branch}..{branch}", cwd=path, check=False
    )
    behind = run_git(
        "rev-list", "--count", f"{branch}..{remote}/{branch}", cwd=path, check=False
    )
    a = int(ahead.stdout.strip()) if ahead.returncode == 0 else 0
    b = int(behind.stdout.strip()) if behind.returncode == 0 else 0

    if a > 0 and b > 0:
        print(f"{name}: DIVERGED (ahead {a}, behind {b})")
    elif a > 0:
        print(f"{name}: ahead {a}")
    elif b > 0:
        print(f"{name}: behind {b}")
