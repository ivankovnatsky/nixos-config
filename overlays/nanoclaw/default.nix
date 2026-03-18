{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
  makeWrapper,
  python3,
}:
buildNpmPackage rec {
  pname = "nanoclaw";
  version = "1.2.17";

  src = fetchFromGitHub {
    owner = "qwibitai";
    repo = "nanoclaw";
    rev = "c71c7b7e830d477e239bb566b3a7aabd49a825f2";
    hash = "sha256-g5BeuSxjMDXbkV6Kaks9TwC/xoqGIKWgCgs1VSvSbH0=";
  };

  npmDepsHash = "sha256-XwIO4M0pNSRmNqMyOljtb7Z+n1MHdEgi8H5H6dCjZOs=";

  nodejs = nodejs_22;

  nativeBuildInputs = [
    makeWrapper
    python3
  ];

  postPatch = ''
    # Switch container runtime from Docker to Apple Container
    substituteInPlace src/container-runtime.ts \
      --replace-fail "export const CONTAINER_RUNTIME_BIN = 'docker';" \
                     "export const CONTAINER_RUNTIME_BIN = 'container';" \
      --replace-fail "export const CONTAINER_HOST_GATEWAY = 'host.docker.internal';" \
                     "export const CONTAINER_HOST_GATEWAY = '192.168.64.1';" \
      --replace-fail "execSync(\`\''${CONTAINER_RUNTIME_BIN} info\`," \
                     "execSync(\`\''${CONTAINER_RUNTIME_BIN} system status\`," \
      --replace-fail "\`\''${CONTAINER_RUNTIME_BIN} ps --filter name=nanoclaw- --format '{{.Names}}'\`" \
                     "\`\''${CONTAINER_RUNTIME_BIN} ls --format json\`"

    # Support NANOCLAW_HOME env var for data directories instead of cwd()
    substituteInPlace src/config.ts \
      --replace-fail "const PROJECT_ROOT = process.cwd();" \
                     "const PROJECT_ROOT = process.env.NANOCLAW_HOME || process.cwd();"

    # Fix orphan cleanup to parse Apple Container JSON output
    substituteInPlace src/container-runtime.ts \
      --replace-fail "const orphans = output.trim().split('\\n').filter(Boolean);" \
                     "const containers = output.trim() ? JSON.parse(output) : []; const orphans = containers.filter((c: any) => c.name?.startsWith('nanoclaw-')).map((c: any) => c.name);"
  '';

  buildPhase = ''
    runHook preBuild
    npm run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    libdir=$out/lib/nanoclaw
    mkdir -p $libdir $out/bin

    cp -r package.json dist node_modules $libdir/
    cp -r assets container groups setup scripts config-examples $libdir/ 2>/dev/null || true

    makeWrapper ${nodejs_22}/bin/node $out/bin/nanoclaw \
      --add-flags "$libdir/dist/index.js" \
      --set NODE_PATH "$libdir/node_modules"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Personal Claude assistant. Lightweight, secure, customizable";
    homepage = "https://github.com/qwibitai/nanoclaw";
    license = licenses.mit;
    mainProgram = "nanoclaw";
    platforms = with platforms; linux ++ darwin;
  };
}
