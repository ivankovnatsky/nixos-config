{
  home.file.".vimrc".text = ''
    " Load vim defaults (includes cursor position restoration and many sensible defaults)
    source $VIMRUNTIME/defaults.vim

    " Our custom settings
    " Disable swap files
    set noswapfile

    " Auto save on text changes
    autocmd TextChanged,TextChangedI <buffer> silent write
  '';
}
