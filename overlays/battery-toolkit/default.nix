{ lib
, fetchzip
, stdenv
}:

let
  version = "1.4";
in

stdenv.mkDerivation rec {
  pname = "battery-toolkit";
  inherit version;

  # https://github.com/mhaeuser/Battery-Toolkit/releases/download/1.4/Battery-Toolkit-1.4.zip
  src = fetchzip {
    url = "https://github.com/mhaeuser/Battery-Toolkit/releases/download/${version}/Battery-Toolkit-${version}.zip";
    hash = "sha256-bTpDr83xKoBxV8EQZBMQU0g9pRXuJNHy3MtaeO1j/M0=";
  };

  installPhase = ''
    mkdir -p $out/Applications
    cp -R . "$out/Applications/Battery Toolkit.app"
  '';

  meta = with lib; {
    description = "Battery Toolkit for macOS";
    homepage = "https://github.com/mhaeuser/Battery-Toolkit";
    license = licenses.mit;
    maintainers = with maintainers; [ ivankovnatsky ];
    platforms = platforms.darwin;
  };
}
