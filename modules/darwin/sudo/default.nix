{
  config,
  lib,
  ...
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
            TMP_SUDOERS=$(mktemp)
            trap 'rm -f "$TMP_SUDOERS"' EXIT
            cat > "$TMP_SUDOERS" <<'EOF'
            # nix-darwin: ${option}
            ${configToUse}
            EOF
            if ! sudo /usr/sbin/visudo -cf "$TMP_SUDOERS" >/dev/null; then
              echo >&2 "ERROR: sudoers content failed visudo validation; leaving ${file} unchanged"
              exit 1
            fi
            sudo install -m 0440 -o root -g wheel "$TMP_SUDOERS" ${file}
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
          Defaults:$USER timestamp_timeout=5
        '';
        description = "Custom sudo configuration content.";
      };

    };
  };

  config = {
    system.activationScripts.extraActivation.text = ''
      # Custom sudo configuration
      ${mkSudoCustomConfigScript cfg.enable cfg.configContent}
    '';
  };
}
