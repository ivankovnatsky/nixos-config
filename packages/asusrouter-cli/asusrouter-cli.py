#!/usr/bin/env python3
"""ASUS Router management tool.

Supports data export, NVRAM queries, and WAN DNS configuration
using the asusrouter library.
"""

from commands import cli


def main():
    cli(prog_name="asusrouter-cli")


if __name__ == "__main__":
    main()
