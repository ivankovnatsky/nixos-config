{
  pkgs,
  watchman,
  python3,
}:

let
  discordSrc = (import ../cleanPythonSource.nix { inherit (pkgs) lib; }) ../discord;
in
pkgs.writeShellApplication {
  name = "rebuild";
  runtimeInputs = [ watchman ];
  text = ''
    export PYTHONPATH="${discordSrc}''${PYTHONPATH:+:$PYTHONPATH}"
    exec ${
      python3.withPackages (ps: [
        ps.click
        ps.pywatchman
        ps.discord-webhook
      ])
    }/bin/python ${./main.py} "$@"
  '';
}
