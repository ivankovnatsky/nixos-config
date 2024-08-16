{ lib
, watchman
, python311Packages
, fetchurl
, makeWrapper
}:

let
  pythonPackages = python311Packages;
in
pythonPackages.buildPythonApplication rec {
  pname = "watchman-make";
  version = "unstable-2024-03-16"; # You may want to update this date

  src = fetchurl {
    url = "https://raw.githubusercontent.com/facebook/watchman/main/watchman/python/bin/watchman-make";
    sha256 = "sha256-q4p1hWCxLvSD6d5IuPIyGjnjxOfAzQl53+gnpjPIz04=";
  };

  dontUnpack = true;
  format = "other";

  nativeBuildInputs = [ makeWrapper ];

  propagatedBuildInputs = with pythonPackages; [
    pywatchman
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/watchman-make
    wrapProgram $out/bin/watchman-make \
      --prefix PATH : ${lib.makeBinPath [ watchman ]}
    runHook postInstall
  '';

  meta = with lib; {
    description = "A convenience tool to trigger commands in response to file changes";
    homepage = "https://facebook.github.io/watchman/";
    license = licenses.mit;
    maintainers = with maintainers; [ ivankovnatsky ];
    platforms = platforms.all;
  };
}
