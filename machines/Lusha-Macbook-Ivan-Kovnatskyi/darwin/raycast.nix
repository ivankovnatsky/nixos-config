{
  system.activationScripts.postActivation.text = ''
    raycast_extensions=(
      "raycast/clipboard-history"
      "asubbotin/shell"
    )

    for ext in "''${raycast_extensions[@]}"; do
      open "raycast://extensions/$ext?source=webstore"
    done
  '';
}
