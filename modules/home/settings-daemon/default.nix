{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.services.settings-daemon;

  settingsPackage = pkgs.callPackage ../../../packages/settingsctl { };

  daemonArgs = concatStringsSep " " (
    [
      "daemon"
      "run"
    ]
    ++ (if cfg.autovolume.enable then [ "--autovolume" ] else [ "--no-autovolume" ])
    ++ [
      "--autovolume-idle"
      (toString cfg.autovolume.idleSeconds)
      "--autovolume-threshold"
      (toString cfg.autovolume.thresholdPercent)
      "--check-interval"
      (toString cfg.checkInterval)
    ]
    ++ (if cfg.verbose then [ "--verbose" ] else [ "--quiet" ])
  );

  daemonCommand = "${settingsPackage}/bin/settings ${daemonArgs}";
in
{
  options.local.services.settings-daemon = {
    enable = mkEnableOption "settings-daemon service";

    verbose = mkOption {
      type = types.bool;
      default = true;
      description = "Log feature activity to the daemon log.";
    };

    checkInterval = mkOption {
      type = types.int;
      default = 60 * 5;
      description = "Seconds between daemon ticks.";
    };

    autovolume = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Enable the autovolume feature: lower system volume to a fixed
          floor after a stretch of detected silence.
        '';
      };

      idleSeconds = mkOption {
        type = types.int;
        default = 60 * 30;
        description = "Seconds of silence required before lowering volume.";
      };

      thresholdPercent = mkOption {
        type = types.int;
        default = 6;
        description = "Volume percentage to lower to.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ settingsPackage ];
    }

    (mkIf pkgs.stdenv.isDarwin {
      local.launchd.services.settings-daemon = {
        enable = true;
        command = daemonCommand;
        runAtLoad = true;
        keepAlive = true;
        throttleInterval = 30;
      };
    })

    (mkIf pkgs.stdenv.isLinux {
      systemd.user.services.settings-daemon = {
        Unit = {
          Description = "Settings daemon (autovolume, etc.)";
          After = [
            "default.target"
            "pipewire.service"
            "pulseaudio.service"
          ];
        };
        Service = {
          # systemd user units inherit a minimal PATH; the autovolume probes
          # shell out to `pactl`, so make the PulseAudio client tools
          # discoverable. Without this every Linux probe fails and the
          # fail-safe pins the daemon to "active" — feature would never fire.
          Environment = [
            "PATH=${makeBinPath [ pkgs.pulseaudio ]}:/run/current-system/sw/bin:/usr/bin:/bin"
          ];
          ExecStart = daemonCommand;
          Restart = "on-failure";
          RestartSec = 10;
        };
        Install.WantedBy = [ "default.target" ];
      };
    })
  ]);
}
