{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.services.dnsmasq;

  settingsToConf =
    settings:
    concatStringsSep "\n" (
      flatten (
        mapAttrsToList (
          name: value:
          if value == true then
            [ name ]
          else if value == false then
            [ ]
          else if isList value then
            map (v: "${name}=${toString v}") value
          else
            [ "${name}=${toString value}" ]
        ) settings
      )
    );

  configFile =
    if cfg.configFile != null then
      cfg.configFile
    else
      pkgs.writeText "dnsmasq.conf" ''
        ${settingsToConf cfg.settings}
      '';

  resolverDomain =
    if cfg.enable && cfg.resolveLocalQueries then cfg.settings.domain or null else null;
in
{
  options.local.services.dnsmasq = {
    enable = mkEnableOption "dnsmasq DNS server";

    package = mkOption {
      type = types.package;
      default = pkgs.dnsmasq;
      defaultText = literalExpression "pkgs.dnsmasq";
      description = "The dnsmasq package to use.";
    };

    settings = mkOption {
      type =
        with types;
        attrsOf (oneOf [
          bool
          int
          str
          (listOf (oneOf [
            str
            int
          ]))
        ]);
      default = { };
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

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to dnsmasq configuration file (overrides settings option if specified).";
    };

    waitForSecrets = mkOption {
      type = types.bool;
      default = false;
      description = "Wait for sops-nix secrets before starting.";
    };
  };

  config = mkMerge [
    {
      system.activationScripts.postActivation.text = mkAfter (
        let
          listenAddresses = cfg.settings."listen-address" or "127.0.0.1";
          listenAddress = if isList listenAddresses then elemAt listenAddresses 0 else listenAddresses;
          port = cfg.settings.port or "53";
          desiredDomain = if resolverDomain == null then "" else resolverDomain;
        in
        ''
          marker=/etc/resolver/.nix-dnsmasq-domain
          previous_domain=""
          if [ -f "$marker" ]; then
            previous_domain=$(cat "$marker")
          fi

          if [ -n "$previous_domain" ] && [ "$previous_domain" != "${desiredDomain}" ]; then
            case "$previous_domain" in
              */*) echo "Refusing to remove invalid managed resolver domain: $previous_domain" ;;
              *) rm -f "/etc/resolver/$previous_domain" ;;
            esac
          fi

          ${
            if resolverDomain == null then
              ''
                rm -f "$marker"
              ''
            else
              ''
                mkdir -p /etc/resolver
                echo "nameserver ${listenAddress}" > "/etc/resolver/${resolverDomain}"
                ${optionalString (port != "53") "echo \"port ${port}\" >> \"/etc/resolver/${resolverDomain}\""}
                echo "${resolverDomain}" > "$marker"
                chmod 600 "$marker"
              ''
          }
        ''
      );
    }

    (mkIf cfg.enable {
      environment.systemPackages = [ cfg.package ];

      local.launchd.services.dnsmasq = {
        enable = true;
        keepAlive = cfg.alwaysKeepRunning;
        inherit (cfg) waitForSecrets;
        command = "${cfg.package}/bin/dnsmasq -k -C ${configFile}";
        extraDirs =
          let
            logFacility = cfg.settings."log-facility" or null;
          in
          optional (logFacility != null) (dirOf logFacility);
        extraServiceConfig.AbandonProcessGroup = false;
      };
    })
  ];
}
