{ username, ... }:
{
  local = {
    sudo = {
      enable = true;
      configContent = ''
        Defaults:${username} timestamp_timeout=720
        # Disable per-TTY tickets to allow nested sudo calls (like in darwin-rebuild)
        # to inherit the parent's sudo timestamp. This fixes repeated password prompts
        # during darwin-rebuild which uses sudo --user=$SUDO_USER internally.
        # Security: Still requires password after 720 minutes, just shares timestamp
        # across all terminals for this user.
        Defaults:${username} !tty_tickets
      '';
    };
  };
}
