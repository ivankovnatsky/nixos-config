{
  programs.nixvim.userCommands = {
    RebuildWatchman = {
      command = "botright split | terminal cd ~/Sources/github.com/ivankovnatsky/nixos-config && make rebuild-watchman";
      desc = "Open terminal and run watchman rebuild command";
      bang = true;
      bar = true;
    };
  };
}
