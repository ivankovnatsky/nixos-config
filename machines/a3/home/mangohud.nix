{ ... }:

{
  # MangoHud - Gaming performance overlay
  programs.mangohud = {
    enable = true;

    # Enable globally for all Vulkan/OpenGL applications
    # Press Shift+F12 to toggle overlay on/off
    # Press Shift+F2 to change overlay position
    # Press Shift+F4 to reload config
    enableSessionWide = true;

    # Configuration settings
    settings = {
      # Display settings
      fps = true;
      frame_timing = true;

      # CPU information
      cpu_temp = true;
      cpu_power = true;
      cpu_stats = true;
      cpu_mhz = true;

      # GPU information
      gpu_temp = true;
      gpu_power = true;
      gpu_core_clock = true;
      gpu_mem_clock = true;
      vram = true;

      # Other metrics
      ram = true;

      # Layout
      position = "top-left";
      font_size = 24;
    };
  };
}
