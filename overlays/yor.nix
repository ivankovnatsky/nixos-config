{ buildGoModule
, fetchFromGitHub
, lib
}:

buildGoModule rec {
  pname = "yor";
  version = "0.1.177";

  src = fetchFromGitHub {
    owner = "bridgecrewio";
    repo = pname;
    rev = "${version}";
    sha256 = "sha256-tOYRd3LxSlAvXCW89LAm4GWWukDBZhsgYIWYlEVKokE=";
  };

  vendorSha256 =
    "sha256-ZeTjGmlu8LndD2DKNncPzlpECdvkOjfwaVvV6S3sL9E=";

  doCheck = false;

  # https://github.com/ivankovnatsky/yor/blob/main/set-version.sh
  preBuild = ''
    echo "Updating version file with new tag: ${version}"
    echo "package common" > src/common/version.go
    echo "" >> src/common/version.go
    echo "const Version = \"${version}\"" >> src/common/version.go
  '';

  ldflags = [
    "-s"
    "-w"
  ];

  meta = with lib; {
    description = "Extensible auto-tagger for your IaC files. The ultimate way to link entities in the cloud back to the codified resource which created it.";
    homepage = "https://github.com/bridgecrewio/yor";
    changelog = "https://github.com/bridgecrewio/yor/releases/tag/${version}";
    license = licenses.asl20;
    maintainers = [ maintainers.ivankovnatsky ];
  };
}
