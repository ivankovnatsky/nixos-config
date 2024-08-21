{ lib
, fetchzip
, makeWrapper
, stdenv
}:

let
  version = "0.1.0";
in

stdenv.mkDerivation rec {
  pname = "bclm";
  inherit version;

  src = fetchzip {
    url = "https://github.com/zackelia/bclm/releases/download/v${version}/bclm.zip";
    hash = "sha256-GtMxg8BnaJjfZ13G+/tzBiM0V/ZGze+RCEaimHdc550=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    install -D bclm $out/bin/bclm
    wrapProgram $out/bin/bclm --prefix PATH ":" $out/bin
  '';

  meta = with lib; {
    description = "macOS command-line utility to limit max battery charge";
    homepage = "https://github.com/zackelia/bclm";
    license = licenses.mit;
    maintainers = with maintainers; [ ivankovnatsky ];
    platforms = platforms.all;
  };
}
