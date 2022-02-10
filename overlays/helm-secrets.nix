{ stdenv, lib, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "helm-secrets";
  version = "3.12.0";

  src = fetchFromGitHub {
    owner = "jkroepke";
    repo = "${pname}";
    rev = "v${version}";
    sha256 = "sha256-y8GumMCABdQGnNWJcmM/cXvJ61GoAm6467Ks+YRRW+s=";
  };

  installPhase = ''
    runHook preBuild
    mkdir $out/
    mv .[A-Za-z0-9_]* $out/
    mv * $out/
    runHook postBuild
  '';

  meta = with lib; {
    description = "A helm plugin that help manage secrets with Git workflow and store them anywhere ";
    homepage = "https://github.com/jkroepke/helm-secrets";
    maintainers = with maintainers; [ ivankovnatsky ];
    license = licenses.asl20;
    platforms = lib.platforms.unix;
  };
}
