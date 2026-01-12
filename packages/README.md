# packages

Custom Nix packages exposed via overlay.

## Naming Convention

> The Unix philosophy treats tools as **nouns** (things you use) rather than
> **verbs** (actions you take). The action is implied by context or flags.

- **Nouns over verbs** - `jpg-converter` not `convert-to-jpg`
- **Domain-first** - `gh-notifications` not `open-gh-notifications`
- **Concise** - `torrent-dl` not `download-torrent-files`
- **Suffix patterns** - `*-mgmt` for management tools (like `systemctl`)

Examples from coreutils/git:

| Tool         | Pattern                              |
| ------------ | ------------------------------------ |
| `ssh-keygen` | domain-noun (not `generate-ssh-key`) |
| `git-branch` | domain-noun (not `get-branch`)       |
| `journalctl` | noun-suffix (not `control-journal`)  |

## Adding Packages

1. Create directory `package-name/`
2. Add `default.nix` with package definition
3. Package auto-discovered via `packages/default.nix`
4. Available via overlay as `pkgs.package-name`

## Distinct names for packages

Since these packages/ are treated as overlays to nixpkgs I've broken the ABS
down:

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
