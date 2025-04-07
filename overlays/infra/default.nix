{
  lib,
  stdenv,
  fetchurl,
  unzip,
}:

stdenv.mkDerivation {
  pname = "infra";
  version = "latest";

  src = fetchurl {
    url = "https://download.infra.app/darwin/Infra-darwin-universal-latest.zip";
    sha256 = "sha256-QfLXH+hJNcTsPrE+c8kenFszw4xZm/cKcnVgkTVtE9E=";
  };

  nativeBuildInputs = [ unzip ];

  sourceRoot = ".";

  installPhase = ''
    # Create the Applications directory
    mkdir -p $out/Applications

    # Move the app bundle
    mv Infra.app $out/Applications/

    # Create a bin directory and symlink to the executable
    mkdir -p $out/bin
    ln -s $out/Applications/Infra.app/Contents/MacOS/Infra $out/bin/infra
  '';

  meta = with lib; {
    description = "Infra - Application for infrastructure management";
    homepage = "https://infra.app";
    license = licenses.unfree;
    platforms = [
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    maintainers = with maintainers; [ ivankovnatsky ];
    mainProgram = "infra";
  };
}
