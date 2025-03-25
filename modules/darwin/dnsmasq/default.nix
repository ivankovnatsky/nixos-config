{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.local.services.dnsmasq;
  
  # Make sure dnsmasq doesn't have any Linux-specific dependencies
  dnsmasqPackage = pkgs.dnsmasq;
  
  # Function to convert settings to dnsmasq configuration format
  settingsToConf = settings:
    concatStringsSep "\n" (flatten (mapAttrsToList (name: value:
      if value == true then
        [ name ]
      else if value == false then
        [ ]
      else if isList value then
        map (v: "${name}=${toString v}") value
      else
        [ "${name}=${toString value}" ]
    ) settings));

  # Build the main configuration file content
  configFile = pkgs.writeText "dnsmasq.conf" ''
    ${settingsToConf cfg.settings}
  '';
  

in
{
  options.local.services.dnsmasq = {
    enable = mkEnableOption "dnsmasq DNS server";

    package = mkOption {
      type = types.package;
      default = dnsmasqPackage;
      defaultText = literalExpression "pkgs.dnsmasq";
      description = "The dnsmasq package to use.";
    };

    settings = mkOption {
      type = with types; attrsOf (oneOf [
        bool
        int
        str
        (listOf (oneOf [ str int ]))
      ]);
      default = {};
      example = literalExpression ''
        {
          "listen-address" = [ "127.0.0.1" "192.168.50.3" ];
          "domain-needed" = true;
          "expand-hosts" = true;
          "domain" = "homelab";
        }
      '';
      description = "Dnsmasq configuration. See man dnsmasq for available options.";
    };

    resolveLocalQueries = mkOption {
      type = types.bool;
      default = true;
      description = "Whether dnsmasq should resolve local queries.";
    };

    alwaysKeepRunning = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to restart dnsmasq if it stops for any reason.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    
    # Set up directories in preActivation
    system.activationScripts.preActivation.text = mkAfter ''
      # Create log directory for dnsmasq
      echo "Setting up dnsmasq directories..."
      mkdir -p /var/log/dnsmasq
      chmod 755 /var/log/dnsmasq
    '';
    
    # Configure DNS resolution in postActivation
    system.activationScripts.postActivation.text = mkIf cfg.resolveLocalQueries (
      let
        domain = cfg.settings.domain or null;
        listenAddress = if isList cfg.settings."listen-address" 
                        then elemAt cfg.settings."listen-address" 0 
                        else cfg.settings."listen-address" or "127.0.0.1";
        port = cfg.settings.port or "53";
      in
      optionalString (domain != null) (mkAfter ''
        echo "Setting up DNS resolver for ${domain}..."
        mkdir -p /etc/resolver
        echo "nameserver ${listenAddress}" > /etc/resolver/${domain}
        ${optionalString (port != "53") "echo \"port ${port}\" > /etc/resolver/${domain}"}
      '')
    );

    launchd.daemons.dnsmasq = {
      command = "${cfg.package}/bin/dnsmasq -k -C ${configFile}";
      serviceConfig = {
        Label = "org.nixos.dnsmasq";
        RunAtLoad = true;
        KeepAlive = cfg.alwaysKeepRunning;
        AbandonProcessGroup = false;
        StandardErrorPath = "/var/log/dnsmasq/stderr.log";
        StandardOutPath = "/var/log/dnsmasq/stdout.log";
      };
    };
  };
}
