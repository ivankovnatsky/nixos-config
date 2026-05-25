{
  config,
  ...
}:

{
  local = {
    dock = {
      enable = true;
      inherit (config.home) username;
      # TODO: can dock be stretched 100% horizontally?
      entries = [
        # Default macOS apps
        { path = "/System/Applications/System Settings.app/"; }

        {
          type = "spacer";
          section = "apps";
        }

        # Additional macOS apps
        { path = "/System/Applications/Utilities/Terminal.app/"; }

        {
          type = "spacer";
          section = "apps";
        }

        # Installed using Iru
        { path = "/Applications/Google Chrome.app/"; }
        { path = "/Applications/Slack.app/"; }

        {
          type = "spacer";
          section = "apps";
        }

        # Installed using homebrew
        { path = "/Applications/kitty.app/"; }
        { path = "/Applications/Firefox.app/"; }
        { path = "/Applications/Vivaldi.app/"; }

        {
          path = "${config.home.homeDirectory}/Downloads/";
          section = "others";
        }
      ];
    };
  };
}
