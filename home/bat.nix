{
  # FIXME: handle dark/light theme switch
  programs.bat = {
    enable = true;
    config = {
      theme = {
        light = "GitHub";
        dark = "Dracula";
      };
      # Other common settings
      style = "numbers,changes,header";
      italic-text = "always";
    };
  };
}
