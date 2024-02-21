{ pkgs, ... }:

{
  imports = [
    ./kitty.nix
    ./mpv.nix
  ];

  home.file = {
    ".manual/config".text = ''
      # Sudo; run as sudo
      bash -c 'cat << EOF > /private/etc/sudoers.d/default
      Defaults:ivan timestamp_timeout=240
      EOF'

      # Firefox
      mkdir -p /Applications/Firefox.app/Contents/Resources/distribution/
      cat > /Applications/Firefox.app/Contents/Resources/distribution/policies.json << EOF
      {
        "policies": {
          "DisableAppUpdate": true
        }
      }
      EOF

      # Dockutil
      ${pkgs.dockutil}/bin/dockutil --remove all
      ${pkgs.dockutil}/bin/dockutil --add "/Applications/kitty.app"
      ${pkgs.dockutil}/bin/dockutil --add "/Applications/Firefox.app"
      ${pkgs.dockutil}/bin/dockutil --add "/Applications/Chromium.app"
      ${pkgs.dockutil}/bin/dockutil --add "/System/Cryptexes/App/System/Applications/Safari.app"
      ${pkgs.dockutil}/bin/dockutil --add "/System/Applications/System Settings.app"
    '';
  };
}
