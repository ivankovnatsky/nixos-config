{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nodejs,
}:
buildGoModule rec {
  pname = "tweety";
  version = "2.1.10";

  src = fetchFromGitHub {
    owner = "pomdtr";
    repo = "tweety";
    rev = "v${version}";
    hash = "sha256-7pf4Z0YdnaLp8dPkuf/nwWWhVsy/zwxkaKbzH+LNybU=";
  };

  vendorHash = "sha256-VFEBX980kOtY/LrJfoJLQ9puiMMeCgI6gDr4oJyDLdU=";

  nativeBuildInputs = [ nodejs ];

  preBuild = ''
    # Build browser extensions
    cd extension
    npm ci
    npm run build
    npm run zip
    cd ..
  '';

  postInstall = ''
    # Install Firefox extension
    mkdir -p $out/share/firefox/extensions
    if [ -f extension/firefox.zip ]; then
      cp extension/firefox.zip $out/share/firefox/extensions/
    fi
  '';

  meta = with lib; {
    description = "An integrated terminal for your browser";
    homepage = "https://github.com/pomdtr/tweety";
    license = licenses.mit;
    maintainers = with maintainers; [ ivankovnatsky ];
    mainProgram = "tweety";
  };
}
