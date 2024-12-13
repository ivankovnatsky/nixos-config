{
  programs.nixvim.userCommands = {
    Terminal = {
      command = "botright split | terminal"; # This uses Neovim's built-in terminal at the bottom
      desc = "Open terminal in horizontal split";
      bang = true; # Allows :Terminal! to force
      bar = true; # Allows command chaining with |
    };

    RebuildWatchman = {
      command = "botright split | terminal cd ~/Sources/github.com/ivankovnatsky/nixos-config && make rebuild-watchman";
      desc = "Open terminal and run watchman rebuild command";
      bang = true;
      bar = true;
    };

    RebuildWatchmanSpecific = {
      command = "botright split | terminal cd ~/Sources/github.com/ivankovnatsky/nixos-config && make rebuild-watchman-machine-specific";
      desc = "Open terminal and run watchman rebuild command";
      bang = true;
      bar = true;
    };
  };
}
