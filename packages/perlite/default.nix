{
  lib,
  fetchFromGitHub,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation rec {
  pname = "perlite";
  version = "1.6.1";

  src = fetchFromGitHub {
    owner = "secure-77";
    repo = "Perlite";
    rev = version;
    hash = "sha256-xmkHfOggT59If07SfZ/F8JdWDgEPEoEERThE5AgIJu0=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/perlite
    cp -r perlite/.js $out/share/perlite/
    cp -r perlite/.src $out/share/perlite/
    cp -r perlite/.styles $out/share/perlite/
    cp -r perlite/vendor $out/share/perlite/
    cp perlite/index.php $out/share/perlite/
    cp perlite/helper.php $out/share/perlite/
    cp perlite/content.php $out/share/perlite/
    cp perlite/settings.php $out/share/perlite/
    cp perlite/favicon.ico $out/share/perlite/
    cp perlite/logo.svg $out/share/perlite/
    cp perlite/perlite.svg $out/share/perlite/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Web-based markdown viewer optimized for Obsidian notes";
    homepage = "https://github.com/secure-77/Perlite";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
