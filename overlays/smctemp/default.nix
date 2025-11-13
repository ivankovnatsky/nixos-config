{ lib
, stdenv
, fetchFromGitHub
,
}:

stdenv.mkDerivation rec {
  pname = "smctemp";
  version = "37cbfece9d5a36c83b77251adbf8d869d70a1a5e";

  src = fetchFromGitHub {
    owner = "ivankovnatsky";
    repo = pname;
    rev = version;
    hash = "sha256-FvsuoJix+v4Qusr+5GhynfkJZ5eN60B2H0KBRk1PBIY=";
  };

  # https://nixos.org/manual/nixpkgs/stable/#sec-darwin-legacy-frameworks
  # Legacy darwin.apple_sdk.frameworks removed - default SDK is sufficient
  patchPhase = ''
    substituteInPlace Makefile \
      --replace 'CXX := g++' 'CXX := c++' \
      --replace 'CXXFLAGS := -Wall -std=c++17 -g -framework IOKit' \
                'CXXFLAGS := -Wall -std=c++17 -g -framework IOKit -Wno-deprecated-declarations -Wno-format-security' \
      --replace 'DEST_PREFIX := /usr/local' 'DEST_PREFIX := $(PREFIX)' \
      --replace 'PROCESS_IS_TRANSLATED := $(shell sysctl -in sysctl.proc_translated)' \
                'PROCESS_IS_TRANSLATED := 0'
  '';

  makeFlags = [
    "PREFIX=${placeholder "out"}"
  ];

  meta = with lib; {
    description = "CLI tool to print CPU and GPU temperature on macOS";
    homepage = "https://github.com/narugit/smctemp";
    license = licenses.gpl2;
    platforms = platforms.darwin;
    maintainers = with maintainers; [ ivankovnatsky ];
    mainProgram = "smctemp";
  };
}
