"""Dump issues to per-ticket markdown files."""

import os
import re
import time
import unicodedata
from pathlib import Path

import click

from ..client import get_jira_client


DEFAULT_OUT_DIR = Path("/tmp/jira-tickets-dump")
PAGE_SIZE = 100
PAGE_SLEEP = 0.5
TITLE_MAX_CHARS = 60


def _pascal_key(issue_key):
    """PROJ-1234 -> Proj1234"""
    m = re.match(r"^([A-Za-z]+)-(\d+)$", issue_key)
    if not m:
        return re.sub(r"[^A-Za-z0-9]", "", issue_key)
    return m.group(1).capitalize() + m.group(2)


def _pascal_title(title):
    """Sanitize + PascalCase, truncate at word boundary."""
    if not title:
        return ""
    norm = unicodedata.normalize("NFKD", title)
    norm = norm.encode("ascii", "ignore").decode("ascii")
    words = re.findall(r"[A-Za-z0-9]+", norm)
    if not words:
        return ""
    pascal = "".join(w.capitalize() for w in words)
    if len(pascal) <= TITLE_MAX_CHARS:
        return pascal
    out = ""
    for w in words:
        cap = w.capitalize()
        if len(out) + len(cap) > TITLE_MAX_CHARS:
            break
        out += cap
    return out or pascal[:TITLE_MAX_CHARS]


def _filename(issue_key, summary):
    stem = _pascal_key(issue_key) + _pascal_title(summary)
    return stem + ".md"


def _read_existing_updated(path):
    """Parse the ``- **Updated:** ...`` line from an existing dump file.

    Returns the raw timestamp string or None when the file is missing or
    doesn't contain the line.
    """
    prefix = "- **Updated:** "
    try:
        with path.open("r", encoding="utf-8") as f:
            for line in f:
                if line.startswith(prefix):
                    return line[len(prefix) :].rstrip("\n").strip()
    except OSError:
        return None
    return None


def _existing_dumps_for_key(day_dir, issue_key):
    """Return .md files in day_dir that belong to issue_key.

    A naive glob like ``Proj1*.md`` would also match ``Proj12...md``, so we
    anchor on the PascalCased key boundary: after the key, the filename is
    either directly ``.md`` (empty title) or an uppercase title character.
    """
    if not day_dir.exists():
        return []
    key_prefix = _pascal_key(issue_key)
    pattern = re.compile(
        rf"^{re.escape(key_prefix)}(?:[A-Z][A-Za-z0-9]*)?\.md$"
    )
    return sorted(
        p for p in day_dir.iterdir() if p.is_file() and pattern.match(p.name)
    )


_CREATED_RE = re.compile(r"^(\d{4})-(\d{2})-(\d{2})")


def _created_bucket(created_str):
    """ISO 8601 -> ('YYYY', 'MM', 'DD'). Raises ValueError on malformed input."""
    m = _CREATED_RE.match(created_str or "")
    if not m:
        raise ValueError(f"unreadable created field: {created_str!r}")
    return m.group(1), m.group(2), m.group(3)


def _fmt_field(label, value):
    return f"- **{label}:** {value}"


def _jql_escape(value):
    """Escape backslashes and double quotes for inclusion in a JQL string literal."""
    return value.replace("\\", "\\\\").replace('"', '\\"')


def _fence(body):
    """Pick a backtick fence longer than any run of backticks in body."""
    longest = 0
    for run in re.findall(r"`+", body or ""):
        if len(run) > longest:
            longest = len(run)
    return "`" * max(3, longest + 1)


def _search_pages(jira, jql, page_size, fields, expand):
    """Yield successive pages of issues matching JQL.

    Tries ``enhanced_search_issues`` + ``nextPageToken`` first (required on Jira
    Cloud with ``jira`` >= 3.10 — the legacy ``startAt`` pagination raises
    there). On Jira Server/Data Center the method exists but is decorated with
    ``@cloud_api`` and returns ``None``; in that case we fall back to
    offset-based ``search_issues``.
    """
    use_enhanced = hasattr(jira, "enhanced_search_issues")
    token = None
    start = 0
    while True:
        if use_enhanced:
            page = jira.enhanced_search_issues(
                jql,
                nextPageToken=token,
                maxResults=page_size,
                fields=fields,
                expand=expand,
            )
            if page is None:
                # @cloud_api no-op on Server/DC — switch to legacy pagination
                # and retry this page from scratch.
                use_enhanced = False
                continue
        else:
            page = jira.search_issues(
                jql,
                startAt=start,
                maxResults=page_size,
                fields=fields,
                expand=expand,
            )
        if not page:
            return
        yield page
        if use_enhanced:
            token = getattr(page, "nextPageToken", None)
            if not token:
                return
        else:
            if len(page) < page_size:
                return
            start += len(page)


def _fetch_comments(jira, issue):
    """Return all comments for an issue.

    Prefers comments embedded via expand="comment" on the search page to avoid
    an extra API call. Falls back to a paginated jira.comments() loop when the
    embedded block is missing or truncated, so tickets with hundreds of
    comments don't get silently cut off.
    """
    comment_block = getattr(issue.fields, "comment", None)
    embedded = getattr(comment_block, "comments", None) if comment_block else None
    if embedded is not None:
        total = getattr(comment_block, "total", len(embedded))
        if len(embedded) >= total:
            return embedded

    out = []
    start = 0
    page_size = 100
    while True:
        batch = jira.comments(issue, start_at=start, max_results=page_size)
        if not batch:
            break
        out.extend(batch)
        if len(batch) < page_size:
            break
        start += len(batch)
    return out


def _render_issue(issue, server, comments):
    f = issue.fields
    url = f"{server}/browse/{issue.key}"
    lines = []
    lines.append(f"# {issue.key}: {f.summary}")
    lines.append("")
    lines.append(f"<{url}>")
    lines.append("")
    lines.append("## Metadata")
    lines.append("")
    lines.append(_fmt_field("Key", issue.key))
    lines.append(_fmt_field("Summary", f.summary or ""))
    lines.append(_fmt_field("Type", f.issuetype.name if f.issuetype else ""))
    lines.append(_fmt_field("Status", f.status.name if f.status else ""))
    lines.append(
        _fmt_field("Priority", f.priority.name if getattr(f, "priority", None) else "")
    )
    lines.append(
        _fmt_field(
            "Assignee",
            f.assignee.displayName if getattr(f, "assignee", None) else "Unassigned",
        )
    )
    lines.append(
        _fmt_field(
            "Reporter",
            f.reporter.displayName if getattr(f, "reporter", None) else "Unknown",
        )
    )
    lines.append(_fmt_field("Created", f.created or ""))
    lines.append(_fmt_field("Updated", f.updated or ""))
    if getattr(f, "resolutiondate", None):
        lines.append(_fmt_field("Resolved", f.resolutiondate))
    if getattr(f, "resolution", None) and f.resolution:
        lines.append(_fmt_field("Resolution", f.resolution.name))
    if getattr(f, "labels", None):
        lines.append(_fmt_field("Labels", ", ".join(f.labels)))
    if getattr(f, "components", None):
        lines.append(_fmt_field("Components", ", ".join(c.name for c in f.components)))
    if getattr(f, "fixVersions", None):
        lines.append(
            _fmt_field("Fix Versions", ", ".join(v.name for v in f.fixVersions))
        )
    if getattr(f, "versions", None):
        lines.append(
            _fmt_field("Affects Versions", ", ".join(v.name for v in f.versions))
        )
    if getattr(f, "parent", None):
        lines.append(
            _fmt_field("Parent", f"{f.parent.key}: {f.parent.fields.summary}")
        )

    if getattr(f, "issuelinks", None):
        lines.append("")
        lines.append("## Linked Issues")
        lines.append("")
        for link in f.issuelinks:
            if hasattr(link, "outwardIssue"):
                lines.append(
                    f"- {link.type.outward} {link.outwardIssue.key}: {link.outwardIssue.fields.summary}"
                )
            if hasattr(link, "inwardIssue"):
                lines.append(
                    f"- {link.type.inward} {link.inwardIssue.key}: {link.inwardIssue.fields.summary}"
                )

    if getattr(f, "attachment", None):
        lines.append("")
        lines.append("## Attachments")
        lines.append("")
        for att in f.attachment:
            lines.append(f"- [{att.filename}]({att.content}) ({att.size} bytes)")

    lines.append("")
    lines.append("## Description")
    lines.append("")
    desc = f.description or ""
    desc_fence = _fence(desc)
    lines.append(desc_fence)
    lines.append(desc)
    lines.append(desc_fence)

    lines.append("")
    lines.append(f"## Comments ({len(comments)})")
    lines.append("")
    for c in comments:
        author = c.author.displayName if getattr(c, "author", None) else "Unknown"
        lines.append(f"### {c.created} — {author}")
        lines.append("")
        body = c.body or ""
        fence = _fence(body)
        lines.append(fence)
        lines.append(body)
        lines.append(fence)
        lines.append("")

    while lines and lines[-1] == "":
        lines.pop()
    return "\n".join(lines) + "\n"


def dump_fn(
    project,
    out_dir,
    me=False,
    assignee=None,
    reporter=None,
    since=None,
    overwrite=False,
    limit=None,
    resolved_only=False,
):
    jira = get_jira_client()
    server = jira._options["server"]
    email = os.getenv("JIRA_EMAIL")

    def _resolve_me(flag_name, value):
        if value.lower() != "me":
            return value
        if not email:
            raise click.ClickException(
                f"JIRA_EMAIL not set; cannot use {flag_name} me"
            )
        return email

    jql_parts = [f'project = "{_jql_escape(project)}"']
    people = []
    if me:
        if not email:
            raise click.ClickException("JIRA_EMAIL not set; cannot use --me")
        esc_email = _jql_escape(email)
        people = [f'assignee = "{esc_email}"', f'reporter = "{esc_email}"']
    else:
        if assignee:
            val = _resolve_me("--assignee", assignee)
            people.append(f'assignee = "{_jql_escape(val)}"')
        if reporter:
            val = _resolve_me("--reporter", reporter)
            people.append(f'reporter = "{_jql_escape(val)}"')
    if people:
        jql_parts.append("(" + " OR ".join(people) + ")")
    if since:
        jql_parts.append(f'created >= "{_jql_escape(since)}"')
    if resolved_only:
        jql_parts.append("resolution is not EMPTY")

    jql = " AND ".join(jql_parts) + " ORDER BY created ASC"
    click.echo(f"JQL: {jql}", err=True)

    out_root = Path(out_dir).expanduser() / project
    out_root.mkdir(parents=True, exist_ok=True)
    click.echo(f"Output: {out_root}", err=True)

    total_written = 0
    total_skipped = 0
    total_seen = 0
    stop = False

    for issues in _search_pages(
        jira, jql, PAGE_SIZE, fields="*all", expand="comment"
    ):
        for issue in issues:
            total_seen += 1
            try:
                y, m, d = _created_bucket(issue.fields.created)
            except Exception:
                click.echo(
                    f"  skip {issue.key}: unreadable created field", err=True
                )
                continue

            day_dir = out_root / y / m / d
            fname = _filename(issue.key, issue.fields.summary)
            path = day_dir / fname

            existing = _existing_dumps_for_key(day_dir, issue.key)

            if existing and not overwrite:
                current_updated = issue.fields.updated or ""
                prev_updated = None
                for ex in existing:
                    prev_updated = _read_existing_updated(ex)
                    if prev_updated is not None:
                        break
                if prev_updated is not None and prev_updated == current_updated:
                    click.echo(f"  skip {issue.key} (unchanged)", err=True)
                    total_skipped += 1
                    continue

            comments = _fetch_comments(jira, issue)
            content = _render_issue(issue, server, comments)

            day_dir.mkdir(parents=True, exist_ok=True)
            for stale in existing:
                if stale != path:
                    stale.unlink()
            path.write_text(content, encoding="utf-8")
            click.echo(f"  wrote {issue.key} -> {path.relative_to(out_root)}", err=True)
            total_written += 1

            if limit is not None and total_written >= limit:
                stop = True
                break

        if stop:
            break
        time.sleep(PAGE_SLEEP)

    click.echo(
        f"Done. seen={total_seen} written={total_written} skipped={total_skipped}",
        err=True,
    )


@click.command("dump")
@click.option("-p", "--project", required=True, help="Project key")
@click.option(
    "-o",
    "--out",
    "out_dir",
    default=str(DEFAULT_OUT_DIR),
    show_default=True,
    help="Output root directory",
)
@click.option("--me", is_flag=True, help="Dump tickets where I am assignee or reporter")
@click.option("-a", "--assignee", help="Filter by assignee (use 'me' for self)")
@click.option("-r", "--reporter", help="Filter by reporter (use 'me' for self)")
@click.option("--since", help='Only issues created on/after this date (YYYY-MM-DD)')
@click.option("--overwrite", is_flag=True, help="Overwrite existing files")
@click.option(
    "--resolved-only",
    is_flag=True,
    help="Only tickets with a non-empty resolution",
)
@click.option(
    "-n", "--limit", type=int, help="Max issues to write (skipped files do not count)"
)
def dump_cmd(
    project, out_dir, me, assignee, reporter, since, overwrite, resolved_only, limit
):
    """Dump issues to per-ticket markdown files.

    Writes <out>/<PROJECT>/YYYY/MM/DD/Proj1234TitleTicket.md using
    the issue's created date for the path split.

    Examples:

      # Dump all tickets where I am assignee or reporter
      jira-custom dump -p PROJ --me

      # Dump a specific user's tickets since a date
      jira-custom dump -p PROJ -a jane@ex.com --since 2024-01-01
    """
    if not (me or assignee or reporter):
        raise click.ClickException(
            "Specify at least one of --me, --assignee, --reporter"
        )
    dump_fn(
        project,
        out_dir,
        me=me,
        assignee=assignee,
        reporter=reporter,
        since=since,
        overwrite=overwrite,
        limit=limit,
        resolved_only=resolved_only,
    )
