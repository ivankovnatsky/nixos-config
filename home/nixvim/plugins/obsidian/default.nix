{
  # https://github.com/nix-community/nixvim/blob/main/tests/test-sources/plugins/by-name/obsidian/default.nix#L65
  programs = {
    nixvim = {
      plugins.obsidian = {
        enable = true;

        # TODO 2025-07-25 explicitly disable legacy commands to suppress deprecation warning
        settings.disable_frontmatter = true;
        settings.legacy_commands = false;
        settings.ui.enable = false;

        # At least one workspaces is needed for the plugin to work
        settings.workspaces = [
          {
            name = "Notes";
            path = "~/Notes";
          }
        ];
      };
    };
  };
}
