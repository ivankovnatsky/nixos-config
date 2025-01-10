# Watchman service for automatic darwin-rebuild
#
# IMPORTANT NOTES AND CAVEATS:
#
# 1. Permission Issues:
#    - Requires Full Disk Access permission in System Settings
#    - May need manual approval in Privacy & Security settings
#    - Uses ProcessType = "Interactive" and AbandonProcessGroup = true to help with permissions
#
# 2. Sudo Handling:
#    - Uses SUDO_ASKPASS to handle privilege escalation non-interactively
#    - Doesn't run entire command as sudo (security best practice)
#    - Let's darwin-rebuild handle its own privilege escalation
#
# 3. Output Handling:
#    - All output is redirected to log files (not visible in terminal)
#    - Check logs at:
#      ~/Library/Logs/rebuild-watchman.log
#      ~/Library/Logs/rebuild-watchman.error.log
#
# 4. Known Limitations:
#    - May still encounter permission issues with certain system operations
#    - Requires careful security consideration (running with elevated privileges)
#    - May need manual intervention for some security-sensitive operations
#    - osascript notifications don't work properly in launchd context
#      (notifications about success/failure may not appear)
#
# Alternative Approaches Considered:
# - Running as root (rejected for security reasons)
# - Using sudoers configuration (more complex, requires system changes)
# - Creating a privileged helper tool (most proper but complex solution)
#
# To monitor service:
# tail -f ~/Library/Logs/rebuild-watchman.log
# tail -f ~/Library/Logs/rebuild-watchman.error.log

{ config, lib, pkgs, ... }:
let
  # Create an askpass script that will return the sudo password
  askpassScript = pkgs.writeScriptBin "askpass" ''
    #!${pkgs.bash}/bin/bash
    echo ""  # Return empty string to skip password prompt
  '';

  # Script to run make rebuild-watchman
  watchmanScript = pkgs.writeScriptBin "rebuild-watchman" ''
    #!${pkgs.bash}/bin/bash

    log_message() {
      /usr/bin/syslog -s -l notice "rebuild-watchman: $1"
    }

    # Set up sudo to use our askpass script
    export SUDO_ASKPASS="${askpassScript}/bin/askpass"
    # Tell sudo to use askpass when needed
    export SUDO_PROMPT="rebuild-watchman"

    WORK_DIR="${config.home.homeDirectory}/Sources/github.com/ivankovnatsky/nixos-config"
    
    log_message "Starting in directory: $WORK_DIR"
    cd "$WORK_DIR" || {
      log_message "Failed to change to directory: $WORK_DIR"
      exit 1
    }

    ${pkgs.watchman-make}/bin/watchman-make \
      --pattern '**/*' \
      --target default \
      --make "${pkgs.gnumake}/bin/make" || {
        log_message "watchman-make failed with exit code: $?"
        sleep 1
        exit 1
      }

    log_message "watchman-make exited, restarting..."
    sleep 1
  '';
in
{
  launchd.agents = {
    "rebuild-watchman" = {
      enable = true;
      config = {
        Label = "rebuild-watchman";
        ProgramArguments = [
          "${watchmanScript}/bin/rebuild-watchman"
        ];
        KeepAlive = true;
        RunAtLoad = true;
        WorkingDirectory = "${config.home.homeDirectory}/Sources/github.com/ivankovnatsky/nixos-config";

        ProcessType = "Interactive";
        AbandonProcessGroup = true;

        EnvironmentVariables = {
          HOME = config.home.homeDirectory;
          SUDO_ASKPASS = "${askpassScript}/bin/askpass";
          # Tell sudo to use askpass when needed
          SUDO_PROMPT = "rebuild-watchman";
          PATH = lib.concatStringsSep ":" [
            "/bin"
            "/usr/bin"
            "/usr/sbin"
            "/usr/local/bin"
            "/run/current-system/sw/bin"
            (lib.makeBinPath [
              pkgs.gnumake
              pkgs.watchman-make
            ])
          ];
        };

        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/rebuild-watchman.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/rebuild-watchman.error.log";
      };
    };
  };
} 
