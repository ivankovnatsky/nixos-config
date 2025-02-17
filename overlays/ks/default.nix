{
  stdenv,
  lib,
  fetchFromGitHub,
}:

stdenv.mkDerivation rec {
  pname = "ks";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "loteoo";
    repo = pname;
    rev = "${version}";
    hash = "sha256-jGo0u0wiwOc2n8x0rvDIg1suu6vJQ5UCfslYD5vUlyI=";
  };

  installPhase = ''
    mkdir -p $out/bin
    cp ${pname} $out/bin/
  '';

  meta = with lib; {
    homepage = "https://github.com/loteoo/ks";
    description = "Command-line secrets manager powered by macOS keychains";
    license = licenses.mit;
    maintainers = with maintainers; [ ivankovnatsky ];
    platform = platforms.darwin;
  };
}
