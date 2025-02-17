{
  programs.nixvim = {
    plugins = {
      copilot-lua = {
        enable = true;

        settings = {
          panel = {
            enabled = true;
            auto_refresh = false;
            keymap = {
              jump_prev = "[[";
              jump_next = "]]";
              accept = "<CR>";
              refresh = "gr";
              open = "<M-CR>";
            };
            layout = {
              position = "bottom";
              ratio = 0.4;
            };
          };
          suggestion = {
            enabled = true;
            auto_trigger = false;
            hide_during_completion = true;
            debounce = 75;
            keymap = {
              accept = "<M-l>";
              accept_word = false;
              accept_line = false;
              next = "<M-]>";
              prev = "<M-[>";
              dismiss = "<C-]>";
            };
          };
          filetypes = {
            yaml = false;
            markdown = true;
            help = false;
            gitcommit = true;
            gitrebase = false;
            hgcommit = false;
            svn = false;
            cvs = false;
            "." = false;
          };
          server_opts_overrides = {
            trace = "verbose";
            settings = {
              advanced = {
                listCount = 10; # number of completions for panel
                inlineSuggestCount = 3; # number of completions for getCompletions
              };
            };
          };
        };
      };
      cmp = {
        settings.sources = [ { name = "copilot"; } ];
      };
    };
  };
}
