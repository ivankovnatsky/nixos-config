# nix-config

Nix flake driving three macOS machines (nix-darwin + home-manager) and one NixOS
machine. ~100 in-tree packages, a handful of overlays, sops-nix-encrypted
secrets, and a custom flake-machine layer that keeps per-machine config terse.

## Rebuild

`make` defaults to a rebuild for the current platform. Useful targets:

| Command                                              | What it does                                                         |
| ---------------------------------------------------- | -------------------------------------------------------------------- |
| `make` / `make rebuild-darwin`                       | `darwin-rebuild switch --impure --flake .`                           |
| `make rebuild-nixos/generic`                         | `nixos-rebuild switch --flake .`                                     |
| `make rebuild-nixos/a3`                              | rebuild the `a3` NixOS machine remotely (`--build-host a3`)          |
| `make rebuild`                                       | quiet rebuild via the in-tree `rebuild` CLI (notifications, locking) |
| `make rebuild-watch`                                 | watch sources and auto-rebuild                                       |
| `make build` / `make test-build`                     | build the current machine's closure (`--dry-run` for test-build)     |
| `make verbose` / `make debug`                        | rerun the default with `--verbose` / `-vvvvv --print-build-logs`     |
| `make flake-update-darwin-unstable`                  | bump the darwin-unstable input group and commit each lock change     |
| `make flake-update-nixos-unstable`                   | same for NixOS unstable                                              |
| `make flake-update-nixvim` / `flake-update-homebrew` | scoped lockfile updates                                              |

`make`'s default target picks `rebuild-darwin` on macOS and
`rebuild-nixos/generic` on Linux from `uname`. The default rebuild auto-runs
`git add -A` first (the `addall` target) so untracked files reach the flake
evaluator.

## Layout

```
flake.nix              Inputs and entry point
flake/                 mkDarwin / mkNixos helpers (machines/darwin.nix, machines/nixos.nix)
machines/<hostname>/   Per-machine config; imports modules and home/ profiles
modules/               Reusable nix-darwin / NixOS option modules (modules/darwin/, modules/home/)
home/                  Home-manager profiles (one .nix per program, plus subdirs for larger configs)
packages/              In-tree derivations (writeShellScriptBin / writeShellApplication / python wrappers)
overlays/              Custom package overlays applied to nixpkgs
secrets/               sops-nix-encrypted YAML (default.yaml) and shared sops-nix import
.sops.yaml             sops creation rules and recipient keys
```

## Machines

| Machine             | Platform | Role              |
| ------------------- | -------- | ----------------- |
| `Ivans-MacBook-Pro` | darwin   | personal laptop   |
| `Ivans-MacBook-Air` | darwin   | personal laptop   |
| `Ivans-Mac-mini`    | darwin   | home server       |
| `a3`                | NixOS    | desktop / GPU box |

## Adding a machine

1. Create `machines/<hostname>/` with `default.nix` and a `home/` subdir.
2. Register the machine in `flake/machines/darwin.nix` (or `nixos.nix`) using
   the existing `mkDarwin` / `mkNixos` blocks as a template.
3. For sops:
   - generate a per-machine age key (`nix-shell -p ssh-to-age` or `age-keygen`)
   - add it to `.sops.yaml` (both the alias under `keys:` and the
     `creation_rules:`)
   - re-encrypt: `sops updatekeys secrets/default.yaml`
4. `make build` to verify, `make` to switch.

Deeper customization happens in the machine's `home/` profile (program
selection, launchd services, machine-specific options).

## Secrets

- **sops-nix** for repo-tracked secrets — a single GPG key plus per-machine and
  per-user age keys are listed in `.sops.yaml`. Encrypted YAML lives under
  `secrets/` and is decrypted on the target machine at activation time.
- **password-store (`pass`)** for local-only credentials sourced via `~/.envrc`
  (Vault, Atlassian, AWS profile). Not part of the flake, GPG-encrypted on disk.

Edit a secret: `sops secrets/default.yaml`. Add a new recipient: edit
`.sops.yaml`, then `sops updatekeys secrets/<file>`.
