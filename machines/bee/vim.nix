{ pkgs, ... }:
{
  environment.variables = { EDITOR = "vim"; };

  environment.systemPackages = with pkgs; [
    ((vim_configurable.override {  }).customize{
      name = "vim";
      vimrcConfig.customRC = ''
        " Disable mouse support
        set mouse=
        
        " Auto-reload files when they change on filesystem
        set autoread
        
        " Check for file changes when cursor is idle or entering buffer
        autocmd FocusGained,BufEnter * :checktime
      '';
    }
  )];
}
