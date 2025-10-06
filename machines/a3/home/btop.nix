{ pkgs, ... }:

{
  programs.btop = {
    # Enable NVIDIA GPU support (adds runtime path for nvidia-ml library)
    package = pkgs.btop.override {
      cudaSupport = true;
    };
  };
}
