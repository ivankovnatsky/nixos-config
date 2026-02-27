{ pkgs, ... }:

{
  # macOS stores scaling preferences per display configuration. If a new
  # arrangement is encountered (e.g., opening lid with external monitor for the
  # first time), run `settings scaling --init` manually to register it.
  system.activationScripts.postActivation.text = ''
    ${pkgs.settings}/bin/settings scaling --init
  '';
}
