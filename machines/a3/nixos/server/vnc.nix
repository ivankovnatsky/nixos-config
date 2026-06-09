{ pkgs, ... }:

{
  security.pam.services.tigervnc = { };

  systemd.services.tigervnc = {
    description = "TigerVNC Plasma session";
    after = [
      "network.target"
      "user@1000.service"
    ];
    requires = [ "user@1000.service" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      DISPLAY = ":1";
      XDG_CURRENT_DESKTOP = "KDE";
      XDG_SESSION_DESKTOP = "KDE";
      XDG_SESSION_TYPE = "x11";
    };

    path = [
      pkgs.coreutils
      pkgs.kdePackages.plasma-workspace
      pkgs.tigervnc
    ];

    script = ''
      export XDG_RUNTIME_DIR=/run/user/$(id -u)
      export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus

      vnc_pid=
      plasma_pid=

      cleanup() {
        if [[ -n "$plasma_pid" ]] && kill -0 "$plasma_pid"; then
          kill "$plasma_pid"
        fi
        if [[ -n "$vnc_pid" ]] && kill -0 "$vnc_pid"; then
          kill "$vnc_pid"
        fi
      }
      trap cleanup EXIT INT TERM

      Xvnc :1 \
        -SecurityTypes RA2_256 \
        -PlainUsers ivan \
        -PAMService tigervnc \
        -rfbport 5900 \
        -nolisten tcp \
        -geometry 1920x1080 \
        -AlwaysShared &
      vnc_pid=$!

      for _ in $(seq 1 100); do
        [[ -S /tmp/.X11-unix/X1 ]] && break
        kill -0 "$vnc_pid"
        sleep 0.1
      done
      [[ -S /tmp/.X11-unix/X1 ]]

      startplasma-x11 &
      plasma_pid=$!

      if wait -n "$vnc_pid" "$plasma_pid"; then
        status=0
      else
        status=$?
      fi

      exit "$status"
    '';

    serviceConfig = {
      User = "ivan";
      Restart = "always";
      RestartSec = 5;
    };
  };

  networking.firewall.allowedTCPPorts = [ 5900 ];
}
