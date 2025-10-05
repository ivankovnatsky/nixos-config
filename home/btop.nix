{ pkgs, ... }:

{
  programs.btop = {
    enable = true;
    # Enable NVIDIA GPU support (adds runtime path for nvidia-ml library)
    package = pkgs.btop.override {
      cudaSupport = true;
    };
    settings = {
      proc_sorting = "cpu lazy";
    };
  };
}
