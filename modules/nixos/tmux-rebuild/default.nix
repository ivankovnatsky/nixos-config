{
  pkgs,
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.local.services.tmuxRebuild;
in
{
  options = {
    local.services.tmuxRebuild = {
      enable = mkEnableOption "tmux rebuild service";

      username = mkOption {
        type = types.str;
        description = "Username for the tmux rebuild service";
      };

      nixosConfigPath = mkOption {
        type = types.str;
        description = "Path to the nixos-config repository";
      };
    };
  };

  config = mkIf cfg.enable {
    # Create a systemd service that starts a tmux session on boot
    systemd.services.tmux-nixos-config = {
      description = "Tmux session for NixOS config rebuilds";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "forking";
        User = cfg.username;
        ExecStart =
          let
            # Create the rebuild watch script
            rebuildWatchScript = pkgs.writeShellScriptBin "nixos-rebuild-watch" ''
              #!/bin/sh
              cd ${cfg.nixosConfigPath}

              echo "Starting watchman-based rebuild for NixOS..."
              echo "Press Ctrl+C to stop watching."

              # Define the rebuild command as a variable for consistency
              REBUILD_CMD="env NIXPKGS_ALLOW_UNFREE=1 nixos-rebuild switch --use-remote-sudo --impure --verbose -L --flake ."

              # Initial build
              echo ""
              echo "Performing initial build..."
              $REBUILD_CMD

              # Then watch for changes
              while true; do
                echo ""
                echo "Watching for changes..."
                # Use watchman-make to watch for changes
                ${pkgs.watchman-make}/bin/watchman-make \
                    --pattern "**/*" \
                    --run "$REBUILD_CMD"

                echo "watchman-make exited, restarting in 3 seconds..."
                sleep 3
              done
            '';

            # Create the tmux starter script
            startTmuxScript = pkgs.writeShellScriptBin "nixos-rebuild-watchman-tmux" ''
              # Use the hostname as session name
              SESSION_NAME="${config.networking.hostName}"

              # Check if the session already exists
              ${pkgs.tmux}/bin/tmux has-session -t "$SESSION_NAME" 2>/dev/null
              if [ $? -eq 0 ]; then
                # Session exists, do nothing
                exit 0
              fi

              # Create a new detached session with a named window
              ${pkgs.tmux}/bin/tmux new-session -d -s "$SESSION_NAME" -n rebuild -c ${cfg.nixosConfigPath}

              # Increase session name length to show full name
              ${pkgs.tmux}/bin/tmux set-option -g status-left-length 30

              # Set up the window with our rebuild script - use the script from the Nix store
              ${pkgs.tmux}/bin/tmux send-keys -t "$SESSION_NAME" "${rebuildWatchScript}/bin/nixos-rebuild-watch" C-m

              # Switch back to the first window
              ${pkgs.tmux}/bin/tmux select-window -t "$SESSION_NAME:rebuild"

              exit 0
            '';
          in
          "${startTmuxScript}/bin/nixos-rebuild-watchman-tmux";

        Restart = "on-failure";
        RestartSec = 10;
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };

    # Install required packages and helper scripts
    environment.systemPackages = with pkgs; [
      # Dependencies
      tmux
      watchman-make

      # Script to attach to the tmux session
      (writeShellScriptBin "nixos-rebuild-tmux-attach" ''
        # Use the hostname as session name
        SESSION_NAME="${config.networking.hostName}"

        # Define the rebuild command for consistency
        REBUILD_CMD="env NIXPKGS_ALLOW_UNFREE=1 nixos-rebuild switch --use-remote-sudo --impure --verbose -L --flake ."

        # Attach to the tmux session or notify if it doesn't exist
        ${tmux}/bin/tmux has-session -t "$SESSION_NAME" 2>/dev/null
        if [ $? -eq 0 ]; then
          echo "Attaching to $SESSION_NAME tmux session..."
          exec ${tmux}/bin/tmux attach-session -t "$SESSION_NAME"
        else
          echo "The $SESSION_NAME tmux session is not running."
          echo "It may have been stopped or failed to start."
          echo "Check the logs with: journalctl -u tmux-nixos-config"
          echo ""
          echo "To start it manually, run:"
          echo "cd ${cfg.nixosConfigPath}"
          echo "$REBUILD_CMD"
          echo ""
          echo "Or restart the tmux service with:"
          echo "sudo systemctl restart tmux-nixos-config"
        fi
      '')
    ];
  };
}
