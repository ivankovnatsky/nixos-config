"""Shared constants for giffer."""

DEFAULT_URL_FILE = ".list.txt"
DEFAULT_FAILED_FILE = ".list.failed.txt"
DEFAULT_MAX_HEIGHT = 1080
DEFAULT_SUB_LANGS = "en"
DEFAULT_SEGMENT_DURATION = 10

SITE_CONFIGS = {
    "3": {
        "pattern": r'<a class="title" href="([^"]+)"',
        "pagination": "/{page}",
    },
}
