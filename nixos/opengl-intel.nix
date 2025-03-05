{ pkgs, ... }:
{
  hardware.opengl = {
    extraPackages = with pkgs; [
      intel-media-driver
      (vaapiIntel.override { enableHybridCodec = true; })
      vaapiVdpau
      libvdpau-va-gl
    ];
  };
}
