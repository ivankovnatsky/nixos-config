{
  home.file.".vimrc".text = ''
    " Our custom settings
    " Disable swap files
    set noswapfile

    " Auto save on text changes
    autocmd TextChanged,TextChangedI <buffer> silent write
  '';
}
