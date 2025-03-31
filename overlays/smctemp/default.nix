{
  lib,
  stdenv,
  fetchFromGitHub,
  darwin,
  gcc,
}:

stdenv.mkDerivation rec {
  pname = "smctemp";
  version = "39cc769b18237e153eb5d15464aa2946676b7142";

  src = fetchFromGitHub {
    owner = "ivankovnatsky";
    repo = pname;
    rev = version;
    hash = "sha256-cSQAWEBpCJHvH4vFnMgxYIv35qZWVJUgZryeBlBr6hs=";
  };

  nativeBuildInputs = [
    gcc
    darwin.apple_sdk.frameworks.IOKit
  ];

  buildInputs = lib.optionals stdenv.isDarwin [
    darwin.IOKit
  ];

  patchPhase = ''
    # Modify the Makefile to use the correct install location
    substituteInPlace Makefile \
      --replace 'CXXFLAGS := -Wall -std=c++17 -g' \
                'CXXFLAGS := -Wall -std=c++17 -g -Wno-deprecated-declarations -Wno-format-security' \
      --replace 'DEST_PREFIX := /usr/local' 'DEST_PREFIX := $(PREFIX)' \
      --replace 'PROCESS_IS_TRANSLATED := $(shell sysctl -in sysctl.proc_translated)' \
                'PROCESS_IS_TRANSLATED := 0'
  '';

  makeFlags = [
    "PREFIX=${placeholder "out"}"
  ];

  buildPhase = ''
    export CXXFLAGS="-Wall -std=c++17 -g -I${darwin.apple_sdk.frameworks.IOKit}/Library/Frameworks/IOKit.framework/Headers"
    export LDFLAGS="-F${darwin.apple_sdk.frameworks.IOKit}/Library/Frameworks -framework IOKit"
    make
  '';

  meta = with lib; {
    description = "CLI tool to print CPU and GPU temperature on macOS";
    homepage = "https://github.com/narugit/smctemp";
    license = licenses.gpl2;
    platforms = platforms.darwin;
    maintainers = with maintainers; [ ivankovnatsky ];
    mainProgram = "smctemp";
  };
}
