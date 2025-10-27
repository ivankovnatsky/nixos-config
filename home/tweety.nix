{
  config,
  lib,
  pkgs,
  ...
}:

{
  home = {
    packages = with pkgs; [
      tweety
    ];

    # Generate tweety fish completions
    activation = lib.mkIf config.flags.enableFishShell {
      generateTweetyCompletions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        TWEETY_BIN="${pkgs.tweety}/bin/tweety"

        if [[ -x "$TWEETY_BIN" ]]; then
          $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/.config/fish/completions"
          $DRY_RUN_CMD rm -f "${config.home.homeDirectory}/.config/fish/completions/tweety.fish"
          $DRY_RUN_CMD "$TWEETY_BIN" completion fish > "${config.home.homeDirectory}/.config/fish/completions/tweety.fish"
        fi
      '';

      installTweety = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        TWEETY_BIN="${pkgs.tweety}/bin/tweety"

        if [[ -x "$TWEETY_BIN" ]]; then
          $DRY_RUN_CMD "$TWEETY_BIN" install
        fi
      '';
    };

    file.".config/tweety/config.json".text = builtins.toJSON {
      command = "${pkgs.fish}/bin/fish";
      args = [ "--login" ];
      editor = "nvim";
      env = { };
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
  };
}
