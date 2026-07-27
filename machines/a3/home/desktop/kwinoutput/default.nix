{ config, ... }:

{
  # KWin display output config (monitor layout, scaling, replicas).
  # plasma-manager can't manage monitors yet:
  #   https://github.com/nix-community/plasma-manager/issues/172
  #
  # Deployed via `tools` as a real writable copy rather than a home.file
  # store symlink, so KWin can persist runtime display changes (e.g.
  # hot-plugging the goggles and setting them as a replica). To re-capture
  # after changing the layout in System Settings, copy the runtime file back:
  #   cp ~/.config/kwinoutputconfig.json \
  #     ~/Sources/github.com/ivankovnatsky/nix-config/machines/a3/home/desktop/kwinoutput/kwinoutputconfig.json
  local.tools.settings.files = [
    {
      source = "${./kwinoutputconfig.json}";
      target = "${config.home.homeDirectory}/.config/kwinoutputconfig.json";
      mode = "0644";
    }
  ];
}
