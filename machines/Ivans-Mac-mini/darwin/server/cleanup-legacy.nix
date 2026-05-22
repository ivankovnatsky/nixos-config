{ config, lib, ... }:
{
  # One-shot cleanup for state left behind by previously-managed services
  # that have now been removed:
  #
  # 1. /etc/resolver/<externalDomain> stub created by the deleted
  #    modules/darwin/dnsmasq postActivation (which only wrote, never
  #    removed).
  # 2. macOS SMB sharing — modules/darwin/sharing's !cfg.enable path
  #    unloaded smbd and removed tracked shares; deleting the module
  #    along with its consumer skips that, leaving the live system with
  #    smbd still loaded and the share still exported.
  #
  # Delete this file in a follow-up commit once mini has rebuilt at
  # least once.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    # --- 1. Remove orphan /etc/resolver/<externalDomain> ---
    if [ -f "${config.sops.secrets.external-domain.path}" ]; then
      domain=$(/bin/cat "${config.sops.secrets.external-domain.path}")
      if [ -n "$domain" ] && [ -f "/etc/resolver/$domain" ]; then
        /bin/rm -f "/etc/resolver/$domain"
        echo "Removed stale /etc/resolver/$domain (old dnsmasq stub)"
      fi
    fi

    # --- 2. Disable macOS SMB sharing left behind by modules/darwin/sharing ---
    # `grep -c` exits non-zero on no-match, swallow with `|| true` so the
    # activation script doesn't abort. grep already prints `0` on no-match,
    # so the captured value stays a single integer for the -eq / -gt tests.
    SMB_ENABLED=$(sudo /usr/bin/defaults read /Library/Preferences/SystemConfiguration/com.apple.services 2>&1 | grep -c 'com.apple.smb.server" = 1' || true)
    SMB_RUNNING=$(sudo /bin/launchctl list | grep -c com.apple.smbd || true)

    if [ "$SMB_ENABLED" -eq 1 ] || [ "$SMB_RUNNING" -gt 0 ]; then
      echo "Disabling legacy file sharing service..."
      sudo /usr/bin/defaults write /Library/Preferences/SystemConfiguration/com.apple.services \
        "com.apple.smb.server" -bool false
      sudo /bin/launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist 2>&1 || true

      TRACKING_DIR="/var/lib/nix-darwin-shared"
      if [ -d "$TRACKING_DIR" ] && ls "$TRACKING_DIR"/*.share 1> /dev/null 2>&1; then
        for tracking_file in "$TRACKING_DIR"/*.share; do
          if [ -f "$tracking_file" ]; then
            share_name=$(basename "$tracking_file" .share)
            sudo /usr/sbin/sharing -r "$share_name" || echo "Failed to remove share: $share_name"
          fi
        done
        sudo /bin/rm -rf "$TRACKING_DIR"
      fi
      echo "Legacy file sharing service disabled."
    fi
  '';
}
