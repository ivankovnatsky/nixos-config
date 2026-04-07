{
  programs.carapace = {
    enable = true;
    enableFishIntegration = true;
  };

  # Exclude "task" from carapace completions so it doesn't override
  # taskwarrior's "task" command with go-task completions.
  home.sessionVariables = {
    CARAPACE_EXCLUDES = "task";
  };
}
