{ pkgs }:

let
  py = pkgs.python3;

  # anker-solix-api is not published to PyPI or nixpkgs; build it from source.
  anker-solix-api = py.pkgs.buildPythonPackage {
    pname = "anker-solix-api";
    version = "3.7.0";
    pyproject = true;

    src = pkgs.fetchFromGitHub {
      owner = "thomluther";
      repo = "anker-solix-api";
      rev = "2008c4e4fd3a19a512dc5dc35e66e2d8e326402f";
      hash = "sha256-vvxqLjN/2kFre5JpHM3j/UxjrIjpcqN6ZESM8fHht1M=";
    };

    build-system = [ py.pkgs.poetry-core ];

    # Upstream pyproject.toml ships no [build-system] table, so pip falls back to
    # setuptools; declare the poetry-core backend it actually uses.
    postPatch = ''
      printf '\n[build-system]\nrequires = ["poetry-core>=2.1"]\nbuild-backend = "poetry.core.masonry.api"\n' >> pyproject.toml
    '';

    dependencies = with py.pkgs; [
      aiohttp
      aiofiles
      cryptography
      paho-mqtt
      python-dotenv
    ];

    doCheck = false;
    pythonImportsCheck = [ "anker_solix_api" ];
  };

  src = (import ../cleanPythonSource.nix { inherit (pkgs) lib; }) ./.;
in
pkgs.writeShellScriptBin "anker-monitor" ''
  exec ${
    py.withPackages (ps: [
      ps.click
      anker-solix-api
    ])
  }/bin/python ${src}/anker-monitor.py "$@"
''
