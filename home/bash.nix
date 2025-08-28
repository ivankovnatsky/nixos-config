{
  programs.bash = {
    enable = true;
    historySize = 0;
    historyFile = "/dev/null";
    historyControl = [ "ignoredups" "ignorespace" ];
    sessionVariables = {
      HISTFILE = "/dev/null";
      HISTSIZE = "0";
      HISTFILESIZE = "0";
    };
  };
}