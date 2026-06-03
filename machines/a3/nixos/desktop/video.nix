{
  config,
  ...
}:
{
  # Enable OpenGL
  hardware.graphics = {
    enable = true;
  };

  # Load amdgpu in initrd so it fully initializes before SDDM starts.
  # Without this, SDDM races with amdgpu init and Xorg fails with EINVAL on card1.
  hardware.amdgpu.initrd.enable = true;

  # services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver.videoDrivers = [ "amdgpu" ];

  # simpledrm claims the AMD DRM slot before amdgpu can; this prevents it
  boot.kernelParams = [ "initcall_blacklist=simpledrm_platform_driver_init" ];

  # https://nixos.wiki/wiki/Nvidia
  # https://wiki.nixos.org/wiki/NVIDIA
  # Check available Linux driver versions: https://download.nvidia.com/XFree86/Linux-x86_64/
  # FIXME: Fix sleep mode screen comes back with wierd artifacts
  # hardware.nvidia = {
  #   # Modesetting is required.
  #   modesetting.enable = true;

  #   # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
  #   # Enable this if you have graphical corruption issues or application crashes after waking
  #   # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
  #   # of just the bare essentials.
  #   powerManagement.enable = true;

  #   # Fine-grained power management. Turns off GPU when not in use.
  #   # Experimental and only works on modern Nvidia GPUs (Turing or newer).
  #   powerManagement.finegrained = false;

  #   # Use the NVidia open source kernel module (not to be confused with the
  #   # independent third-party "nouveau" open source driver).
  #   # Support is limited to the Turing and later architectures. Full list of
  #   # supported GPUs is at:
  #   # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
  #   # Only available from driver 515.43.04+
  #   open = true;

  #   # Enable the Nvidia settings menu,
  #   # accessible via `nvidia-settings`.
  #   nvidiaSettings = true;

  #   # Optionally, you may need to select the appropriate driver version for your specific GPU.
  #   # Using mkDriver to compile driver for current kernel (6.14.8) instead of nixpkgs-master
  #   # which has kernel 6.16.3 and would cause "inconsistent kernel versions" error
  #   package = config.boot.kernelPackages.nvidiaPackages.bleeding_edge;
  #   # package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
  #   #   version = "580.76.05";
  #   #   sha256_64bit = "sha256-IZvmNrYJMbAhsujB4O/4hzY8cx+KlAyqh7zAVNBdl/0=";
  #   #   sha256_aarch64 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  #   #   openSha256 = "sha256-xEPJ9nskN1kISnSbfBigVaO6Mw03wyHebqQOQmUg/eQ=";
  #   #   settingsSha256 = "sha256-ll7HD7dVPHKUyp5+zvLeNqAb6hCpxfwuSyi+SAXapoQ=";
  #   #   persistencedSha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  #   # };

  #   # Monitor is connected to AMD iGPU (card2-DP-4); NVIDIA is render offload.
  #   # NVIDIA: 01:00.0 -> PCI:1:0:0, AMD: 0d:00.0 -> PCI:13:0:0
  #   # prime = {
  #   #   offload = {
  #   #     enable = true;
  #   #     enableOffloadCmd = true;
  #   #   };
  #   #   nvidiaBusId = "PCI:1:0:0";
  #   #   amdgpuBusId = "PCI:13:0:0";
  #   # };
  # };
}
