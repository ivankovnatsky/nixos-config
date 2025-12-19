#!/usr/bin/env python3

import argparse
import logging
import os
import subprocess
import sys
import threading
import time
from datetime import datetime
from pathlib import Path

URL_FILE = "List.txt"

downloads = []
downloads_lock = threading.Lock()
processing_lock = threading.Lock()
process_event = threading.Event()

HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>YouTube Downloader</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #1a1a1a;
            color: #e0e0e0;
            min-height: 100vh;
            padding: 2rem;
        }
        .container { max-width: 800px; margin: 0 auto; }
        h1 { margin-bottom: 1.5rem; color: #fff; }
        .input-group { display: flex; gap: 1rem; margin-bottom: 2rem; }
        input[type="text"] {
            flex: 1;
            padding: 0.75rem 1rem;
            font-size: 1rem;
            border: 1px solid #333;
            border-radius: 6px;
            background: #2a2a2a;
            color: #fff;
        }
        input[type="text"]:focus { outline: none; border-color: #ff4444; }
        button {
            padding: 0.75rem 1.5rem;
            font-size: 1rem;
            border: none;
            border-radius: 6px;
            background: #ff4444;
            color: #fff;
            cursor: pointer;
            transition: background 0.2s;
        }
        button:hover { background: #ff6666; }
        button:disabled { background: #666; cursor: not-allowed; }
        .downloads { background: #2a2a2a; border-radius: 8px; padding: 1rem; }
        .downloads h2 { margin-bottom: 1rem; font-size: 1.1rem; color: #888; }
        .download-item {
            padding: 0.75rem;
            border-bottom: 1px solid #333;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .download-item:last-child { border-bottom: none; }
        .download-url { word-break: break-all; flex: 1; margin-right: 1rem; }
        .status {
            padding: 0.25rem 0.5rem;
            border-radius: 4px;
            font-size: 0.85rem;
            white-space: nowrap;
        }
        .status-pending { background: #444; color: #aaa; }
        .status-downloading { background: #2a5298; color: #88c0ff; }
        .status-completed { background: #1b5e20; color: #81c784; }
        .status-failed { background: #b71c1c; color: #ef9a9a; }
        .empty-state { text-align: center; color: #666; padding: 2rem; }
        .time { color: #666; font-size: 0.85rem; margin-top: 0.25rem; }
        .queue-info {
            background: #333;
            padding: 0.5rem 1rem;
            border-radius: 6px;
            margin-bottom: 1rem;
            font-size: 0.9rem;
            color: #888;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>YouTube Downloader</h1>
        <div class="input-group">
            <input type="text" id="url" placeholder="Paste YouTube URL here..." autofocus>
            <button id="download-btn" onclick="submitDownload()">Download</button>
        </div>
        <div class="queue-info" id="queue-info">Queue: loading...</div>
        <div class="downloads">
            <h2>Recent Downloads</h2>
            <div id="downloads-list">
                <div class="empty-state">No downloads yet</div>
            </div>
        </div>
    </div>
    <script>
        function submitDownload() {
            const url = document.getElementById('url').value.trim();
            if (!url) return;
            const btn = document.getElementById('download-btn');
            btn.disabled = true;
            fetch('/download', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ url })
            })
            .then(r => r.json())
            .then(() => {
                document.getElementById('url').value = '';
                refreshDownloads();
            })
            .finally(() => btn.disabled = false);
        }
        function refreshDownloads() {
            fetch('/downloads')
                .then(r => r.json())
                .then(data => {
                    document.getElementById('queue-info').textContent =
                        'Queue: ' + data.queue_count + ' URLs pending';
                    const list = document.getElementById('downloads-list');
                    if (data.history.length === 0) {
                        list.innerHTML = '<div class="empty-state">No downloads yet</div>';
                        return;
                    }
                    list.innerHTML = data.history.map(d => `
                        <div class="download-item">
                            <div>
                                <div class="download-url">${escapeHtml(d.url)}</div>
                                <div class="time">${d.time}</div>
                            </div>
                            <span class="status status-${d.status}">${d.status}</span>
                        </div>
                    `).join('');
                });
        }
        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
        document.getElementById('url').addEventListener('keypress', e => {
            if (e.key === 'Enter') submitDownload();
        });
        setInterval(refreshDownloads, 3000);
        refreshDownloads();
    </script>
</body>
</html>
"""


def get_urls_from_file(url_file):
    """Read URLs from file, skipping comments and empty lines."""
    if not os.path.exists(url_file):
        return []
    with open(url_file, "r") as f:
        return [
            line.strip()
            for line in f
            if line.strip() and not line.strip().startswith("#")
        ]


def add_url_to_file(url, url_file):
    """Append a URL to the file if not already present."""
    urls = get_urls_from_file(url_file)
    if url not in urls:
        with open(url_file, "a") as f:
            f.write(url + "\n")
        return True
    return False


def remove_url_from_file(url_to_remove, url_file):
    """Remove a specific URL from the file."""
    try:
        with open(url_file, "r") as f:
            lines = f.readlines()
        with open(url_file, "w") as f:
            for line in lines:
                if line.strip() != url_to_remove:
                    f.write(line)
    except Exception as e:
        logging.warning(f"Could not remove URL from file: {e}")


def download_video(url: str, output_dir: str):
    """Download a video using yt-dlp. Returns True on success."""
    try:
        cmd = [
            "yt-dlp",
            "--write-auto-subs",
            "--embed-subs",
            "--sub-langs",
            "en",
            "--ignore-errors",
            "--format",
            "bestvideo[height<=1080]+bestaudio/best[height<=1080]",
            "--merge-output-format",
            "mp4",
            "-o",
            f"{output_dir}/%(title)s.%(ext)s",
            url,
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0:
            logging.info(f"Downloaded: {url}")
            return True
        else:
            logging.error(f"Failed to download {url}: {result.stderr}")
            return False
    except Exception as e:
        logging.error(f"Exception downloading {url}: {e}")
        return False


def process_queue(output_dir, url_file):
    """Background thread that processes the URL queue on file changes."""
    while True:
        try:
            # Wait for signal or timeout (for failed URL retry)
            process_event.wait(timeout=60)
            process_event.clear()

            with processing_lock:
                urls = get_urls_from_file(url_file)
                if not urls:
                    continue

                url = urls[0]
                logging.info(f"Processing: {url}")

                with downloads_lock:
                    for d in downloads:
                        if d["url"] == url:
                            d["status"] = "downloading"
                            break

                success = download_video(url, output_dir)

                with downloads_lock:
                    for d in downloads:
                        if d["url"] == url:
                            d["status"] = "completed" if success else "failed"
                            break

                if success:
                    remove_url_from_file(url, url_file)
                    logging.info(f"Removed from queue: {url}")
                    # Check if more URLs to process
                    if get_urls_from_file(url_file):
                        process_event.set()
                else:
                    logging.warning(f"Keeping failed URL in queue: {url}")

        except Exception as e:
            logging.error(f"Queue processing error: {e}")
            time.sleep(10)


def start_file_watcher(url_file, output_dir):
    """Start watching the URL file for changes using watchdog."""
    from watchdog.events import FileSystemEventHandler
    from watchdog.observers import Observer

    class UrlFileHandler(FileSystemEventHandler):
        def __init__(self, target_file):
            self.target_file = os.path.basename(target_file)

        def on_modified(self, event):
            if event.is_directory:
                return
            if os.path.basename(event.src_path) == self.target_file:
                logging.debug(f"File change detected: {event.src_path}")
                process_event.set()

        def on_created(self, event):
            if event.is_directory:
                return
            if os.path.basename(event.src_path) == self.target_file:
                logging.debug(f"File created: {event.src_path}")
                process_event.set()

    handler = UrlFileHandler(url_file)
    observer = Observer()
    observer.schedule(handler, output_dir, recursive=False)
    observer.start()
    logging.info(f"Watching for changes: {url_file}")
    return observer


def cmd_batch(args):
    """Process URLs from a file (original behavior)."""
    url_file = args.file if args.file else URL_FILE
    output_dir = args.output_dir if args.output_dir else os.getcwd()

    if not os.path.exists(url_file):
        print(f"No URLs to process: {url_file} not found")
        return

    success_count = 0
    total_count = 0

    while True:
        urls = get_urls_from_file(url_file)
        if not urls:
            break

        url = urls[0]
        total_count += 1
        print(f"Downloading: {url}")

        try:
            cmd = [
                "yt-dlp",
                "--write-auto-subs",
                "--embed-subs",
                "--sub-langs",
                "en",
                "--ignore-errors",
                "--format",
                "bestvideo[height<=1080]+bestaudio/best[height<=1080]",
                "--merge-output-format",
                "mp4",
                "-o",
                f"{output_dir}/%(title)s.%(ext)s",
                url,
            ]
            subprocess.run(cmd, check=True, capture_output=False)
            print(f"Successfully downloaded: {url}")
            remove_url_from_file(url, url_file)
            print(f"Removed URL from list: {url}")
            success_count += 1
        except subprocess.CalledProcessError:
            print(f"Failed to download: {url}")
            break
        except FileNotFoundError:
            print("Error: yt-dlp not found. Please install yt-dlp.")
            sys.exit(1)

    if total_count > 0:
        print(f"Processing complete. {success_count}/{total_count} URLs downloaded")


def cmd_daemon(args):
    """Run as a web service with Flask UI."""
    from flask import Flask, jsonify, render_template_string, request

    app = Flask(__name__)
    output_dir = args.output_dir
    url_file = os.path.join(output_dir, ".urls.txt")

    Path(output_dir).mkdir(parents=True, exist_ok=True)

    logging.basicConfig(
        level=logging.DEBUG if args.debug else logging.INFO,
        format="%(asctime)s - %(levelname)s - %(message)s",
    )

    # Start file watcher
    observer = start_file_watcher(url_file, output_dir)

    # Start background queue processor
    processor = threading.Thread(
        target=process_queue, args=(output_dir, url_file), daemon=True
    )
    processor.start()

    # Trigger initial processing if file has URLs
    if get_urls_from_file(url_file):
        process_event.set()

    @app.route("/")
    def index():
        return render_template_string(HTML_TEMPLATE)

    @app.route("/download", methods=["POST"])
    def start_download():
        data = request.get_json()
        url = data.get("url", "").strip()

        if not url:
            return jsonify({"error": "URL required"}), 400

        added = add_url_to_file(url, url_file)

        if added:
            download_entry = {
                "url": url,
                "status": "pending",
                "time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            }
            with downloads_lock:
                downloads.insert(0, download_entry)
                if len(downloads) > 50:
                    downloads.pop()
            # Signal processor (file watcher will also trigger)
            process_event.set()

        return jsonify({"status": "queued" if added else "already_queued"})

    @app.route("/downloads")
    def list_downloads():
        queue_count = len(get_urls_from_file(url_file))
        with downloads_lock:
            return jsonify({"queue_count": queue_count, "history": downloads})

    @app.route("/health")
    def health():
        return jsonify({"status": "ok"})

    logging.info(f"Starting YouTube Downloader on {args.host}:{args.port}")
    logging.info(f"Output directory: {output_dir}")
    logging.info(f"URL queue file: {url_file}")

    try:
        app.run(host=args.host, port=args.port, debug=args.debug, threaded=True)
    finally:
        observer.stop()
        observer.join()


def main():
    parser = argparse.ArgumentParser(description="YouTube Video Downloader")
    subparsers = parser.add_subparsers(dest="command", help="Commands")

    batch_parser = subparsers.add_parser("batch", help="Process URLs from a file")
    batch_parser.add_argument(
        "-f", "--file", default=URL_FILE, help="File containing URLs"
    )
    batch_parser.add_argument(
        "-o", "--output-dir", default=".", help="Output directory"
    )

    daemon_parser = subparsers.add_parser("daemon", help="Run as web service")
    daemon_parser.add_argument("--host", default="0.0.0.0", help="Host to bind to")
    daemon_parser.add_argument(
        "--port", type=int, default=8085, help="Port to bind to"
    )
    daemon_parser.add_argument(
        "--output-dir",
        default="/Volumes/Storage/Data/Media/Youtube",
        help="Output directory for downloads",
    )
    daemon_parser.add_argument("--debug", action="store_true", help="Enable debug mode")

    args = parser.parse_args()

    if args.command == "batch":
        cmd_batch(args)
    elif args.command == "daemon":
        cmd_daemon(args)
    else:
        args.file = URL_FILE
        args.output_dir = "."
        cmd_batch(args)


if __name__ == "__main__":
    main()
