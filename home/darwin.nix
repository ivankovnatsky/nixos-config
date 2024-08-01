{
  imports = [
    ./kitty.nix
    ./mpv.nix
  ];

  home.file = {
    ".manual/config".text = ''
      # Firefox
      mkdir -p /Applications/Firefox.app/Contents/Resources/distribution/
      cat > /Applications/Firefox.app/Contents/Resources/distribution/policies.json << EOF
      {
        "policies": {
          "DisableAppUpdate": true
        }
      }
      EOF
    '';
  };
}
