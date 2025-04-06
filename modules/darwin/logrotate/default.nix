{ config, lib, pkgs, ... }:

with lib;

let
  # Override the logrotate package to disable ACL support on Darwin
  logrotatePackage = pkgs.logrotate.override { aclSupport = false; };

  cfg = config.local.services.logrotate;

  # Function to generate a logrotate configuration line
  generateLine = n: v:
    if builtins.elem n [ "files" "priority" "enable" "global" ] || v == null then null
    else if builtins.elem n [ "frequency" ] then "${v}\n"
    else if builtins.elem n [ "firstaction" "lastaction" "prerotate" "postrotate" "preremove" ]
         then "${n}\n    ${v}\n  endscript\n"
    else if lib.isInt v then "${n} ${toString v}\n"
    else if v == true then "${n}\n"
    else if v == false then "no${n}\n"
    else "${n} ${v}\n";
    
  # Generate a complete section with proper indentation
  generateSection = indent: settings: lib.concatStringsSep (lib.fixedWidthString indent " " "") (
    lib.filter (x: x != null) (lib.mapAttrsToList generateLine settings)
  );

  # Generate a complete configuration block
  # generateSection includes a final newline hence weird closing brace
  mkConf = settings:
    if settings.global or false then generateSection 0 settings
    else ''
      ${lib.concatMapStringsSep "\n" (files: ''"${files}"'') (lib.toList settings.files)} {
        ${generateSection 2 settings}}
    '';

  # Process and sort all settings
  settings = lib.sortProperties (lib.attrValues (lib.filterAttrs (_: settings: settings.enable) (
    lib.foldAttrs lib.recursiveUpdate { } [
      {
        header = {
          enable = true;
          missingok = true;
          notifempty = true;
          frequency = "weekly";
          rotate = 4;
          compress = true;
        };
      }
      cfg.settings
      { header = { global = true; priority = 100; }; }
    ]
  )));
  
  # Generate the complete logrotate config file
  configFile = pkgs.writeTextFile {
    name = "logrotate.conf";
    text = lib.concatStringsSep "\n" (map mkConf settings);
  };
  
  # Shell script to run logrotate
  rotateLogs = pkgs.writeShellScript "rotate-logs" ''
    #!/bin/sh
    export PATH="${pkgs.coreutils}/bin:${pkgs.gzip}/bin:${logrotatePackage}/bin:$PATH"
    mkdir -p /var/lib/logrotate
    logrotate -s /var/lib/logrotate/status ${configFile} ${lib.concatStringsSep " " cfg.extraArgs}
  '';
in
{
  options.local.services.logrotate = {
    enable = mkEnableOption "logrotate for log rotation" // {
      default = lib.foldr (n: a: a || n.enable) false (lib.attrValues cfg.settings);
      defaultText = lib.literalExpression "cfg.settings != {}";
    };
    
    settings = lib.mkOption {
      default = {};
      description = ''
        Logrotate settings: each attribute here will define its own section,
        ordered by `services.logrotate.settings.<name>.priority`,
        which can either define files to rotate with their settings
        or settings common to all further files settings.
        
        All attribute names not explicitly defined as sub-options here are passed through
        as logrotate config directives.
        Refer to logrotate manual for details.
      '';
      example = lib.literalExpression ''
        {
          # global options
          header = {
            dateext = true;
          };
          # example custom files
          "/var/log/mylog.log" = {
            frequency = "daily";
            rotate = 3;
          };
          "multiple paths" = {
             files = [
              "/var/log/first*.log"
              "/var/log/second.log"
            ];
          };
          # specify custom order of sections
          "/var/log/myservice/*.log" = {
            # ensure lower priority
            priority = 110;
            postrotate = '''
              launchctl kickstart -k myservice
            ''';
          };
        };
        '';
      type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
        freeformType = with lib.types; attrsOf (nullOr (oneOf [ int bool str ]));

        options = {
          enable = lib.mkEnableOption "setting individual kill switch" // {
            default = true;
          };

          global = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = ''
              Whether this setting is a global option or not: set to have these
              settings apply to all files settings with a higher priority.
            '';
          };
          
          files = lib.mkOption {
            type = with lib.types; either str (listOf str);
            default = name;
            defaultText = ''
              The attrset name if not specified
            '';
            description = ''
              Single or list of files for which rules are defined.
              The files are quoted with double-quotes in logrotate configuration,
              so globs and spaces are supported.
              Note this setting is ignored if globals is true.
            '';
          };

          frequency = lib.mkOption {
            type = lib.types.nullOr (lib.types.enum [
              "daily" "weekly" "monthly" "yearly"
            ]);
            default = null;
            description = ''
              How often to rotate the logs. Defaults to previously set global setting,
              which itself defaults to weekly.
            '';
          };

          priority = lib.mkOption {
            type = lib.types.int;
            default = 1000;
            description = ''
              Order of this logrotate block in relation to the others. The semantics are
              the same as with `lib.mkOrder`. Smaller values are inserted first.
            '';
          };
        };
      }));
    };
    
    frequency = mkOption {
      type = types.enum [ "hourly" "daily" "weekly" "monthly" ];
      default = "daily";
      description = "How often to run the logrotate tool";
    };
    
    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional command line arguments to pass on logrotate invocation";
    };
  };
  
  config = mkIf cfg.enable {
    environment.systemPackages = [ logrotatePackage ];
    
    # Create directories needed for logrotate
    system.activationScripts.preActivation.text = mkAfter ''
      # Create logrotate directories
      echo "Setting up logrotate directories..."
      mkdir -p /var/lib/logrotate
      chmod 755 /var/lib/logrotate
      
      mkdir -p /tmp/logrotate
      chmod 755 /tmp/logrotate
    '';
    
    # Run logrotate via launchd
    launchd.daemons.logrotate = {
      serviceConfig = {
        Label = "org.nixos.logrotate";
        ProgramArguments = [ "${rotateLogs}" ];
        # Production schedule based on configured frequency
        StartCalendarInterval = 
          if cfg.frequency == "hourly" then [
            { Hour = "*"; Minute = 0; }
          ] else if cfg.frequency == "daily" then [
            { Hour = 3; Minute = 0; }
          ] else if cfg.frequency == "weekly" then [
            { Weekday = 0; Hour = 3; Minute = 0; }
          ] else if cfg.frequency == "monthly" then [
            { Day = 1; Hour = 3; Minute = 0; }
          ] else [
            { Hour = 3; Minute = 0; }
          ];
        RunAtLoad = false; # Don't run immediately on system boot
        StandardErrorPath = "/tmp/logrotate/stderr.log";
        StandardOutPath = "/tmp/logrotate/stdout.log";
        EnvironmentVariables = {
          PATH = "${pkgs.coreutils}/bin:${pkgs.gzip}/bin:${logrotatePackage}/bin:/usr/bin:/bin";
        };
        ProcessType = "Background";
        Nice = 19; # Lower priority
      };
    };
  };
} 
