{
  lib,
  buildGoModule,
  fetchFromGitHub,
  go_1_26,
}:
(buildGoModule.override { go = go_1_26; }) rec {
  pname = "gwq";
  version = "0.0.17";

  src = fetchFromGitHub {
    owner = "d-kuro";
    repo = "gwq";
    rev = "v${version}";
    hash = "sha256-A7CUzLhhjKRhiL88l8j3xCmKrRDk+KOhdbaow8FAlCo=";
  };

  vendorHash = "sha256-4K01Xf1EXl/NVX1loQ76l1bW8QglBAQdvlZSo7J4NPI=";

  # Tests require filesystem access (config directory creation) that fails in the sandbox
  doCheck = false;

  meta = with lib; {
    description = "Git worktree manager with fuzzy finder";
    homepage = "https://github.com/d-kuro/gwq";
    license = licenses.mit;
    maintainers = with maintainers; [ ivankovnatsky ];
    mainProgram = "gwq";
  };
}
