"""HTML parsing utilities for Apple Notes."""

import html.parser


class BaseHTMLParser(html.parser.HTMLParser):
    """Base parser for Apple Notes HTML body."""

    def __init__(self):
        super().__init__()
        self._lines = []
        self._current = ""
        self._href = None
        self._link_text_start = 0
        self._tag_stack = []
        self._ul_depth = 0

    def _heading_level(self, tag):
        if tag in ("h1", "h2", "h3", "h4", "h5", "h6"):
            return int(tag[1])
        return 0

    def handle_starttag(self, tag, attrs):
        self._tag_stack.append(tag)
        if tag == "ul":
            self._ul_depth += 1
        if tag in ("div", "br", "p") or self._heading_level(tag):
            if self._current:
                self._lines.append(self._current)
                self._current = ""
        if tag == "a":
            for k, v in attrs:
                if k == "href":
                    self._href = v
                    self._link_text_start = len(self._current)
        if tag == "li":
            if self._current:
                self._lines.append(self._current)
                self._current = ""
        if tag == "img":
            self._current += "[image]"

    def handle_data(self, data):
        if not data.strip():
            if self._current and not self._current.endswith(" "):
                self._current += " "
            return
        self._current += data

    def get_text(self):
        if self._current:
            self._lines.append(self._current)
        return "\n".join(self._lines)


class TextHTMLParser(BaseHTMLParser):
    """Convert HTML to plain text with links in parentheses."""

    def handle_starttag(self, tag, attrs):
        super().handle_starttag(tag, attrs)
        if tag == "li":
            indent = "  " * max(0, self._ul_depth - 1)
            self._current = f"{indent}- "

    def handle_endtag(self, tag):
        if tag == "ul":
            self._ul_depth = max(0, self._ul_depth - 1)
        if tag == "a" and self._href:
            if self._href not in self._current:
                self._current += f" ({self._href})"
            self._href = None
        if tag in ("div", "p") or self._heading_level(tag):
            if self._current or not self._lines or self._lines[-1] != "":
                self._lines.append(self._current)
            self._current = ""
        if tag in self._tag_stack:
            self._tag_stack.remove(tag)


class MarkdownHTMLParser(BaseHTMLParser):
    """Convert HTML to Markdown."""

    def handle_starttag(self, tag, attrs):
        super().handle_starttag(tag, attrs)
        level = self._heading_level(tag)
        if level:
            self._current = "#" * level + " "
        if tag == "b" or tag == "strong":
            self._current += "**"
        if tag == "i" or tag == "em":
            self._current += "*"
        if tag == "li":
            indent = "  " * max(0, self._ul_depth - 1)
            self._current = f"{indent}- "

    def handle_endtag(self, tag):
        if tag == "ul":
            self._ul_depth = max(0, self._ul_depth - 1)
        if tag == "a" and self._href:
            link_text = self._current[self._link_text_start :]
            self._current = self._current[: self._link_text_start]
            if link_text == self._href:
                self._current += self._href
            else:
                self._current += f"[{link_text}]({self._href})"
            self._href = None
        if tag == "b" or tag == "strong":
            self._current += "**"
        if tag == "i" or tag == "em":
            self._current += "*"
        if tag in ("div", "p") or self._heading_level(tag):
            if self._current or not self._lines or self._lines[-1] != "":
                self._lines.append(self._current)
            self._current = ""
        if tag in self._tag_stack:
            self._tag_stack.remove(tag)


def html_to_text(html_body, fmt="text"):
    """Convert HTML note body to the specified format."""
    if fmt == "html":
        return html_body
    if fmt == "plain":
        parser = BaseHTMLParser()
    elif fmt == "md":
        parser = MarkdownHTMLParser()
    else:
        parser = TextHTMLParser()
    parser.feed(html_body)
    return parser.get_text()
