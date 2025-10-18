{
  pkgs,
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.local.services.tmuxRebuild;
  isDarwin = pkgs.stdenv.isDarwin;
  darwinRebuildPath = "/run/current-system/sw/bin/darwin-rebuild";
in
{
  options = {
    local.services.tmuxRebuild = {
      enable = mkEnableOption "tmux rebuild service with polling";

      username = mkOption {
        type = types.str;
        default = "";
        description = "Username for the tmux rebuild service (required for NixOS)";
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

      watchPattern = mkOption {
        type = types.str;
        default = "*.nix";
        description = "File pattern to watch for changes (e.g., '*.nix', '**/*', '*.{nix,md}')";
      };

      useSudo = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to use sudo for darwin-rebuild (Darwin only)";
      };
    };
  };

  config = mkIf cfg.enable (
    let
      rebuildWatchScript =
        if isDarwin then
          pkgs.writeShellScriptBin "rebuild-watch" ''
            echo "Waiting for ${cfg.nixosConfigPath} to be available..."
            /bin/wait4path "${cfg.nixosConfigPath}"

            cd ${cfg.nixosConfigPath}
            echo "${cfg.nixosConfigPath} is now available!"

            echo "Starting polling-based rebuild for Darwin..."
            echo "Press Ctrl+C to stop watching."

            ${
              if cfg.useSudo then
                ''
                  REBUILD_CMD="env NIXPKGS_ALLOW_UNFREE=1 sudo -E ${darwinRebuildPath} switch --impure --verbose -L --flake ."
                ''
              else
                ''
                  REBUILD_CMD="env NIXPKGS_ALLOW_UNFREE=1 ${darwinRebuildPath} switch --impure --verbose -L --flake ."
                ''
            }

            echo ""
            echo "Performing initial build..."
            $REBUILD_CMD

            echo ""
            echo "Watching for changes (checking every ${toString cfg.pollInterval}s)..."
            echo "Watch pattern: ${cfg.watchPattern}"

            get_hash() {
              find . -name "${cfg.watchPattern}" -type f ! -path "./.direnv/*" ! -path "./result/*" -exec ${pkgs.coreutils}/bin/md5sum {} \; | ${pkgs.coreutils}/bin/sort | ${pkgs.coreutils}/bin/md5sum | ${pkgs.coreutils}/bin/cut -d' ' -f1
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
          ''
        else
          pkgs.writeShellScriptBin "rebuild-watch" ''
            cd ${cfg.nixosConfigPath}

            echo "Starting polling-based rebuild for NixOS..."
            echo "Press Ctrl+C to stop watching."

            REBUILD_CMD="sudo -E NIXPKGS_ALLOW_UNFREE=1 nixos-rebuild switch --impure --verbose -L --flake ."

            echo ""
            echo "Performing initial build..."
            $REBUILD_CMD

            echo ""
            echo "Watching for changes (checking every ${toString cfg.pollInterval}s)..."
            echo "Watch pattern: ${cfg.watchPattern}"

            get_hash() {
              find . -name "${cfg.watchPattern}" -type f ! -path "./.direnv/*" ! -path "./result/*" -exec ${pkgs.coreutils}/bin/md5sum {} \; | ${pkgs.coreutils}/bin/sort | ${pkgs.coreutils}/bin/md5sum | ${pkgs.coreutils}/bin/cut -d' ' -f1
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

      startTmuxScript = pkgs.writeShellScriptBin "rebuild-tmux" ''
        SESSION_NAME="${config.networking.hostName}"

        ${pkgs.tmux}/bin/tmux has-session -t "$SESSION_NAME" 2>/dev/null
        if [ $? -eq 0 ]; then
          exit 0
        fi

        ${pkgs.tmux}/bin/tmux new-session -d -s "$SESSION_NAME" -n rebuild -c ${cfg.nixosConfigPath}
        ${pkgs.tmux}/bin/tmux set-option -g status-left-length ${if isDarwin then "40" else "30"}
        ${pkgs.tmux}/bin/tmux send-keys -t "$SESSION_NAME" "${rebuildWatchScript}/bin/rebuild-watch" C-m
        ${pkgs.tmux}/bin/tmux select-window -t "$SESSION_NAME:rebuild"

        exit 0
      '';

      attachScript = pkgs.writeShellScriptBin "rebuild-tmux-attach" ''
        SESSION_NAME="${config.networking.hostName}"

        ${pkgs.tmux}/bin/tmux has-session -t "$SESSION_NAME" 2>/dev/null
        if [ $? -eq 0 ]; then
          echo "Attaching to $SESSION_NAME tmux session..."
          exec ${pkgs.tmux}/bin/tmux attach-session -t "$SESSION_NAME"
        else
          echo "The $SESSION_NAME tmux session is not running."
          ${
            if isDarwin then
              ''
                echo "Check the logs with: cat /tmp/agents/log/launchd/tmux-rebuild.log"
                echo ""
                echo "Or restart the tmux agent with:"
                echo "launchctl unload ~/Library/LaunchAgents/com.ivankovnatsky.tmux-rebuild.plist"
                echo "launchctl load ~/Library/LaunchAgents/com.ivankovnatsky.tmux-rebuild.plist"
              ''
            else
              ''
                echo "Check the logs with: journalctl -u tmux-rebuild"
                echo ""
                echo "Or restart the service with:"
                echo "sudo systemctl restart tmux-rebuild"
              ''
          }
        fi
      '';
    in
    if isDarwin then
      {
        launchd.user.agents.tmux-rebuild = {
          serviceConfig = {
            Label = "com.ivankovnatsky.tmux-rebuild";
            RunAtLoad = true;
            KeepAlive = true;
            StandardOutPath = "/tmp/agents/log/launchd/tmux-rebuild.log";
            StandardErrorPath = "/tmp/agents/log/launchd/tmux-rebuild.error.log";
            ThrottleInterval = 3;
          };

          command = "${startTmuxScript}/bin/rebuild-tmux";
        };

        environment.systemPackages = with pkgs; [
          tmux
          attachScript
        ];
      }
    else
      {
        systemd.services.tmux-rebuild = {
          description = "Tmux session for NixOS config rebuilds with polling";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];

          serviceConfig = {
            Type = "forking";
            User = cfg.username;
            KillMode = "none";
            RemainAfterExit = true;
            ExecStart = "${startTmuxScript}/bin/rebuild-tmux";
            Restart = "always";
            RestartSec = 3;
            StandardOutput = "journal";
            StandardError = "journal";
          };
        };

        environment.systemPackages = with pkgs; [
          tmux
          attachScript
        ];
      }
  );
}
