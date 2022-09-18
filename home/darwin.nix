{
  imports = [
    ./dockutil.nix
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
      sudo bash -c 'cat << EOF > /etc/sudoers.d/default
      Defaults timestamp_timeout=240
      EOF'
    '';
  };
}
