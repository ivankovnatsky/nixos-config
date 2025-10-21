# packages

## Distinct names for packages

Since these packages/ are treated as overlays to nixpkgs I've broken the ABS down:

```logs
Oct 21 18:26:30 bee audiobookshelf[2785956]: Error: '--host' is not a recognized command.
Oct 21 18:26:30 bee audiobookshelf[2785956]: Commands must come first, before any options.
Oct 21 18:26:30 bee audiobookshelf[2785956]: Available commands: upload, libraries, list-listened, cleanup-listened, download, process
Oct 21 18:26:30 bee audiobookshelf[2785956]: Usage examples:
Oct 21 18:26:30 bee audiobookshelf[2785956]:   audiobookshelf upload --url https://example.com --file file.mp3 --library-id ID
Oct 21 18:26:30 bee audiobookshelf[2785956]:   audiobookshelf libraries --url https://example.com
Oct 21 18:26:30 bee audiobookshelf[2785956]:   audiobookshelf list-listened --url https://example.com --library-id ID
Oct 21 18:26:30 bee audiobookshelf[2785956]:   audiobookshelf cleanup-listened --url https://example.com --library-id ID
Oct 21 18:26:30 bee audiobookshelf[2785956]:   audiobookshelf download --url https://youtube.com/watch?v=example
Oct 21 18:26:30 bee audiobookshelf[2785956]:   audiobookshelf process --file-url-list /path/to/urls.txt
Oct 21 18:26:30 bee systemd[1]: audiobookshelf.service: Main process exited, code=exited, status=1/FAILURE
Oct 21 18:26:30 bee systemd[1]: audiobookshelf.service: Failed with result 'exit-code'.
Oct 21 18:26:30 bee systemd[1]: audiobookshelf.service: Scheduled restart job, restart counter is at 5.
Oct 21 18:26:30 bee systemd[1]: audiobookshelf.service: Start request repeated too quickly.
Oct 21 18:26:30 bee systemd[1]: audiobookshelf.service: Failed with result 'exit-code'.
Oct 21 18:26:30 bee systemd[1]: Failed to start Audiobookshelf is a self-hosted audiobook and podcast server.
lines 3660-3712/3712 (END)
```
