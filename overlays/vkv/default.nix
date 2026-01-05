{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "vkv";
  version = "0.9.3";

  src = fetchFromGitHub {
    owner = "FalcoSuessgott";
    repo = "vkv";
    rev = "v${version}";
    hash = "sha256-4RYb3ElM3d5PdvbG5sIr+32j1ZDxOcykBS/GEBCvqMk=";
  };

  vendorHash = "sha256-/+8JteAwAZploHs921Z5hJE9Db9KBk1/5y2KWBdIZyw=";

  doCheck = false;

  ldflags = [
    "-s"
    "-w"
    "-X=main.version=${version}"
  ];

  meta = with lib; {
    description = "CLI tool for HashiCorp Vault KV engine management";
    homepage = "https://github.com/FalcoSuessgott/vkv";
    license = licenses.mit;
    maintainers = with maintainers; [ ivankovnatsky ];
    mainProgram = "vkv";
  };
}
