# GNOME

## Cursor Theme

### Reset Cursor Theme

To reset the cursor theme to the default (system-managed) setting:

```console
dconf reset /org/gnome/desktop/interface/cursor-theme
```

This is useful when you want GNOME to use the cursor theme defined in your NixOS configuration instead of a user-specific override.
