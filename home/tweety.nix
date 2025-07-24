{ config, lib, pkgs, ... }:

{
  programs.fish = lib.mkIf config.flags.enableFishShell {
    # Generate tweety completions file
    functions = {};
  };

  # Generate tweety fish completions
  home.activation = lib.mkIf config.flags.enableFishShell {
    generateTweetyCompletions = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [[ -x "/opt/homebrew/bin/tweety" ]]; then
        $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/.config/fish/completions"
        $DRY_RUN_CMD rm -f "${config.home.homeDirectory}/.config/fish/completions/tweety.fish"
        $DRY_RUN_CMD /opt/homebrew/bin/tweety completion fish > "${config.home.homeDirectory}/.config/fish/completions/tweety.fish"
      fi
    '';
  };

  home.file.".config/tweety/config.json".text = builtins.toJSON {
    command = "${pkgs.fish}/bin/fish";
    args = [ "--login" ];
    editor = "nvim";
    env = {};
    xterm = {
      fontFamily = config.flags.fontGeneral;
      fontSize = 13;
      cursorBlink = false;
      cursorStyle = "block";
      theme = {
        background = "#1e1e1e";
        foreground = "#d4d4d4";
      };
      allowTransparency = false;
      scrollback = 10000;
      tabStopWidth = 4;
    };
    theme = "Tomorrow";
    themeDark = "Tomorrow Night";
  };
}
