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
    profileExtra = ''
      # Added by OrbStack: command-line tools and integration
      # This won't be added again if you remove it.
      source ~/.orbstack/shell/init.bash 2>/dev/null || :
    '';
  };
}
