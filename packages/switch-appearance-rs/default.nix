{
  lib,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "switch-appearance-rs";
  version = "1.0.0";

  src = ./.;

  cargoHash = "sha256-TpGr1EJrHuTO6NuAfVuWrfyrTi1Pjm/7ApKD993uFqQ=";

  meta = with lib; {
    description = "Toggle system appearance between dark and light mode (Rust version)";
    license = licenses.mit;
    maintainers = with maintainers; [ ivankovnatsky ];
    mainProgram = "switch-appearance-rs";
  };
}
