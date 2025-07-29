{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "zesh";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "roberte777";
    repo = "zesh";
    rev = "zesh-v${version}";
    sha256 = "sha256-10zKOsNEcHb/bNcGC/TJLA738G0cKeMg1vt+PZpiEUI=";
  };

  cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

  meta = with lib; {
    description = "A zellij session manager with zoxide integration";
    homepage = "https://github.com/roberte777/zesh";
    license = licenses.mit;
    maintainers = with maintainers; [ ivankovnatsky ];
    mainProgram = "zesh";
  };
}
