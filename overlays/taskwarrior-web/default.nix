{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  nodejs,
  pkg-config,
  openssl,
  sqlite,
  apple-sdk ? null,
  libiconv ? null,
  cacert,
}:

let
  version = "2026-02-21-unstable";

  src = fetchFromGitHub {
    owner = "tmahmood";
    repo = "taskwarrior-web";
    rev = "352f588ab611090ce97b0cbd4f61d8d4180fd449";
    hash = "sha256-9qzGAW4W7dua2Dmx3znQb3vbnD6EUqldAQR3RxSkqx4=";
  };

  npmDeps = stdenv.mkDerivation {
    name = "taskwarrior-web-npm-deps-${version}";
    inherit src;
    nativeBuildInputs = [
      nodejs
      cacert
    ];
    buildPhase = ''
      cd frontend
      export HOME=$TMPDIR
      npm install --ignore-scripts
    '';
    installPhase = ''
      cp -r node_modules $out
    '';
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = "sha256-OuCWuJEr2s6UHjwcSFFJzExvM6fQq9u0/Lp/jtpvewg=";
    impureEnvVars = lib.fetchers.proxyImpureEnvVars;
  };
in
rustPlatform.buildRustPackage {
  pname = "taskwarrior-web";
  inherit version src;

  cargoHash = "sha256-xdLlVrDMThxPAbZ7hey5j3340CnXZwYA5VSrdz16HQI=";

  nativeBuildInputs = [
    pkg-config
    nodejs
  ];

  buildInputs = [
    openssl
    sqlite
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    apple-sdk
    libiconv
  ];

  postPatch = ''
    cp -r ${npmDeps} frontend/node_modules
    chmod -R u+w frontend/node_modules
    mkdir -p dist
    sed -i '/^#!\[feature(exit_status_error)\]/d' src/lib.rs
    cat > build.rs << 'BUILDRS'
    use std::process::Command;
    fn main() {
        println!("cargo:rerun-if-changed=frontend/");
        if !Command::new("frontend/node_modules/.bin/tailwindcss")
            .args(["-i", "frontend/css/style.css", "-o", "dist/style.css"])
            .status()
            .unwrap()
            .success()
        {
            panic!("Failed to process css")
        }
        if !Command::new("frontend/node_modules/.bin/rollup")
            .args(["-c", "frontend/rollup.config.js"])
            .status()
            .unwrap()
            .success()
        {
            panic!("Failed to process js")
        }
        if !Command::new("cp")
            .args(["-r", "frontend/templates", "dist"])
            .status()
            .unwrap()
            .success()
        {
            panic!("Failed to copy template files")
        }
    }
    BUILDRS
  '';

  postInstall = ''
    mkdir -p $out/share/taskwarrior-web
    cp -r dist $out/share/taskwarrior-web/

    mv $out/bin/taskwarrior-web $out/bin/.taskwarrior-web-unwrapped
    cat > $out/bin/taskwarrior-web << EOF
    #!/bin/sh
    cd $out/share/taskwarrior-web
    exec $out/bin/.taskwarrior-web-unwrapped "\$@"
    EOF
    chmod +x $out/bin/taskwarrior-web
  '';

  doCheck = false;

  meta = {
    description = "Minimalistic web interface for Taskwarrior";
    homepage = "https://github.com/tmahmood/taskwarrior-web";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ivankovnatsky ];
    mainProgram = "taskwarrior-web";
    platforms = lib.platforms.unix;
  };
}
