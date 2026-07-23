{
  # https://github.com/nix-community/nixvim/blob/main/tests/test-sources/plugins/by-name/obsidian/default.nix#L65
  programs = {
    nixvim = {
      plugins.obsidian = {
        enable = true;

        # TODO 2025-07-25 explicitly disable legacy commands to suppress deprecation warning
        settings.legacy_commands = false;

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
