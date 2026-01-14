#!/usr/bin/env python3

from atlassian import Confluence
import sys
import os
import argparse
import markdown
import re
from html import unescape


def get_confluence_client():
    """Get authenticated Confluence client"""
    server = os.getenv("CONFLUENCE_SERVER")
    email = os.getenv("CONFLUENCE_EMAIL")
    token = os.getenv("CONFLUENCE_API_TOKEN")

    if not all([server, email, token]):
        print(
            "Error: Set CONFLUENCE_SERVER, CONFLUENCE_EMAIL, and CONFLUENCE_API_TOKEN in environment",
            file=sys.stderr,
        )
        sys.exit(1)

    return Confluence(url=server, username=email, password=token, cloud=True)


def convert_markdown_to_html(md_content):
    """Convert markdown to HTML for Confluence storage format"""
    md = markdown.Markdown(extensions=["fenced_code", "tables", "nl2br"])
    return md.convert(md_content)


def convert_storage_to_markdown(storage_content):
    """Convert Confluence storage format to markdown"""
    content = storage_content

    # Remove TOC macro
    content = re.sub(
        r'<ac:structured-macro ac:name="toc"[^>]*>.*?</ac:structured-macro>',
        "",
        content,
        flags=re.DOTALL,
    )

    # Convert code blocks
    def replace_code_block(match):
        full_match = match.group(0)
        lang_match = re.search(
            r'<ac:parameter ac:name="language">([^<]+)</ac:parameter>', full_match
        )
        lang = lang_match.group(1) if lang_match else ""
        code_match = re.search(r"<!\[CDATA\[(.*?)\]\]>", full_match, re.DOTALL)
        code = code_match.group(1) if code_match else ""
        return f"\n```{lang}\n{code}\n```\n"

    content = re.sub(
        r'<ac:structured-macro ac:name="code"[^>]*>.*?</ac:structured-macro>',
        replace_code_block,
        content,
        flags=re.DOTALL,
    )

    # Remove remaining ac:structured-macro elements
    content = re.sub(
        r"<ac:structured-macro[^>]*>.*?</ac:structured-macro>",
        "",
        content,
        flags=re.DOTALL,
    )

    # Convert headings
    for i in range(6, 0, -1):
        content = re.sub(
            rf"<h{i}>(.*?)</h{i}>", r"\n" + "#" * i + r" \1\n", content
        )

    # Convert bold/strong
    content = re.sub(r"<strong>(.*?)</strong>", r"**\1**", content)
    content = re.sub(r"<b>(.*?)</b>", r"**\1**", content)

    # Convert italic/em
    content = re.sub(r"<em>(.*?)</em>", r"_\1_", content)
    content = re.sub(r"<i>(.*?)</i>", r"_\1_", content)

    # Convert inline code
    content = re.sub(r"<code>(.*?)</code>", r"`\1`", content)

    # Convert links
    content = re.sub(r'<a href="([^"]+)"[^>]*>([^<]+)</a>', r"[\2](\1)", content)

    # Convert tables
    def convert_table(match):
        table_html = match.group(0)
        rows = re.findall(r"<tr>(.*?)</tr>", table_html, re.DOTALL)
        if not rows:
            return ""

        md_rows = []
        for row in rows:
            headers = re.findall(r"<th[^>]*>(.*?)</th>", row, re.DOTALL)
            cells = re.findall(r"<td[^>]*>(.*?)</td>", row, re.DOTALL)

            if headers:
                headers = [re.sub(r"<[^>]+>", "", h).strip() for h in headers]
                md_rows.append("| " + " | ".join(headers) + " |")
                md_rows.append("|" + "|".join(["---"] * len(headers)) + "|")
            elif cells:
                cells = [re.sub(r"<[^>]+>", "", c).strip() for c in cells]
                md_rows.append("| " + " | ".join(cells) + " |")

        return "\n" + "\n".join(md_rows) + "\n"

    content = re.sub(r"<table>.*?</table>", convert_table, content, flags=re.DOTALL)

    # Convert unordered lists
    content = re.sub(
        r"<ul>(.*?)</ul>",
        lambda m: "\n"
        + re.sub(r"<li>(.*?)</li>", r"- \1\n", m.group(1), flags=re.DOTALL),
        content,
        flags=re.DOTALL,
    )

    # Convert ordered lists
    def convert_ol(match):
        items = re.findall(r"<li>(.*?)</li>", match.group(1), re.DOTALL)
        return "\n" + "\n".join(f"{i+1}. {item.strip()}" for i, item in enumerate(items)) + "\n"

    content = re.sub(r"<ol>(.*?)</ol>", convert_ol, content, flags=re.DOTALL)

    # Convert paragraphs
    content = re.sub(r"<p>(.*?)</p>", r"\1\n", content, flags=re.DOTALL)

    # Clean up remaining HTML tags
    content = re.sub(r"<[^>]+>", "", content)

    # Unescape HTML entities
    content = unescape(content)

    # Clean up whitespace
    content = re.sub(r"\n{3,}", "\n\n", content)
    content = content.strip()

    return content


def page_create(space_key, title, body=None, body_file=None, parent_id=None):
    """Create a new page"""
    confluence = get_confluence_client()

    if body_file:
        with open(body_file, "r") as f:
            body = f.read()
        # Auto-detect markdown files and convert
        if body_file.endswith(".md"):
            body = convert_markdown_to_html(body)

    if not body:
        body = ""

    result = confluence.create_page(
        space=space_key,
        title=title,
        body=body,
        parent_id=parent_id,
        representation="storage",
    )
    print(f"Created: {result['id']}")
    print(f"URL: {result['_links']['base']}{result['_links']['webui']}")


def page_update(
    page_id=None,
    space_key=None,
    title=None,
    body=None,
    body_file=None,
    minor_edit=False,
):
    """Update an existing page"""
    confluence = get_confluence_client()

    if body_file:
        with open(body_file, "r") as f:
            body = f.read()
        # Auto-detect markdown files and convert
        if body_file.endswith(".md"):
            body = convert_markdown_to_html(body)

    if not body:
        print("Error: Either --body or --body-file is required", file=sys.stderr)
        sys.exit(1)

    # Get page by ID or by space+title
    if page_id:
        page = confluence.get_page_by_id(page_id)
        if not page:
            print(f"Error: Page {page_id} not found", file=sys.stderr)
            sys.exit(1)
        title = title or page["title"]
    elif space_key and title:
        page = confluence.get_page_by_title(space_key, title)
        if not page:
            print(
                f"Error: Page '{title}' not found in space {space_key}", file=sys.stderr
            )
            sys.exit(1)
        page_id = page["id"]
    else:
        print(
            "Error: Either --page-id or both --space and --title are required",
            file=sys.stderr,
        )
        sys.exit(1)

    result = confluence.update_page(
        page_id=page_id,
        title=title,
        body=body,
        representation="storage",
        minor_edit=minor_edit,
    )
    print(f"Updated: {result['id']}", file=sys.stderr)


def page_get(page_id=None, space_key=None, title=None, output_format="storage"):
    """Get page content"""
    confluence = get_confluence_client()

    if page_id:
        page = confluence.get_page_by_id(page_id, expand="body.storage,version")
    elif space_key and title:
        page = confluence.get_page_by_title(
            space_key, title, expand="body.storage,version"
        )
    else:
        print(
            "Error: Either --page-id or both --space and --title are required",
            file=sys.stderr,
        )
        sys.exit(1)

    if not page:
        print("Error: Page not found", file=sys.stderr)
        sys.exit(1)

    if output_format == "storage":
        print(page["body"]["storage"]["value"])
    elif output_format == "markdown":
        print(convert_storage_to_markdown(page["body"]["storage"]["value"]))
    elif output_format == "info":
        print(f"ID: {page['id']}")
        print(f"Title: {page['title']}")
        print(f"Version: {page['version']['number']}")
        print(f"Space: {page['space']['key'] if 'space' in page else 'N/A'}")


def page_list(space_key, limit=25):
    """List pages in a space"""
    confluence = get_confluence_client()
    pages = confluence.get_all_pages_from_space(
        space_key, limit=limit, expand="version"
    )

    for page in pages:
        print(f"{page['id']}: {page['title']} (v{page['version']['number']})")


def space_list():
    """List all spaces"""
    confluence = get_confluence_client()
    spaces = confluence.get_all_spaces(limit=500)

    for space in spaces:
        print(f"{space['key']}: {space['name']}")


def space_get(space_key):
    """Get space details"""
    confluence = get_confluence_client()
    space = confluence.get_space(space_key, expand="description.plain,homepage")

    print(f"Key: {space['key']}")
    print(f"Name: {space['name']}")
    print(f"Type: {space['type']}")
    if "description" in space and space["description"].get("plain", {}).get("value"):
        print(f"Description: {space['description']['plain']['value']}")
    if "homepage" in space:
        print(f"Homepage ID: {space['homepage']['id']}")


def search(cql, limit=25):
    """Search using CQL"""
    confluence = get_confluence_client()
    results = confluence.cql(cql, limit=limit)

    for result in results.get("results", []):
        content = result.get("content", result)
        print(
            f"{content.get('id', 'N/A')}: {content.get('title', result.get('title', 'N/A'))}"
        )


def main():
    parser = argparse.ArgumentParser(description="Confluence operations")
    subparsers = parser.add_subparsers(dest="command", help="Command to execute")

    # Page commands
    page_parser = subparsers.add_parser("page", help="Manage pages")
    page_subparsers = page_parser.add_subparsers(dest="page_action", help="Page action")

    # page create
    create_parser = page_subparsers.add_parser("create", help="Create a new page")
    create_parser.add_argument("space_key", help="Space key (e.g., TEAM)")
    create_parser.add_argument("title", help="Page title")
    create_parser.add_argument("--body", "-b", help="Page body (storage format)")
    create_parser.add_argument("--body-file", "-f", help="Read body from file")
    create_parser.add_argument("--parent-id", "-p", help="Parent page ID")

    # page update
    update_parser = page_subparsers.add_parser("update", help="Update a page")
    update_parser.add_argument("--page-id", help="Page ID")
    update_parser.add_argument("--space", "-s", help="Space key")
    update_parser.add_argument("--title", "-t", help="Page title")
    update_parser.add_argument("--body", "-b", help="Page body (storage format)")
    update_parser.add_argument("--body-file", "-f", help="Read body from file")
    update_parser.add_argument(
        "--minor", action="store_true", help="Mark as minor edit"
    )

    # page get
    get_parser = page_subparsers.add_parser("get", help="Get page content")
    get_parser.add_argument("--page-id", help="Page ID")
    get_parser.add_argument("--space", "-s", help="Space key")
    get_parser.add_argument("--title", "-t", help="Page title")
    get_parser.add_argument(
        "--format",
        "-o",
        choices=["storage", "info", "markdown"],
        default="storage",
        help="Output format",
    )

    # page list
    list_parser = page_subparsers.add_parser("list", help="List pages in a space")
    list_parser.add_argument("space_key", help="Space key")
    list_parser.add_argument("--limit", "-l", type=int, default=25, help="Max results")

    # Space commands
    space_parser = subparsers.add_parser("space", help="Manage spaces")
    space_subparsers = space_parser.add_subparsers(
        dest="space_action", help="Space action"
    )

    # space list
    space_subparsers.add_parser("list", help="List all spaces")

    # space get
    space_get_parser = space_subparsers.add_parser("get", help="Get space details")
    space_get_parser.add_argument("space_key", help="Space key")

    # Search command
    search_parser = subparsers.add_parser("search", help="Search using CQL")
    search_parser.add_argument(
        "cql", help="CQL query (e.g., 'type=page and space=TEAM')"
    )
    search_parser.add_argument(
        "--limit", "-l", type=int, default=25, help="Max results"
    )

    args = parser.parse_args()

    # Handle commands
    if args.command == "page":
        if args.page_action == "create":
            page_create(
                args.space_key, args.title, args.body, args.body_file, args.parent_id
            )
        elif args.page_action == "update":
            page_update(
                args.page_id,
                args.space,
                args.title,
                args.body,
                args.body_file,
                args.minor,
            )
        elif args.page_action == "get":
            page_get(args.page_id, args.space, args.title, args.format)
        elif args.page_action == "list":
            page_list(args.space_key, args.limit)
        else:
            page_parser.print_help()
    elif args.command == "space":
        if args.space_action == "list":
            space_list()
        elif args.space_action == "get":
            space_get(args.space_key)
        else:
            space_parser.print_help()
    elif args.command == "search":
        search(args.cql, args.limit)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
