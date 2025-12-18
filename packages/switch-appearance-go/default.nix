{
  lib,
  buildGoModule,
}:
buildGoModule {
  pname = "switch-appearance-go";
  version = "1.0.0";

  src = ./.;

  vendorHash = null;

  meta = with lib; {
    description = "Toggle system appearance between dark and light mode (Go version)";
    license = licenses.mit;
    maintainers = with maintainers; [ ivankovnatsky ];
    mainProgram = "switch-appearance-go";
  };
}
