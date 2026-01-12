{
  lib,
  stdenv,
  zip,
}:

# https://gist.github.com/zbraniecki/000268ea27154bbccaad190dd479d226
stdenv.mkDerivation {
  pname = "firefox-selecttab";
  version = "1.0";

  src = ./.;

  nativeBuildInputs = [ zip ];

  buildPhase = ''
    runHook preBuild

    mkdir -p extension
    cp ${./manifest.json} extension/manifest.json
    cp ${./background.js} extension/background.js

    cd extension
    ${zip}/bin/zip -r ../firefox-selecttab.xpi .
    cd ..

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/extensions
    cp firefox-selecttab.xpi $out/share/extensions/firefox.zip

    runHook postInstall
  '';

  meta = with lib; {
    description = "Firefox extension to enable Ctrl+1-9 tab switching on Linux";
    license = licenses.mit;
    maintainers = with maintainers; [ ivankovnatsky ];
  };
}
