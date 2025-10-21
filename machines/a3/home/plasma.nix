{ lib, pkgs, ... }:

{
  # Configure mouse with slow speed using plasma-manager
  programs = {
    plasma = {
      enable = true;
      # Configure input devices
      input = {
        keyboard = {
          layouts = [
            {
              layout = "us";
            }
            {
              layout = "ua";
            }
          ];
          # Use Caps Lock to switch layouts
          # Shift+Caps Lock will still work for actual CAPS LOCK functionality
          options = [ "grp:caps_toggle" ];
        };

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

      # Configure panels - macOS-like layout
      panels = [
        # Top panel with global menu bar
        {
          location = "top";
          height = 26;
          widgets = [
            {
              kickoff = {
              };
            }
            "org.kde.plasma.appmenu"
            {
              name = "org.kde.plasma.panelspacer";
            }
            {
              systemTray.items = {
                shown = [
                  "org.kde.plasma.keyboardlayout"
                  "org.kde.plasma.networkmanagement"
                  "org.kde.plasma.volume"
                ];
              };
            }
            {
              digitalClock = {
                time.format = "24h";
              };
            }
          ];
        }
        # Bottom panel - dock with application icons
        {
          location = "bottom";
          height = 48;
          lengthMode = "fit";
          floating = true;
          hiding = "none";
          widgets = [
            {
              iconTasks = {
                launchers = [
                  "applications:org.kde.dolphin.desktop"
                  "applications:kitty.desktop"
                  "applications:firefox-devedition.desktop"
                  "applications:chromium-browser.desktop"
                  "applications:org.kde.plasma-systemmonitor.desktop"
                  "applications:org.kde.spectacle.desktop"
                  "applications:org.kde.kinfocenter.desktop"
                  "applications:org.kde.krdc.desktop"
                  "applications:systemsettings.desktop"
                ];
              };
            }
          ];
        }
      ];

      # Configure keyboard shortcuts
      shortcuts = {
        "KDE Keyboard Layout Switcher" = {
          # Disable KDE's shortcut to let XKB options (grp:caps_toggle) work
          "Switch to Next Keyboard Layout" = [];
        };
      };

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

        krdcrc = {
          MainWindow = {
            StatusBar = "Disabled";
          };
          "PerformanceSettings" = {
            windowedScale = true;
            fullscreenScale = true;
            grabAllKeys = true;
            showLocalCursor = true;
            walletSupport = true;
            quality = 1;
          };
        };
      };
    };
    konsole = {
      enable = true;
    };
  };

  # Run plasma-manager scripts after configuration
  # plasma-manager has built-in checksum tracking and will only reapply when config changes
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
