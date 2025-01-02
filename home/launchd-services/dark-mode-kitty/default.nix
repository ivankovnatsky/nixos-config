{ config, lib, pkgs, ... }:
let
  # Get the base kitty config from the kitty module
  baseKittyConfig = import ../../kitty { inherit config lib pkgs; };

  # Script to initialize kitty config and handle theme switching
  scriptWithKittyPath = ''
        #!${pkgs.bash}/bin/bash

        log_message() {
          /usr/bin/syslog -s -l notice "kitty-theme: $1"
        }

        # Always ensure directory exists and write the latest config
        ${pkgs.coreutils}/bin/mkdir -p "$HOME/.config/kitty"
        cat > "$HOME/.config/kitty/kitty.conf" << EOL
    ${baseKittyConfig.home.file.".config/kitty/kitty.conf".text}
    EOL

        # Define your themes
        DARK_THEME="Catppuccin-Mocha"
        LIGHT_THEME="Catppuccin-Latte"

        KITTY="/Applications/kitty.app/Contents/MacOS/kitty"

        KITTY_PID=$(/bin/ps aux | /usr/bin/grep "[k]itty.app" | /usr/bin/awk 'NR==1{print $2}')

        if [ -z "$KITTY_PID" ]; then
            log_message "Error: Kitty terminal not found"
            exit 1
        fi

        if [ "$DARKMODE" = "1" ]; then
            log_message "Switching to dark theme: $DARK_THEME"
            TERM=xterm-kitty "$KITTY" +kitten themes --reload-in=all "$DARK_THEME" </dev/null
        else
            log_message "Switching to light theme: $LIGHT_THEME"
            TERM=xterm-kitty "$KITTY" +kitten themes --reload-in=all "$LIGHT_THEME" </dev/null
        fi

        log_message "Reloading kitty configuration..."
        kill -SIGUSR1 "$KITTY_PID"
        log_message "Theme switch completed successfully"
  '';

  toggleScript = pkgs.writeScriptBin "toggle-kitty-theme" scriptWithKittyPath;
in
{
  launchd.agents = {
    "dark-mode-notify-kitty" = {
      enable = true;
      config = {
        Label = "dark-mode-notify-kitty";
        ProgramArguments = [
          "${pkgs.dark-mode-notify}/bin/dark-mode-notify"
          "${toggleScript}/bin/toggle-kitty-theme"
        ];
        KeepAlive = true;
        RunAtLoad = true;

        EnvironmentVariables = {
          HOME = config.home.homeDirectory;
          PATH = "${pkgs.coreutils}/bin:$PATH";
        };
      };
    };
  };
}
