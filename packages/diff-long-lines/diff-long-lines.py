#!/usr/bin/env python3

"""
This script is designed to compare Content Security Policy (CSP) strings and show their differences.
It's particularly useful when working with Terraform configurations where CSP changes are hard to read
due to their length and formatting.

Usage modes:

1. Two-file mode (original):
   python3 diff-long-lines.py --old-file old.txt --new-file new.txt

2. Single file with separators:
   python3 diff-long-lines.py data.txt
   (File should contain: old_csp\n---\nnew_csp or use ==OLD== and ==NEW== markers)

3. Terraform diff mode:
   python3 diff-long-lines.py --terraform-diff terraform-output.txt
   (Parses: ~ content_security_policy = "old" -> "new")

4. Stdin (Terraform diff):
   terraform plan | python3 diff-long-lines.py

The script will show:
- New directives added [+]
- Directives removed [-]
- Changes in existing directives [~]
  - Added values
  - Removed values
"""

import sys

import click


def parse_csp(csp_string):
    """
    Parse a CSP string into a dictionary of directives and their values.
    Each directive's values are stored as a set for easy comparison.
    """
    directives = {}
    for directive in csp_string.split(";"):
        directive = directive.strip()
        if not directive:
            continue
        parts = directive.split()
        if parts:
            directive_name = parts[0]
            values = set(parts[1:])
            directives[directive_name] = values
    return directives


def compare_csp(old_csp, new_csp):
    """
    Compare two CSP strings and print their differences in a readable format.
    Shows added/removed directives and changes in existing directives' values.
    """
    old_directives = parse_csp(old_csp)
    new_directives = parse_csp(new_csp)

    all_directive_names = sorted(
        set(old_directives.keys()) | set(new_directives.keys())
    )

    click.echo("CSP Differences:\n")

    for directive in all_directive_names:
        if directive not in old_directives:
            click.echo(f"[+] New directive '{directive}':")
            click.echo(f"    {' '.join(sorted(new_directives[directive]))}\n")

        elif directive not in new_directives:
            click.echo(f"[-] Removed directive '{directive}':")
            click.echo(f"    {' '.join(sorted(old_directives[directive]))}\n")

        else:
            old_values = old_directives[directive]
            new_values = new_directives[directive]

            if old_values != new_values:
                added = new_values - old_values
                removed = old_values - new_values

                click.echo(f"[~] Changed directive '{directive}':")
                if removed:
                    click.echo("    Removed values:")
                    click.echo(f"    - {' '.join(sorted(removed))}")
                if added:
                    click.echo("    Added values:")
                    click.echo(f"    + {' '.join(sorted(added))}")
                click.echo("")


def parse_terraform_diff(content):
    """
    Parse Terraform diff content to extract old and new CSP values.
    Looks for lines like: ~ content_security_policy = "old_value" -> "new_value"
    """
    import re

    # First try the simple pattern for single-line diffs
    pattern = r'~?\s*content_security_policy\s*=\s*"([^"]+)"\s*->\s*"([^"]+)"'
    match = re.search(pattern, content)

    if match:
        return match.group(1), match.group(2)

    # Try to handle multi-line format where quotes might be escaped or split
    # Look for the pattern even if it spans multiple lines
    pattern_multiline = r'content_security_policy\s*=\s*"(.*?)"\s*->\s*"(.*?)"'
    match = re.search(pattern_multiline, content, re.DOTALL)

    if match:
        return match.group(1), match.group(2)

    # More aggressive approach: find anything between quotes around ->
    if '" -> "' in content:
        # Find the last quote before -> and first quote after
        arrow_pos = content.find('" -> "')
        if arrow_pos > 0:
            # Find start of old value
            start = content.rfind('"', 0, arrow_pos)
            if start >= 0:
                old_value = content[start + 1 : arrow_pos]
                # Find end of new value
                end_start = arrow_pos + len('" -> "')
                end = content.find('"', end_start)
                if end > 0:
                    new_value = content[end_start:end]
                    return old_value, new_value

    # Try another format: just find two quoted strings separated by ->
    parts = content.split(" -> ")
    if len(parts) == 2:
        # Extract quoted content from each part
        old_match = re.search(r'"([^"]*)"[^"]*$', parts[0])
        new_match = re.search(r'^[^"]*"([^"]*)"', parts[1])
        if old_match and new_match:
            return old_match.group(1), new_match.group(1)

    return None, None


@click.command()
@click.argument("input_file", required=False, type=click.Path(exists=False))
@click.option(
    "--terraform-diff",
    "-t",
    is_flag=True,
    help="Parse input as Terraform diff output",
)
@click.option(
    "--old-file",
    type=click.Path(exists=True),
    help="Path to file containing old CSP (alternative to single file)",
)
@click.option(
    "--new-file",
    type=click.Path(exists=True),
    help="Path to file containing new CSP (alternative to single file)",
)
def main(input_file, terraform_diff, old_file, new_file):
    """Compare CSP policies from files or Terraform diff output."""
    try:
        if old_file and new_file:
            # Original two-file mode
            with open(old_file, "r") as f:
                old_csp = f.read().strip()

            with open(new_file, "r") as f:
                new_csp = f.read().strip()

        elif input_file:
            with open(input_file, "r") as f:
                content = f.read()

            # Always try to parse as Terraform diff first
            old_csp, new_csp = parse_terraform_diff(content)

            if not old_csp or not new_csp:
                # Try to split by common separators
                if "\n---\n" in content:
                    parts = content.split("\n---\n", 1)
                    old_csp, new_csp = parts[0].strip(), parts[1].strip()
                elif "\n==OLD==\n" in content and "\n==NEW==\n" in content:
                    old_start = content.find("\n==OLD==\n") + len("\n==OLD==\n")
                    new_start = content.find("\n==NEW==\n") + len("\n==NEW==\n")
                    old_csp = content[old_start : content.find("\n==NEW==\n")].strip()
                    new_csp = content[new_start:].strip()
                elif terraform_diff:
                    click.echo("Error: Could not parse Terraform diff format", err=True)
                    click.echo(
                        'Expected format: ~ content_security_policy = "old" -> "new"',
                        err=True,
                    )
                    sys.exit(1)
                else:
                    click.echo(
                        "Error: Could not parse file. Expected Terraform diff or separator '---' or '==OLD==' and '==NEW==' markers",
                        err=True,
                    )
                    click.echo(
                        "Tip: Try adding --terraform-diff flag if this is Terraform output",
                        err=True,
                    )
                    sys.exit(1)
        else:
            # Read from stdin if no file specified
            content = click.get_text_stream("stdin").read()
            old_csp, new_csp = parse_terraform_diff(content)
            if not old_csp or not new_csp:
                click.echo("Error: Could not parse input as Terraform diff", err=True)
                click.echo("Use --help for usage information", err=True)
                sys.exit(1)

        compare_csp(old_csp, new_csp)

    except FileNotFoundError as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)
    except Exception as e:
        click.echo(f"Error: {e}", err=True)
        sys.exit(1)


if __name__ == "__main__":
    main()
