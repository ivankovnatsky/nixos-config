#!/usr/bin/env python3

from atlassian import Confluence
import sys
import os
import click
import markdown
import re
from html import unescape


def get_confluence_client():
    """Get authenticated Confluence client"""
    server = os.getenv("CONFLUENCE_SERVER")
    email = os.getenv("CONFLUENCE_EMAIL")
    token = os.getenv("CONFLUENCE_API_TOKEN")

    if not all([server, email, token]):
        click.echo(
            "Error: Set CONFLUENCE_SERVER, CONFLUENCE_EMAIL, and CONFLUENCE_API_TOKEN in environment",
            err=True,
        )
        sys.exit(1)

    return Confluence(url=server, username=email, password=token, cloud=True)


def convert_markdown_to_html(md_content):
    """Convert markdown to HTML for Confluence storage format"""
    md = markdown.Markdown(extensions=["fenced_code", "tables", "nl2br"])
    html = md.convert(md_content)

    # Convert <pre><code class="language-X"> to Confluence code macro
    def replace_code_block(match):
        lang = match.group(1) or ""
        code = match.group(2)
        # Unescape HTML entities in code
        code = (
            code.replace("&lt;", "<")
            .replace("&gt;", ">")
            .replace("&amp;", "&")
            .replace("&quot;", '"')
        )
        return f"""<ac:structured-macro ac:name="code" ac:schema-version="1">
<ac:parameter ac:name="language">{lang}</ac:parameter>
<ac:plain-text-body><![CDATA[{code}]]></ac:plain-text-body>
</ac:structured-macro>"""

    # Match <pre><code class="language-X">...</code></pre>
    html = re.sub(
        r'<pre><code class="language-(\w+)">(.*?)</code></pre>',
        replace_code_block,
        html,
        flags=re.DOTALL,
    )

    # Handle <pre><code> without language
    def replace_code_block_no_lang(match):
        code = match.group(1)
        code = (
            code.replace("&lt;", "<")
            .replace("&gt;", ">")
            .replace("&amp;", "&")
            .replace("&quot;", '"')
        )
        return f"""<ac:structured-macro ac:name="code" ac:schema-version="1">
<ac:plain-text-body><![CDATA[{code}]]></ac:plain-text-body>
</ac:structured-macro>"""

    html = re.sub(
        r"<pre><code>(.*?)</code></pre>",
        replace_code_block_no_lang,
        html,
        flags=re.DOTALL,
    )

    # Convert [TOC] placeholder to Confluence TOC macro
    # Markdown wraps [TOC] in <p> tags, so match <p>[TOC]</p>
    html = re.sub(
        r"<p>\[TOC\]</p>",
        '<ac:structured-macro ac:name="toc" ac:schema-version="1"><ac:parameter ac:name="minLevel">1</ac:parameter><ac:parameter ac:name="maxLevel">4</ac:parameter></ac:structured-macro>',
        html,
        flags=re.IGNORECASE,
    )

    return html


def generate_slug(text):
    """Generate GitHub-style anchor slug from heading text"""
    # Lowercase
    slug = text.lower()
    # Replace spaces with hyphens
    slug = re.sub(r"\s+", "-", slug)
    # Remove special characters except hyphens
    slug = re.sub(r"[^\w\-]", "", slug)
    # Remove consecutive hyphens
    slug = re.sub(r"-+", "-", slug)
    # Strip leading/trailing hyphens
    slug = slug.strip("-")
    return slug


def convert_storage_to_markdown(storage_content, generate_toc=False):
    """Convert Confluence storage format to markdown"""
    content = storage_content

    # Check if TOC macro exists
    has_toc = re.search(
        r'<ac:structured-macro ac:name="toc"[^>]*>.*?</ac:structured-macro>',
        content,
        flags=re.DOTALL,
    )

    if has_toc and generate_toc:
        # Extract TOC parameters (minLevel, maxLevel)
        min_level = 1
        max_level = 4
        min_match = re.search(
            r'<ac:parameter ac:name="minLevel">(\d+)</ac:parameter>', has_toc.group(0)
        )
        max_match = re.search(
            r'<ac:parameter ac:name="maxLevel">(\d+)</ac:parameter>', has_toc.group(0)
        )
        if min_match:
            min_level = int(min_match.group(1))
        if max_match:
            max_level = int(max_match.group(1))

        # Extract all headings from content
        headings = []
        for level in range(min_level, max_level + 1):
            for match in re.finditer(
                rf"<h{level}[^>]*>(.*?)</h{level}>", content, re.DOTALL
            ):
                # Strip HTML tags from heading text
                heading_text = re.sub(r"<[^>]+>", "", match.group(1)).strip()
                if heading_text:
                    headings.append((match.start(), level, heading_text))

        # Sort by position in document
        headings.sort(key=lambda x: x[0])

        # Generate markdown TOC
        if headings:
            # Use actual minimum level found for indentation
            # Start with 2-space base indent so markdown produces nested <ul>
            actual_min_level = min(h[1] for h in headings)
            toc_lines = ["## Table of Contents\n"]
            for _, level, text in headings:
                indent = "  " * (level - actual_min_level + 1)
                slug = generate_slug(text)
                toc_lines.append(f"{indent}- [{text}](#{slug})")
            toc_md = "\n".join(toc_lines) + "\n"
        else:
            toc_md = ""

        # Replace TOC macro with generated TOC
        content = re.sub(
            r'<ac:structured-macro ac:name="toc"[^>]*>.*?</ac:structured-macro>',
            toc_md,
            content,
            flags=re.DOTALL,
        )
    elif has_toc:
        # Strip TOC macro when not generating
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

    # Convert headings (with optional attributes like local-id)
    for i in range(6, 0, -1):
        content = re.sub(
            rf"<h{i}[^>]*>(.*?)</h{i}>", r"\n" + "#" * i + r" \1\n", content
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

    # Convert tables (with optional attributes, may have tbody wrapper)
    def convert_table(match):
        table_html = match.group(0)
        # Remove tbody wrapper if present
        table_html = re.sub(r"</?tbody[^>]*>", "", table_html)
        rows = re.findall(r"<tr[^>]*>(.*?)</tr>", table_html, re.DOTALL)
        if not rows:
            return ""

        md_rows = []
        for row in rows:
            headers = re.findall(r"<th[^>]*>(.*?)</th>", row, re.DOTALL)
            cells = re.findall(r"<td[^>]*>(.*?)</td>", row, re.DOTALL)

            if headers:
                # Strip <p> and other tags from headers
                headers = [re.sub(r"<[^>]+>", "", h).strip() for h in headers]
                md_rows.append("| " + " | ".join(headers) + " |")
                md_rows.append("|" + "|".join(["---"] * len(headers)) + "|")
            elif cells:
                # Strip <p> and other tags from cells
                cells = [re.sub(r"<[^>]+>", "", c).strip() for c in cells]
                md_rows.append("| " + " | ".join(cells) + " |")

        return "\n" + "\n".join(md_rows) + "\n"

    content = re.sub(
        r"<table[^>]*>.*?</table>", convert_table, content, flags=re.DOTALL
    )

    # Convert unordered lists (with optional attributes)
    # List items may contain <p> tags inside
    def convert_ul(match):
        items = re.findall(r"<li[^>]*>(.*?)</li>", match.group(1), re.DOTALL)
        result = "\n"
        for item in items:
            # Strip <p> tags from inside list items
            item = re.sub(r"<p[^>]*>(.*?)</p>", r"\1", item, flags=re.DOTALL)
            item = re.sub(r"<[^>]+>", "", item).strip()
            result += f"- {item}\n"
        return result

    content = re.sub(r"<ul[^>]*>(.*?)</ul>", convert_ul, content, flags=re.DOTALL)

    # Convert ordered lists (with optional attributes)
    def convert_ol(match):
        items = re.findall(r"<li[^>]*>(.*?)</li>", match.group(1), re.DOTALL)
        result = "\n"
        for i, item in enumerate(items):
            # Strip <p> tags from inside list items
            item = re.sub(r"<p[^>]*>(.*?)</p>", r"\1", item, flags=re.DOTALL)
            item = re.sub(r"<[^>]+>", "", item).strip()
            result += f"{i + 1}. {item}\n"
        return result

    content = re.sub(r"<ol[^>]*>(.*?)</ol>", convert_ol, content, flags=re.DOTALL)

    # Convert paragraphs (with optional attributes)
    content = re.sub(r"<p[^>]*>(.*?)</p>", r"\1\n", content, flags=re.DOTALL)

    # Clean up remaining HTML tags
    content = re.sub(r"<[^>]+>", "", content)

    # Unescape HTML entities
    content = unescape(content)

    # Clean up whitespace
    content = re.sub(r"\n{3,}", "\n\n", content)
    content = content.strip()

    return content


@click.group()
def cli():
    """Confluence operations"""
    pass


@cli.group()
def page():
    """Manage pages"""
    pass


@cli.group()
def space():
    """Manage spaces"""
    pass


@page.command("create")
@click.argument("space_key")
@click.argument("title")
@click.option("--body", "-b", default=None, help="Page body (storage format)")
@click.option("--body-file", "-f", default=None, help="Read body from file")
@click.option("--parent-id", "-p", default=None, help="Parent page ID")
def page_create(space_key, title, body, body_file, parent_id):
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
    click.echo(f"Created: {result['id']}")
    click.echo(f"URL: {result['_links']['base']}{result['_links']['webui']}")


@page.command("update")
@click.option("--page-id", default=None, help="Page ID")
@click.option("--space", "-s", default=None, help="Space key")
@click.option("--title", "-t", default=None, help="Page title")
@click.option("--body", "-b", default=None, help="Page body (storage format)")
@click.option("--body-file", "-f", default=None, help="Read body from file")
@click.option("--minor", is_flag=True, default=False, help="Mark as minor edit")
def page_update(page_id, space, title, body, body_file, minor):
    """Update a page"""
    confluence = get_confluence_client()

    if body_file:
        with open(body_file, "r") as f:
            body = f.read()
        # Auto-detect markdown files and convert
        if body_file.endswith(".md"):
            body = convert_markdown_to_html(body)

    if not body:
        click.echo("Error: Either --body or --body-file is required", err=True)
        sys.exit(1)

    # Get page by ID or by space+title
    if page_id:
        page = confluence.get_page_by_id(page_id)
        if not page:
            click.echo(f"Error: Page {page_id} not found", err=True)
            sys.exit(1)
        title = title or page["title"]
    elif space and title:
        page = confluence.get_page_by_title(space, title)
        if not page:
            click.echo(f"Error: Page '{title}' not found in space {space}", err=True)
            sys.exit(1)
        page_id = page["id"]
    else:
        click.echo(
            "Error: Either --page-id or both --space and --title are required",
            err=True,
        )
        sys.exit(1)

    result = confluence.update_page(
        page_id=page_id,
        title=title,
        body=body,
        representation="storage",
        minor_edit=minor,
    )
    click.echo(f"Updated: {result['id']}", err=True)


@page.command("get")
@click.option("--page-id", default=None, help="Page ID")
@click.option("--space", "-s", default=None, help="Space key")
@click.option("--title", "-t", default=None, help="Page title")
@click.option(
    "--format",
    "output_format",
    type=click.Choice(["storage", "info", "markdown"]),
    default="storage",
    help="Output format",
)
@click.option("--output", "-o", default=None, help="Output file path (default: stdout)")
@click.option(
    "--toc",
    is_flag=True,
    default=False,
    help="Generate table of contents from headings (markdown format only)",
)
def page_get(page_id, space, title, output_format, output, toc):
    """Get page content"""
    confluence = get_confluence_client()

    if page_id:
        page = confluence.get_page_by_id(page_id, expand="body.storage,version")
    elif space and title:
        page = confluence.get_page_by_title(space, title, expand="body.storage,version")
    else:
        click.echo(
            "Error: Either --page-id or both --space and --title are required",
            err=True,
        )
        sys.exit(1)

    if not page:
        click.echo("Error: Page not found", err=True)
        sys.exit(1)

    # Prepare output content
    if output_format == "storage":
        content = page["body"]["storage"]["value"]
    elif output_format == "markdown":
        content = convert_storage_to_markdown(
            page["body"]["storage"]["value"], generate_toc=toc
        )
    elif output_format == "info":
        content = f"ID: {page['id']}\nTitle: {page['title']}\nVersion: {page['version']['number']}\nSpace: {page['space']['key'] if 'space' in page else 'N/A'}"

    # Write to file or stdout
    if output:
        with open(output, "w") as f:
            f.write(content)
        click.echo(f"Written to {output}", err=True)
    else:
        click.echo(content)


@page.command("list")
@click.argument("space_key")
@click.option("--limit", "-l", type=int, default=25, help="Max results")
def page_list(space_key, limit):
    """List pages in a space"""
    confluence = get_confluence_client()
    pages = confluence.get_all_pages_from_space(
        space_key, limit=limit, expand="version"
    )

    for p in pages:
        click.echo(f"{p['id']}: {p['title']} (v{p['version']['number']})")


@space.command("list")
def space_list():
    """List all spaces"""
    confluence = get_confluence_client()
    spaces = confluence.get_all_spaces(limit=500)

    for s in spaces:
        click.echo(f"{s['key']}: {s['name']}")


@space.command("get")
@click.argument("space_key")
def space_get(space_key):
    """Get space details"""
    confluence = get_confluence_client()
    s = confluence.get_space(space_key, expand="description.plain,homepage")

    click.echo(f"Key: {s['key']}")
    click.echo(f"Name: {s['name']}")
    click.echo(f"Type: {s['type']}")
    if "description" in s and s["description"].get("plain", {}).get("value"):
        click.echo(f"Description: {s['description']['plain']['value']}")
    if "homepage" in s:
        click.echo(f"Homepage ID: {s['homepage']['id']}")


@cli.command("search")
@click.argument("cql")
@click.option("--limit", "-l", type=int, default=25, help="Max results")
def search(cql, limit):
    """Search using CQL"""
    confluence = get_confluence_client()
    results = confluence.cql(cql, limit=limit)

    for result in results.get("results", []):
        content = result.get("content", result)
        click.echo(
            f"{content.get('id', 'N/A')}: {content.get('title', result.get('title', 'N/A'))}"
        )


def main():
    cli(prog_name="confluence")


if __name__ == "__main__":
    main()
