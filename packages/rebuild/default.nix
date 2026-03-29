{
  pkgs,
  watchman,
  python3,
}:

pkgs.writeShellApplication {
  name = "rebuild";
  runtimeInputs = [ watchman ];
  text = ''
    exec ${python3.withPackages (ps: [ ps.click ps.pywatchman ])}/bin/python ${./main.py} "$@"
  '';
}
