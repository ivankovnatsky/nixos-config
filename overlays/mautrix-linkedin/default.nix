{
  lib,
  buildGoModule,
  fetchFromGitHub,
  olm,
  ...
}:

buildGoModule rec {
  pname = "mautrix-linkedin";
  version = "0.5.4-unstable-2025-10-17";

  src = fetchFromGitHub {
    owner = "mautrix";
    repo = "linkedin";
    rev = "17afb9e355ec3279e14bf00a5c58e04bef5a5411";
    hash = "sha256-p0dhrHiwB2y7MvJi6dCtjUJ8MmHXnLT5eX6CFjAf3OM=";
  };

  buildInputs = [ olm ];

  vendorHash = "sha256-lSAXm9sguihNZyd5h2wF5ktwwDf1ctDJCt3gZDBDV3s=";

  doCheck = false;

  meta = with lib; {
    description = "A Matrix-LinkedIn puppeting bridge";
    homepage = "https://github.com/mautrix/linkedin";
    license = licenses.agpl3Plus;
    maintainers = [ ];
    mainProgram = "mautrix-linkedin";
  };
}
