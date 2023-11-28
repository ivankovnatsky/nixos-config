{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "kor";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "yonahd";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-emijYJL054UCOAUobspDqSc7LuQjUjT2E/rQKqJDvA8=";
  };

  vendorHash = "sha256-iAqptugku3qX6e45+YYf1bU9j2YntNQj82vR04bFMOQ=";

  # ```console
  # kor> slack_test.go:59: Expected no error, got failed to create output file: open /homeless-shelter/kor-scan-results.txt: no such file or directory
  # ```
  preCheck = ''
    HOME=$(mktemp -d)
    export HOME
  '';

  ldflags = [
    "-s"
    "-w"
  ];

  meta = with lib; {
    description = "A Golang Tool to discover unused Kubernetes Resources";
    homepage = "https://github.com/yonahd/kor";
    changelog = "https://github.com/yonahd/kor/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = [ maintainers.ivankovnatsky ];
    mainProgram = "kor";
  };
}
