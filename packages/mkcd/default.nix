{
  lib,
  buildGoModule,
}:
buildGoModule {
  pname = "mkcd";
  version = "1.0.0";

  src = ./.;

  vendorHash = null;

  meta = with lib; {
    description = "Make directory and change into it";
    license = licenses.mit;
    maintainers = with maintainers; [ ivankovnatsky ];
    mainProgram = "mkcd";
  };
}
