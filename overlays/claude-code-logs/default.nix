{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "claude-code-logs";
  version = "0.1.35";

  src = fetchFromGitHub {
    owner = "fabriqaai";
    repo = "claude-code-logs";
    rev = "v${version}";
    hash = "sha256-9lkTH+nJ6pGeaIfWirdJtwnfyBpJSDO1LSdax3iON6c=";
  };

  vendorHash = "sha256-QLLFqkHrhCuBILADemkyKovNime5Zc1cc0DmdPHUtKA=";

  meta = with lib; {
    description = "CLI tool to browse and search Claude Code chat logs";
    homepage = "https://github.com/fabriqaai/claude-code-logs";
    license = licenses.mit;
    maintainers = with maintainers; [ ivankovnatsky ];
    mainProgram = "claude-code-logs";
  };
}
