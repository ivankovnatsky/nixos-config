{
  programs.bash = {
    enable = true;
    historySize = 0;
    historyFile = "/dev/null";
    historyControl = [
      "ignoredups"
      "ignorespace"
    ];
    sessionVariables = {
      HISTFILE = "/dev/null";
      HISTSIZE = "0";
      HISTFILESIZE = "0";
    };
    # Disable shell options that don't work in bash 3.2 (macOS default)
    shellOptions = [ ];
    # Don't enable bash completion by default (causes issues with bash 3.2)
    enableCompletion = false;
    initExtra = ''
      # Ensure Nix paths are available in SSH sessions (for mosh-server)
      export PATH="/run/current-system/sw/bin:$PATH"
    '';
    profileExtra = ''
      # Ensure Nix paths are available in SSH sessions (for mosh-server)
      export PATH="/run/current-system/sw/bin:$PATH"

      # Added by OrbStack: command-line tools and integration
      # This won't be added again if you remove it.
      source ~/.orbstack/shell/init.bash 2>/dev/null || :
    '';
  };
}
