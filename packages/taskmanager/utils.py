"""Shared utilities, constants, and date helpers for taskmanager."""

import platform
import shutil
import subprocess

import click

_verbose = False
_prefix_mode = False


def has_command(cmd):
    return shutil.which(cmd) is not None


def is_darwin():
    return platform.system() == "Darwin"


def prefixed_title(project, title):
    """Build a task description, optionally prefixed with 'Project: '."""
    if _prefix_mode and project:
        return f"{project}: {title}"
    return title


def run(cmd, stdin_text=None):
    if _verbose:
        click.echo(f"  >> {' '.join(cmd)}", err=True)
    result = subprocess.run(cmd, capture_output=True, text=True, input=stdin_text)
    if result.returncode != 0:
        click.echo(f"Error running {' '.join(cmd)}: {result.stderr.strip()}", err=True)
    return result


REMINDERS_READ_ONLY_FIELDS = {"completed", "created"}

REMINDERS_PRIORITY_MAP = {0: "", 1: "H", 5: "M", 9: "L"}
TW_TO_REMINDERS_PRIORITY = {"H": "high", "M": "medium", "L": "low"}
PRIORITY_LABEL = {"H": "high", "M": "medium", "L": "low", "": "none"}

FIELD_DISPLAY_NAMES = {
    "due": "due",
    "end": "completed",
    "entry": "created",
    "notes": "notes",
    "priority": "priority",
    "title": "title",
    "status": "status",
}


def normalize_date(date_str):
    """Normalize date to compact form for comparison (strip punctuation)."""
    if not date_str:
        return ""
    return date_str.replace("-", "").replace(":", "")


def format_date(date_str):
    """Format date for display as YYYY-MM-DD."""
    if not date_str:
        return ""
    clean = normalize_date(date_str)
    if len(clean) >= 8:
        d = clean[:8]
        return f"{d[:4]}-{d[4:6]}-{d[6:8]}"
    return date_str


def tw_date_to_iso(tw_date):
    """Convert TW compact date (20260319T220000Z) to ISO 8601 UTC."""
    if not tw_date or len(tw_date) < 16:
        return tw_date
    return (
        f"{tw_date[:4]}-{tw_date[4:6]}-{tw_date[6:8]}"
        f"T{tw_date[9:11]}:{tw_date[11:13]}:{tw_date[13:15]}Z"
    )


def tw_date_to_local_iso(tw_date):
    """Convert TW compact UTC date (20260319T220000Z) to local ISO 8601."""
    if not tw_date or len(tw_date) < 16:
        return tw_date
    from datetime import datetime

    utc_dt = datetime.fromisoformat(tw_date_to_iso(tw_date))
    return utc_dt.astimezone().strftime("%Y-%m-%dT%H:%M:%S")


def is_tw_compact(date_str):
    """Check if date string is TW compact format (YYYYMMDDTHHMMSSZ)."""
    return (
        len(date_str) == 16
        and date_str[8] == "T"
        and date_str[15] == "Z"
        and date_str[:8].isdigit()
        and date_str[9:15].isdigit()
    )


def format_date_local(date_str):
    """Format a date string to local YYYY-MM-DDTHH:MM:SS, converting UTC if needed."""
    if not date_str:
        return ""
    from datetime import datetime

    if is_tw_compact(date_str):
        return tw_date_to_local_iso(date_str)
    try:
        dt = datetime.fromisoformat(date_str)
        if dt.tzinfo is not None:
            return dt.astimezone().strftime("%Y-%m-%dT%H:%M:%S")
        return dt.strftime("%Y-%m-%dT%H:%M:%S")
    except ValueError:
        pass
    return date_str


def date_key(date_str):
    """Normalize date+time for instance matching.

    Strips punctuation to a compact form (YYYYMMDDTHHMMSS) so TW format
    (20250808T210000Z) and Rem format (2025-08-08T21:00:00) compare equal.
    """
    if not date_str:
        return ""
    clean = normalize_date(date_str)
    # Strip trailing Z for comparison (both are UTC)
    return clean.rstrip("Z")


def infer_flow(field, rem_val, tw_val):
    """Infer natural sync direction for a field based on which side has data."""
    empty = ("''", "none", "pending")
    if field == "title":
        if len(tw_val) >= len(rem_val):
            return "tw_to_rem"
        return "rem_to_tw"
    if field == "status":
        if rem_val == "completed":
            return "rem_to_tw"
        return "tw_to_rem"
    if field in ("completed", "created"):
        return "rem_to_tw"
    if field == "due":
        rem_e = rem_val in empty
        tw_e = tw_val in empty
        if rem_e and not tw_e:
            return "tw_to_rem"
        if tw_e and not rem_e:
            return "rem_to_tw"
        # Same calendar date but one is midnight (date-only) — sync the
        # specific time to the midnight side instead of overwriting it.
        if len(rem_val) >= 10 and len(tw_val) >= 10 and rem_val[:10] == tw_val[:10]:
            rem_midnight = rem_val.endswith("T00:00:00")
            tw_midnight = tw_val.endswith("T00:00:00")
            if rem_midnight and not tw_midnight:
                return "tw_to_rem"
            if tw_midnight and not rem_midnight:
                return "rem_to_tw"
        # Both have values — prefer older (more original) date
        if rem_val < tw_val:
            return "rem_to_tw"
        return "tw_to_rem"
    rem_empty = rem_val in empty
    tw_empty = tw_val in empty
    if rem_empty and not tw_empty:
        return "tw_to_rem"
    if tw_empty and not rem_empty:
        return "rem_to_tw"
    # Both have values — prefer the longer/more complete one
    if field == "notes" and len(str(tw_val)) > len(str(rem_val)):
        return "tw_to_rem"
    return "rem_to_tw"


def normalize_system_name(name):
    """Normalize system name to internal form."""
    if name in ("t", "tw", "taskwarrior"):
        return "tw"
    if name in ("r", "rem", "rems", "reminders"):
        return "reminders"
    return name


def parse_projects(project_str):
    """Parse comma-separated project string into list."""
    if not project_str:
        return [None]
    return [p.strip() for p in project_str.split(",") if p.strip()]
