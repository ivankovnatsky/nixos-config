{ lib
, fetchurl
, unzip
, stdenv
,
}:

# https://github.com/mhaeuser/Battery-Toolkit/issues/105#issuecomment-2797029669
# https://github.com/mhaeuser/Battery-Toolkit/issues/7#issuecomment-2036664963
# https://github.com/mhaeuser/Battery-Toolkit/blob/main/uninstall.sh

let
  version = "1.6";
in

stdenv.mkDerivation rec {
  pname = "battery-toolkit";
  inherit version;

  src = fetchurl {
    url = "https://github.com/mhaeuser/Battery-Toolkit/releases/download/${version}/Battery-Toolkit-${version}.zip";
    hash = "sha256-Gk2ZtV5JtpRl9SbXg96KL6XhZIOUmJ9sgyjM2dSw1z8=";
  };

  nativeBuildInputs = [ unzip ];

  sourceRoot = ".";

  dontStrip = true;
  dontFixup = true;

  unpackPhase = ''
    unzip $src
  '';

  installPhase = ''
    ls -la
    mkdir -p "$out/Applications"
    mv "Battery Toolkit.app" "$out/Applications/"
  '';

  meta = with lib; {
    description = "Battery Toolkit for macOS";
    homepage = "https://github.com/mhaeuser/Battery-Toolkit";
    license = licenses.mit;
    maintainers = with maintainers; [ ivankovnatsky ];
    platforms = platforms.darwin;
  };
}
