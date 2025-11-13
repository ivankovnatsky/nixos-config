{ lib
, buildGoModule
, fetchFromGitHub
, nodejs
,
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
    export HOME=$TMPDIR
    export MANIFEST_VERSION=${version}

    cd extension
    npm ci
    npm run build
    npm run zip:firefox
    cd ..
  '';

  postInstall = ''
    # Install Firefox extension
    mkdir -p $out/share/extensions
    if [ -f extension/dist/tweety-${version}-firefox.zip ]; then
      cp extension/dist/tweety-${version}-firefox.zip $out/share/extensions/firefox.zip
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
