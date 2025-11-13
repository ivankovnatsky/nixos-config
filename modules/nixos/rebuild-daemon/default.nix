{ pkgs
, config
, lib
, ...
}:

with lib;

let
  cfg = config.local.services.rebuildDaemon;
in
{
  options = {
    local.services.rebuildDaemon = {
      enable = mkEnableOption "automated rebuild daemon with watchman";

      configPath = mkOption {
        type = types.str;
        description = "Path to the nixos-config repository";
      };
    };
  };

  config = mkIf cfg.enable {
    # Create log directory (root-owned for root service)
    systemd.tmpfiles.rules = [
      "d /tmp/log 0755 root root -"
    ];

    systemd.services.rebuild-daemon = {
      description = "Automated NixOS configuration rebuild daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      path = with pkgs; [
        watchman-rebuild
        watchman
        nixos-rebuild
        git
      ];

      # Allow root to access git repo owned by user
      preStart = ''
        ${pkgs.git}/bin/git config --global --add safe.directory ${cfg.configPath}
      '';

      serviceConfig = {
        Type = "simple";
        # Run as root for passwordless nixos-rebuild (like Darwin launchd)
        # Set HOME so git config can work
        Environment = "HOME=/root";
        Restart = "always";
        RestartSec = 10;
        ExecStart = "${pkgs.watchman-rebuild}/bin/watchman-rebuild ${cfg.configPath}";
        # Redirect output to files like Darwin launchd
        StandardOutput = "append:/tmp/log/rebuild-daemon.log";
        StandardError = "append:/tmp/log/rebuild-daemon.error.log";
      };

      unitConfig = {
        # Wait for config path to exist
        ConditionPathExists = cfg.configPath;
      };
    };
  };
}
