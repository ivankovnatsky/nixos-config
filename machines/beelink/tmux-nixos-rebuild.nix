{ pkgs, ... }:

{
  # Create a systemd service that starts a tmux session on boot
  systemd.services.tmux-nixos-config = {
    description = "Start tmux session with nixos-config";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    # Define a specific user to run the tmux session
    serviceConfig = {
      Type = "forking";
      User = "ivan";
      ExecStart = pkgs.writeShellScript "start-tmux-session" ''
        # Check if the session already exists
        ${pkgs.tmux}/bin/tmux has-session -t beelink 2>/dev/null
        if [ $? -eq 0 ]; then
          # Session exists, do nothing
          exit 0
        fi

        # Create a new detached session with a named window
        ${pkgs.tmux}/bin/tmux new-session -d -s beelink -n rebuild -c /home/ivan/Sources/github.com/ivankovnatsky/nixos-config

        # Increase session name length to show full name
        ${pkgs.tmux}/bin/tmux set-option -g status-left-length 30

        # Create a custom script for watchman-based rebuilds
        REBUILD_SCRIPT="${pkgs.writeShellScript "nixos-watchman-rebuild" ''
          cd /home/ivan/Sources/github.com/ivankovnatsky/nixos-config

          echo "Starting watchman-based rebuild for NixOS..."
          echo "Press Ctrl+C to stop watching."

          # Set PATH to include sudo
          export PATH="/run/wrappers/bin:$PATH"

          # Initial build
          echo ""
          echo "Performing initial build..."
          ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --use-remote-sudo --verbose -L --flake .

          # Then watch for changes
          while true; do
            echo ""
            echo "Watching for changes..."
            # Use watchman-make to watch for changes
            ${pkgs.watchman-make}/bin/watchman-make \
                --pattern "**/*" \
                --run "${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --use-remote-sudo --verbose -L --flake ."
            
            echo "watchman-make exited, restarting in 3 seconds..."
            sleep 3
          done
        ''}"

        # Set up the window with our custom watchman rebuild script
        ${pkgs.tmux}/bin/tmux send-keys -t beelink "$REBUILD_SCRIPT" C-m

        # Switch back to the first window
        ${pkgs.tmux}/bin/tmux select-window -t beelink:rebuild

        exit 0
      '';
      # Restart on failure
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  # Create a simple shell script to attach to the tmux session
  environment.systemPackages = with pkgs; [
    # Script to attach to the tmux session
    (writeShellScriptBin "nixos-config-tmux" ''
      # Attach to the nixos-config tmux session or notify if it doesn't exist
      ${tmux}/bin/tmux has-session -t beelink 2>/dev/null
      if [ $? -eq 0 ]; then
        echo "Attaching to beelink tmux session..."
        exec ${tmux}/bin/tmux attach-session -t beelink
      else
        echo "The beelink tmux session is not running."
        echo "It may have been stopped or failed to start."
        echo "Check the status with: systemctl status tmux-nixos-config"
        echo ""
        echo "To start it manually, run:"
        echo "cd /home/ivan/Sources/github.com/ivankovnatsky/nixos-config"
        echo "nixos-rebuild switch --use-remote-sudo --verbose -L --flake ."
        echo ""
        echo "Or restart the tmux service with:"
        echo "systemctl restart tmux-nixos-config"
      fi
    '')
  ];
}
