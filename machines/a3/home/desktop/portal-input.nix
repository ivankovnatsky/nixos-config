{ pkgs, ... }:

{
  # KDE Wayland "Remote Control / Control input devices" portal nag:
  # Proton/XWayland games (no app_id) trigger the RemoteDesktop portal on every
  # launch, popping a dialog that KDE can't permanently remember. Mega-authorize
  # the empty app_id once via the xdg permission store so xdg-desktop-portal-kde
  # stops asking.
  #
  # The permission lives in a binary GVariant DB
  # (~/.local/share/flatpak/db/kde-authorized), not a kconfig file, so it can't
  # be managed by plasma-manager or home.file. Set it via the PermissionStore
  # D-Bus API instead.
  #
  # Security scope (read before keeping this): the empty app_id is a
  # mega-authorization for ANY RemoteDesktop portal client that presents no
  # app_id, i.e. unknown/unsandboxed host apps -- most commonly Xwayland
  # (Proton games), but NOT exclusively Proton. Any matching no-app-id client
  # can then control pointer/keyboard without a prompt. Native Wayland apps
  # with a real app_id are unaffected and still prompted individually. This is
  # a broad trust grant accepted here because this is a personal gaming
  # machine; a least-privilege alternative is to disable Xalia per-game
  # instead (Steam launch options: PROTON_USE_XALIA=0 %command%).
  #
  # Persistent state caveat: this writes to the on-disk permission store
  # (~/.local/share/flatpak/db/kde-authorized). Removing this module does NOT
  # revoke the grant. To revoke manually:
  #   busctl --user call org.freedesktop.impl.portal.PermissionStore \
  #     /org/freedesktop/impl/portal/PermissionStore \
  #     org.freedesktop.impl.portal.PermissionStore \
  #     DeletePermission sss kde-authorized remote-desktop ""
  #
  # Refs:
  # - https://github.com/KDE/xdg-desktop-portal-kde/blob/master/src/remotedesktop.cpp (isAppMegaAuthorized)
  # - https://bugs.kde.org/show_bug.cgi?id=480235
  # - https://discuss.kde.org/t/remote-control-requested-still-an-issue/24733
  # - https://www.reddit.com/r/kde/comments/15xh0t0/is_there_a_way_to_permanently_grant_this/
  # - https://bbs.archlinux.org/viewtopic.php?id=307526
  systemd.user.services.kde-remote-desktop-authorize = {
    Unit = {
      Description = "Authorize XWayland apps for KDE RemoteDesktop portal (no input dialog)";
      After = [ "xdg-desktop-portal.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = ''
        ${pkgs.systemd}/bin/busctl --user call \
          org.freedesktop.impl.portal.PermissionStore \
          /org/freedesktop/impl/portal/PermissionStore \
          org.freedesktop.impl.portal.PermissionStore \
          SetPermission sbssas kde-authorized true remote-desktop "" 1 yes
      '';
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
