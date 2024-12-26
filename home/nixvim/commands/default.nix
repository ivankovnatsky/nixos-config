{
  programs.nixvim.userCommands = {
    RebuildWatchman = {
      command = "botright split | terminal cd ~/Sources/github.com/ivankovnatsky/nixos-config && make rebuild-watchman";
      desc = "Open terminal and run watchman rebuild command";
      bang = true;
      bar = true;
    };
    MouseToggle = {
      command = "if &mouse == 'a' | set mouse= | else | set mouse=a | endif";
      desc = "Toggle mouse";
      bang = true;
      bar = true;
    };
    Eat = {
      command = "%y+";
      desc = "Copy file contents to clipboard";
      bang = true;
      bar = true;
    };
  };
}
