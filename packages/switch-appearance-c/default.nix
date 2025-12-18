{
  lib,
  stdenv,
}:
stdenv.mkDerivation {
  pname = "switch-appearance-c";
  version = "1.0.0";

  src = ./.;

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild
    $CC -O2 -Wall -o switch-appearance-c main.c
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp switch-appearance-c $out/bin/
    runHook postInstall
  '';

  meta = with lib; {
    description = "Toggle system appearance between dark and light mode (C version)";
    license = licenses.mit;
    maintainers = with maintainers; [ ivankovnatsky ];
    mainProgram = "switch-appearance-c";
  };
}
