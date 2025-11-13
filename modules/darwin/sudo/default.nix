{ config
, lib
, ...
}:

with lib;
let
  cfg = config.local.sudo;

  mkSudoCustomConfigScript =
    isEnabled: configToUse:
    let
      file = "/etc/sudoers.d/nix-darwin-sudo-config";
      option = "local.sudo.enable";
    in
    ''
      ${
        if isEnabled then
          ''
            # Enable custom sudo configuration
            echo >&2 "Configuring custom sudo settings..."
            sudo tee ${file} > /dev/null << EOF
            # nix-darwin: ${option}
            ${configToUse}
            EOF
            sudo chmod 440 ${file}
          ''
        else
          ''
            # Disable custom sudo configuration
            if [ -f ${file} ]; then
              echo >&2 "Removing custom sudo configuration..."
              sudo rm ${file}
            fi
          ''
      }
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
          Defaults:$USER timestamp_timeout=720
        '';
        description = "Custom sudo configuration content.";
      };

      nopasswd = {
        enable = mkEnableOption "Enable NOPASSWD for specified commands";

        user = mkOption {
          type = types.str;
          default = "$USER";
          example = "username";
          description = "User for which NOPASSWD commands should be enabled.";
        };

        setenv = mkOption {
          type = types.bool;
          default = false;
          example = true;
          description = "Allow preserving environment variables with sudo -E (adds SETENV tag).";
        };

        commands = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [
            "/usr/bin/systemctl"
            "/usr/bin/reboot"
          ];
          description = "List of commands that can be executed without password.";
        };
      };
    };
  };

  # FIXME: Should also clean NOPASSWD commands when disabled.
  config = {
    system.activationScripts.extraActivation.text =
      let
        finalConfigContent =
          if (cfg.enable && cfg.nopasswd.enable) then
            let
              tags = if cfg.nopasswd.setenv then "NOPASSWD:SETENV:" else "NOPASSWD:";
              nopasswdRules = map (cmd: "${cfg.nopasswd.user} ALL=(ALL) ${tags} ${cmd}") cfg.nopasswd.commands;
              nopasswdContent = concatStringsSep "\n" nopasswdRules;
            in
            ''
              ${cfg.configContent}

              # NOPASSWD commands
              ${nopasswdContent}
            ''
          else
            cfg.configContent;
      in
      ''
        # Custom sudo configuration
        ${mkSudoCustomConfigScript cfg.enable finalConfigContent}
      '';
  };
}
