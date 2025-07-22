{ scripts, ... }:
let
  copyPathScript = builtins.readFile ./copy-path.vim;
  prScript = builtins.readFile ./pr.vim;
  completionScript = builtins.readFile ./completion.vim;
in
{
  programs.nixvim = {
    globals = {
      pr_script = "${scripts.pr}/bin/pr";
    };

    extraConfigVim = completionScript + "\n" + copyPathScript + "\n" + prScript;

    userCommands = {
      # TODO: Move all defined commands here in this file
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
      SpellToggle = {
        command = "if &spell | set nospell | else | set spell | endif";
        desc = "Toggle mouse.";
        bang = true;
        bar = true;
      };
      Yank = {
        command = ''
          silent %y+
          echo "Copied file contents to clipboard"
        '';
        desc = "Copy file contents to clipboard.";
        bang = true;
        bar = true;
      };
      Eat = {
        command = "Yank";
        desc = "Copy file contents to clipboard (alias for Yank).";
        bang = true;
        bar = true;
      };
      PasteReplace = {
        command = "%d | put + | 0d | wall";
        desc = "Replace file contents with clipboard.";
        bang = true;
        bar = true;
      };
      ReplaceFileText = {
        command = "PasteReplace";
        desc = "Replace file contents with clipboard (alias for PasteReplace).";
        bang = true;
        bar = true;
      };
      # Copy path to clipboard commands
      CopyPath = {
        command = "call CopyPathFunction()";
        desc = "Copy absolute working directory path to clipboard";
        bang = true;
        bar = true;
      };
      CopyPathFile = {
        command = "call CopyPathFunction('file')";
        desc = "Copy absolute file path to clipboard";
        bang = true;
        bar = true;
      };
      CopyPathDir = {
        command = "call CopyPathFunction('dir')";
        desc = "Copy directory path of current file to clipboard";
        bang = true;
        bar = true;
      };
      CopyPathGit = {
        command = "call CopyPathFunction('git')";
        desc = "Copy git-relative file path to clipboard";
        bang = true;
        bar = true;
      };

      # Pull request commands
      PrCreate = {
        command = "call PrFunction('create')";
        desc = "Create a new pull request";
        bang = true;
        bar = true;
      };
      PrMerge = {
        command = "call PrFunction('merge')";
        desc = "Merge a pull request";
        bang = true;
        bar = true;
      };
      PrView = {
        command = "call PrFunction('view')";
        desc = "View pull request files in browser";
        bang = true;
        bar = true;
      };
      E = {
        command = "e %:h/<args>";
        desc = "Open a new file in the same directory as the current file";
        nargs = 1;
        bang = true;
        bar = true;
        complete = "dir";
      };
      EditInCurrentDir = {
        command = "E <args>";
        desc = "Open a file in the same directory as the current file";
        nargs = 1;
        bang = true;
        bar = true;
        complete = "dir";
      };
      # fzf.vim muscle memory commands
      Files = {
        command = "Telescope find_files";
        desc = "Find files using Telescope";
        bang = true;
        bar = true;
      };
      Buffers = {
        command = "Telescope buffers";
        desc = "List buffers using Telescope";
        bang = true;
        bar = true;
      };
      Registers = {
        command = "Telescope registers";
        desc = "List registers using Telescope";
        bang = true;
        bar = true;
      };
      GFiles = {
        command = "Telescope git_files";
        desc = "Find git files using Telescope";
        bang = true;
        bar = true;
      };
      OFiles = {
        command = "Telescope oldfiles";
        desc = "Find recently opened files using Telescope";
        bang = true;
        bar = true;
      };
      # Ripgrep commands
      Rg = {
        command = "lua require('telescope.builtin').grep_string({ search = <q-args> })";
        desc = "Search using ripgrep (static)";
        nargs = "?";
        bang = true;
        bar = true;
      };
      RG = {
        command = "Telescope live_grep";
        desc = "Search using ripgrep (dynamic)";
        bang = true;
        bar = true;
      };
    };
  };
}
