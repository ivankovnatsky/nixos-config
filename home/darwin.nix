{
  imports = [
    ./dockutil.nix
    ./kitty.nix
    ./mpv.nix
  ];

  home.file = {
    ".firefox/config".text = ''
      mkdir -p /Applications/Firefox.app/Contents/Resources/distribution/
      cat > /Applications/Firefox.app/Contents/Resources/distribution/policies.json << EOF
      {
        "policies": {
          "DisableAppUpdate": true
        }
      }
      EOF
    '';

    ".sudo/config".text = ''
      bash -c 'cat << EOF > /private/etc/sudoers.d/default
      Defaults:ivan timestamp_timeout=240
      EOF'
    '';
  };
}
