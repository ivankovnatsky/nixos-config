{
  programs.nixvim.extraConfigLua = ''
    -- We need to disable termguicolors in Apple Terminal not under tmux, since
    -- Terminal does not support truecolor.
    if vim.fn.getenv('TERM_PROGRAM') == 'Apple_Terminal' and vim.o.termguicolors ~= 'true' then
        vim.opt.termguicolors = false
    else
        vim.opt.termguicolors = true
    end
  '';
}
