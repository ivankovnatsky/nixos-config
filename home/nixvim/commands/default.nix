{
  programs.nixvim.userCommands = {
    RebuildWatchman = {
      command = "botright split | terminal cd ~/Sources/github.com/ivankovnatsky/nixos-config && make rebuild-watchman";
      desc = "Open terminal and run watchman rebuild command.";
      bang = true;
      bar = true;
    };
    MouseToggle = {
      command = "if &mouse == 'a' | set mouse= | else | set mouse=a | endif";
      desc = "Toggle mouse.";
      bang = true;
      bar = true;
    };
    Eat = {
      command = ''
        silent %y+
        lua require('notify')('Copied file contents to clipboard', 'info')
      '';
      desc = "Copy file contents to clipboard.";
      bang = true;
      bar = true;
    };
    ReplaceFileText = {
      command = "%d | put + | 0d | wall";
      desc = "Replace text.";
      bang = true;
      bar = true;
    };
    CreatePr = {
      command = "terminal create-pr";
      desc = "Create PR with create-pr wrapper around gh CLI.";
      bang = true;
      bar = true;
    };
    MergePr = {
      command = "terminal gh pr merge --squash";
      desc = "Merge PR with gh CLI.";
      bang = true;
      bar = true;
    };
  };
}
