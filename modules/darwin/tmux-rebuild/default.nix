{
  pkgs,
  config,
  lib,
  username,
  ...
}:

with lib;

let
  cfg = config.local.services.tmuxRebuild;
in
{

  # Should grant access to most probably bash that needs to have Full Disk Permissions.
  options = {
    local.services.tmuxRebuild = {
      nixosConfigPath = mkOption {
        type = types.str;
        default = "${config.users.users.${username}.home}/Sources/github.com/ivankovnatsky/nixos-config";
        description = "Path to the nixos-config repository";
      };
    };
  };

  config = {
    # Create a launchd service that starts a tmux session on boot
    launchd.user.agents.tmux-darwin-config = {
      serviceConfig = {
        Label = "com.ivankovnatsky.tmux-darwin-config";
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/tmp/agents/log/launchd/tmux-darwin-config.log";
        StandardErrorPath = "/tmp/agents/log/launchd/tmux-darwin-config.error.log";
        ThrottleInterval = 3;
      };

      # Using command instead of ProgramArguments to automatically utilize wait4path
      command =
        let
          # Create the rebuild watch script
          rebuildWatchScript = pkgs.writeShellScriptBin "darwin-rebuild-watch" ''
            # Wait for the Samsung2TB volume to be mounted using the built-in wait4path utility
            echo "Waiting for ${cfg.nixosConfigPath} to be available..."
            /bin/wait4path "${cfg.nixosConfigPath}"

            # Now we can safely cd into it
            cd ${cfg.nixosConfigPath}
            echo "${cfg.nixosConfigPath} is now available!"

            echo "Starting watchman-based rebuild for Darwin..."
            echo "Press Ctrl+C to stop watching."

            ${pkgs.watchman-rebuild}/bin/watchman-rebuild "${cfg.nixosConfigPath}"
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
            ${pkgs.tmux}/bin/tmux new-session -d -s "$SESSION_NAME" -n rebuild -c ${cfg.nixosConfigPath}

            # Increase session name length to show full name
            ${pkgs.tmux}/bin/tmux set-option -g status-left-length 40

            # Set up the window with our rebuild script - use the script from the Nix store
            ${pkgs.tmux}/bin/tmux send-keys -t "$SESSION_NAME" "${rebuildWatchScript}/bin/darwin-rebuild-watch" C-m

            # Switch back to the first window
            ${pkgs.tmux}/bin/tmux select-window -t "$SESSION_NAME:rebuild"

            exit 0
          '';
        in
        "${startTmuxScript}/bin/darwin-rebuild-watchman-tmux";
    };

    # Install required packages and helper scripts
    environment.systemPackages = with pkgs; [
      # Script to attach to the tmux session
      (writeShellScriptBin "darwin-rebuild-tmux-attach" ''
        # Use the hostname as session name
        SESSION_NAME="${config.networking.hostName}"

        # Attach to the tmux session or notify if it doesn't exist
        ${tmux}/bin/tmux has-session -t "$SESSION_NAME" 2>/dev/null
        if [ $? -eq 0 ]; then
          echo "Attaching to $SESSION_NAME tmux session..."
          exec ${tmux}/bin/tmux attach-session -t "$SESSION_NAME"
        else
          echo "The $SESSION_NAME tmux session is not running."
          echo "It may have been stopped or failed to start."
          echo "Check the logs with: cat /tmp/agents/log/launchd/tmux-darwin-config.log"
          echo ""
          echo "To start it manually, run:"
          echo "cd ${cfg.nixosConfigPath} && ${pkgs.watchman-rebuild}/bin/watchman-rebuild ."
          echo ""
          echo "Or restart the tmux agent with:"
          echo "launchctl unload ~/Library/LaunchAgents/com.ivankovnatsky.tmux-darwin-config.plist"
          echo "launchctl load ~/Library/LaunchAgents/com.ivankovnatsky.tmux-darwin-config.plist"
        fi
      '')
    ];
  };
}
