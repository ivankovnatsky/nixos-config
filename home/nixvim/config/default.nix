{ config, ... }:
let
  neovimBackground = if config.flags.darkMode then "dark" else "light";
  neovimTrueColorThemeName = if config.flags.darkMode then "tokyonight-night" else "tokyonight-day";
in
{
  programs.nixvim.extraConfigLua = ''
    vim.api.nvim_set_hl(0, "Comment", { italic = true })

    -- Configuration for GitHub Copilot in Neovim using Lua
    vim.g.copilot_filetypes = {
        gitcommit = true,
        markdown = true,
        yaml = true
    }

    -- Autocommand to disable Copilot for large files
    vim.api.nvim_create_autocmd("BufReadPre", {
        callback = function()
            local file_size = vim.fn.getfsize(vim.fn.expand("<afile>"))
            if file_size > 100000 or file_size == -2 then
                vim.b.copilot_enabled = false
            end
        end
    })

    -- Disable logs, I'm not reading them and they grow too big.
    vim.lsp.set_log_level("off")

    -- Create or clear the autocommand group named 'fmt'
    local group = vim.api.nvim_create_augroup('fmt', { clear = true })

    -- Filetype specific settings for multiple types
    local filetypes = {
        dhall = 'ts=2 sts=2 sw=2 expandtab',
        jsonnet = 'ts=2 sts=2 sw=2 expandtab',
        helm = 'commentstring=#\\ %s'
    }

    for filetype, settings in pairs(filetypes) do
        local group = vim.api.nvim_create_augroup(filetype, { clear = true })
        vim.api.nvim_create_autocmd('FileType', {
            group = group,
            pattern = filetype,
            command = 'setlocal ' .. settings
        })
    end

    -- Custom filetype association
    local custom_filetype_group = vim.api.nvim_create_augroup('custom_filetype', { clear = true })
    vim.api.nvim_create_autocmd({'BufNewFile', 'BufRead'}, {
        group = custom_filetype_group,
        pattern = '*.typ',
        command = 'set filetype=typst'
    })

    -- Disable focus reporting mode when leaving Neovim to prevent [I and [O escape sequences
    -- from leaking into Claude Code
    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = function()
        if vim.env.TMUX then
          io.stdout:write("\x1bPtmux;\x1b\x1b[?1004l\x1b\\")
        else
          io.stdout:write("\x1b[?1004l")
        end
      end,
    })

    -- Apple Terminal now supports truecolor (24-bit) in macOS Tahoe
    vim.opt.termguicolors = true
    vim.o.background = ${neovimBackground}
    vim.cmd([[colorscheme ${neovimTrueColorThemeName}]])
  '';
}
