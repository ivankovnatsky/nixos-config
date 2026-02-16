"""Editor integration for jira-custom."""

import os
import subprocess
import tempfile

import click


def edit_in_editor(text, suffix=""):
    """Open text in $EDITOR and return the edited content.

    Returns the edited text, or the original if the user quits without saving.
    Raises ClickException if the editor exits with a non-zero status.
    """
    editor = os.environ.get("EDITOR", "vi")

    with tempfile.NamedTemporaryFile(
        mode="w",
        suffix=f"{suffix}.md",
        prefix="jira-",
        delete=False,
    ) as f:
        f.write(text)
        tmpfile = f.name

    try:
        result = subprocess.run([editor, tmpfile])
        if result.returncode != 0:
            raise click.ClickException(f"Editor exited with status {result.returncode}")

        with open(tmpfile) as f:
            return f.read()
    finally:
        os.unlink(tmpfile)
