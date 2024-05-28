{ lib
, stdenvNoCC
, fetchurl
, _7zz
, undmg
}:

stdenvNoCC.mkDerivation rec {
  pname = "mos";
  version = "3.4.1";

  src = fetchurl {
    url = "https://github.com/Caldis/Mos/releases/download/${version}/Mos.Versions.${version}.dmg";
    hash = "sha256-OOoz6GeBVQZBQyNIQUe4grbZffSvl1m8oKZNmMlQKbM=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ undmg ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications
    cp -r *.app $out/Applications

    runHook postInstall
  '';

  meta = with lib; {
    description = "Smooths scrolling and set mouse scroll directions independently";
    homepage = "https://mos.caldis.me/";
    license = licenses.unfree;
    maintainers = [ maintainers.ivankovnatsky ];
    platforms = platforms.darwin;
  };
}
