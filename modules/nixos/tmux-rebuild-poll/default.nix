{
  pkgs,
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.local.services.tmuxRebuildPoll;
in
{
  options = {
    local.services.tmuxRebuildPoll = {
      enable = mkEnableOption "tmux rebuild service with polling";

      username = mkOption {
        type = types.str;
        description = "Username for the tmux rebuild service";
      };

      nixosConfigPath = mkOption {
        type = types.str;
        description = "Path to the nixos-config repository";
      };

      pollInterval = mkOption {
        type = types.int;
        default = 2;
        description = "Polling interval in seconds";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.tmux-nixos-config-poll = {
      description = "Tmux session for NixOS config rebuilds with polling";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "forking";
        User = cfg.username;
        KillMode = "none"; # Don't kill tmux session on service changes
        RemainAfterExit = true; # Mark as active even after ExecStart completes
        ExecStart =
          let
            rebuildWatchScript = pkgs.writeShellScriptBin "nixos-rebuild-watch-poll" ''
              cd ${cfg.nixosConfigPath}

              echo "Starting polling-based rebuild for NixOS..."
              echo "Press Ctrl+C to stop watching."

              REBUILD_CMD="sudo -E NIXPKGS_ALLOW_UNFREE=1 ${config.system.build.nixos-rebuild}/bin/nixos-rebuild switch --impure --verbose -L --flake ."

              echo ""
              echo "Performing initial build..."
              $REBUILD_CMD

              echo ""
              echo "Watching for changes (checking every ${toString cfg.pollInterval}s)..."

              # Calculate initial hash of all .nix files
              get_hash() {
                find . -name "*.nix" -type f ! -path "./.direnv/*" ! -path "./result/*" -exec ${pkgs.coreutils}/bin/md5sum {} \; | ${pkgs.coreutils}/bin/sort | ${pkgs.coreutils}/bin/md5sum | ${pkgs.coreutils}/bin/cut -d' ' -f1
              }

              LAST_HASH=$(get_hash)

              while true; do
                sleep ${toString cfg.pollInterval}
                CURRENT_HASH=$(get_hash)

                if [ "$CURRENT_HASH" != "$LAST_HASH" ]; then
                  echo ""
                  echo "Changes detected in .nix files"
                  echo "Running rebuild..."
                  $REBUILD_CMD
                  LAST_HASH=$(get_hash)
                fi
              done
            '';

            startTmuxScript = pkgs.writeShellScriptBin "nixos-rebuild-poll-tmux" ''
              SESSION_NAME="${config.networking.hostName}"

              ${pkgs.tmux}/bin/tmux has-session -t "$SESSION_NAME" 2>/dev/null
              if [ $? -eq 0 ]; then
                exit 0
              fi

              ${pkgs.tmux}/bin/tmux new-session -d -s "$SESSION_NAME" -n rebuild -c ${cfg.nixosConfigPath}
              ${pkgs.tmux}/bin/tmux set-option -g status-left-length 30
              ${pkgs.tmux}/bin/tmux send-keys -t "$SESSION_NAME" "${rebuildWatchScript}/bin/nixos-rebuild-watch-poll" C-m
              ${pkgs.tmux}/bin/tmux select-window -t "$SESSION_NAME:rebuild"

              exit 0
            '';
          in
          "${startTmuxScript}/bin/nixos-rebuild-poll-tmux";

        Restart = "on-failure";
        RestartSec = 10;
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };

    environment.systemPackages = with pkgs; [
      tmux

      (writeShellScriptBin "nixos-rebuild-poll-attach" ''
        SESSION_NAME="${config.networking.hostName}"

        ${tmux}/bin/tmux has-session -t "$SESSION_NAME" 2>/dev/null
        if [ $? -eq 0 ]; then
          echo "Attaching to $SESSION_NAME tmux session..."
          exec ${tmux}/bin/tmux attach-session -t "$SESSION_NAME"
        else
          echo "The $SESSION_NAME tmux session is not running."
          echo "Check the logs with: journalctl -u tmux-nixos-config-poll"
          echo ""
          echo "Or restart the service with:"
          echo "sudo systemctl restart tmux-nixos-config-poll"
        fi
      '')
    ];
  };
}
