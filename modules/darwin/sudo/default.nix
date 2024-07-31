{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.local.sudo;

  mkSudoCustomConfigScript = isEnabled:
    let
      file = "/etc/sudoers.d/nix-darwin-sudo-config";
      option = "local.sudo.enable";
    in
    ''
      ${if isEnabled then ''
        # Enable custom sudo configuration
        echo >&2 "Configuring custom sudo settings..."
        sudo tee ${file} > /dev/null << EOF
        # nix-darwin: ${option}
        ${cfg.configContent}
        EOF
        sudo chmod 440 ${file}
      '' else ''
        # Disable custom sudo configuration
        if [ -f ${file} ]; then
          echo >&2 "Removing custom sudo configuration..."
          sudo rm ${file}
        fi
      ''}
    '';
in
{
  options = {
    local.sudo = {
      enable = mkEnableOption ''
        Enable custom sudo configuration
        When enabled, this option creates a file /etc/sudoers.d/nix-darwin-sudo-config
        with the specified content.
      '';

      configContent = mkOption {
        type = types.lines;
        default = "";
        example = ''
          Defaults:$USER timestamp_timeout=240
        '';
        description = "Custom sudo configuration content.";
      };
    };
  };

  config = {
    system.activationScripts.extraActivation.text = ''
      # Custom sudo configuration
      ${mkSudoCustomConfigScript cfg.enable}
    '';
  };
}
