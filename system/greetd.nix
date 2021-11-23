{ pkgs, lib, ... }:

let
  termName = import ../home/tmux.nix { inherit pkgs; };

  waylandEnablement = pkgs.writeShellScript "wayland-enablement" ''
    export CLUTTER_BACKEND=wayland
    export QT_QPA_PLATFORM=wayland-egl
    export ECORE_EVAS_ENGINE=wayland-egl
    export ELM_ENGINE=wayland_egl
    export SDL_VIDEODRIVER=wayland
    export _JAVA_AWT_WM_NONREPARENTING=1
    export NO_AT_BRIDGE=1
  '';

  swayRun = pkgs.writeShellScript "sway-run" ''
    export XDG_SESSION_TYPE=wayland
    export XDG_SESSION_DESKTOP=sway
    export XDG_CURRENT_DESKTOP=sway

    export TERM=${termName.programs.tmux.terminal}

    source ${waylandEnablement}

    ${pkgs.systemd}/bin/systemd-run --user --scope --collect --quiet --unit=sway-$(${pkgs.systemd}/bin/systemd-id128 new) ${pkgs.systemd}/bin/systemd-cat --identifier=sway ${pkgs.sway}/bin/sway
  '';

in
{
  services.greetd = {
    enable = true;

    restart = false;

    settings = {
      default_session = {
        command =
          "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd ${swayRun}";
        user = "greeter";
      };

      initial_session = {
        command = "${swayRun}";
        user = "ivan";
      };
    };
  };

  users.users.greeter.group = "greeter";
  users.groups.greeter = { };
}
