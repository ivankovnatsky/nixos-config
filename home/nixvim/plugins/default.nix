{ pkgs, ... }:

{
  programs.nixvim = {
    plugins = {
      neo-tree.enable = true;
      treesitter = {
        enable = true;
        indent = true;
        # folding = true;
      };
      treesitter-context.enable = true;
      surround.enable = true;
      lualine.enable = true;
      lastplace.enable = true;
      commentary.enable = true;
      fugitive.enable = true;
      gitblame.enable = true;
      # Somehow typing `r` in search escapes search and places cursor in text,
      # even though it did not find any occurrences
      # flash.enable = true;
      oil.enable = true;
      undotree.enable = true;
      which-key.enable = true;
      hardtime = {
        enable = true;
        enabled = true;
        disableMouse = true;
        disabledFiletypes = [ "Oil" ];
        hint = true;
        maxCount = 4;
        maxTime = 1000;
        restrictionMode = "hint";
        restrictedKeys = { };
      };
      nvim-autopairs.enable = true;
      illuminate = {
        enable = true;
        underCursor = false;
        filetypesDenylist = [
          "Outline"
          "TelescopePrompt"
          "alpha"
          "harpoon"
          "reason"
        ];
      };
      conform-nvim = {
        enable = true;
        formatOnSave = {
          lspFallback = true;
          timeoutMs = 500;
        };
        notifyOnError = true;
        formattersByFt = { };
      };
      luasnip = {
        enable = true;
        extraConfig = {
          enable_autosnippets = true;
          store_selection_keys = "<Tab>";
        };
        fromVscode = [
          {
            lazyLoad = true;
            paths = "${pkgs.vimPlugins.friendly-snippets}";
          }
        ];
      };
      trouble.enable = true;
      cmp-emoji.enable = true;
      cmp-spell.enable = true;
      nvim-cmp = {
        enable = true;
        autoEnableSources = true;
        performance = {
          debounce = 60;
          fetchingTimeout = 200;
          maxViewEntries = 30;
        };
        snippet.expand = "luasnip";
        formatting.fields = [ "kind" "abbr" "menu" ];
        sources = [
          { name = "git"; }
          { name = "emoji"; }
          { name = "spell"; }
          { name = "nvim_lsp"; }
          {
            name = "buffer"; # text within current buffer
            option.get_bufnrs.__raw = "vim.api.nvim_list_bufs";
            keywordLength = 3;
          }
          {
            name = "path"; # file system paths
            keywordLength = 3;
          }
          {
            name = "luasnip"; # snippets
            keywordLength = 3;
          }
        ];
        mapping = {
          "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
          "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
          "<C-j>" = "cmp.mapping.select_next_item()";
          "<C-k>" = "cmp.mapping.select_prev_item()";
          "<C-e>" = "cmp.mapping.abort()";
          "<C-b>" = "cmp.mapping.scroll_docs(-4)";
          "<C-f>" = "cmp.mapping.scroll_docs(4)";
          "<C-Space>" = "cmp.mapping.complete()";
          "<CR>" = "cmp.mapping.confirm({ select = true })";
          "<S-CR>" = "cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true })";
        };
      };
      cmp-nvim-lsp.enable = true; # lsp
      cmp-buffer.enable = true;
      cmp-path.enable = true; # file system paths
      cmp_luasnip.enable = true; # snippets
      cmp-cmdline.enable = false; # autocomplete for cmdline
      telescope = {
        enable = true;
        extensions = {
          # file-browser = {
          #   enable = true;
          # };
          fzf-native = {
            enable = true;
          };
        };
        # settings = {
        #   defaults = {
        #     layout_config = {
        #       horizontal = {
        #         prompt_position = "top";
        #       };
        #     };
        #     sorting_strategy = "ascending";
        #   };
        # };
      };
    };
    extraConfigLua =
      builtins.readFile ./telescope.lua
    ;
  };
}
