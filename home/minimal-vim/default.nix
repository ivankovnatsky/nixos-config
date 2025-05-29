{
  home.file.".vimrc".text = ''
    " Disable swap files
    set noswapfile

    " Auto save on text changes
    autocmd TextChanged,TextChangedI <buffer> silent write
  '';
}
