#!/usr/bin/env python3

"""
This script is designed to compare Content Security Policy (CSP) strings and show their differences.
It's particularly useful when working with Terraform configurations where CSP changes are hard to read
due to their length and formatting.

Example use case:
When Terraform shows a CSP change like:
  ~ content_security_policy = "default-src 'self'..." -> "default-src 'self' *.example.com..."

Usage:
1. Save the old CSP to old.txt
2. Save the new CSP to new.txt
3. Run: python3 long-lines-diff.py old.txt new.txt

The script will show:
- New directives added [+]
- Directives removed [-]
- Changes in existing directives [~]
  - Added values
  - Removed values
"""

import sys
import argparse


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

    print("CSP Differences:\n")

    for directive in all_directive_names:
        if directive not in old_directives:
            print(f"[+] New directive '{directive}':")
            print(f"    {' '.join(sorted(new_directives[directive]))}\n")

        elif directive not in new_directives:
            print(f"[-] Removed directive '{directive}':")
            print(f"    {' '.join(sorted(old_directives[directive]))}\n")

        else:
            old_values = old_directives[directive]
            new_values = new_directives[directive]

            if old_values != new_values:
                added = new_values - old_values
                removed = old_values - new_values

                print(f"[~] Changed directive '{directive}':")
                if removed:
                    print("    Removed values:")
                    print(f"    - {' '.join(sorted(removed))}")
                if added:
                    print("    Added values:")
                    print(f"    + {' '.join(sorted(added))}")
                print()


def main():
    parser = argparse.ArgumentParser(
        description='Compare CSP policies from two files and show their differences'
    )
    parser.add_argument('old_file', help='Path to file containing old CSP')
    parser.add_argument('new_file', help='Path to file containing new CSP')
    
    args = parser.parse_args()

    try:
        with open(args.old_file, 'r') as f:
            old_csp = f.read().strip()
        
        with open(args.new_file, 'r') as f:
            new_csp = f.read().strip()

        compare_csp(old_csp, new_csp)

    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main() 
