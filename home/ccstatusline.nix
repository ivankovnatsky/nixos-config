{ config, ... }:

{
  # https://github.com/sirmalloc/ccstatusline
  home.file.".config/ccstatusline/settings.json".text = builtins.toJSON {
    version = 3;

    # Status line widgets configuration
    # Each line is an array of widgets
    lines = [
      # Line 1: Model, Version, Output Style, Session Info
      [
        {
          id = "1";
          type = "model";
          color = "cyan";
        }
        {
          id = "2";
          type = "separator";
        }
        {
          id = "3";
          type = "version";
          color = "blue";
        }
        {
          id = "4";
          type = "separator";
        }
        {
          id = "5";
          type = "output-style";
          color = "green";
        }
        {
          id = "6";
          type = "separator";
        }
        {
          id = "7";
          type = "session-clock";
          color = "yellow";
        }
        {
          id = "8";
          type = "separator";
        }
        {
          id = "9";
          type = "session-cost";
          color = "magenta";
        }
        {
          id = "10";
          type = "separator";
        }
        {
          id = "11";
          type = "block-timer";
          color = "red";
        }
        {
          id = "12";
          type = "separator";
        }
        {
          id = "13";
          type = "claude-session-id";
          color = "brightBlack";
        }
      ]
      # Line 2: Git Info & Current Directory
      [
        {
          id = "14";
          type = "current-working-dir";
          color = "cyan";
        }
        {
          id = "15";
          type = "separator";
        }
        {
          id = "16";
          type = "git-branch";
          color = "magenta";
        }
        {
          id = "17";
          type = "separator";
        }
        {
          id = "18";
          type = "git-changes";
          color = "yellow";
        }
        {
          id = "19";
          type = "separator";
        }
        {
          id = "20";
          type = "git-worktree";
          color = "blue";
        }
      ]
      # Line 3: Token & Context Metrics
      [
        {
          id = "21";
          type = "tokens-input";
          color = "green";
        }
        {
          id = "22";
          type = "separator";
        }
        {
          id = "23";
          type = "tokens-output";
          color = "yellow";
        }
        {
          id = "24";
          type = "separator";
        }
        {
          id = "25";
          type = "tokens-cached";
          color = "blue";
        }
        {
          id = "26";
          type = "separator";
        }
        {
          id = "27";
          type = "tokens-total";
          color = "cyan";
        }
        {
          id = "28";
          type = "separator";
        }
        {
          id = "29";
          type = "context-length";
          color = "magenta";
        }
        {
          id = "30";
          type = "separator";
        }
        {
          id = "31";
          type = "context-percentage";
          color = "red";
        }
        {
          id = "32";
          type = "separator";
        }
        {
          id = "33";
          type = "context-percentage-usable";
          color = "brightRed";
        }
        {
          id = "34";
          type = "separator";
        }
        {
          id = "35";
          type = "terminal-width";
          color = "brightBlack";
        }
      ]
    ];

    # Terminal width handling
    # Options: "full-width", "full-minus-40", "full-until-compact"
    flexMode = "full-minus-40";

    # When using "full-until-compact", switch to minus-40 at this percentage
    compactThreshold = 60;

    # Color support level
    # 0 = basic (16 colors)
    # 1 = 256 colors
    # 2 = truecolor (24-bit)
    colorLevel = 2;

    # Global options
    inheritSeparatorColors = false;
    globalBold = false;

    # Powerline configuration
    powerline = {
      enabled = false;
      separators = [ "" ]; # \uE0B0
      separatorInvertBackground = [ false ];
      startCaps = [ ];
      endCaps = [ ];
      autoAlign = false;
    };
  };
}
