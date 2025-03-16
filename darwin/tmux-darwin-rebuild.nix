{ pkgs, config, username, ... }:

{
  # Create a launchd service that starts a tmux session on boot
  launchd.user.agents.tmux-darwin-config = {
    serviceConfig = {
      Label = "com.ivankovnatsky.tmux-darwin-config";
      ProgramArguments = let
        # Create the rebuild watch script
        rebuildWatchScript = pkgs.writeShellScriptBin "darwin-rebuild-watch" ''
          #!/bin/sh
          cd ${config.users.users.${username}.home}/Sources/github.com/ivankovnatsky/nixos-config

          echo "Starting watchman-based rebuild for Darwin..."
          echo "Press Ctrl+C to stop watching."

          # Define the rebuild command as a variable for consistency
          REBUILD_CMD="env NIXPKGS_ALLOW_UNFREE=1 darwin-rebuild switch --impure --verbose -L --flake ."

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
        startTmuxScript = pkgs.writeShellScriptBin "darwin-rebuild-watchman-tmux" ''
          # This is the main script that will show up in Security settings
          # Use the hostname as session name
          SESSION_NAME="${config.networking.hostName}"

          # Check if the session already exists
          ${pkgs.tmux}/bin/tmux has-session -t "$SESSION_NAME" 2>/dev/null
          if [ $? -eq 0 ]; then
            # Session exists, do nothing
            exit 0
          fi

          # Create a new detached session with a named window
          ${pkgs.tmux}/bin/tmux new-session -d -s "$SESSION_NAME" -n rebuild -c ${config.users.users.${username}.home}/Sources/github.com/ivankovnatsky/nixos-config

          # Increase session name length to show full name
          ${pkgs.tmux}/bin/tmux set-option -g status-left-length 30

          # Set up the window with our rebuild script - use the script from the Nix store
          ${pkgs.tmux}/bin/tmux send-keys -t "$SESSION_NAME" "${rebuildWatchScript}/bin/darwin-rebuild-watch" C-m

          # Switch back to the first window
          ${pkgs.tmux}/bin/tmux select-window -t "$SESSION_NAME:rebuild"

          exit 0
        '';
      in [
        "${startTmuxScript}/bin/darwin-rebuild-watchman-tmux"
      ];
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "/tmp/tmux-darwin-config.log";
      StandardErrorPath = "/tmp/tmux-darwin-config.error.log";
      # Restart on failure
      ThrottleInterval = 10;
    };
  };

  # Install required packages and helper scripts
  environment.systemPackages = with pkgs; [
    # Script to attach to the tmux session
    (writeShellScriptBin "darwin-rebuild-tmux-attach" ''
      # Use the hostname as session name
      SESSION_NAME="${config.networking.hostName}"
      
      # Define the rebuild command for consistency
      REBUILD_CMD="env NIXPKGS_ALLOW_UNFREE=1 darwin-rebuild switch --impure --verbose -L --flake ."
      
      # Attach to the tmux session or notify if it doesn't exist
      ${tmux}/bin/tmux has-session -t "$SESSION_NAME" 2>/dev/null
      if [ $? -eq 0 ]; then
        echo "Attaching to $SESSION_NAME tmux session..."
        exec ${tmux}/bin/tmux attach-session -t "$SESSION_NAME"
      else
        echo "The $SESSION_NAME tmux session is not running."
        echo "It may have been stopped or failed to start."
        echo "Check the logs with: cat /tmp/tmux-darwin-config.log"
        echo ""
        echo "To start it manually, run:"
        echo "cd ${config.users.users.${username}.home}/Sources/github.com/ivankovnatsky/nixos-config"
        echo "$REBUILD_CMD"
        echo ""
        echo "Or restart the tmux agent with:"
        echo "launchctl unload ~/Library/LaunchAgents/com.ivankovnatsky.tmux-darwin-config.plist"
        echo "launchctl load ~/Library/LaunchAgents/com.ivankovnatsky.tmux-darwin-config.plist"
      fi
    '')
  ];
}
