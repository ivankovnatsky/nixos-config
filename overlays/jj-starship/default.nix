{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
  zlib,
  libgit2,
  apple-sdk ? null,
  libiconv ? null,
  stdenv,
}:

rustPlatform.buildRustPackage rec {
  pname = "jj-starship";
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "dmmulroy";
    repo = "jj-starship";
    rev = "v${version}";
    hash = "sha256-YfcFlJsPCRfqhN+3JUWE77c+eHIp5RAu2rq/JhSxCec=";
  };

  cargoHash = "sha256-XMz6b63raPkgmUzB6L3tOYPxTenytmGWOQrs+ikcSts=";

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    openssl
    zlib
    libgit2
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    apple-sdk
    libiconv
  ];

  meta = {
    description = "Unified Git/JJ Starship prompt module optimized for latency";
    homepage = "https://github.com/dmmulroy/jj-starship";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ivankovnatsky ];
    mainProgram = "jj-starship";
    platforms = lib.platforms.unix;
  };
}
