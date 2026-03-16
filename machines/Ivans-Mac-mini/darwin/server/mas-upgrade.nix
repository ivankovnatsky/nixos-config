{ pkgs, ... }:
{
  system.activationScripts.postActivation.text = ''
    if [ "$(date +%d)" = "15" ]; then
      echo "Upgrading App Store apps..."
      ${pkgs.mas}/bin/mas upgrade || true
    fi
  '';
}
