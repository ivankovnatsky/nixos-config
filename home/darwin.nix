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
      dockutil --remove all
      dockutil --add "/Applications/kitty.app"
      dockutil --add "/Applications/Firefox.app"
      dockutil --add "/System/Applications/Mail.app"
      dockutil --add "/System/Applications/Calendar.app"
      dockutil --add "/System/Applications/System Settings.app"
    '';
  };
}
