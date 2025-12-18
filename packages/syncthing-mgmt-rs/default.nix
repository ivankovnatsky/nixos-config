{
  lib,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "syncthing-mgmt-rs";
  version = "1.0.0";

  src = ./.;

  cargoHash = "sha256-RkSwSSjSnnVFVOqKvUdR2PS//ULt1o1tCfkJjB20DZI=";

  meta = with lib; {
    description = "Syncthing status tool (Rust version)";
    license = licenses.mit;
    maintainers = with maintainers; [ ivankovnatsky ];
    mainProgram = "syncthing-mgmt-rs";
  };
}
