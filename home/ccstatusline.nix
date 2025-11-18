{ config, ... }:

{
  # https://github.com/sirmalloc/ccstatusline
  home.file.".config/ccstatusline/settings.json".text = builtins.toJSON {
    version = 3;

    # Status line widgets configuration
    # Each line is an array of widgets
    lines = [
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
          type = "context-length";
          color = "brightBlack";
        }
        {
          id = "4";
          type = "separator";
        }
        {
          id = "5";
          type = "git-branch";
          color = "magenta";
        }
        {
          id = "6";
          type = "separator";
        }
        {
          id = "7";
          type = "git-changes";
          color = "yellow";
        }
      ]
      # Line 2 (empty)
      []
      # Line 3 (empty)
      []
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
    defaultSeparator = null;
    defaultPadding = null;
    inheritSeparatorColors = false;
    overrideBackgroundColor = null;
    overrideForegroundColor = null;
    globalBold = false;

    # Powerline configuration
    powerline = {
      enabled = false;
      separators = [ "" ]; # \uE0B0
      separatorInvertBackground = [ false ];
      startCaps = [];
      endCaps = [];
      theme = null;
      autoAlign = false;
    };
  };
}
