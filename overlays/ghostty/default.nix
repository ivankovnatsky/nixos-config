{ lib
, fetchzip
, stdenv
, unzip
}:

let
  version = "tip";
in

stdenv.mkDerivation rec {
  pname = "ghostty";
  inherit version;

  src = ./ghostty-macos-universal.zip;

  nativeBuildInputs = [ unzip ];

  # Skip the default unpack phase and handle it manually
  dontUnpack = true;

  installPhase = ''
    # Create a temporary directory and unzip there
    mkdir -p $out/Applications
    cd $out/Applications
    ${unzip}/bin/unzip ${src}
  '';

  meta = with lib; {
    description = "A fast, feature-rich terminal emulator";
    homepage = "https://github.com/ghostty-org/ghostty";
    license = licenses.mit;
    platforms = platforms.darwin;
  };
} 
