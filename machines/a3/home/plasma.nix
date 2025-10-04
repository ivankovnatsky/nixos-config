{ lib, pkgs, ... }:

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
                  "applications:kitty.desktop"
                  "applications:firefox-devedition.desktop"
                  "applications:chromium-browser.desktop"
                  "applications:steam.desktop"
                  "applications:org.kde.plasma-systemmonitor.desktop"
                  "applications:org.kde.spectacle.desktop"
                  "applications:org.kde.kinfocenter.desktop"
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

  # Run plasma-manager scripts after configuration
  # FIXME: This doesn't actually force the scripts to run due to plasma-manager's
  # checksum tracking. Need to manually run ~/.local/share/plasma-manager/run_all.sh
  # after rebuild for taskbar changes to apply
  home.activation.apply-plasma-config = lib.hm.dag.entryAfter [ "configure-plasma" ] ''
    if [[ -v DRY_RUN ]]; then
      echo "Would apply plasma configuration"
    else
      # Run the plasma-manager scripts
      if [[ -x ~/.local/share/plasma-manager/run_all.sh ]]; then
        ~/.local/share/plasma-manager/run_all.sh
      fi
    fi
  '';

  # Manage Bluetooth configuration file
  # home.file.".config/bluedevilglobalrc".text = ''
  #   [Adapters]
  #   C0:BF:BE:B6:AE:4B_powered=true

  #   [Devices]
  #   connectedDevices=

  #   [Global]
  #   bluetoothBlocked=false
  # '';
}
