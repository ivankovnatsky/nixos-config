{
  lib,
  stdenv,
  fetchurl,
  unzip,
}:

stdenv.mkDerivation {
  pname = "ghostty";
  version = "tip";

  src = fetchurl {
    url = "https://github.com/ghostty-org/ghostty/releases/download/tip/ghostty-macos-universal.zip";
    sha256 = "sha256-kUzDeo4Lkf8i78lIXdGy0fRpq6NLBElcyPTJMknEjfk=";
  };

  nativeBuildInputs = [ unzip ];

  sourceRoot = ".";

  unpackPhase = ''
    unzip $src
  '';

  installPhase = ''
    mkdir -p $out/Applications
    cp -r Ghostty.app $out/Applications
  '';

  meta = with lib; {
    description = "A fast, feature-rich terminal emulator";
    homepage = "https://github.com/ghostty-org/ghostty";
    platforms = platforms.darwin;
    license = licenses.mit;
    maintainers = with maintainers; [ ivankovnatsky ];
  };
}
