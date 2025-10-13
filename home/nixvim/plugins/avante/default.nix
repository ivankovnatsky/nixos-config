{ pkgs, ... }:

{
  programs.nixvim = {
    # extraPlugins = with pkgs.vimPlugins; [
    # FIXME:
    #
    # ```vim
    # paste: Error executing lua:
    # ...eovimPackages/start/avante.nvim/lua/avante/clipboard.lua:51: attempt
    # to index upvalue 'ImgClip' (a nil value)^@stack
    # traceback:^@^I...eovimPackages/start/avante.nvim/lua/avante/clipboard.lua:51:
    # in function '
    # paste_image'^@^I...f7a6nai4x-vimplugin-avante.nvim-0.0.16/plugin/avante.lua:35:
    # in function
    # <...f7a6nai4x-vimplugin-avante.nvim-0.0.16/plugin/avante.lua:25>
    # ```
    # img-clip-nvim
    # ];
    # extraConfigLua = ''
    #   require('img-clip').setup({ })
    # '';
    plugins = {
      # https://github.com/yetone/avante.nvim?tab=readme-ov-file#default-setup-configuration
      # https://github.com/nix-community/nixvim/blob/f4b0b81ef9eb4e37e75f32caf1f02d5501594811/tests/test-sources/plugins/by-name/avante/default.nix#L3
      avante = {
        enable = true;
        settings = {
          debug = false;
          provider = "claude";
          auto_suggestions_provider = "claude";
          tokenizer = "tiktoken";
          system_prompt = ''
            You are an excellent programming expert.
          '';
          # https://github.com/yetone/avante.nvim/wiki/Provider-configuration-migration-guide
          providers = {
            openai = {
              endpoint = "https://api.openai.com/v1";
              timeout = 30000;
              extra_request_body = {
                temperature = 0;
                max_tokens = 4096;
              };
            };
            copilot = {
              endpoint = "https://api.githubcopilot.com";
              proxy = null;
              allow_insecure = false;
              timeout = 30000;
              extra_request_body = {
                temperature = 0;
                max_tokens = 4096;
              };
            };
            claude = {
              endpoint = "https://api.anthropic.com";
              timeout = 30000;
              extra_request_body = {
                temperature = 0;
                max_tokens = 8000;
              };
            };
          };
          behaviour = {
            auto_suggestions = false;
            auto_set_highlight_group = true;
            auto_set_keymaps = true;
            auto_apply_diff_after_generation = false;
            support_paste_from_clipboard = false;
          };
          mappings = {
            sidebar = {
              # Tab is currently used for Github Copilot.
              switch_windows = "<C-k>";
              reverse_switch_windows = "<C-j>";
            };
          };
          windows = {
            width = 40;
          };
          diff = {
            autojump = true;
          };
          hints = {
            enabled = true;
          };
        };
      };
    };
  };
}
