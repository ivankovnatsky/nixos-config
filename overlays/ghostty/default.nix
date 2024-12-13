{ lib
, fetchzip
, stdenv
, unzip
}:

let
  version = "tip";
  homeDir = builtins.getEnv "HOME";
in

stdenv.mkDerivation rec {
  pname = "ghostty";
  inherit version;

  src = builtins.path {
    name = "ghostty-zip";
    path = "${homeDir}/.ghostty/ghostty-macos-universal.zip";
  };

  nativeBuildInputs = [ unzip ];

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/Applications
    cd $out/Applications
    ${unzip}/bin/unzip ${src}
  '';

  __noChroot = true;
  preferLocalBuild = true;
  allowSubstitutes = false;

  meta = with lib; {
    description = "A fast, feature-rich terminal emulator";
    homepage = "https://github.com/ghostty-org/ghostty";
    license = licenses.mit;
    platforms = platforms.darwin;
  };
} 
