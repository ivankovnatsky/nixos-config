{ lib
, python3Packages
, fetchFromGitHub
,
}:

python3Packages.buildPythonApplication rec {
  pname = "perplexity-cli";
  version = "unstable-2025-10-21";
  pyproject = false;

  src = fetchFromGitHub {
    owner = "dawid-szewc";
    repo = "perplexity-cli";
    rev = "0a62d96fc4506f3b0cdc2a4d487536966a6cfe62";
    hash = "sha256-doK3uYP71CU2PwZmH2g3Jf/cp18xcCLSKuToD+WvNQE=";
  };

  propagatedBuildInputs = with python3Packages; [
    requests
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 perplexity.py $out/bin/perplexity

    runHook postInstall
  '';

  meta = with lib; {
    description = "A simple command-line client for the Perplexity API";
    homepage = "https://github.com/dawid-szewc/perplexity-cli";
    license = licenses.mit;
    maintainers = with maintainers; [ ivankovnatsky ];
    mainProgram = "perplexity";
  };
}
