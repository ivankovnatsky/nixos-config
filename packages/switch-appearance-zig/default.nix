{
  lib,
  stdenv,
  zig,
}:
stdenv.mkDerivation {
  pname = "switch-appearance-zig";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [
    zig.hook
  ];

  meta = {
    description = "Toggle system appearance between dark and light mode (Zig version)";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ivankovnatsky ];
    mainProgram = "switch-appearance-zig";
    inherit (zig.meta) platforms;
  };
}
