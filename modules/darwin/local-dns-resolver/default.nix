{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.local-dns-resolver;
in
{
  options.services.local-dns-resolver = {
    enable = mkEnableOption "Local DNS resolver configuration";

    zones = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            nameserver = mkOption {
              type = types.str;
              description = "IP address of the nameserver for this zone";
              example = "192.168.50.169";
            };
          };
        }
      );
      default = { };
      description = "Mapping of zone names to their DNS configuration";
      example = literalExpression ''
        {
          "homelab" = {
            nameserver = "192.168.50.169";
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    system.activationScripts.postActivation.text = ''
      # Create /etc/resolver directory if it doesn't exist
      echo >&2 "setting up /etc/resolver directory..."
      sudo mkdir -p /etc/resolver

      # Configure DNS resolver for each zone
      ${concatStringsSep "\n" (
        mapAttrsToList (zone: conf: ''
          echo >&2 "configuring DNS resolver for ${zone}..."
          echo "nameserver ${conf.nameserver}" | sudo tee /etc/resolver/${zone} >/dev/null
        '') cfg.zones
      )}

      # Restart mDNSResponder
      echo >&2 "restarting mDNSResponder..."
      sudo killall -HUP mDNSResponder
    '';

    system.activationScripts.preActivation.text = mkIf (!cfg.enable) ''
      # Remove DNS configuration if it exists
      echo >&2 "removing DNS resolver configurations..."
      ${concatStringsSep "\n" (
        mapAttrsToList (zone: conf: ''
          if [ -f /etc/resolver/${zone} ]; then
            sudo rm /etc/resolver/${zone}
          fi
        '') cfg.zones
      )}

      # Restart mDNSResponder
      echo >&2 "restarting mDNSResponder..."
      sudo killall -HUP mDNSResponder
    '';
  };
}
