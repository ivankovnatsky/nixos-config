{ ... }:

{
  # Configure mouse with slow speed using plasma-manager
  programs = {
    plasma = {
      # Configure KDE Wallet for GPG passphrases
      configFile = {
        kwinrc = {
          Wayland.InputMethod = "/run/current-system/sw/share/applications/com.github.maliit.keyboard.desktop";
        };
      };
    };
  };
}
