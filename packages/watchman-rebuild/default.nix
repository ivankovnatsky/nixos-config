{ lib
, stdenv
, makeWrapper
, python3
, watchman
,
}:

let
  pythonEnv = python3.withPackages (ps: [ ps.pywatchman ]);
in
stdenv.mkDerivation {
  name = "watchman-rebuild";
  version = "0.1.0";
  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    # Install Python module
    mkdir -p $out/${pythonEnv.sitePackages}
    cp watchman_rebuild.py $out/${pythonEnv.sitePackages}/

    # Install script
    mkdir -p $out/bin
    cp helper.py $out/bin/watchman-rebuild
    chmod +x $out/bin/watchman-rebuild

    # Wrap script with correct Python environment
    wrapProgram $out/bin/watchman-rebuild \
      --prefix PYTHONPATH : "$out/${pythonEnv.sitePackages}:${pythonEnv}/${pythonEnv.sitePackages}" \
      --prefix PATH : "${watchman}/bin"
  '';
}
