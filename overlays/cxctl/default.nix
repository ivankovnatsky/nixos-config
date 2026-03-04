# https://coralogix.com/docs/developer-portal/infrastructure-as-code/cli/coralogix-cli/
{
  lib,
  stdenv,
  fetchurl,
  gzip,
}:

stdenv.mkDerivation rec {
  pname = "cxctl";
  version = "latest";

  src = fetchurl {
    url = "https://coralogix-public.s3-eu-west-1.amazonaws.com/cxctl/latest/cxctl-macOS.gz";
    hash = "sha256-sKMF4+OsAld37OXQ4k7knCiR6Ei8hoXpEPdOIZC+zTk=";
  };

  dontUnpack = true;

  nativeBuildInputs = [ gzip ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    gzip -dc $src > $out/bin/cxctl
    chmod +x $out/bin/cxctl

    runHook postInstall
  '';

  meta = with lib; {
    description = "Coralogix CLI for managing operations without the web interface";
    homepage = "https://coralogix.com/docs/developer-portal/infrastructure-as-code/cli/coralogix-cli/";
    license = licenses.unfree;
    maintainers = with maintainers; [ ivankovnatsky ];
    mainProgram = "cxctl";
    platforms = [
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
}
