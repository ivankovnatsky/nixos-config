{
  lib,
  stdenv,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
}:
buildGoModule rec {
  pname = "obsidian-cli";
  version = "0.2.3";

  src = fetchFromGitHub {
    owner = "Yakitrak";
    repo = "obsidian-cli";
    rev = "v${version}";
    hash = "sha256-zVl7dBOl9UAIclAV7dx5WQes9w9PY7iS9pkby/8oaHM=";
  };

  # The upstream repo vendors Go dependencies (has a vendor/ dir).
  vendorHash = null;

  nativeBuildInputs = [ installShellFiles ];

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd obsidian-cli \
      --bash <($out/bin/obsidian-cli completion bash) \
      --fish <($out/bin/obsidian-cli completion fish) \
      --zsh <($out/bin/obsidian-cli completion zsh)
  '';

  meta = with lib; {
    description = "Interact with Obsidian in the terminal";
    homepage = "https://github.com/Yakitrak/obsidian-cli";
    license = licenses.mit;
    maintainers = with maintainers; [ ivankovnatsky ];
    mainProgram = "obsidian-cli";
  };
}
