{
  lib,
  stdenv,
  fetchurl,
  installShellFiles,
}:

stdenv.mkDerivation rec {
  pname = "kubectl-ai";
  version = "0.0.7";

  src = fetchurl {
    url = "https://github.com/GoogleCloudPlatform/kubectl-ai/releases/download/v${version}/kubectl-ai_Darwin_arm64.tar.gz";
    hash = "sha256-pYyYV6mpTG92xMbvYQCGywiIDasiCDt5lQmVMhdGAmo=";
  };

  nativeBuildInputs = [ installShellFiles ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -m755 kubectl-ai $out/bin/kubectl-ai

    # Generate shell completions if available
    if [[ -f ./completions/kubectl-ai.bash ]]; then
      installShellCompletion --bash ./completions/kubectl-ai.bash
    fi
    if [[ -f ./completions/kubectl-ai.fish ]]; then
      installShellCompletion --fish ./completions/kubectl-ai.fish
    fi
    if [[ -f ./completions/kubectl-ai.zsh ]]; then
      installShellCompletion --zsh ./completions/kubectl-ai.zsh
    fi

    runHook postInstall
  '';

  meta = with lib; {
    description = "AI powered Kubernetes Assistant";
    homepage = "https://github.com/GoogleCloudPlatform/kubectl-ai";
    license = licenses.asl20;
    maintainers = with maintainers; [ ivankovnatsky ];
    mainProgram = "kubectl-ai";
    platforms = [ "aarch64-darwin" ];
  };
}
