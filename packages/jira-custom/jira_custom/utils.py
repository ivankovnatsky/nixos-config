"""Utility functions for jira-custom."""

import re
import time
import click


class IssueKeyType(click.ParamType):
    """Click parameter type that accepts an issue key or a Jira browse URL."""

    name = "issue_key"

    _URL_RE = re.compile(r"(?:https?://)?[^/]+/browse/([A-Z][A-Z0-9]+-\d+)")

    def convert(self, value, param, ctx):
        if value is None:
            return value
        m = self._URL_RE.match(value)
        if m:
            return m.group(1)
        return value


ISSUE_KEY = IssueKeyType()


def parse_labels(labels):
    """Parse label arguments, separating adds from removes"""
    if not labels:
        return None, None

    add = []
    remove = []

    for label in labels:
        if label.startswith("-"):
            remove.append(label[1:])
        else:
            add.append(label)

    return add or None, remove or None


def parse_fields(field_args):
    """Parse field arguments (KEY=VALUE format)"""
    if not field_args:
        return None

    fields = {}
    for f in field_args:
        if "=" not in f:
            raise click.ClickException(f"Invalid field format '{f}'. Use KEY=VALUE")
        key, value = f.split("=", 1)
        fields[key] = value
    return fields


def get_issue_type_id_for_project(jira, project_key, type_name):
    """Get issue type ID by name using createmeta endpoint"""
    url = f"{jira._options['server']}/rest/api/3/issue/createmeta/{project_key}/issuetypes"
    response = jira._session.get(url)

    if response.status_code != 200:
        raise click.ClickException(f"Failed to get issue types: {response.text}")

    data = response.json()
    for it in data.get("issueTypes", data.get("values", [])):
        if it.get("name", "").lower() == type_name.lower():
            return it.get("id")

    available = [
        it.get("name") for it in data.get("issueTypes", data.get("values", []))
    ]
    raise click.ClickException(
        f"Issue type '{type_name}' not found in project {project_key}. "
        f"Available: {', '.join(available)}"
    )


def move_issue_type(jira, issue_key, type_name):
    """Change issue type using Bulk Move API (async operation)"""
    issue = jira.issue(issue_key)
    project_key = issue.fields.project.key
    type_id = get_issue_type_id_for_project(jira, project_key, type_name)

    # Build composite mapping key: "PROJECT_KEY,ISSUE_TYPE_ID"
    mapping_key = f"{project_key},{type_id}"

    payload = {
        "sendBulkNotification": True,  # Must be True to avoid permission error
        "targetToSourcesMapping": {
            mapping_key: {
                "issueIdsOrKeys": [issue_key],
                "inferClassificationDefaults": True,
                "inferFieldDefaults": True,
                "inferStatusDefaults": True,
                "inferSubtaskTypeDefault": True,
            }
        },
    }

    # Submit bulk move request
    url = f"{jira._options['server']}/rest/api/3/bulk/issues/move"
    response = jira._session.post(url, json=payload)

    if response.status_code not in (200, 201, 202):
        error_msg = response.text
        try:
            error_data = response.json()
            if "errorMessages" in error_data:
                error_msg = "; ".join(error_data["errorMessages"])
            elif "errors" in error_data:
                error_msg = "; ".join(
                    f"{k}: {v}" for k, v in error_data["errors"].items()
                )
        except Exception:
            pass
        raise click.ClickException(f"Move failed ({response.status_code}): {error_msg}")

    result = response.json()
    task_id = result.get("taskId")

    if not task_id:
        raise click.ClickException(f"No taskId in response: {result}")

    # Poll for completion
    queue_url = f"{jira._options['server']}/rest/api/3/bulk/queue/{task_id}"
    timeout = 120
    start_time = time.time()

    while time.time() - start_time < timeout:
        status_response = jira._session.get(queue_url)
        if status_response.status_code != 200:
            raise click.ClickException(
                f"Failed to check task status: {status_response.text}"
            )

        status_data = status_response.json()
        status = status_data.get("status")

        if status == "COMPLETE":
            return status_data
        elif status == "FAILED":
            raise click.ClickException(f"Move failed: {status_data}")

        time.sleep(2)

    raise click.ClickException(f"Move timed out after {timeout}s (task: {task_id})")


def truncate_text(text, max_len):
    """Truncate text to max_len, adding ellipsis if needed"""
    if len(text) <= max_len:
        return text
    if max_len <= 3:
        return text[:max_len]
    return text[: max_len - 3] + "..."
