{
  # Configure mouse with slow speed using plasma-manager
  programs = {
    plasma = {
      enable = true;
      # Configure input devices
      input = {
        mice = [
          # Only configure the main Razer Razer Viper entry
          {
            name = "Razer Razer Viper";
            vendorId = "1532"; # Razer vendor ID (hex)
            productId = "0078"; # Razer Viper product ID (hex)

            # Mouse settings
            accelerationProfile = "none";
            acceleration = -0.6;
          }
        ];
      };

      # Configure power management to use power saving mode
      powerdevil = {
        AC.powerProfile = "balanced";
      };

      # Configure taskbar with pinned applications
      panels = [
        {
          widgets = [
            {
              kickoff = {
              };
            }
            {
              iconTasks = {
                launchers = [
                  "applications:org.kde.dolphin.desktop"
                  "applications:org.kde.konsole.desktop"
                  "applications:firefox-devedition.desktop"
                  "applications:steam.desktop"
                  "applications:systemsettings.desktop"
                ];
              };
            }
            {
              systemTray.items = {
                shown = [
                ];
              };
            }
            {
              digitalClock = { };
            }
          ];
        }
      ];

      # Configure KDE Wallet for GPG passphrases
      configFile = {
        kwalletrc = {
          "org.freedesktop.secrets" = {
            apiEnabled = true;
          };
          "Auto Allow" = {
            kdewallet = "GPG,gpg-agent";
          };
          "Wallet" = {
            "Default Wallet" = "kdewallet";
            "Enabled" = true;
            "Launch Manager" = false;
            "Leave Open" = true;
          };
        };
      };
    };
    konsole = {
      enable = true;
    };
  };
}
