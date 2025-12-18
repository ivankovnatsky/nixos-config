{
  lib,
  buildGoModule,
}:
buildGoModule {
  pname = "syncthing-mgmt-go";
  version = "1.0.0";

  src = ./.;

  vendorHash = null;

  meta = with lib; {
    description = "Syncthing status tool (Go version)";
    license = licenses.mit;
    maintainers = with maintainers; [ ivankovnatsky ];
    mainProgram = "syncthing-mgmt-go";
  };
}
