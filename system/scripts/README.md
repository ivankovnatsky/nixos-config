# scripts

Shell scripts automatically packaged via `default.nix`.

## Naming Convention

> The Unix philosophy treats tools as **nouns** (things you use) rather than
> **verbs** (actions you take). The action is implied by context or flags.

- **Nouns over verbs** - `syncthing-cleaner` not `clean-syncthing-files`
- **Domain-first** - `aws-profile` not `switch-aws-profile`
- **Concise** - `git-repo-dl` not `download-git-repository`

Examples from coreutils/git:

| Tool         | Pattern                              |
| ------------ | ------------------------------------ |
| `ssh-keygen` | domain-noun (not `generate-ssh-key`) |
| `git-branch` | domain-noun (not `get-branch`)       |
| `journalctl` | noun-suffix (not `control-journal`)  |

## Adding Scripts

1. Create `script-name.sh` in this directory
2. Script is auto-discovered and packaged
3. Available as `script-name` (without `.sh`)

## Aliases

Define in `default.nix` under `scriptAliases`:

```nix
scriptAliases = {
  "original-name" = [ "alias1" "alias2" ];
};
```
