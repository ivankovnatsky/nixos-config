# Git Setup

## Hooks

After cloning, enable commit message validation:

```console
git config core.hooksPath .githooks
```

This enforces:

- Commit subject max 72 characters
