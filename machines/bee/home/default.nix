{
  imports = [
    ../../../home/btop.nix
    ../../../home/git
    ../../../home/gpg.nix
    ../../../home/home-session-vars.nix
    ../../../home/lsd.nix
    ../../../home/neovim-minimal.nix
    # ../../../home/nixvim
    ../../../home/rebuild-diff.nix
    ../../../home/scripts.nix
    ../../../home/shell.nix
    ../../../home/starship
    ../../../home/tmux.nix
    ../../../modules/flags
    ./env.nix
    ./flags.nix
    ./packages.nix
    ../../../home/sops.nix
    ./vim.nix
  ];
}
