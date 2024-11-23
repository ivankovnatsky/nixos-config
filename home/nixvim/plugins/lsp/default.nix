{
  programs.nixvim.plugins = {
    fidget.enable = true;
    # Issues:
    # * `gq` does not work when enabled, but `qw` does
    # * The formatting itself does not work for some servers
    #
    # Reference: https://github.com/neovim/neovim/issues/23381#issuecomment-1527899109.
    lsp-format.enable = true;
    lspkind = {
      enable = true;
      extraOptions = {
        maxwidth = 50;
        ellipsis_char = "...";
      };
    };
    lsp = {
      enable = true;
      servers = {
        # FIXME: https://github.com/nix-community/nixvim/blob/3d24cb72618738130e6af9c644c81fe42aa34ebc/plugins/lsp/lsp-packages.nix#L52
        # fish_lsp.enable = true;
        nil_ls.enable = true;
        lua_ls.enable = true;
      };
      keymaps = {
        silent = true;
        lspBuf = {
          gd = {
            action = "definition";
            desc = "Goto Definition";
          };
          gr = {
            action = "references";
            desc = "Goto References";
          };
          gD = {
            action = "declaration";
            desc = "Goto Declaration";
          };
          gI = {
            action = "implementation";
            desc = "Goto Implementation";
          };
          # Conflicts with prev tab keymap
          # gT = {
          #   action = "type_definition";
          #   desc = "Type Definition";
          # };
          K = {
            action = "hover";
            desc = "Hover";
          };
          "<leader>cw" = {
            action = "workspace_symbol";
            desc = "Workspace Symbol";
          };
          "<leader>cr" = {
            action = "rename";
            desc = "Rename";
          };
        };
        diagnostic = {
          "<leader>cd" = {
            action = "open_float";
            desc = "Line Diagnostics";
          };
          "[d" = {
            action = "goto_next";
            desc = "Next Diagnostic";
          };
          "]d" = {
            action = "goto_prev";
            desc = "Previous Diagnostic";
          };
        };
      };
    };
  };
}
