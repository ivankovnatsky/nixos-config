{
  lib,
  python3Packages,
  fetchFromGitHub,
}:

# NOTE: Requires nixpkgs MLX >= 0.31 for reliable GPU inference.
# Current nixpkgs has MLX 0.30.5 which intermittently falls back to
# CPU and crashes with "AddMM::eval_cpu only supports float32".
# Tracking: https://github.com/NixOS/nixpkgs/pull/504828
python3Packages.buildPythonApplication rec {
  pname = "mlx-whisper";
  version = "0.4.3";
  src = fetchFromGitHub {
    owner = "ml-explore";
    repo = "mlx-examples";
    rev = "c1af8c46bd4c4704cff1561736a634cee38efc6c";
    hash = "sha256-z5ociO3OoTAwz06tHWFuT3ybivx6SiYEr5Tuh4jKcT0=";
  };

  sourceRoot = "${src.name}/whisper";

  format = "setuptools";

  propagatedBuildInputs = with python3Packages; [
    mlx
    numba
    numpy
    torch
    tqdm
    more-itertools
    tiktoken
    huggingface-hub
    scipy
  ];

  nativeBuildInputs = with python3Packages; [
    setuptools
  ];

  pythonImportsCheck = [ "mlx_whisper" ];

  # No tests in upstream
  doCheck = false;

  meta = with lib; {
    description = "OpenAI Whisper on Apple silicon with MLX and the Hugging Face Hub";
    homepage = "https://github.com/ml-explore/mlx-examples/tree/main/whisper";
    license = licenses.mit;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "mlx_whisper";
  };
}
