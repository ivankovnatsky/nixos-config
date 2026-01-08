# Claude Code

## Known Issues

### Invalid Version crash (v2.1.0)

**Issue**: [#16678](https://github.com/anthropics/claude-code/issues/16678) - Claude Code crashes on startup with `ERROR Invalid Version: 2.1.0 (2026-01-07)` due to date format in changelog breaking semver parsing.

**Workaround**:

```console
# Empty the changelog and make it read-only to prevent re-fetch
echo "" > ~/.claude/cache/changelog.md
chmod 444 ~/.claude/cache/changelog.md
```

Alternative: downgrade to previous version with `claude install 2.0.76`

**Status**: Fixed in later versions. If you encounter this, update Claude Code or apply the workaround above.
