{
  lib,
  stdenv,
  zig,
  curl,
}:
stdenv.mkDerivation {
  pname = "syncthing-mgmt-zig";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [
    zig.hook
  ];

  # Zig version shells out to curl for HTTP
  buildInputs = [ curl ];

  meta = {
    description = "Syncthing status tool (Zig version)";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ivankovnatsky ];
    mainProgram = "syncthing-mgmt-zig";
    inherit (zig.meta) platforms;
  };
}
