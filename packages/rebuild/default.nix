{
  pkgs,
  watchman,
  python3,
}:

let
  src = (import ../cleanPythonSource.nix { inherit (pkgs) lib; }) ./.;
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
    }/bin/python ${src}/main.py "$@"
  '';
}
