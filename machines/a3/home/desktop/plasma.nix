{ lib, pkgs, config, ... }:

{
  # Configure mouse with slow speed using plasma-manager
  programs = {
    plasma = {
      enable = true;

      # Set solid dark gray wallpaper
      workspace = {
        wallpaperPlainColor = "64,64,64";
        cursor = {
          theme = "breeze_cursors";
          size = 30;
        };
      };

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
          switchingPolicy = "window";
        };

        mice = [
          {
            name = "Glorious Model D";
            vendorId = "258a";
            productId = "0033";

            accelerationProfile = "none";
            acceleration = -0.7;
          }
        ];

        touchpads = [
          {
            name = "Apple Inc. Magic Trackpad";
            vendorId = "05ac";
            productId = "0324";

            scrollSpeed = 0.1;
            tapToClick = false;
          }
        ];
      };

      # Disable sleep/suspend, only blank the screen
      powerdevil = {
        AC = {
          powerProfile = "balanced";
          autoSuspend.action = "nothing";
          turnOffDisplay.idleTimeout = 600; # 10 minutes
          dimDisplay = {
            enable = true;
            idleTimeout = 540; # 9 minutes, dim before 10min turn-off
          };
        };
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
              systemMonitor = {
                showTitle = false;
                showLegend = false;
                displayStyle = "org.kde.ksysguard.textonly";
                sensors = [
                  {
                    name = "cpu/all/usage";
                    color = "255,255,255";
                    label = "💻";
                  }
                  {
                    name = "memory/physical/usedPercent";
                    color = "255,255,255";
                    label = "🧠";
                  }
                  {
                    name = "disk/all/read";
                    color = "255,255,255";
                    label = "💾";
                  }
                ];
              };
            }
            {
              name = "org.kde.plasma.weather";
              config = {
                Appearance.showTemperatureInCompactMode = true;
                Units = {
                  temperatureUnit = 6001; # Celsius
                  pressureUnit = 5008; # Hectopascal
                  speedUnit = 9000; # MeterPerSecond
                };
                WeatherStation = {
                  placeDisplayName = "@WEATHER_LABEL@";
                  placeInfo = "@WEATHER_LABEL@|@WEATHER_ID@";
                  provider = "bbcukmet";
                };
              };
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
                  "applications:com.mitchellh.ghostty.desktop"
                  "applications:kitty.desktop"
                  "applications:firefox-devedition.desktop"
                  "applications:chromium-browser.desktop"
                  "applications:discord.desktop"
                  "applications:org.kde.plasma-systemmonitor.desktop"
                  "applications:org.kde.spectacle.desktop"
                  "applications:org.kde.kinfocenter.desktop"
                  "applications:org.kde.krdc.desktop"
                  "applications:steam.desktop"
                  "applications:velocidrone.desktop"
                  "applications:obsidian.desktop"
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
          "Switch to Next Keyboard Layout" = [ ];
        };
      };

      # Configure KDE Wallet for GPG passphrases
      configFile = {
        # Reset window rules to empty (clears any previously applied rules)
        kwinrulesrc.General = {
          count = 0;
          rules = "";
        };
        kwinrc."org.kde.kdecoration2" = {
          BorderSize = "None";
          BorderSizeAuto = false;
        };
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

  # Clean up kwinrulesrc before plasma-manager writes to it
  # This ensures stale window rules are removed
  home.activation.clean-kwin-rules = lib.hm.dag.entryBefore [ "configure-plasma" ] ''
    if [[ ! -v DRY_RUN ]]; then
      rm -f ~/.config/kwinrulesrc
    fi
  '';

  # Run plasma-manager scripts after configuration
  # plasma-manager has built-in checksum tracking and will only reapply when config changes
  home.activation.apply-plasma-config = lib.hm.dag.entryAfter [ "configure-plasma" "sops-nix" ] ''
    if [[ -v DRY_RUN ]]; then
      echo "Would apply plasma configuration"
    else
      # Run the plasma-manager scripts
      if [[ -x ~/.local/share/plasma-manager/run_all.sh ]]; then
        ~/.local/share/plasma-manager/run_all.sh
      fi
      # Rewrite the weather widget keys from sops-encrypted values.
      # Anchored on the [WeatherStation] section header so substitution
      # is always applied (placeholders or stale values) — secret rotation
      # propagates every activation, not just when plasma-manager rewrites.
      # Values are passed via env so they never appear in /proc/PID/cmdline.
      # The widget only picks up the new values after plasmashell re-reads
      # the file — run `~/.local/share/plasma-manager/run_all.sh` or restart
      # plasma-plasmashell.service manually when you want it applied live.
      appletsrc="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
      label_file=${config.sops.secrets.weather-label.path}
      id_file=${config.sops.secrets.weather-id.path}
      if [[ -f "$appletsrc" && -r "$label_file" && -r "$id_file" ]]; then
        WEATHER_LABEL=$(cat "$label_file")
        WEATHER_ID=$(cat "$id_file")
        if [[ -n "$WEATHER_LABEL" && -n "$WEATHER_ID" ]]; then
          tmp=$(mktemp -p "$(dirname "$appletsrc")")
          WEATHER_LABEL="$WEATHER_LABEL" WEATHER_ID="$WEATHER_ID" \
            ${pkgs.gawk}/bin/awk '
              BEGIN { lbl=ENVIRON["WEATHER_LABEL"]; id=ENVIRON["WEATHER_ID"]; in_ws=0 }
              /^\[/ { in_ws = ($0 ~ /\]\[WeatherStation\]$/) }
              in_ws && /^placeDisplayName=/ { print "placeDisplayName=" lbl; next }
              in_ws && /^placeInfo=/        { print "placeInfo=" lbl "|" id; next }
              { print }
            ' "$appletsrc" > "$tmp"
          if ! cmp -s "$tmp" "$appletsrc"; then
            mv "$tmp" "$appletsrc"
          else
            rm -f "$tmp"
          fi
        fi
      fi
      # Reload KWin to apply window rules and other changes
      if command -v qdbus >/dev/null 2>&1 && qdbus org.kde.KWin >/dev/null 2>&1; then
        qdbus org.kde.KWin /KWin reconfigure || true
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
