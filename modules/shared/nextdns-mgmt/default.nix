{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.local.services.nextdns-mgmt;

  profileOptions = types.submodule {
    options = {
      enable = mkEnableOption "declarative NextDNS profile synchronization";

      profileId = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "abc123";
        description = "NextDNS profile ID to sync";
      };

      profileIdFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/run/secrets/nextdns-profile-id";
        description = "Path to file containing NextDNS profile ID";
      };

      profileFile = mkOption {
        type = types.path;
        example = ./nextdns/profile.json;
        description = "Path to NextDNS profile JSON file";
      };

      apiKey = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "NextDNS API key";
      };

      apiKeyFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/run/secrets/nextdns-api-key";
        description = "Path to file containing NextDNS API key";
      };
    };
  };

  enabledProfiles = filterAttrs (_: profile: profile.enable) cfg;
in
{
  options.local.services.nextdns-mgmt = mkOption {
    type = types.attrsOf profileOptions;
    default = {};
    description = "NextDNS profile management instances";
  };

  config = mkMerge [
    # Assertions for all platforms
    {
      assertions = flatten (mapAttrsToList (name: profile: [
        {
          assertion = (profile.apiKey != null) != (profile.apiKeyFile != null);
          message = "Exactly one of apiKey or apiKeyFile must be set for nextdns-mgmt profile '${name}'";
        }
        {
          assertion = (profile.profileId != null) != (profile.profileIdFile != null);
          message = "Exactly one of profileId or profileIdFile must be set for nextdns-mgmt profile '${name}'";
        }
      ]) enabledProfiles);
    }

    # Darwin configuration
    (mkIf (enabledProfiles != {} && pkgs.stdenv.isDarwin) {
      system.activationScripts.postActivation.text = concatStringsSep "\n" (
        mapAttrsToList (name: profile:
          let
            apiKeyArg = if profile.apiKeyFile != null
              then ''--api-key "$(cat ${profile.apiKeyFile})"''
              else ''--api-key "${profile.apiKey}"'';
            profileIdArg = if profile.profileIdFile != null
              then ''--profile-id "$(cat ${profile.profileIdFile})"''
              else ''--profile-id "${profile.profileId}"'';
            displayMsg = if profile.profileIdFile != null
              then "Updating NextDNS profile ${name}..."
              else "Updating NextDNS profile ${name} (${profile.profileId})...";
          in ''
            echo "${displayMsg}"
            ${pkgs.nextdns-mgmt}/bin/nextdns-mgmt update \
              ${apiKeyArg} \
              ${profileIdArg} \
              --profile-file "${profile.profileFile}" || echo "Warning: NextDNS update for ${name} failed"
          '') enabledProfiles
      );
    })

    # NixOS configuration
    (mkIf (enabledProfiles != {} && !pkgs.stdenv.isDarwin) {
      system.activationScripts.nextdns-mgmt = {
        text = concatStringsSep "\n" (
          mapAttrsToList (name: profile:
            let
              apiKeyArg = if profile.apiKeyFile != null
                then ''--api-key "$(cat ${profile.apiKeyFile})"''
                else ''--api-key "${profile.apiKey}"'';
              profileIdArg = if profile.profileIdFile != null
                then ''--profile-id "$(cat ${profile.profileIdFile})"''
                else ''--profile-id "${profile.profileId}"'';
              displayMsg = if profile.profileIdFile != null
                then "Updating NextDNS profile ${name}..."
                else "Updating NextDNS profile ${name} (${profile.profileId})...";
            in ''
              echo "${displayMsg}"
              ${pkgs.nextdns-mgmt}/bin/nextdns-mgmt update \
                ${apiKeyArg} \
                ${profileIdArg} \
                --profile-file "${profile.profileFile}" || echo "Warning: NextDNS update for ${name} failed"
            '') enabledProfiles
        );
      };
    })
  ];
}
