{ stdenv, lib, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "helm-secrets";
  version = "92415f7543343c0f21af6b344b3295483c562550";

  src = fetchFromGitHub {
    owner = "jkroepke";
    repo = "${pname}";
    rev = "${version}";
    sha256 = "sha256-xy5PXXK8ji6lsHyZ0hFa9Et6I9LRMnP4jxboYFIhoh4=";
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
