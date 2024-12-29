{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "terragrunt-atlantis-config";
  version = "1.19.0";

  src = fetchFromGitHub {
    owner = "transcend-io";
    repo = "terragrunt-atlantis-config";
    rev = "v${version}";
    hash = "sha256-JVfNjigojMyDX7sUEkVU9IqtN+zfeM6bD8D/aWNSy2o=";
  };

  vendorHash = "sha256-fWuWT56VsbPpMo/rnqonrbPJ7EWgi7DeJ36TOoxdbEc=";

  ldflags = [
    "-s"
    "-w"
    "-X main.VERSION=v${version}"
  ];

  doCheck = false;

  doInstallCheck = true;

  meta = with lib; {
    description = "Generate Atlantis config for Terragrunt projects.";
    homepage = "https://github.com/transcend-io/terragrunt-atlantis-config";
    changelog = "https://github.com/transcend-io/terragrunt-atlantis-config/releases/tag/v${version}";
    license = licenses.mit;
    mainProgram = "terragrunt-atlantis-config";
    maintainers = with maintainers; [ ivankovnatsky ];
  };
}
