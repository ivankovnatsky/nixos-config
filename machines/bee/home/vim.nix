{ ... }:
{
  programs.vim = {
    enable = true;
    extraConfig = ''
      " Disable mouse support
      set mouse=
      
      " Auto-reload files when they change on filesystem
      set autoread
      
      " Check for file changes when cursor is idle or entering buffer
      autocmd FocusGained,BufEnter * :checktime
    '';
  };
} 
