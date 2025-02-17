{
  lib,
  buildFishPlugin,
  fetchFromGitHub,
  python3,
  fzf,
}:

buildFishPlugin rec {
  pname = "fish-ai";
  version = "v1.0.0";

  src = fetchFromGitHub {
    owner = "Realiserad";
    repo = "fish-ai";
    rev = version;
    hash = "sha256-OnKkANNR51G34edj2HbohduaFARk6ud15N3+ULYs7s4=";
  };

  propagatedBuildInputs = [
    fzf
    (python3.withPackages (
      ps: with ps; [
        openai
        tiktoken
        anthropic
      ]
    ))
  ];

  postInstall = ''
    # Install fish functions and conf.d
    install -Dm644 functions/*.fish $out/share/fish/vendor_functions.d/
    install -Dm644 conf.d/*.fish $out/share/fish/vendor_conf.d/

    # Install Python module
    mkdir -p $out/share/fish/vendor_functions.d/fish_ai
    cp -r src/fish_ai/* $out/share/fish/vendor_functions.d/fish_ai/
    chmod +x $out/share/fish/vendor_functions.d/fish_ai/__init__.py

    # Create a symlink in Python path for easier importing
    mkdir -p $out/lib/${python3.sitePackages}
    ln -s $out/share/fish/vendor_functions.d/fish_ai $out/lib/${python3.sitePackages}/
  '';

  meta = with lib; {
    description = "AI assistant integration for the fish shell";
    homepage = "https://github.com/Realiserad/fish-ai";
    license = licenses.mit;
    maintainers = [ ];
  };
}
