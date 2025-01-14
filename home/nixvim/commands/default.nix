{ pkgs, scripts, ... }:
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
        echo "Copied file contents to clipboard"
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
      command = "terminal ${scripts.create-pr}/bin/create-pr";
      desc = "Create PR with create-pr wrapper around gh CLI.";
      bang = true;
      bar = true;
    };
    MergePr = {
      command = "terminal ${scripts.merge-pr}/bin/merge-pr";
      desc = "Merge PR with merge-pr wrapper around gh CLI.";
      bang = true;
      bar = true;
    };
    CopyPath = {
      command = ''
        let @+ = getcwd()
        echo "Copied absolute working directory path to clipboard"
      '';
      desc = "Copy absolute working directory path to clipboard.";
      bang = true;
      bar = true;
    };
    CopyFilePath = {
      command = ''
        let @+ = expand('%:p')
        echo "Copied absolute file path to clipboard"
      '';
      desc = "Copy absolute file path to clipboard.";
      bang = true;
      bar = true;
    };
    ViewPr = {
      command = "!${scripts.view-pr}/bin/view-pr";
      desc = "View PR files in browser.";
      bang = true;
      bar = true;
    };
  };
}
