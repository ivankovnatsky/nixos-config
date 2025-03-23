{
  lib,
  stdenv,
  fetchFromGitHub,
  darwin,
}:

stdenv.mkDerivation rec {
  pname = "smctemp";
  version = "eebe38b4e27ca9a8b2caef0fda09694de5751874";

  src = fetchFromGitHub {
    owner = "narugit";
    repo = pname;
    rev = version;
    hash = "sha256-961N5bLZcBqdo3IKpIRxOCDLoG1+fL1YGJLsNfll7lE=";
  };

  buildInputs = lib.optionals stdenv.isDarwin [
    darwin.IOKit
  ];

  # Fix the Makefile and code issues
  patchPhase = ''
    # Fix the snprintf format string security issue
    substituteInPlace smctemp.cc \
      --replace 'snprintf(val.key, sizeof(val.key), key);' \
                'snprintf(val.key, sizeof(val.key), "%s", key);'
    
    # Modify the Makefile to use the correct C++ compiler and install location
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
