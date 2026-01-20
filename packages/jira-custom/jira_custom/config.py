"""Configuration constants for jira-custom."""

# Status categories for filtering and styling
# Used in JQL queries and get_status_style()
STATUS_DONE = frozenset({"done", "closed", "resolved", "declined"})
STATUS_DONE_JQL = frozenset({"Done", "Closed", "Resolved", "Declined", "removed", "Not a bug"})
STATUS_IN_PROGRESS = frozenset({"in progress", "in review", "review"})
STATUS_BLOCKED = frozenset({"blocked", "impediment"})
STATUS_TODO = frozenset({"to do", "open", "backlog", "unresolved"})

# Default terminal width fallback for CI/pipes where console.width is None
DEFAULT_TERMINAL_WIDTH = 120
