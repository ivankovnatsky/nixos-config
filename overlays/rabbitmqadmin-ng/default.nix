{
  lib,
  fetchFromGitHub,
  nixpkgs-master,
}:

nixpkgs-master.rustPlatform.buildRustPackage rec {
  pname = "rabbitmqadmin-ng";
  # version = "0.24.0";
  version = "2af49f8047e9a00e1d6e851ad1ce3f1bd5dd5dc8";

  src = fetchFromGitHub {
    owner = "rabbitmq";
    repo = pname;
    # rev = "v${version}";
    rev = "${version}";
    hash = "sha256-0+3bRcyls66UON8EUijPIb6iWOgCfDx1edSQneMIETc=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      "rabbitmq_http_client-0.23.0" = "sha256-6+PNJQOb8p4COs+S/UZJbyku284Q6AWYjqWYRDdGziU=";
    };
  };

  # Add cargo-features at the top of Cargo.toml
  postPatch = ''
    sed -i '1i cargo-features = ["edition2024"]' Cargo.toml
  '';

  # Enable nightly features
  RUSTC_BOOTSTRAP = 1;
  RUSTFLAGS = "-Z unstable-options";

  # Skip tests as they require a running RabbitMQ server
  doCheck = false;

  meta = with lib; {
    description = "A modern command line tool for RabbitMQ that uses the HTTP API";
    homepage = "https://github.com/rabbitmq/rabbitmqadmin-ng";
    changelog = "https://github.com/rabbitmq/rabbitmqadmin-ng/blob/v${version}/CHANGELOG.md";
    license = with licenses; [
      asl20
      mit
    ];
    mainProgram = "rabbitmqadmin";
  };
}
