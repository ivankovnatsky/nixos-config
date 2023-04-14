{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "ktop";
  version = "cb3a80f1ea70c6fbc1207c2b2340314aa19962b8";

  src = fetchFromGitHub {
    owner = "vladimirvivien";
    repo = pname;
    rev = "${version}";
    sha256 = "sha256-nkIRVt2kqsE9QBYvvHmupohnzH+OBcwWwV16rMePw4I=";
  };

  vendorSha256 = "sha256-IiAMmHOq69WMT2B1q9ZV2fGDnLr7AbRm1P7ACSde2FE=";

  postConfigure = ''
    rm -rf ./.ci ./hack
  '';

  doCheck = false;

  ldflags = [
    "-s"
    "-w"
    "-X github.com/vladimirvivien/ktop/buildinfo.Version=v${version}"
    "-X github.com/vladimirvivien/ktop/buildinfo.GitSHA=${src.rev}"
  ];

  postInstall = ''
    mv $out/bin/ktop $out/bin/kubectl-ktop
  '';

  meta = with lib; {
    description = "A top-like tool for your Kubernetes clusters";
    homepage = "https://github.com/vladimirvivien/ktop";
    changelog = "https://github.com/vladimirvivien/ktop/releases/tag/${version}";
    license = licenses.asl20;
    maintainers = [ maintainers.ivankovnatsky ];
  };
}
