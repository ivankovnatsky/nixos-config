# https://wiki.nixos.org/wiki/Steam#Gamescope_Compositor_/_%22Boot_to_Steam_Deck%22
# Gamescope session for SDDM with Nvidia GPU support

{ pkgs, username, ... }:
{
  # Enable gamescope and the gamescope session
  programs = {
    gamescope = {
      enable = true;
      capSysNice = true;
    };
    steam.gamescopeSession = {
      enable = true; # Creates a session for display managers

      # Nvidia-specific environment variables for better compatibility
      env = {
        # Ensure Vulkan uses Nvidia
        "__GLX_VENDOR_LIBRARY_NAME" = "nvidia";
        # Force GBM backend for better Nvidia compatibility
        "GBM_BACKEND" = "nvidia-drm";
        # Enable DRM KMS for modesetting
        "__GL_GSYNC_ALLOWED" = "1";
        "__GL_VRR_ALLOWED" = "1";
      };

      # Additional args for the gamescope session
      args = [
        "-e" # Enable Steam integration (important for Nvidia)
        "--expose-wayland"
      ];
    };
  };

  # Note: This configuration provides gamescope as a session option in SDDM.
  # Select "gamescope" from the session menu in SDDM to launch Steam Big Picture
  # in a dedicated gamescope compositor environment.
  #
  # Nvidia GPU considerations:
  # - The -e flag enables Steam integration for better compatibility
  # - GBM_BACKEND=nvidia-drm helps with DRM/KMS support
  # - Vulkan environment variables ensure proper GPU selection
  # - Performance may vary compared to AMD GPUs
  # - If you experience issues after Vulkan/Mesa updates, check nvidia.nix driver version
  #
  # For auto-boot to gamescope, configure SDDM auto-login with gamescope as default session.
}
