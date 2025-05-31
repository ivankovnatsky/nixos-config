{
  home.file.".vimrc".text = ''
    " Load vim defaults (normally auto-loaded when no vimrc exists, but we need
    " to explicitly source since we're creating one)
    source $VIMRUNTIME/defaults.vim

    " Our custom settings
    " Disable swap files
    set noswapfile

    " Enable mouse support
    set mouse=a

    " Auto save on text changes
    autocmd TextChanged,TextChangedI <buffer> silent write
  '';
}
